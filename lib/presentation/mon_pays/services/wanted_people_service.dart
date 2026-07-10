// lib/presentation/mon_pays/services/wanted_people_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wanted_person_model.dart';

class WantedPeopleService {
  final SupabaseClient _supabase;

  WantedPeopleService(this._supabase);

  Future<List<WantedPerson>> getAll() async {
    try {
      final response = await _supabase.from('wanted_persons').select('*');
      if (response == null || response is! List) return [];
      return (response as List).map((e) => WantedPerson.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<WantedPerson> getById(String id) async {
    final response = await _supabase
        .from('wanted_persons')
        .select('*')
        .eq('id', id)
        .single();
    return WantedPerson.fromJson(response);
  }

  Future<WantedPerson> create(WantedPerson person) async {
    final response = await _supabase
        .from('wanted_persons')
        .insert(person.toJson())
        .select()
        .single();
    return WantedPerson.fromJson(response);
  }

  Future<WantedPerson> update(WantedPerson person) async {
    final response = await _supabase
        .from('wanted_persons')
        .update(person.toJson())
        .eq('id', person.id)
        .select()
        .single();
    return WantedPerson.fromJson(response);
  }

  Future<void> delete(String id) async {
    await _supabase.from('wanted_persons').delete().eq('id', id);
  }

  Future<void> reportPerson(String personId, {required String details, String? location}) async {
    await _supabase.from('wanted_persons').update({
      'status': 'reported',
      'details': details,
      'location': location,
    }).eq('id', personId);
  }
}
