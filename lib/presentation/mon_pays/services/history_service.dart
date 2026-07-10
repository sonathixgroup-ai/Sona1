// lib/presentation/mon_pays/services/history_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/history_model.dart';

class HistoryService {
  final SupabaseClient _supabase;

  HistoryService(this._supabase);

  Future<List<HistoricalFigure>> getAll() async {
    try {
      final response = await _supabase.from('historical_figures').select('*');
      if (response == null || response is! List) return [];
      return (response as List).map((e) => HistoricalFigure.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<HistoricalFigure> getById(String id) async {
    final response = await _supabase
        .from('historical_figures')
        .select('*')
        .eq('id', id)
        .single();
    return HistoricalFigure.fromJson(response);
  }

  Future<HistoricalFigure> create(HistoricalFigure figure) async {
    final response = await _supabase
        .from('historical_figures')
        .insert(figure.toJson())
        .select()
        .single();
    return HistoricalFigure.fromJson(response);
  }

  Future<HistoricalFigure> update(HistoricalFigure figure) async {
    final response = await _supabase
        .from('historical_figures')
        .update(figure.toJson())
        .eq('id', figure.id)
        .select()
        .single();
    return HistoricalFigure.fromJson(response);
  }

  Future<void> delete(String id) async {
    await _supabase.from('historical_figures').delete().eq('id', id);
  }
}
