// lib/presentation/mon_pays/services/consultations_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/consultation_model.dart';

class ConsultationsService {
  final SupabaseClient _supabase;

  ConsultationsService(this._supabase);

  Future<List<Consultation>> getAll() async {
    try {
      final response = await _supabase.from('consultations').select('*');
      if (response == null || response is! List) return [];
      return (response as List).map((e) => Consultation.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Consultation> getById(String id) async {
    final response = await _supabase
        .from('consultations')
        .select('*')
        .eq('id', id)
        .single();
    return Consultation.fromJson(response);
  }

  Future<Consultation> create(Consultation consultation) async {
    final response = await _supabase
        .from('consultations')
        .insert(consultation.toJson())
        .select()
        .single();
    return Consultation.fromJson(response);
  }

  Future<Consultation> update(Consultation consultation) async {
    final response = await _supabase
        .from('consultations')
        .update(consultation.toJson())
        .eq('id', consultation.id)
        .select()
        .single();
    return Consultation.fromJson(response);
  }

  Future<void> delete(String id) async {
    await _supabase.from('consultations').delete().eq('id', id);
  }
}
