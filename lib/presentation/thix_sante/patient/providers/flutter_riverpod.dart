import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/grossesse_model.dart';
import '../services/grossesse_service.dart';
import '../models/health_record_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final grossesseServiceProvider = Provider((ref)=> GrossesseService());

final grossesseProfileProvider = FutureProvider.family<PregnancyProfile?, String?>((ref, patientId) async {
  return ref.read(grossesseServiceProvider).getProfile(patientId);
});
final vitalsProvider = FutureProvider.family<List<PregnancyVital>, String?>((ref, patientId) async {
  return ref.read(grossesseServiceProvider).getVitals(patientId);
});
final kicksProvider = FutureProvider.family<List<PregnancyKick>, String?>((ref, patientId) async {
  return ref.read(grossesseServiceProvider).getKicks(patientId);
});
final journalProvider = FutureProvider.family<List<PregnancyJournal>, String?>((ref, patientId) async {
  return ref.read(grossesseServiceProvider).getJournals(patientId);
});
final checklistProvider = FutureProvider.family<List<PregnancyChecklist>, String?>((ref, patientId) async {
  final svc = ref.read(grossesseServiceProvider);
  await svc.ensureDefaultChecklist(patientId);
  return svc.getChecklist(patientId);
});
final grossesseRecordsProvider = FutureProvider.family<List<HealthRecordModel>, String?>((ref, patientId) async {
  final db = Supabase.instance.client;
  final uid = patientId ?? db.auth.currentUser!.id;
  final data = await db.from('health_records').select().eq('patient_uid', uid).or('title.ilike.%grossesse%,description.ilike.%grossesse%').order('exam_date', ascending: false);
  return (data as List).map((e)=> HealthRecordModel.fromJson(e)).toList();
});
