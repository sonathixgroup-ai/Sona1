// lib/presentation/mon_pays/services/citizens_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/citizen_model.dart';

class CitizensService {
  final SupabaseClient _supabase;

  CitizensService(this._supabase);

  Future<List<ExemplaryCitizen>> getAll() async {
    try {
      final response = await _supabase.from('exemplary_citizens').select('*');
      if (response == null || response is! List) return [];
      return (response as List).map((e) => ExemplaryCitizen.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<ExemplaryCitizen> getById(String id) async {
    final response = await _supabase
        .from('exemplary_citizens')
        .select('*')
        .eq('id', id)
        .single();
    return ExemplaryCitizen.fromJson(response);
  }

  Future<ExemplaryCitizen> create(ExemplaryCitizen citizen) async {
    final response = await _supabase
        .from('exemplary_citizens')
        .insert(citizen.toJson())
        .select()
        .single();
    return ExemplaryCitizen.fromJson(response);
  }

  Future<ExemplaryCitizen> update(ExemplaryCitizen citizen) async {
    final response = await _supabase
        .from('exemplary_citizens')
        .update(citizen.toJson())
        .eq('id', citizen.id)
        .select()
        .single();
    return ExemplaryCitizen.fromJson(response);
  }

  Future<void> delete(String id) async {
    await _supabase.from('exemplary_citizens').delete().eq('id', id);
  }
}
