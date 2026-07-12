// lib/presentation/mon_pays/services/authorities_service.dart

import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/authority.dart';

class AuthoritiesService {
  final SupabaseClient _client = Supabase.instance.client;

  // ============================================================
  // STORAGE (UPLOAD FICHIERS)
  // ============================================================

  /// Télécharge un fichier (photo ou vidéo) vers Supabase Storage
  /// Retourne l'URL publique du fichier
  Future<String> uploadMedia(String fileName, Uint8List fileBytes, {bool isVideo = false}) async {
    try {
      final folder = isVideo ? 'videos' : 'photos';
      final path = 'authorities/$folder/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      
      // Envoi du fichier dans le bucket "media"
      await _client.storage.from('media').uploadBinary(
        path, 
        fileBytes,
        fileOptions: FileOptions(
          upsert: true,
          contentType: isVideo ? 'video/mp4' : 'image/jpeg',
        ),
      );
      
      // Récupérer le lien public
      return _client.storage.from('media').getPublicUrl(path);
    } catch (e) {
      throw Exception('Erreur lors du téléchargement du média: $e');
    }
  }

  // ============================================================
  // READ
  // ============================================================

  Future<List<Authority>> getAuthorities({String? category}) async {
    try {
      var query = _client.from('authorities').select('*');
      if (category != null && category != 'Tous' && category != 'Toutes') {
        query = query.eq('title', category);
      }
      final response = await query.order('name');
      return response.map((json) => Authority.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des autorités: $e');
    }
  }

  Future<Authority> getAuthorityById(String id) async {
    try {
      final response = await _client.from('authorities').select('*').eq('id', id).single();
      return Authority.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors du chargement de l\'autorité: $e');
    }
  }

  Future<List<Authority>> searchAuthorities(String query) async {
    try {
      if (query.trim().isEmpty) return [];
      final response = await _client
          .from('authorities')
          .select('*')
          .ilike('name', '%$query%')
          .order('name');
      return response.map((json) => Authority.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  Future<List<Authority>> getAuthoritiesByParty(String party) async {
    try {
      if (party.trim().isEmpty) return [];
      final response = await _client.from('authorities').select('*').eq('party', party).order('name');
      return response.map((json) => Authority.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement par parti: $e');
    }
  }

  // ============================================================
  // CREATE
  // ============================================================

  Future<Authority> createAuthority(Authority authority) async {
    try {
      final authData = authority.toJson();
      if (authData['id'] == null || authData['id'] == '') {
        authData.remove('id');
      }

      final response = await _client
          .from('authorities')
          .insert(authData)
          .select()
          .single();
      return Authority.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la création: $e');
    }
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<Authority> updateAuthority(Authority authority) async {
    try {
      final response = await _client
          .from('authorities')
          .update(authority.toJson())
          .eq('id', authority.id)
          .select()
          .single();
      return Authority.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deleteAuthority(String id) async {
    try {
      await _client.from('authorities').delete().eq('id', id);
    } catch (e) {
      throw Exception('Erreur lors de la suppression: $e');
    }
  }
}
