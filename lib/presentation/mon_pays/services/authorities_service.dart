// lib/presentation/mon_pays/services/authorities_service.dart
// Service CRUD complet pour les autorités (Supabase)

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/authority.dart';

class AuthoritiesService {
  final SupabaseClient _client = Supabase.instance.client;

  // ============================================================
  // READ
  // ============================================================

  /// Récupère toutes les autorités, avec filtre optionnel par catégorie
  Future<List<Authority>> getAuthorities({String? category}) async {
    try {
      // ✅ Construction de la requête de base
      var query = _client.from('authorities').select('*');
      
      // ✅ Appliquer le filtre si une catégorie est spécifiée
      if (category != null && category != 'Tous' && category != 'Toutes') {
        query = query.eq('title', category);
      }
      
      // ✅ .order() est disponible sur PostgrestFilterBuilder
      final response = await query.order('name');
      return response.map((json) => Authority.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des autorités: $e');
    }
  }

  /// Récupère une autorité par son ID
  Future<Authority> getAuthorityById(String id) async {
    try {
      final response = await _client
          .from('authorities')
          .select('*')
          .eq('id', id)
          .single();
      return Authority.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors du chargement de l\'autorité: $e');
    }
  }

  /// Recherche des autorités par nom ou titre
  Future<List<Authority>> searchAuthorities(String query) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }
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

  /// Récupère les autorités d'un parti politique
  Future<List<Authority>> getAuthoritiesByParty(String party) async {
    try {
      if (party.trim().isEmpty) {
        return [];
      }
      final response = await _client
          .from('authorities')
          .select('*')
          .eq('party', party)
          .order('name');
      return response.map((json) => Authority.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement par parti: $e');
    }
  }

  /// Récupère les autorités par titre/fonction
  Future<List<Authority>> getAuthoritiesByTitle(String title) async {
    try {
      if (title.trim().isEmpty) {
        return [];
      }
      final response = await _client
          .from('authorities')
          .select('*')
          .ilike('title', '%$title%')
          .order('name');
      return response.map((json) => Authority.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement par titre: $e');
    }
  }

  /// ✅ CORRECTION : Pagination simplifiée
  Future<List<Authority>> getAuthoritiesPaginated({
    int page = 0,
    int limit = 20,
    String? category,
  }) async {
    try {
      final start = page * limit;
      final end = start + limit - 1;
      
      var query = _client
          .from('authorities')
          .select('*')
          .range(start, end);
      
      if (category != null && category != 'Tous' && category != 'Toutes') {
        query = query.eq('title', category);
      }
      
      final response = await query.order('name');
      return response.map((json) => Authority.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement paginé: $e');
    }
  }

  /// ✅ CORRECTION : Comptage simplifié
  Future<int> countAuthorities({String? category}) async {
    try {
      var query = _client.from('authorities').select('*');
      
      if (category != null && category != 'Tous' && category != 'Toutes') {
        query = query.eq('title', category);
      }
      
      final response = await query;
      return response.length;
    } catch (e) {
      throw Exception('Erreur lors du comptage: $e');
    }
  }

  // ============================================================
  // CREATE
  // ============================================================

  /// Crée une nouvelle autorité
  Future<Authority> createAuthority(Authority authority) async {
    try {
      final response = await _client
          .from('authorities')
          .insert(authority.toJson())
          .select()
          .single();
      return Authority.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la création: $e');
    }
  }

  /// Crée plusieurs autorités en une seule requête
  Future<List<Authority>> createAuthorities(List<Authority> authorities) async {
    try {
      final data = authorities.map((a) => a.toJson()).toList();
      final response = await _client
          .from('authorities')
          .insert(data)
          .select();
      return response.map((json) => Authority.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la création multiple: $e');
    }
  }

  // ============================================================
  // UPDATE
  // ============================================================

  /// Met à jour une autorité existante
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

  /// Met à jour partiellement une autorité
  Future<Authority> patchAuthority(String id, Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('authorities')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return Authority.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour partielle: $e');
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  /// Supprime une autorité
  Future<void> deleteAuthority(String id) async {
    try {
      await _client.from('authorities').delete().eq('id', id);
    } catch (e) {
      throw Exception('Erreur lors de la suppression: $e');
    }
  }

  /// Supprime plusieurs autorités
  Future<void> deleteAuthorities(List<String> ids) async {
    try {
      for (final id in ids) {
        await _client.from('authorities').delete().eq('id', id);
      }
    } catch (e) {
      throw Exception('Erreur lors de la suppression multiple: $e');
    }
  }

  // ============================================================
  // BULK OPERATIONS
  // ============================================================

  /// Met à jour le statut de plusieurs autorités
  Future<void> updateAuthoritiesStatus(List<String> ids, String status) async {
    try {
      for (final id in ids) {
        await _client
            .from('authorities')
            .update({'status': status})
            .eq('id', id);
      }
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du statut: $e');
    }
  }
}
