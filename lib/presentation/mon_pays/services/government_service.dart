// lib/presentation/mon_pays/services/government_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/government_model.dart';

class GovernmentService {
  final SupabaseClient _supabase;

  GovernmentService(this._supabase);

  Future<List<Government>> getAll() async {
    try {
      final response = await _supabase.from('governments').select('*');
      if (response == null || response is! List) return [];
      return (response as List).map((e) => Government.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Government> getById(String id) async {
    final response = await _supabase
        .from('governments')
        .select('*')
        .eq('id', id)
        .single();
    return Government.fromJson(response);
  }

  Future<Government> create(Government gov) async {
    final response = await _supabase
        .from('governments')
        .insert(gov.toJson())
        .select()
        .single();
    return Government.fromJson(response);
  }

  Future<Government> update(Government gov) async {
    final response = await _supabase
        .from('governments')
        .update(gov.toJson())
        .eq('id', gov.id)
        .select()
        .single();
    return Government.fromJson(response);
  }

  Future<void> delete(String id) async {
    await _supabase.from('governments').delete().eq('id', id);
  }
}
