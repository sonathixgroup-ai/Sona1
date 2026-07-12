// lib/presentation/mon_pays/services/laws_service.dart
// Service CRUD pour les lois (Supabase)

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/law.dart';

class LawsService {
  final SupabaseClient _client = Supabase.instance.client;

  // READ : toutes les lois avec filtre optionnel par catégorie
  Future<List<Law>> getLaws({String? category}) async {
    try {
      var query = _client.from('laws').select('*');
      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }
      final response = await query.order('title');
      return response.map((json) => Law.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des lois: $e');
    }
  }

  // READ : une loi par ID
  Future<Law> getLawById(String id) async {
    try {
      final response = await _client
          .from('laws')
          .select('*')
          .eq('id', id)
          .single();
      return Law.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors du chargement de la loi: $e');
    }
  }

  // READ : recherche par titre ou contenu
  Future<List<Law>> searchLaws(String query) async {
    try {
      if (query.trim().isEmpty) return [];
      final response = await _client
          .from('laws')
          .select('*')
          .or('title.ilike.%$query%,content.ilike.%$query%')
          .order('title');
      return response.map((json) => Law.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  // CREATE
  Future<Law> createLaw(Law law) async {
    try {
      final response = await _client
          .from('laws')
          .insert(law.toJson())
          .select()
          .single();
      return Law.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la création: $e');
    }
  }

  // UPDATE
  Future<Law> updateLaw(Law law) async {
    try {
      final response = await _client
          .from('laws')
          .update(law.toJson())
          .eq('id', law.id)
          .select()
          .single();
      return Law.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  // DELETE
  Future<void> deleteLaw(String id) async {
    try {
      await _client.from('laws').delete().eq('id', id);
    } catch (e) {
      throw Exception('Erreur lors de la suppression: $e');
    }
  }
}
