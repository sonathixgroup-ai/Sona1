import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/supabase/supabase_config.dart';
import 'package:thix_id/services/platform_file_from_path_stub.dart' if (dart.library.io) 'package:thix_id/services/platform_file_from_path_io.dart';

class DocumentService {
  static const String table = 'documents';
  static const String bucket = 'documents'; // ou 'thix-credentials'

  final SupabaseClient _client;
  DocumentService({SupabaseClient? client}) : _client = client?? SupabaseConfig.client;
  static final Map<String,_UrlCache> _urlCache={};
  SupabaseClient get _db=>_client;
  Future<T> _retry<T>(Future<T> Function() fn) async { for(int i=0;i<3;i++){ try{ return await fn(); }catch(_){ if(i==2) rethrow; await Future.delayed(Duration(milliseconds:200*(i+1))); }} throw StateError('retry'); }

  static bool isBucketNotFound(Object e){ if(e is! StorageException) return false; return e.statusCode==404 && e.message.toLowerCase().contains('bucket'); }

  Future<String> uploadPickedFileToBucket({required String bucketName, required String uid, required String objectPath, required PlatformFile file, bool upsert=true}) async {
    final mime=_mime(file);
    return _retry(() async {
      final st=_db.storage.from(bucketName);
      if(kIsWeb){ return await st.uploadBinary(objectPath, file.bytes!, fileOptions: FileOptions(upsert: upsert, contentType: mime)); }
      else { return await st.upload(objectPath, fileFromPath(file.path!) as dynamic, fileOptions: FileOptions(upsert: upsert, contentType: mime)); }
    });
  }
  Future<void> deleteLatestDocumentByDocId({required String uid, required String docId}) async { final r=await fetchLatestDocumentRowByDocId(uid:uid, docId:docId); if(r!=null) await deleteDocument(uid:uid, documentId:r['id'].toString(), storagePath:r['storage_path']?.toString()); }
  Future<void> deleteObjectFromBucket({required String bucketName, required String storagePath}) async => await _db.storage.from(bucketName).remove([storagePath]);

  Future<List<Map<String,dynamic>>> fetchDocumentsPaginated(String uid,{int limit=20,int offset=0}) => _retry(() async { final res=await _db.from(table).select('id,doc_id,title,doc_type,status,file_name,mime_type,size_bytes,storage_path,created_at').eq('user_id',uid).order('created_at',ascending:false).range(offset,offset+limit-1); return (res as List).cast<Map<String,dynamic>>(); });
  Future<List<Map<String,dynamic>>> fetchDocuments(String uid,{int limit=20})=>fetchDocumentsPaginated(uid,limit:limit,offset:0);
  Stream<List<Map<String,dynamic>>> streamDocuments(String uid)=>_db.from(table).stream(primaryKey:['id']).eq('user_id',uid).map((r)=>r.cast<Map<String,dynamic>>().toList());
  Future<String> createDownloadUrl({required String storagePath, Duration expiresIn=const Duration(minutes:18), String bucketName=bucket}) async { final k='$bucketName::$storagePath'; if(_urlCache[k]?.isValid==true) return _urlCache[k]!.url; final url=await _retry(()=>_db.storage.from(bucketName).createSignedUrl(storagePath.trim(),expiresIn.inSeconds.clamp(60,3600))); _urlCache[k]=_UrlCache(url); return url; }
  Future<String> resolveRowDownloadUrl(Map<String,dynamic> row) async { final sp=(row['storage_path']??'').toString().trim(); if(sp.isEmpty) return (row['download_url']??'').toString(); return createDownloadUrl(storagePath:sp); }
  Future<String> uploadPickedFile({required String uid, required String docId, required String title, required PlatformFile file, String? docType, DateTime? expiresAt}) async { if(file.size>15*1024*1024) throw Exception('>15MB'); final p='users/$uid/${docId.toUpperCase()}/${DateTime.now().millisecondsSinceEpoch}_${file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'),'_')}'; await uploadPickedFileToBucket(bucketName:bucket,uid:uid,objectPath:p,file:file); try{ await _db.from(table).insert({'user_id':uid,'doc_id':docId.toUpperCase(),'title':title.trim().isEmpty?file.name:title.trim(),'doc_type':docType,'status':'uploaded','file_name':file.name,'mime_type':_mime(file),'size_bytes':file.size,'storage_path':p,'expires_at':expiresAt?.toIso8601String()}); }catch(e){ _db.storage.from(bucket).remove([p]).catchError((_)=>[]); rethrow; } return p; }
  Future<void> updateDocumentStatus({required String uid, required String documentId, required String status}) async => await _db.from(table).update({'status':status,'updated_at':DateTime.now().toUtc().toIso8601String()}).eq('id',documentId).eq('user_id',uid);
  Future<void> deleteDocument({required String uid, required String documentId, String? storagePath}) async { await _db.from(table).delete().eq('id',documentId).eq('user_id',uid); if(storagePath!=null&&storagePath.isNotEmpty) _db.storage.from(bucket).remove([storagePath]).catchError((_)=>[]); }
  Future<Map<String,dynamic>?> fetchLatestDocumentRowByDocId({required String uid, required String docId}) async { final r=await _db.from(table).select().eq('user_id',uid).eq('doc_id',docId.toUpperCase()).order('created_at',ascending:false).limit(1).maybeSingle(); return r==null?null:(r as Map).cast<String,dynamic>(); }
  static String _mime(PlatformFile f){ const m={'pdf':'application/pdf','png':'image/png','jpg':'image/jpeg','jpeg':'image/jpeg','webp':'image/webp','mp4':'video/mp4','mov':'video/quicktime','webm':'video/webm'}; return m[(f.extension??'').toLowerCase()]??'application/octet-stream'; }
}
class _UrlCache{ final String url; final DateTime at=DateTime.now(); _UrlCache(this.url); bool get isValid=>DateTime.now().difference(at).inMinutes<15; }
