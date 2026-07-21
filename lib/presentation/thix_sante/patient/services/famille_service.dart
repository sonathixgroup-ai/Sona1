import 'package:flutter/foundation.dart'; // Pour kIsWeb
import 'package:supabase_flutter/supabase_flutter.dart';

class FamilleService {
  final _db = Supabase.instance.client;
  static const _table = 'family_members';
  static const _bucket = 'avatars';

  Future<List<Map<String, dynamic>>> getMembers() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return [];
    final res = await _db.from(_table).select().eq('tuteur_id', uid).order('created_at');
    return List<Map<String, dynamic>>.from(res);
  }

  Future<Map<String, dynamic>> addMember({
    required String thixId,
    required String nom,
    String? postnom,
    required String prenom,
    required DateTime dob,
    required String sexe,
    required String lien,
    String groupe = 'O+',
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

  /// Modifié pour supporter le Web et le Mobile via les octets (Bytes)
  Future<String> uploadAvatar(dynamic fileInput, String thixId) async {
    final fileName = '${_db.auth.currentUser!.id}/$thixId-${DateTime.now().millisecondsSinceEpoch}.jpg';
    
    if (kIsWeb) {
      // Si on est sur le Web, fileInput doit être un Uint8List (les octets du fichier)
      if (fileInput is Uint8List) {
        await _db.storage.from(_bucket).uploadBinary(
          fileName,
          fileInput,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );
      } else {
        throw Exception("Format de fichier non supporté sur le web (Uint8List attendu)");
      }
    } else {
      // Sur mobile (Android/iOS), fileInput peut être un String (chemin du fichier) ou un File
      final file = fileInput is String ? io.File(fileInput) : fileInput;
      // Note: si vous gardez le code mobile, vous pouvez utiliser upload standard avec un File si vous isolez l'import,
      // mais utiliser uploadBinary partout avec des bytes est encore plus propre et universel.
      await _db.storage.from(_bucket).upload(
        fileName,
        file,
        fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
      );
    }

    return _db.storage.from(_bucket).getPublicUrl(fileName);
  }

  Future<void> deleteMember(String id) async {
    await _db.from(_table).delete().eq('id', id);
  }

  Future<bool> isThixIdExists(String thixId) async {
    final r = await _db.from(_table).select('id').eq('thix_id', thixId.trim().toUpperCase()).maybeSingle();
    return r != null;
  }
}
