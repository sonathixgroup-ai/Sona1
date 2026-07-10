// lib/presentation/mon_pays/services/authorities_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/authority_model.dart';

class AuthoritiesService {
  final SupabaseClient _supabase;

  AuthoritiesService(this._supabase);

  Future<List<Authority>> getAll() async {
    final response = await _supabase
        .from('authorities')
        .select('*');
    return (response as List).map((e) => Authority.fromJson(e)).toList();
  }

  Future<Authority> getById(String id) async {
    final response = await _supabase
        .from('authorities')
        .select('*')
        .eq('id', id)
        .single();
    return Authority.fromJson(response);
  }

  Future<Authority> create(Authority authority) async {
    final response = await _supabase
        .from('authorities')
        .insert(authority.toJson())
        .select()
        .single();
    return Authority.fromJson(response);
  }

  Future<Authority> update(Authority authority) async {
    final response = await _supabase
        .from('authorities')
        .update(authority.toJson())
        .eq('id', authority.id)
        .select()
        .single();
    return Authority.fromJson(response);
  }

  Future<void> delete(String id) async {
    await _supabase
        .from('authorities')
        .delete()
        .eq('id', id);
  }
}
