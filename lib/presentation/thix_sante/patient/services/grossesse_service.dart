import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/grossesse_model.dart';

class GrossesseService {
  final _db = Supabase.instance.client;
  String get _uid => _db.auth.currentUser!.id;
  String resolveUid(String? patientId) => patientId ?? _uid;
  bool isDoctor(String? patientId) => patientId != null && patientId != _uid;

  // Profil
  Future<PregnancyProfile?> getProfile(String? patientId) async {
    final uid = resolveUid(patientId);
    final res = await _db.from('pregnancy_profiles').select().eq('user_id', uid).maybeSingle();
    return res==null? null : PregnancyProfile.fromJson(res);
  }
  Future<void> createProfile(String? patientId, DateTime lastPeriod) async {
    final uid = resolveUid(patientId);
    final dpa = lastPeriod.add(const Duration(days: 280));
    await _db.from('pregnancy_profiles').upsert({
      'user_id': uid, 'last_period_date': lastPeriod.toIso8601String().substring(0,10),
      'dpa': dpa.toIso8601String().substring(0,10)
    }, onConflict: 'user_id');
  }

  // Vitals - femme + medecin lié
  Future<List<PregnancyVital>> getVitals(String? patientId) async {
    final uid = resolveUid(patientId);
    final res = await _db.from('pregnancy_vitals').select().eq('user_id', uid).order('created_at', ascending: false).limit(100);
    return (res as List).map((e)=> PregnancyVital.fromJson(e)).toList();
  }
  Future<void> addVital(String? patientId, VitalType type, String value, {String? value2, String? note}) async {
    final uid = resolveUid(patientId);
    await _db.from('pregnancy_vitals').insert({'user_id': uid, 'type': type.name, 'value': value, 'value2': value2, 'note': note});
  }

  // Kicks - femme seule
  Future<List<PregnancyKick>> getKicks(String? patientId) async {
    final uid = resolveUid(patientId);
    final res = await _db.from('pregnancy_kicks').select().eq('user_id', uid).order('created_at', ascending: false).limit(50);
    return (res as List).map((e)=> PregnancyKick.fromJson(e)).toList();
  }
  Future<void> addKick(String? patientId) async {
    if(isDoctor(patientId)) throw Exception('Seule la femme peut compter les coups');
    final uid = resolveUid(patientId);
    await _db.from('pregnancy_kicks').insert({'user_id': uid, 'count':1});
  }

  // Contractions - femme seule
  Future<void> addContraction(String? patientId, int duration, int interval) async {
    if(isDoctor(patientId)) throw Exception('Seule la femme');
    final uid = resolveUid(patientId);
    await _db.from('pregnancy_contractions').insert({'user_id': uid, 'duration_sec': duration, 'interval_sec': interval});
  }

  // Journal - femme seule
  Future<List<PregnancyJournal>> getJournals(String? patientId) async {
    final uid = resolveUid(patientId);
    final res = await _db.from('pregnancy_journal').select().eq('user_id', uid).order('created_at', ascending: false);
    return (res as List).map((e)=> PregnancyJournal.fromJson(e)).toList();
  }
  Future<void> addJournal(String? patientId, String title, String content, {String? photoUrl, String? mood}) async {
    if(isDoctor(patientId)) throw Exception('Journal réservé à la femme');
    final uid = resolveUid(patientId);
    await _db.from('pregnancy_journal').insert({'user_id': uid, 'title': title, 'content': content, 'photo_url': photoUrl, 'mood': mood});
  }

  // Checklist
  Future<List<PregnancyChecklist>> getChecklist(String? patientId) async {
    final uid = resolveUid(patientId);
    final res = await _db.from('pregnancy_checklist').select().eq('user_id', uid);
    return (res as List).map((e)=> PregnancyChecklist.fromJson(e)).toList();
  }
  Future<void> toggleChecklist(String id, bool done) async {
    await _db.from('pregnancy_checklist').update({'done': done}).eq('id', id);
  }
  Future<void> ensureDefaultChecklist(String? patientId) async {
    final uid = resolveUid(patientId);
    final existing = await _db.from('pregnancy_checklist').select().eq('user_id', uid).limit(1);
    if((existing as List).isNotEmpty) return;
    final defaults = [
      {'item':'Dossier médical + carte THIX','category':'maman'},
      {'item':'3 pyjamas ouverts devant','category':'maman'},
      {'item':'Couches taille 1 + lingettes','category':'bebe'},
      {'item':'Siège auto homologué','category':'bebe'},
    ];
    for(final d in defaults){ await _db.from('pregnancy_checklist').insert({'user_id': uid, 'item': d['item'], 'category': d['category']}); }
  }

  // Health_records - MEDECIN LIE SEULEMENT
  Future<void> addConsultation(String? patientId, String title, String desc) async {
    final uid = resolveUid(patientId);
    await _db.from('health_records').insert({
      'patient_uid': uid, 'professional_uid': _uid,
      'type': 'consultation', 'title': 'Grossesse - $title',
      'description': desc, 'exam_date': DateTime.now().toIso8601String(),
    });
  }

  BabyWeekInfo getBabyInfo(int sa){
    if(sa>=40) return BabyWeekInfo(fruit:'Pastèque', size:'51 cm', weight:'3.4 kg', desc:'Prêt à naître');
    if(sa>=36) return BabyWeekInfo(fruit:'Pastèque petite', size:'47 cm', weight:'2.6 kg', desc:'Tête en bas');
    if(sa>=32) return BabyWeekInfo(fruit:'Courge', size:'42 cm', weight:'1.7 kg', desc:'Os se solidifient');
    if(sa>=28) return BabyWeekInfo(fruit:'Aubergine', size:'37 cm', weight:'1 kg', desc:'Yeux ouverts');
    if(sa>=24) return BabyWeekInfo(fruit:'Maïs', size:'30 cm', weight:'600 g', desc:'Poumons en développement');
    if(sa>=20) return BabyWeekInfo(fruit:'Banane', size:'25 cm', weight:'300 g', desc:'Premiers coups');
    if(sa>=12) return BabyWeekInfo(fruit:'Citron vert', size:'6 cm', weight:'14 g', desc:'Organes formés');
    return BabyWeekInfo(fruit:'Graines', size:'0.1 cm', weight:'0 g', desc:'Fécondation');
  }
}
