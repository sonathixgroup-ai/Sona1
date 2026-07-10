// lib/presentation/mon_pays/services/agencies_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/agency_model.dart';

class AgenciesService {
  final SupabaseClient _supabase;

  AgenciesService(this._supabase);

  Future<List<Agency>> getAll() async {
    final response = await _supabase
        .from('agencies')
        .select('*');
    return (response as List).map((e) => Agency.fromJson(e)).toList();
  }

  Future<Agency> getById(String id) async {
    final response = await _supabase
        .from('agencies')
        .select('*')
        .eq('id', id)
        .single();
    return Agency.fromJson(response);
  }

  Future<Agency> create(Agency agency) async {
    final response = await _supabase
        .from('agencies')
        .insert(agency.toJson())
        .select()
        .single();
    return Agency.fromJson(response);
  }

  Future<Agency> update(Agency agency) async {
    final response = await _supabase
        .from('agencies')
        .update(agency.toJson())
        .eq('id', agency.id)
        .select()
        .single();
    return Agency.fromJson(response);
  }

  Future<void> delete(String id) async {
    await _supabase
        .from('agencies')
        .delete()
        .eq('id', id);
  }
}
