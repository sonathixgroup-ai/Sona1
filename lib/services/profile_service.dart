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
  static const String kLightColumns = 'id,thix_id,display_name,full_name,avatar_url,bio,updated_at';
  // On ne met PLUS education/experience dans kPublicColumns - ils sont dans tables séparées
  static const String kPublicColumns = 'id,thix_id,display_name,full_name,avatar_url,bio,profession,occupation,country_or_origin,nationality,competence,thix_chat,languages,languages_detailed';

  final _cache = <String, _CacheEntry>{};
  SupabaseClient get _db => SupabaseConfig.client;

  Future<T> _retry<T>(Future<T> Function() fn) async {
    for(int i=0;i<3;i++){
      try{ return await fn(); } catch(e){
        if(i==2) rethrow;
        await Future.delayed(Duration(milliseconds: 200*(i+1) + Random().nextInt(100)));
      }
    }
    throw StateError('retry');
  }

  Future<List<ThixProfile>> fetchPublicSuggestions({int limit = 12, int offset = 0}) async {
    return _retry(() async {
      final res = await _db.from(table).select(kLightColumns).order('updated_at', ascending: false).range(offset, offset+limit-1);
      return (res as List).map((e) => ThixProfile.fromPrivateRow(e as Map<String,dynamic>)).where((p)=>p.thixId.isNotEmpty).toList();
    });
  }

  Future<ThixProfile?> fetchPublicProfileByThixId(String thixId) async {
    final normalized = thixId.trim().toUpperCase();
    final key = 'thix:$normalized';
    if(_cache[key]?.isValid == true) return _cache[key]!.profile;

    try {
      // 1. Essaie la fonction SECURITY DEFINER pour anon (fix ton screenshot)
      final rpcRes = await _db.rpc('public_verify_thix_id', params: {'p_thix_id': normalized});
      if(rpcRes is Map && rpcRes['found']==true && rpcRes['profile']!=null){
        final profile = ThixProfile.fromPrivateRow((rpcRes['profile'] as Map).cast<String,dynamic>());
        _cache[key]=_CacheEntry(profile);
        return profile;
      }
      if(rpcRes is Map && rpcRes['found']==false) return null;
    } catch (_) {
      // RPC pas encore déployée, fallback
    }

    final res = await _retry(() async {
      final row = await _db.from(table).select(kPublicColumns).eq('thix_id', normalized).maybeSingle();
      return row==null? null : ThixProfile.fromPrivateRow(row);
    });
    if(res!=null) _cache[key]=_CacheEntry(res);
    return res;
  }

  Future<ThixProfile?> fetchPublicProfileByUserId(String userId) async {
    return _retry(() async {
      final row = await _db.from(table).select(kPublicColumns).eq('id', userId).maybeSingle();
      return row==null? null : ThixProfile.fromPrivateRow(row);
    });
  }

  Future<List<Map<String,dynamic>>> fetchFormationsPaginated(String uid, {int limit=20, int offset=0}) => _fetchSub(formationsTable, uid, limit: limit, offset: offset);
  Future<List<Map<String,dynamic>>> fetchExperiencesPaginated(String uid, {int limit=20, int offset=0}) => _fetchSub(experiencesTable, uid, limit: limit, offset: offset);
  Future<List<Map<String,dynamic>>> fetchFormations(String uid) => fetchFormationsPaginated(uid, limit: 100, offset: 0);
  Future<List<Map<String,dynamic>>> fetchExperiences(String uid) => fetchExperiencesPaginated(uid, limit: 100, offset: 0);
  Future<List<Map<String,dynamic>>> fetchEmergencyContacts(String uid) => _fetchSub(emergencyContactsTable, uid, limit: 50, offset: 0);
  Future<List<Map<String,dynamic>>> _fetchSub(String tbl, String uid, {required int limit, required int offset}) async {
    return _retry(() async {
      final res = await _db.from(tbl).select().eq('user_id', uid).order('created_at', ascending: false).range(offset, offset+limit-1);
      return (res as List).cast<Map<String,dynamic>>();
    });
  }

  Stream<ThixProfile?> streamMyProfile(String uid) => _db.from(table).stream(primaryKey: ['id']).eq('id', uid).map((r)=> r.isEmpty? null : ThixProfile.fromPrivateRow(r.first));
  Stream<ThixProfile?> streamPublicProfileByThixId(String thixId) => _db.from(table).stream(primaryKey: ['id']).eq('thix_id', thixId.toUpperCase()).map((r)=> r.isEmpty? null : ThixProfile.fromPrivateRow(r.first));
  Stream<ThixProfile?> streamPublicProfileByUserId(String uid) => streamMyProfile(uid);
  Stream<List<Map<String,dynamic>>> streamFormations(String uid) => _db.from(formationsTable).stream(primaryKey: ['id']).eq('user_id', uid).map((r)=> r.cast<Map<String,dynamic>>());
  Stream<List<Map<String,dynamic>>> streamExperiences(String uid) => _db.from(experiencesTable).stream(primaryKey: ['id']).eq('user_id', uid).map((r)=> r.cast<Map<String,dynamic>>());
  Stream<List<Map<String,dynamic>>> streamEmergencyContacts(String uid) => _db.from(emergencyContactsTable).stream(primaryKey: ['id']).eq('user_id', uid).map((r)=> r.cast<Map<String,dynamic>>());

  Future<void> replaceFormations({required String userId, required List<Map<String,dynamic>> entries}) => _retry(()=>_db.rpc('thix_replace_formations', params: {'p_user_id': userId, 'p_entries': entries}));
  Future<void> replaceExperiences({required String userId, required List<Map<String,dynamic>> entries}) => _retry(()=>_db.rpc('thix_replace_experiences', params: {'p_user_id': userId, 'p_entries': entries}));
  Future<void> replaceEmergencyContacts({required String userId, required List<Map<String,dynamic>> entries}) => _retry(()=>_db.rpc('thix_replace_emergency_contacts', params: {'p_user_id': userId, 'p_entries': entries}));

  Future<void> ensureProfileExists({required AppUser user}) async {
    await _retry(()=>_db.from(table).upsert({'id': user.id, 'thix_id': user.thixId, 'avatar_url': user.photoUrl}, onConflict: 'id'));
  }

  Future<void> updateProfile({
    required String userId,
    String? displayName, String? fullName, String? photoUrl, String? bio,
    String? profession, String? occupation, String? countryOrOrigin, String? maritalStatus, String? gender, String? thixChat, String? contactPhone,
    String? dateOfBirth, String? placeOfBirth, String? nationality, String? address, String? fatherName, String? motherName,
    String? emergencyContactName, String? emergencyContactPhone, String? emergencyContactRelation,
    String? originProvince, String? originTerritory, String? originSector,
    String? residenceCountry, String? residenceProvince, String? residenceTerritory, String? residenceCity, String? residenceCommune, String? residenceQuarter, String? residenceAvenue, String? residenceNumber,
    List<Map<String,dynamic>>? emergencyContacts,
    String? height, String? weight, String? bloodGroup, bool? hasPhysicalDisability, String? physicalDisabilityDescription,
    String? nationalIdNumber, String? idDocumentType, String? idDocumentIssueDate, String? idDocumentExpiryDate, String? idDocumentIssuePlace,
    String? idDocumentFrontDocId, String? idDocumentBackDocId, String? idDocumentSelfieDocId, String? idVerificationStatus,
    String? competence, List<Map<String,dynamic>>? languagesDetailed, List<Map<String,dynamic>>? trainings,
    List<String>? languages, List<Map<String,dynamic>>? education, List<Map<String,dynamic>>? experience, List<Map<String,dynamic>>? skills,
    List<Map<String,dynamic>>? certifications, List<Map<String,dynamic>>? documents, List<Map<String,dynamic>>? contacts, dynamic visibility,
    String? thixId,
  }) async {
    final patch = <String,dynamic>{};
    void put(String k, dynamic v){ if(v!=null) patch[k]=v; }
    // FIX MILLION : on ne stocke PLUS education/experience/skills dans profiles
    put('full_name', fullName?? displayName); put('avatar_url', photoUrl); put('bio', bio);
    put('profession', profession); put('occupation', occupation); put('competence', competence);
    put('thix_chat', thixChat); put('languages', languages); put('languages_detailed', languagesDetailed);
    put('certifications', certifications); put('trainings', trainings);
    if(patch.isNotEmpty){
      await _retry(()=> _db.from(table).update(patch).eq('id', userId));
      _cache.clear(); // FIX : clear total, pas removeWhere foireux
    }
    if(education!=null || trainings!=null){
      final merged = [...?trainings,...?education];
      if(merged.isNotEmpty) await replaceFormations(userId: userId, entries: merged);
    }
    if(experience!=null) await replaceExperiences(userId: userId, entries: experience);
    if(emergencyContacts!=null) await replaceEmergencyContacts(userId: userId, entries: emergencyContacts);
    // skills : si tu as une table skills, fais pareil, sinon laisse dans patch
    if(skills!=null){
       await _retry(()=> _db.from(table).update({'skills': skills}).eq('id', userId));
    }
  }

  Future<void> updateVisibility({required String userId, required dynamic visibility}) async {
    await _retry(()=>_db.from(table).update({'visibility_settings': visibility is Map? visibility : (visibility as dynamic).toJson()}).eq('id', userId));
  }

  Future<String> generateThixId({required String uid}) async => (await _retry(()=>_db.rpc('thix_generate_id', params: {'p_user_id': uid}))).toString();
  Future<String> reserveThixChat({required String userId, required String desired}) async => (await _retry(()=>_db.rpc('thix_reserve_chat', params: {'p_user_id': userId, 'p_desired': desired.trim()}))).toString();
  Future<String> activateAccountAfterPayment({required String userId, required String countryCode, required String displayName, required String txRef, required String method, required num amount, required String currency, String? photoUrl}) async => (await _retry(()=>_db.rpc('thix_activate_account_after_payment', params: {'p_user_id': userId, 'p_country_code': countryCode, 'p_display_name': displayName, 'p_photo_url': photoUrl, 'p_method': method, 'p_tx_ref': txRef, 'p_amount': amount, 'p_currency': currency}))).toString();
}

class _CacheEntry{ final ThixProfile profile; final DateTime at=DateTime.now(); _CacheEntry(this.profile); bool get isValid => DateTime.now().difference(at).inMinutes < 2; }
