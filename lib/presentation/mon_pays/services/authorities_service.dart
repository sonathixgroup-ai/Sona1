// lib/presentation/mon_pays/services/authorities_service.dart

import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/authority.dart';

class AuthoritiesService {
  final SupabaseClient _client = Supabase.instance.client;

  // ============================================================
  // ASSISTANT IA (Tavily + Astral IA)
  // ============================================================

  /// Interroge vos agents IA (Tavily + Astral IA) pour récupérer 
  /// et structurer les informations d'une personnalité au format JSON
  Future<Map<String, dynamic>> fetchAuthorityDataWithAi(String query) async {
    try {
      // ⚠️ Branchez ici votre appel HTTP vers votre backend ou votre service IA existant
      // Exemple :
      // final response = await http.post(
      //   Uri.parse('VOTRE_ENDPOINT_API_THIX_IA'),
      //   headers: {'Authorization': 'Bearer VOTRE_TOKEN', 'Content-Type': 'application/json'},
      //   body: jsonEncode({'query': query, 'use_tavily': true}),
      // );
      // if (response.statusCode == 200) {
      //   return jsonDecode(response.body);
      // }

      // Simulation en attendant le raccordement de vos endpoints :
      await Future.delayed(const Duration(seconds: 2));

      return {
        'name': query,
        'title': 'Ministre / Haute Autorité',
        'category': 'Gouvernement',
        'biography': 'Biographie officielle récupérée et recoupée par Tavily et structurée par Astral IA.',
        'mandate': '2024 - Présent',
        'party': 'Union Sacrée',
        'imageUrl': 'https://i.pravatar.cc/300?u=$query',
        'education': [],
        'career': [],
        'achievements': [],
      };
    } catch (e) {
      throw Exception('Erreur de l\'assistant Thix IA: $e');
    }
  }

  // ============================================================
  // STORAGE (UPLOAD FICHIERS)
  // ============================================================

