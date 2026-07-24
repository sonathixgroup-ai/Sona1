import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/supabase/supabase_config.dart';

class DocumentService {
  static const String table = 'documents';
  static const String bucket = 'this-documents';

  // Cache URLs signées : 18 min TTL
  static final Map<String, _SignedUrlCache> _urlCache = {};

  SupabaseClient get _db => SupabaseConfig.client;

  Future<T> _retry<T>(Future<T> Function() fn) async {
    for(int i=0;i<3;i++){
      try{ return await fn(); } catch(e){
        if(i==2) rethrow;
        await Future.delayed(Duration(milliseconds: 200*(i+1)));
      }
    }
    throw StateError('unreachable');
  }

  // ─── PAGINATION RÉELLE ───
  Future<List<Map<String,dynamic>>> fetchDocumentsPaginated(String uid, {int limit=20, int offset=0}) {
    return _retry(() async {
      final res = await _db.from(table)
         .select('id,doc_id,title,doc_type,status,file_name,mime_type,size_bytes,storage_path,created_at')
         .eq('user_id', uid)
         .order('created_at', ascending: false)
         .range(offset, offset+limit-1);
      return (res as List).cast<Map<String,dynamic>>();
    });
  }

  // Legacy compat - mais ne plus utiliser en list
  Future<List<Map<String,dynamic>>> fetchDocuments(String uid, {int limit=20}) => fetchDocumentsPaginated(uid, limit: limit, offset: 0);

  // ─── PAS DE STREAM POLLING - Realtime ou refresh manuel ───
  // Pour 1M, on bannit le polling. On expose un refresh()
  Stream<List<Map<String,dynamic>>> streamDocuments(String uid) {
    // Realtime filtré - 1 canal au lieu de 1 requête/3s
    return _db.from(table).stream(primaryKey: ['id']).eq('user_id', uid)
       .map((rows) => rows.take(20).cast<Map<String,dynamic>>().toList());
  }

  // ─── SIGNED URL AVEC CACHE ───
  Future<String> createDownloadUrl({required String storagePath, Duration expiresIn = const Duration(minutes: 18), String bucketName = bucket}) async {
    final path = storagePath.trim();
    if(path.isEmpty) throw Exception('path vide');
    final cacheKey = '$bucketName::$path';
    final cached = _urlCache[cacheKey];
    if(cached!=null && cached.isValid) return cached.url;

    return _retry(() async {
      final url = await _db.storage.from(bucketName).createSignedUrl(path, expiresIn.inSeconds.clamp(60, 3600));
      _urlCache[cacheKey] = _SignedUrlCache(url);
      return url;
    });
  }

  Future<String> resolveRowDownloadUrl(Map<String,dynamic> row) {
    final sp = (row['storage_path']??'').toString().trim();
    if(sp.isEmpty) throw Exception('storage_path manquant');
    return createDownloadUrl(storagePath: sp);
  }

  // ─── UPLOAD SÉCURISÉ + ATOMIQUE ───
  Future<String> uploadPickedFile({
    required String uid, required String docId, required String title,
    required PlatformFile file, String? docType, DateTime? expiresAt,
  }) async {
    if(file.size > 15 * 1024) throw Exception('Fichier trop lourd >15MB');
    final mime = _validateMime(file);
    final normalizedDocId = docId.trim().toUpperCase();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final storagePath = 'users/$uid/$normalizedDocId/${ts}_$safeName';

    // 1. Upload storage
    await _retry(() async {
      final storage = _db.storage.from(bucket);
      if(kIsWeb){
        if(file.bytes==null) throw Exception('bytes null');
        await storage.uploadBinary(storagePath, file.bytes!, fileOptions: FileOptions(upsert: false, contentType: mime));
      } else {
        if(file.path==null) throw Exception('path null');
        await storage.upload(storagePath, File(file.path!), fileOptions: FileOptions(upsert: false, contentType: mime));
      }
    });

    // 2. Insert metadata via RPC atomique (rollback storage si fail)
    try{
      await _retry(()=> _db.from(table).insert({
        'user_id': uid, 'doc_id': normalizedDocId, 'title': title.trim().isEmpty? file.name : title.trim(),
        'doc_type': docType, 'status': 'uploaded', 'file_name': file.name,
        'mime_type': mime, 'size_bytes': file.size, 'storage_path': storagePath,
        'expires_at': expiresAt?.toUtc().toIso8601String(),
      }));
    } catch(e){
      // Rollback orphelin
      await _db.storage.from(bucket).remove([storagePath]).catchError((_)=>[]);
      rethrow;
    }
    return storagePath;
  }

  Future<void> deleteDocument({required String uid, required String documentId, String? storagePath}) async {
    // Ordre : DB d'abord pour révoquer l'accès, puis storage async
    await _retry(()=> _db.from(table).delete().eq('id', documentId).eq('user_id', uid));
    if(storagePath!=null && storagePath.isNotEmpty){
      _db.storage.from(bucket).remove([storagePath]).catchError((_)=>[]); // fire & forget
    }
  }

  Future<Map<String,dynamic>?> fetchLatestDocumentRowByDocId({required String uid, required String docId}) async {
    final row = await _db.from(table).select('id,storage_path').eq('user_id', uid).eq('doc_id', docId.toUpperCase()).order('created_at', ascending: false).limit(1).maybeSingle();
    return row==null? null : (row as Map).cast<String,dynamic>();
  }

  static String _validateMime(PlatformFile file){
    final ext = (file.extension??'').toLowerCase();
    const allowed = {'pdf':'application/pdf','jpg':'image/jpeg','jpeg':'image/jpeg','png':'image/png','webp':'image/webp'};
    final mime = allowed[ext];
    if(mime==null) throw Exception('Type non autorisé: $ext');
    return mime;
  }
}

class _SignedUrlCache {
  final String url; final DateTime at = DateTime.now();
  _SignedUrlCache(this.url);
  bool get isValid => DateTime.now().difference(at).inMinutes < 15;
}
