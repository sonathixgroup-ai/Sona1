// lib/presentation/mon_pays/services/law_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/law_model.dart';

class LawService {
  final SupabaseClient _supabase;

  LawService(this._supabase);

  Future<List<Law>> getAll() async {
    final response = await _supabase
        .from('laws')  // ou 'values' selon votre table
        .select('*');
    return (response as List).map((e) => Law.fromJson(e)).toList();
  }

  Future<Law> getById(String id) async {
    final response = await _supabase
        .from('laws')
        .select('*')
        .eq('id', id)
        .single();
    return Law.fromJson(response);
  }

  Future<Law> create(Law law) async {
    final response = await _supabase
        .from('laws')
        .insert(law.toJson())
        .select()
        .single();
    return Law.fromJson(response);
  }

  Future<Law> update(Law law) async {
    final response = await _supabase
        .from('laws')
        .update(law.toJson())
        .eq('id', law.id)
        .select()
        .single();
    return Law.fromJson(response);
  }

  Future<void> delete(String id) async {
    await _supabase
        .from('laws')
        .delete()
        .eq('id', id);
  }
}
