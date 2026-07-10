// lib/presentation/mon_pays/services/values_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/value_model.dart';

class ValuesService {
  final SupabaseClient _supabase;

  ValuesService(this._supabase);

  Future<List<Value>> getAll() async {
    final response = await _supabase
        .from('values_laws')  // ✅ Correction : utilisation de la table existante
        .select('*');
    return (response as List).map((e) => Value.fromJson(e)).toList();
  }

  Future<Value> getById(String id) async {
    final response = await _supabase
        .from('values_laws')
        .select('*')
        .eq('id', id)
        .single();
    return Value.fromJson(response);
  }

  Future<Value> create(Value value) async {
    final response = await _supabase
        .from('values_laws')
        .insert(value.toJson())
        .select()
        .single();
    return Value.fromJson(response);
  }

  Future<Value> update(Value value) async {
    final response = await _supabase
        .from('values_laws')
        .update(value.toJson())
        .eq('id', value.id)
        .select()
        .single();
    return Value.fromJson(response);
  }

  Future<void> delete(String id) async {
    await _supabase
        .from('values_laws')
        .delete()
        .eq('id', id);
  }
}
