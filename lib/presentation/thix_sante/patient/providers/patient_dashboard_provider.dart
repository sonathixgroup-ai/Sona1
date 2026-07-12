import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/health_record_model.dart';
import '../services/health_record_service.dart';
import '../services/prescription_service.dart';

// =============================================================================
// SERVICES
// =============================================================================
final healthRecordServiceProvider = Provider<HealthRecordService>((ref) => HealthRecordService());
final prescriptionServiceProvider = Provider<PrescriptionService>((ref) => PrescriptionService());
final patientLinkServiceProvider = Provider<PatientLinkService>((ref) => PatientLinkService());

class PatientLinkService {
  Future<void> requestDoctorByThixId({required String thixId}) async {
    final db = Supabase.instance.client;
    final uid = db.auth.currentUser!.id;
    final String clean = thixId.trim().toUpperCase();
    final doc = await db.from('doctor_profiles').select('uid').eq('thix_id', clean).maybeSingle();
    if (doc == null) throw Exception('Medecin THIX ID introuvable');
    await db.from('health_links').insert({
      'patient_uid': uid,
      'doctor_uid': doc['uid'],
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}

// =============================================================================
// RECORDS
// =============================================================================
final recentRecordsProvider = FutureProvider<List<HealthRecordModel>>((ref) async {
  final service = ref.watch(healthRecordServiceProvider);
  return service.getMyRecords();
});

final prescriptionsProvider = FutureProvider<List<Map<String,dynamic>>>((ref) async {
  final db = Supabase.instance.client;
  final uid = db.auth.currentUser!.id;
  final List data = await db.from('prescriptions').select().eq('patient_uid', uid).order('created_at', ascending: false);
  return data.map((e) => e as Map<String,dynamic>).toList();
});
