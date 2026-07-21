import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class FamilleService {
  final _db = Supabase.instance.client;
  static const _table = 'family_members';
  static const _bucket = 'avatars';

  Future<List<Map<String,dynamic>>> getMembers() async {
    final uid = _db.auth.currentUser?.id;
    if(uid==null) return [];
    final res = await _db.from(_table).select().eq('tuteur_id', uid).order('created_at');
    return List<Map<String,dynamic>>.from(res);
  }

  Future<Map<String,dynamic>> addMember({
    required String thixId,
    required String nom,
    String? postnom,
    required String prenom,
    required DateTime dob,
    required String sexe, // M/F
    required String lien, // Fille/Fils
    String groupe='O+',
    double? poids,
    double? taille,
    String? avatarUrl,
  }) async {
    final uid = _db.auth.currentUser!.id;
    final payload = {
      'tuteur_id': uid,
      'thix_id': thixId.toUpperCase().trim(),
      'nom': nom,
      'postnom': postnom,
      'prenom': prenom,
      'date_naissance': dob.toIso8601String(),
      'sexe': sexe,
      'lien': lien,
      'role': '$lien - ${DateTime.now().year - dob.year} ans',
      'groupe_sanguin': groupe,
      'poids': poids,
      'taille': taille,
      'avatar_url': avatarUrl,
      'is_verified': true,
    };
    final res = await _db.from(_table).insert(payload).select().single();
    return res;
  }

  Future<String> uploadAvatar(String localPath, String thixId) async {
    try {
      await _db.storage.from(_bucket).createBucket(_bucket);
    } catch (_) {}
    final file = File(localPath);
    final fileName = '${_db.auth.currentUser!.id}/$thixId-${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _db.storage.from(_bucket).upload(fileName, file, fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'));
    return _db.storage.from(_bucket).getPublicUrl(fileName);
  }

  Future<void> updateMember(String id, Map<String,dynamic> data) async {
    await _db.from(_table).update(data).eq('id', id);
  }

  Future<void> deleteMember(String id) async {
    await _db.from(_table).delete().eq('id', id);
  }

  // Lien dossier santé enfant
  Future<Map<String,dynamic>?> getChildHealth(String thixId) async {
    // health_records, prescriptions, appointments liés à l'enfant via thix_id
    try {
      final rec = await _db.from('health_records').select().eq('patient_thix_id', thixId).limit(5);
      final presc = await _db.from('prescriptions').select().eq('patient_thix_id', thixId).limit(3);
      return {'records': rec, 'prescriptions': presc};
    } catch (_) { return null; }
  }

  Future<bool> isThixIdExists(String thixId) async {
    final r = await _db.from(_table).select('id').eq('thix_id', thixId.trim().toUpperCase()).maybeSingle();
    return r != null;
  }
}
