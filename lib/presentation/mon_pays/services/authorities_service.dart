// lib/presentation/mon_pays/services/authorities_service.dart
// Service CRUD pour les autorités (Supabase) - VERSION SIMPLIFIÉE

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
      
      // ✅ .order() directement sur le résultat filtré
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
}
