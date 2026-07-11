// lib/presentation/mon_pays/services/government_service.dart
// Service pour le Gouvernement (Supabase)

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/government.dart';

class GovernmentService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Government>> getAllGovernments() async {
    try {
      final response = await _client
          .from('governments')
          .select('*')
          .order('formation_date', ascending: false);
      return response.map((json) => Government.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des gouvernements: $e');
    }
  }

  Future<Government> getGovernmentById(String id) async {
    try {
      final response = await _client
          .from('governments')
          .select('*')
          .eq('id', id)
          .single();
      return Government.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors du chargement du gouvernement: $e');
    }
  }

  Future<Government> getCurrentGovernment() async {
    try {
      final response = await _client
          .from('governments')
          .select('*')
          .eq('is_current', true)
          .single();
      return Government.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors du chargement du gouvernement actuel: $e');
    }
  }

  Future<Government> createGovernment(Government government) async {
    try {
      final response = await _client
          .from('governments')
          .insert(government.toJson())
          .select()
          .single();
      return Government.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la création: $e');
    }
  }

  Future<Government> updateGovernment(Government government) async {
    try {
      final response = await _client
          .from('governments')
          .update(government.toJson())
          .eq('id', government.id)
          .select()
          .single();
      return Government.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  Future<void> deleteGovernment(String id) async {
    try {
      await _client.from('governments').delete().eq('id', id);
    } catch (e) {
      throw Exception('Erreur lors de la suppression: $e');
    }
  }
}
