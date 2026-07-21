// lib/presentation/thix_sante/patient/services/grossesse_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/grossesse_model.dart';

class GrossesseService {
  final _db = Supabase.instance.client;
  String get _uid => _db.auth.currentUser!.id;
  String resolveUid(String? pid) => pid ?? _uid;

  Future<PregnancyProfile?> getProfile(String? pid) async {
    final uid = resolveUid(pid);
    final res = await _db.from('pregnancy_profiles').select().eq('user_id', uid).maybeSingle();
    return res == null ? null : PregnancyProfile.fromJson(res);
  }

  Future<void> createProfile(String? pid, DateTime ddr, PregnancyType type) async {
    final uid = resolveUid(pid);
    final dpa = ddr.add(Duration(days: type == PregnancyType.jumeaux ? 259 : 280));
    await _db.from('pregnancy_profiles').upsert({
      'user_id': uid,
      'last_period_date': ddr.toIso8601String().substring(0, 10),
      'dpa': dpa.toIso8601String().substring(0, 10),
      'pregnancy_type': type.name
    }, onConflict: 'user_id');
  }

  Future<List<PregnancyVital>> getVitals(String? pid) async {
    final res = await _db.from('pregnancy_vitals').select().eq('user_id', resolveUid(pid)).order('created_at', ascending: false).limit(100);
    return (res as List).map((e) => PregnancyVital.fromJson(e)).toList();
  }

  Future<void> addVital(String? pid, String type, String value, {String? value2}) async {
    await _db.from('pregnancy_vitals').insert({'user_id': resolveUid(pid), 'type': type, 'value': value, 'value2': value2});
  }

  Future<List<PregnancyKick>> getKicks(String? pid) async {
    final res = await _db.from('pregnancy_kicks').select().eq('user_id', resolveUid(pid)).order('created_at', ascending: false).limit(100);
    return (res as List).map((e) => PregnancyKick.fromJson(e)).toList();
  }

  Future<void> addKick(String? pid) async {
    if (pid != null) throw Exception('Femme seule');
    await _db.from('pregnancy_kicks').insert({'user_id': resolveUid(pid)});
  }

  Future<List<PregnancyContraction>> getContractions(String? pid) async {
    final res = await _db.from('pregnancy_contractions').select().eq('user_id', resolveUid(pid)).order('created_at', ascending: false).limit(20);
    return (res as List).map((e) => PregnancyContraction.fromJson(e)).toList();
  }

  Future<void> addContraction(String? pid, int dur, int inter) async {
    await _db.from('pregnancy_contractions').insert({'user_id': resolveUid(pid), 'duration_sec': dur, 'interval_sec': inter});
  }

  Future<List<PregnancyJournal>> getJournals(String? pid) async {
    final res = await _db.from('pregnancy_journal').select().eq('user_id', resolveUid(pid)).order('created_at', ascending: false);
    return (res as List).map((e) => PregnancyJournal.fromJson(e)).toList();
  }

  Future<void> addJournal(String? pid, String title, String content, {String? photoUrl}) async {
    if (pid != null) throw Exception('Femme seule');
    await _db.from('pregnancy_journal').insert({'user_id': resolveUid(pid), 'title': title, 'content': content, 'photo_url': photoUrl});
  }

  // CORRIGÉ : Utilisation de ChecklistItem au lieu de PregnancyChecklist
  Future<List<ChecklistItem>> getChecklist(String? pid) async {
    final res = await _db.from('pregnancy_checklist').select().eq('user_id', resolveUid(pid));
    return (res as List).map((e) => ChecklistItem.fromJson(e)).toList();
  }

  Future<void> toggleChecklist(String id, bool done) async {
    await _db.from('pregnancy_checklist').update({'done': done}).eq('id', id);
  }

  Future<String> uploadPhoto(String? patientId, String path, dynamic bytes) async {
    return "url_de_la_photo";
  }

  Future<void> uploadDoc(String? patientId, String fileName, dynamic bytes) async {}

  Future<void> ensureDefaultChecklist(String? pid) async {
    final uid = resolveUid(pid);
    final existing = await _db.from('pregnancy_checklist').select().eq('user_id', uid).limit(1);
    if ((existing as List).isNotEmpty) return;
    final defaults = [
      {'item': 'Dossier médical + carte THIX', 'category': 'maman'},
      {'item': '3 pyjamas ouverts devant', 'category': 'maman'},
      {'item': 'Couches taille 1 + lingettes', 'category': 'bebe'},
      {'item': 'Siège auto homologué', 'category': 'bebe'},
    ];
    for (final d in defaults) {
      await _db.from('pregnancy_checklist').insert({'user_id': uid, 'item': d['item'], 'category': d['category']});
    }
  }

  Future<void> addConsultation(String? pid, String title, String desc) async {
    await _db.from('health_records').insert({
      'patient_uid': resolveUid(pid),
      'professional_uid': _uid,
      'type': 'consultation',
      'title': 'Grossesse - $title',
      'description': desc,
      'exam_date': DateTime.now().toIso8601String()
    });
  }

  List<String> calculateRisks({required int sa, List<PregnancyVital> vitals = const [], List<PregnancyKick> kicks = const [], List<PregnancyContraction> contractions = const []}) {
    final alerts = <String>[];
    final ta = vitals.where((v) => v.type == 'tension').toList();
    if (ta.isNotEmpty) {
      final sys = int.tryParse(ta.first.value.split('/').first) ?? 0;
      if (sys >= 140) alerts.add('🚨 TA ${ta.first.value} >140 - Risque pré-éclampsie');
    }
    if (kicks.where((k) => k.createdAt.day == DateTime.now().day).isEmpty && sa >= 28) {
      alerts.add('⚠️ 0 mouvement aujourd\'hui après 28 SA');
    }
    if (sa >= 37 && contractions.length >= 3) {
      final avg = contractions.take(3).map((c) => c.intervalSec).reduce((a, b) => a + b) / 3;
      if (avg <= 300) alerts.add('🚨 Contractions toutes les 5 min - Maternité');
    }
    return alerts;
  }
}
