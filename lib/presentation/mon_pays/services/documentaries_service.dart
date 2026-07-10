// lib/presentation/mon_pays/services/documentaries_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/documentary_model.dart';

class DocumentariesService {
  final SupabaseClient _supabase;

  DocumentariesService(this._supabase);

  Future<List<Documentary>> getAll() async {
    try {
      final response = await _supabase.from('documentaries').select('*');
      if (response == null || response is! List) return [];
      return (response as List).map((e) => Documentary.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Documentary> getById(String id) async {
    final response = await _supabase
        .from('documentaries')
        .select('*')
        .eq('id', id)
        .single();
    return Documentary.fromJson(response);
  }

  Future<Documentary> create(Documentary doc) async {
    final response = await _supabase
        .from('documentaries')
        .insert(doc.toJson())
        .select()
        .single();
    return Documentary.fromJson(response);
  }

  Future<Documentary> update(Documentary doc) async {
    final response = await _supabase
        .from('documentaries')
        .update(doc.toJson())
        .eq('id', doc.id)
        .select()
        .single();
    return Documentary.fromJson(response);
  }

  Future<void> delete(String id) async {
    await _supabase.from('documentaries').delete().eq('id', id);
  }
}
