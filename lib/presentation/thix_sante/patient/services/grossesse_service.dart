// lib/presentation/thix_sante/patient/services/grossesse_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/grossesse_model.dart';

class GrossesseService {
  final _db = Supabase.instance.client;
  String get _uid => _db.auth.currentUser!.id;
  String resolveUid(String? pid)=> pid?? _uid;

  Future<PregnancyProfile?> getProfile(String? pid) async {
    final uid = resolveUid(pid);
    try{ final res = await _db.from('pregnancy_profiles').select().eq('user_id', uid).maybeSingle(); if(res!=null) { await Hive.box('grossesse').put('profile_$uid', res); return PregnancyProfile.fromJson(res);} }catch(_){}
    final cached = Hive.box('grossesse').get('profile_$uid'); return cached!=null? PregnancyProfile.fromJson(Map<String,dynamic>.from(cached)) : null;
  }
  Future<void> createProfile(String? pid, DateTime ddr, PregnancyType type) async {
    final uid = resolveUid(pid); final dpa = ddr.add(Duration(days: type==PregnancyType.jumeaux? 259 : 280));
    await _db.from('pregnancy_profiles').upsert({'user_id': uid, 'last_period_date': ddr.toIso8601String().substring(0,10), 'dpa': dpa.toIso8601String().substring(0,10), 'pregnancy_type': type.name}, onConflict: 'user_id');
  }

  // Risques métier
  List<String> calculateRisks({required int sa, List<PregnancyVital> vitals = const [], List<PregnancyKick> kicks = const [], List<PregnancyContraction> contractions = const []}){
    final alerts = <String>[];
    final ta = vitals.where((v)=> v.type=='tension').toList();
    if(ta.isNotEmpty){ final last = ta.first.value; final parts = last.split('/'); if(parts.isNotEmpty){ final sys = int.tryParse(parts[0])??0; if(sys>=140) alerts.add('🚨 TA $last > 140/90 - Risque pré-éclampsie - Consulter'); } }
    if(kicks.isNotEmpty){ final today = kicks.where((k)=> k.createdAt.day==DateTime.now().day).length; if(today==0 && sa>=28) alerts.add('⚠️ 0 mouvement aujourd\'hui après 28 SA - Consulter'); }
    if(sa>=37 && contractions.length>=3){ final avgInterval = contractions.take(3).map((c)=> c.intervalSec).reduce((a,b)=> a+b)/3; if(avgInterval<=300) alerts.add('🚨 Contractions toutes les 5 min - Va à la maternité'); }
    return alerts;
  }

  Future<void> addVital(String? pid, String type, String value, {String? v2}) async { await _db.from('pregnancy_vitals').insert({'user_id': resolveUid(pid), 'type': type, 'value': value, 'value2': v2}); }
  Future<List<PregnancyVital>> getVitals(String? pid) async { final res = await _db.from('pregnancy_vitals').select().eq('user_id', resolveUid(pid)).order('created_at', ascending:false).limit(100); return (res as List).map((e)=> PregnancyVital.fromJson(e)).toList(); }
  Future<void> addKick(String? pid) async { if(pid!=null) throw Exception('Femme seule'); await _db.from('pregnancy_kicks').insert({'user_id': resolveUid(pid)}); }
  Future<List<PregnancyKick>> getKicks(String? pid) async { final res = await _db.from('pregnancy_kicks').select().eq('user_id', resolveUid(pid)).order('created_at', ascending:false).limit(100); return (res as List).map((e)=> PregnancyKick.fromJson(e)).toList(); }
  Future<void> addJournal(String? pid, String title, String content, {String? photoUrl}) async { if(pid!=null) throw Exception('Femme seule'); await _db.from('pregnancy_journal').insert({'user_id': resolveUid(pid), 'title': title, 'content': content, 'photo_url': photoUrl}); }
  Future<List<PregnancyJournal>> getJournals(String? pid) async { final res = await _db.from('pregnancy_journal').select().eq('user_id', resolveUid(pid)).order('created_at', ascending:false); return (res as List).map((e)=> PregnancyJournal.fromJson(e)).toList(); }
  Future<List<PregnancyContraction>> getContractions(String? pid) async { final res = await _db.from('pregnancy_contractions').select().eq('user_id', resolveUid(pid)).order('created_at', ascending:false).limit(20); return (res as List).map((e)=> PregnancyContraction.fromJson(e)).toList(); }
  Future<void> addContraction(String? pid, int dur, int inter) async { await _db.from('pregnancy_contractions').insert({'user_id': resolveUid(pid), 'duration_sec': dur, 'interval_sec': inter}); }
  Future<String> uploadPhoto(String? pid, String path, List<int> bytes) async { final uid = resolveUid(pid); final name = '${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg'; await _db.storage.from('pregnancy_photos').uploadBinary(name, bytes as dynamic); return _db.storage.from('pregnancy_photos').getPublicUrl(name); }
  Future<String> uploadDoc(String? pid, String fileName, List<int> bytes) async { final uid = resolveUid(pid); final name = '${uid}/${DateTime.now().millisecondsSinceEpoch}_$fileName'; await _db.storage.from('pregnancy_docs').uploadBinary(name, bytes as dynamic); return _db.storage.from('pregnancy_docs').getPublicUrl(name); }
  Future<void> addConsultation(String? pid, String title, String desc) async { await _db.from('health_records').insert({'patient_uid': resolveUid(pid), 'professional_uid': _uid, 'type': 'consultation', 'title': 'Grossesse - $title', 'description': desc, 'exam_date': DateTime.now().toIso8601String()}); }
}
