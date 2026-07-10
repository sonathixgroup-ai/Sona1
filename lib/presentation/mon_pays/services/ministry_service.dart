// lib/presentation/mon_pays/services/ministry_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ministry_model.dart';

class MinistryService {
  final SupabaseClient _supabase;

  MinistryService(this._supabase);

  Future<List<Ministry>> getAll() async {
    final response = await _supabase
        .from('ministries')
        .select('*');
    return (response as List).map((e) => Ministry.fromJson(e)).toList();
  }

  Future<Ministry> getById(String id) async {
    final response = await _supabase
        .from('ministries')
        .select('*')
        .eq('id', id)
        .single();
    return Ministry.fromJson(response);
  }

  Future<Ministry> create(Ministry ministry) async {
    final response = await _supabase
        .from('ministries')
        .insert(ministry.toJson())
        .select()
        .single();
    return Ministry.fromJson(response);
  }

  Future<Ministry> update(Ministry ministry) async {
    final response = await _supabase
        .from('ministries')
        .update(ministry.toJson())
        .eq('id', ministry.id)
        .select()
        .single();
    return Ministry.fromJson(response);
  }

  Future<void> delete(String id) async {
    await _supabase
        .from('ministries')
        .delete()
        .eq('id', id);
  }
}
