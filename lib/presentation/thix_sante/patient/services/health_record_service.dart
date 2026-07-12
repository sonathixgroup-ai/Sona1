// lib/presentation/thix_sante/patient/services/health_record_service.dart
// =============================================================================
// Service: HealthRecordService
// Role: CRUD dossier medical + Upload/Download photo & ordonnance
// Storage: Supabase Storage bucket: health_docs
// Fonctionnalites modernes: upload image/PDF, generation URL signee
// =============================================================================

import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/health_record_model.dart';

class HealthRecordService {
  HealthRecordService({SupabaseClient? client})
      : _db = client?? Supabase.instance.client;

  final SupabaseClient _db;
  static const String _bucket = 'health_docs';
  static const String _table = 'health_records';

  /// Recupere tous les dossiers du patient connecte.
  Future<List<HealthRecordModel>> getMyRecords({RecordType? filterType}) async {
    final String uid = _db.auth.currentUser!.id;
    var query = _db.from(_table).select().eq('patient_uid', uid).order('created_at', ascending: false);

    if (filterType!= null) {
      query = query.eq('type', filterType.name);
    }

    final List<dynamic> data = await query;
    return data.map((e) => HealthRecordModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Stream temps reel pour dashboard.
  Stream<List<HealthRecordModel>> watchMyRecords() {
    final String uid = _db.auth.currentUser!.id;
    return _db
      .from(_table)
      .stream(primaryKey: ['id'])
      .eq('patient_uid', uid)
      .order('created_at', ascending: false)
      .map((rows) => rows.map(HealthRecordModel.fromJson).toList());
  }

  /// Upload fichier medical (photo radio, PDF ordonnance) vers Storage.
  /// Retourne l'URL publique securisee.
  Future<String> uploadMedicalFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final String uid = _db.auth.currentUser!.id;
    final String path = '$uid/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await _db.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: false),
        );

    final String publicUrl = _db.storage.from(_bucket).getPublicUrl(path);
    return publicUrl;
  }

  /// Cree un nouveau dossier medical avec ou sans fichier.
  Future<HealthRecordModel> createRecord({
    required String title,
    required RecordType type,
    String? description,
    String? fileName,
    Uint8List? fileBytes,
    String? mimeType,
    DateTime? examDate,
  }) async {
    final User? user = _db.auth.currentUser;
    if (user == null) throw Exception('Non authentifie');

    final Map<String, dynamic> myProfile =
        await _db.from('profiles').select('thix_id').eq('uid', user.id).single();

    String? fileUrl;
    int? fileSize;

    if (fileBytes!= null && fileName!= null && mimeType!= null) {
      fileUrl = await uploadMedicalFile(
        fileName: fileName,
        bytes: fileBytes,
        mimeType: mimeType,
      );
      fileSize = fileBytes.length;
    }

    final Map<String, dynamic> payload = {
      'patient_uid': user.id,
      'patient_thix_id': myProfile['thix_id'],
      'title': title,
      'type': type.name,
      'description': description,
      'file_url': fileUrl,
      'file_name': fileName,
      'file_size': fileSize,
      'mime_type': mimeType,
      'created_by_uid': user.id,
      'exam_date': examDate?.toIso8601String(),
    };

    final Map<String, dynamic> inserted =
        await _db.from(_table).insert(payload).select().single();

    return HealthRecordModel.fromJson(inserted);
  }

  /// Genere une URL signee temporaire pour download securise (validite 1h).
  Future<String> getSignedDownloadUrl(String filePath) async {
    final String url = await _db.storage.from(_bucket).createSignedUrl(filePath, 3600);
    return url;
  }

  /// Supprime un dossier et son fichier Storage associe.
  Future<void> deleteRecord(HealthRecordModel record) async {
    if (record.fileUrl!= null) {
      try {
        final String path = record.fileUrl!.split('$_bucket/').last;
        await _db.storage.from(_bucket).remove([path]);
      } catch (_) {}
    }
    await _db.from(_table).delete().eq('id', record.id);
  }

  /// Statistiques pour dashboard (12 consultations, 8 examens...).
  Future<Map<RecordType, int>> getStats() async {
    final String uid = _db.auth.currentUser!.id;
    final List<dynamic> data = await _db.from(_table).select('type').eq('patient_uid', uid);
    final Map<RecordType, int> counts = {};
    for (final row in data) {
      final RecordType t = RecordType.fromString(row['type'] as String?);
      counts[t] = (counts[t]?? 0) + 1;
    }
    return counts;
  }
}
