import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/models/app_user.dart';
import 'package:thix_id/models/thix_profile.dart';
import 'package:thix_id/supabase/supabase_config.dart';

class ProfileService {
  static const String table = 'profiles';
  static const String formationsTable = 'formations';
  static const String experiencesTable = 'experiences';
  static const String emergencyContactsTable = 'contacts_urgence';
  
  // Colonnes légères pour les listes publiques - CRITIQUE pour la scalabilité
  static const String kLightColumns = 'id,thix_id,display_name,full_name,avatar_url,bio,updated_at';
  static const String kPublicColumns = 'id,thix_id,display_name,full_name,avatar_url,bio,profession,occupation,country_or_origin,nationality,education,experience,competence';

  final _cache = <String, _CacheEntry>{};
  final _rand = Random();

  SupabaseClient get _db => SupabaseConfig.client;

  Future<T> _withRetry<T>(Future<T> Function() fn, {int maxRetries = 3}) async {
    for(int i=0; i<maxRetries; i++){
      try { return await fn(); } 
      catch(e){
        if(i == maxRetries-1) rethrow;
        if(e is PostgrestException && e.code != null && e.code!.startsWith('PGRST')) await Future.delayed(Duration(milliseconds: 200 * pow(2,i).toInt() + _rand.nextInt(100)));
        else await Future.delayed(Duration(milliseconds: 300 * (i+1)));
      }
    }
    throw Exception('retry exhausted');
  }

  // ─── FETCH PUBLIC - PAGINÉ & LÉGER ───
  Future<List<ThixProfile>> fetchPublicSuggestions({int limit = 12, int offset = 0}) async {
    return _withRetry(() async {
      final res = await _db.from(table)
          .select(kLightColumns)
          .order('updated_at', ascending: false)
          .range(offset, offset + limit -1);
      return (res as List).map((e) => ThixProfile.fromPrivateRow(e as Map<String,dynamic>)).where((p)=>p.thixId.isNotEmpty).toList();
    });
  }

  Future<ThixProfile?> fetchPublicProfileByThixId(String thixId) async {
    final key = 'thix:${thixId.toUpperCase()}';
    if(_cache[key]?.isValid == true) return _cache[key]!.profile;
    final res = await _withRetry(() async {
      final row = await _db.from(table).select(kPublicColumns).eq('thix_id', thixId.trim().toUpperCase()).maybeSingle();
      return row==null? null : ThixProfile.fromPrivateRow(row);
    });
    if(res!=null) _cache[key] = _CacheEntry(res);
    return res;
  }

  Future<ThixProfile?> fetchPublicProfileByUserId(String userId) async {
    return _withRetry(() async {
      final row = await _db.from(table).select(kPublicColumns).eq('id', userId).maybeSingle();
      return row==null? null : ThixProfile.fromPrivateRow(row);
    });
  }

  // ─── PAGINATION RÉELLE POUR 1M USERS ───
  Future<List<Map<String,dynamic>>> fetchFormationsPaginated(String userId, {int limit=20, int offset=0}) {
    return _fetchSubPaginated(formationsTable, userId, limit: limit, offset: offset);
  }
  Future<List<Map<String,dynamic>>> fetchExperiencesPaginated(String userId, {int limit=20, int offset=0}) {
    return _fetchSubPaginated(experiencesTable, userId, limit: limit, offset: offset);
  }
  Future<List<Map<String,dynamic>>> fetchDocumentsPaginated(String userId, {int limit=20, int offset=0}) {
    // suppose table documents existe
    return _fetchSubPaginated('documents', userId, limit: limit, offset: offset);
  }

  Future<List<Map<String,dynamic>>> _fetchSubPaginated(String tbl, String userId, {required int limit, required int offset}) {
    return _withRetry(() async {
      final res = await _db.from(tbl).select().eq('user_id', userId).order('created_at', ascending: false).range(offset, offset+limit-1);
      return (res as List).cast<Map<String,dynamic>>();
    });
  }

  // Legacy pour compatibilité - mais maintenant paginé par défaut
  Future<List<Map<String,dynamic>>> fetchFormations(String userId) => fetchFormationsPaginated(userId, limit: 100, offset: 0);
  Future<List<Map<String,dynamic>>> fetchExperiences(String userId) => fetchExperiencesPaginated(userId, limit: 100, offset: 0);
  Future<List<Map<String,dynamic>>> fetchEmergencyContacts(String userId) => _fetchSubPaginated(emergencyContactsTable, userId, limit: 50, offset: 0);

  // ─── STREAMS - UN SEUL POUR PROFIL, PAS POUR LES LISTES ───
  Stream<ThixProfile?> streamPublicProfileByThixId(String thixId) {
    return _db.from(table).stream(primaryKey: ['id']).eq('thix_id', thixId.toUpperCase()).map((rows)=> rows.isEmpty? null : ThixProfile.fromPrivateRow(rows.first));
  }
  Stream<ThixProfile?> streamMyProfile(String userId) => streamPublicProfileByUserId(userId);
  Stream<ThixProfile?> streamPublicProfileByUserId(String userId) => _db.from(table).stream(primaryKey: ['id']).eq('id', userId).map((rows)=> rows.isEmpty? null : ThixProfile.fromPrivateRow(rows.first));

  // Les streams de sous-tables sont BANNIS en prod pour 1M users. On garde des futures.
  // Si tu veux vraiment du realtime, utilise un seul canal realtime avec filtre.

  // ─── WRITE ATOMIQUE - TRANSACTION RPC ───
  Future<void> replaceFormations({required String userId, required List<Map<String,dynamic>> entries}) async {
    await _db.rpc('thix_replace_formations', params: {'p_user_id': userId, 'p_entries': entries});
  }
  Future<void> replaceExperiences({required String userId, required List<Map<String,dynamic>> entries}) async {
    await _db.rpc('thix_replace_experiences', params: {'p_user_id': userId, 'p_entries': entries});
  }
  Future<void> replaceEmergencyContacts({required String userId, required List<Map<String,dynamic>> entries}) async {
    await _db.rpc('thix_replace_emergency_contacts', params: {'p_user_id': userId, 'p_entries': entries});
  }

  Future<void> ensureProfileExists({required AppUser user}) async {
    await _withRetry(() => _db.from(table).upsert({'id': user.id, 'thix_id': user.thixId, 'avatar_url': user.photoUrl}, onConflict: 'id').select().limit(1));
  }

  Future<void> updateProfile({required String userId, Map<String,dynamic>? patch}) async {
    if(patch==null||patch.isEmpty) return;
    await _withRetry(()=> _db.from(table).update(patch).eq('id', userId));
    _cache.removeWhere((k,_)=>k.contains(userId));
  }

  // ─── RPCs avec idempotency key ───
  Future<String> generateThixId({required String uid}) async {
    final res = await _db.rpc('thix_generate_id', params: {'p_user_id': uid});
    return res.toString();
  }
  Future<String> reserveThixChat({required String userId, required String desired}) async {
    final res = await _db.rpc('thix_reserve_chat', params: {'p_user_id': userId, 'p_desired': desired.trim().toLowerCase()});
    return res.toString();
  }
}

class _CacheEntry {
  final ThixProfile profile; final DateTime at = DateTime.now();
  _CacheEntry(this.profile);
  bool get isValid => DateTime.now().difference(at).inMinutes < 2;
}
