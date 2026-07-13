import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final familyServiceProvider = Provider<FamilyService>((ref) => FamilyService());

final familyMembersProvider = FutureProvider<List<Map<String,dynamic>>>((ref) async {
  return ref.read(familyServiceProvider).getMyFamily();
});

final enfantsProvider = FutureProvider<List<Map<String,dynamic>>>((ref) async {
  return ref.read(familyServiceProvider).getEnfants();
});

class FamilyService {
  final _db = Supabase.instance.client;
  String get _uid => _db.auth.currentUser!.id;

  // GET toute la famille
  Future<List<Map<String,dynamic>>> getMyFamily() async {
    final res = await _db.from('family_members')
        .select('*')
        .eq('owner_id', _uid)
        .order('created_at', ascending: false);
    return List<Map<String,dynamic>>.from(res);
  }

  Future<List<Map<String,dynamic>>> getEnfants() async {
    final res = await _db.from('family_members')
        .select('*')
        .eq('owner_id', _uid)
        .eq('type', 'enfant')
        .order('date_naissance', ascending: true);
    return List<Map<String,dynamic>>.from(res);
  }

  // CREATE
  Future<Map<String,dynamic>> addMember({
    required String prenom,
    required String nom,
    required String type, // enfant, conjoint, parent, autre
    required String sexe,
    String? dateNaissance,
    String? lien,
    String? telephone,
    String? numeroSecu,
    String? groupeSanguin,
    String? allergies,
  }) async {
    final data = {
      'owner_id': _uid,
      'prenom': prenom.trim(),
      'nom': nom.trim(),
      'type': type,
      'sexe': sexe,
      'date_naissance': dateNaissance,
      'lien_parente': lien,
      'telephone': telephone,
      'numero_securite_sociale': numeroSecu,
      'groupe_sanguin': groupeSanguin,
      'allergies': allergies,
      'is_active': true,
    }..removeWhere((k,v)=> v==null || (v is String && v.isEmpty));

    final res = await _db.from('family_members').insert(data).select().single();
    return Map<String,dynamic>.from(res);
  }

  // UPDATE
  Future<void> updateMember(String id, Map<String,dynamic> updates) async {
    updates.removeWhere((k,v)=> v==null);
    await _db.from('family_members').update(updates).eq('id', id).eq('owner_id', _uid);
  }

  // DELETE (soft delete)
  Future<void> deleteMember(String id) async {
    await _db.from('family_members').update({'is_active': false}).eq('id', id).eq('owner_id', _uid);
  }

  Future<void> hardDelete(String id) async {
    await _db.from('family_members').delete().eq('id', id).eq('owner_id', _uid);
  }

  // Lier un patient existant via health_link
  Future<void> linkExistingPatient(String familyMemberId, String patientUserId) async {
    await _db.from('family_members').update({'linked_patient_id': patientUserId}).eq('id', familyMemberId).eq('owner_id', _uid);
  }

  // Stats pour dashboard enfants
  Future<Map<String,int>> getStats() async {
    final all = await getMyFamily();
    return {
      'total': all.length,
      'enfants': all.where((m) => m['type'] == 'enfant').length,
    };
  }
}
