// lib/presentation/mon_pays/services/authorities_service.dart
// Service CRUD complet pour les autorités (Supabase)

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/authority.dart';

class AuthoritiesService {
  final SupabaseClient _client = Supabase.instance.client;

  // --- READ ---

  Future<List<Authority>> getAuthorities({String? category}) async {
    try {
      var query = _client.from('authorities').select('*');
      if (category != null && category != 'Tous') {
        query = query.eq('title', category);
      }
      query = query.order('name');
      final response = await query;
      return response.map((json) => Authority.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des autorités: $e');
    }
  }

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

  Future<List<Authority>> searchAuthorities(String query) async {
    try {
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

  // --- CREATE ---

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

  // --- UPDATE ---

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

  // --- DELETE ---

  Future<void> deleteAuthority(String id) async {
    try {
      await _client.from('authorities').delete().eq('id', id);
    } catch (e) {
      throw Exception('Erreur lors de la suppression: $e');
    }
  }
}
