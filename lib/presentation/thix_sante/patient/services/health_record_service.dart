// lib/presentation/thix_sante/patient/services/health_record_service.dart
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/health_record_model.dart';

class HealthRecordService {
  final _db = Supabase.instance.client;
  String get _uid => _db.auth.currentUser!.id;

  Future<List<HealthRecordModel>> getMyRecords({RecordType? filter}) async {
    var q = _db.from('health_records').select().eq('patient_id', _uid).order('created_at', ascending: false);
    final res = await q;
    var list = (res as List).map((e)=>HealthRecordModel.fromJson(e)).toList();
    if(filter!=null) list = list.where((r)=>r.type==filter).toList();
    return list;
  }

  Future<HealthRecordModel> createRecord({
    required String title,
    required RecordType type,
    String? description,
    required String fileName,
    required Uint8List fileBytes,
    required String mimeType,
    required DateTime examDate,
  }) async {
    final path = '$_uid/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _db.storage.from('medical-docs').uploadBinary(path, fileBytes, fileOptions: FileOptions(contentType: mimeType, upsert: true));

    final inserted = await _db.from('health_records').insert({
      'patient_id': _uid,
      'title': title,
      'type': type.name,
      'description': description,
      'file_name': fileName,
      'file_path': path,
      'file_size': fileBytes.length,
      'mime_type': mimeType,
      'exam_date': examDate.toIso8601String().substring(0,10),
    }).select().single();

    return HealthRecordModel.fromJson(inserted);
  }

  Future<void> deleteRecord(String id) async {
    final rec = await _db.from('health_records').select('file_path').eq('id', id).eq('patient_id', _uid).maybeSingle();
    if(rec!=null && rec['file_path']!=null){
      try{ await _db.storage.from('medical-docs').remove([rec['file_path']]); }catch(_){}
    }
    await _db.from('health_records').delete().eq('id', id).eq('patient_id', _uid);
  }

  Future<String> getSignedUrl(String filePath) async {
    return await _db.storage.from('medical-docs').createSignedUrl(filePath, 3600);
  }
}