  Future<String> uploadMedia(String fileName, Uint8List fileBytes,
      {String folder = 'photos'}) async {
    try {
      final path =
          'authorities/$folder/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      await _client.storage.from('media').uploadBinary(
            path,
            fileBytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType:
                  folder == 'videos' ? 'video/mp4' : 'image/jpeg',
            ),
          );
      return _client.storage.from('media').getPublicUrl(path);
    } catch (e) {
      throw Exception('Erreur upload média: $e');
    }
  }

  // ============================================================
  // READ AVEC PAGINATION SCALABLE
  // ============================================================

  /// Récupère les autorités avec pagination et filtres optimisés
  Future<PaginatedResult<Authority>> getAuthoritiesPaginated({
    int page = 0,
    int limit = 20,
    String? category,
    String? search,
    bool? activeOnly,
  }) async {
    try {
      final offset = page * limit;
      
      var query = _client
          .from('authorities')
          .select(
              '*, education:authority_education(*), career:authority_career(*), achievements:authority_achievements(*), photos:authority_photos(*), videos:authority_videos(*), documents:authority_documents(*)'
          );

      if (category != null && category != 'Tous') {
        query = query.eq('title', category);
      }
      if (activeOnly == true) {
        query = query.eq('is_active', true);
      } else if (activeOnly == false) {
        query = query.eq('is_active', false);
      }
      if (search != null && search.trim().isNotEmpty) {
        query = query.or('name.ilike.%$search%,title.ilike.%$search%');
      }

      final response = await query.order('name').range(offset, offset + limit - 1);

      var countQuery = _client.from('authorities').select();
      if (category != null && category != 'Tous') {
        countQuery = countQuery.eq('title', category);
      }
      if (activeOnly == true) {
        countQuery = countQuery.eq('is_active', true);
      } else if (activeOnly == false) {
        countQuery = countQuery.eq('is_active', false);
      }
      if (search != null && search.trim().isNotEmpty) {
        countQuery = countQuery.or('name.ilike.%$search%,title.ilike.%$search%');
      }
      final countResponse = await countQuery;
      final totalCount = (countResponse as List).length;

      final data = response.map((json) => Authority.fromJson(json)).toList();

      return PaginatedResult(
        data: data,
        total: totalCount,
        page: page,
        limit: limit,
        hasMore: (offset + limit) < totalCount,
      );
    } catch (e) {
      throw Exception('Erreur chargement autorités: $e');
    }
  }

  /// Récupère une autorité avec toutes ses relations
  Future<Authority> getAuthorityWithRelations(String id) async {
    try {
      final response = await _client
          .from('authorities')
          .select(
              '*, education:authority_education(*), career:authority_career(*), achievements:authority_achievements(*), photos:authority_photos(*), videos:authority_videos(*), documents:authority_documents(*)')
          .eq('id', id)
          .single();
      return Authority.fromJson(response);
    } catch (e) {
      throw Exception('Erreur chargement autorité: $e');
    }
  }

  /// Récupère les autorités actives uniquement (pour l'affichage principal)
  Future<List<Authority>> getActiveAuthorities() async {
    try {
      final response = await _client
          .from('authorities')
          .select('*')
          .eq('is_active', true)
          .order('name');
      return response.map((json) => Authority.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur chargement autorités actives: $e');
    }
  }

  /// Récupère les autorités historiques (mandat terminé)
  Future<List<Authority>> getHistoricalAuthorities() async {
    try {
      final response = await _client
          .from('authorities')
          .select('*')
          .eq('is_active', false)
          .order('mandate_end', ascending: false);
      return response.map((json) => Authority.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur chargement autorités historiques: $e');
    }
  }

  // ============================================================
  // CREATE / UPDATE / DELETE
  // ============================================================

  Future<Authority> createAuthority(Authority authority) async {
    try {
      final data = authority.toJson();
      data.remove('id');

      data.remove('education');
      data.remove('career');
      data.remove('achievements');
      data.remove('photos');
      data.remove('videos');
      data.remove('documents');

      final response = await _client
          .from('authorities')
          .insert(data)
          .select()
          .single();

      final newAuthority = Authority.fromJson(response);

      await _insertRelations(newAuthority.id, authority);

      return await getAuthorityWithRelations(newAuthority.id);
    } catch (e) {
      throw Exception('Erreur lors de la création: $e');
    }
  }

  Future<Authority> updateAuthority(Authority authority) async {
    try {
      final data = authority.toJson();
      data.remove('education');
      data.remove('career');
      data.remove('achievements');
      data.remove('photos');
      data.remove('videos');
      data.remove('documents');

      await _client
          .from('authorities')
          .update(data)
          .eq('id', authority.id);

      await _deleteRelations(authority.id);
      await _insertRelations(authority.id, authority);

      return await getAuthorityWithRelations(authority.id);
    } catch (e) {
      throw Exception('Erreur mise à jour: $e');
    }
  }

  Future<void> deleteAuthority(String id) async {
    try {
      await _deleteRelations(id);
      await _client.from('authorities').delete().eq('id', id);
    } catch (e) {
      throw Exception('Erreur suppression: $e');
    }
  }

  Future<void> archiveAuthority(String id) async {
    try {
      await _client
          .from('authorities')
          .update({'is_active': false})
          .eq('id', id);
    } catch (e) {
      throw Exception('Erreur archivage: $e');
    }
  }

  // ============================================================
  // RELATIONS PRIVÉES
  // ============================================================

  Future<void> _insertRelations(String authorityId, Authority authority) async {
    for (var item in authority.education) {
      final data = item.toJson();
      data.remove('id');
      data['authority_id'] = authorityId;
      await _client.from('authority_education').insert(data);
    }

    for (var item in authority.career) {
      final data = item.toJson();
      data.remove('id');
      data['authority_id'] = authorityId;
      await _client.from('authority_career').insert(data);
    }

    for (var item in authority.achievements) {
      final data = item.toJson();
      data.remove('id');
      data['authority_id'] = authorityId;
      await _client.from('authority_achievements').insert(data);
    }

    for (var item in authority.photos) {
      final data = item.toJson();
      data.remove('id');
      data['authority_id'] = authorityId;
      await _client.from('authority_photos').insert(data);
    }

    for (var item in authority.videos) {
      final data = item.toJson();
      data.remove('id');
      data['authority_id'] = authorityId;
      await _client.from('authority_videos').insert(data);
    }

    for (var item in authority.documents) {
      final data = item.toJson();
      data.remove('id');
      data['authority_id'] = authorityId;
      await _client.from('authority_documents').insert(data);
    }
  }

  Future<void> _deleteRelations(String authorityId) async {
    await _client.from('authority_education').delete().eq('authority_id', authorityId);
    await _client.from('authority_career').delete().eq('authority_id', authorityId);
    await _client.from('authority_achievements').delete().eq('authority_id', authorityId);
    await _client.from('authority_photos').delete().eq('authority_id', authorityId);
    await _client.from('authority_videos').delete().eq('authority_id', authorityId);
    await _client.from('authority_documents').delete().eq('authority_id', authorityId);
  }
}

// ---- Classe utilitaire pour la pagination ----
class PaginatedResult<T> {
  final List<T> data;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;

  PaginatedResult({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
  });
}
