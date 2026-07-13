import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/appointment_model.dart';

class AppointmentService {
  final _db = Supabase.instance.client;
  String get _uid => _db.auth.currentUser!.id;

  Future<List<Map<String, dynamic>>> getMyLinkedDoctors() async {
    final res = await _db
       .from('health_links')
       .select('doctor_id, doctors!inner(id, full_name, specialite, avatar_url, adresse, telephone)')
       .eq('patient_id', _uid)
       .eq('is_active', true);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<String>> getTakenSlots({required String doctorId, required DateTime date}) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final res = await _db
       .from('appointments')
       .select('creneau')
       .eq('doctor_id', doctorId)
       .gte('date_rdv', start.toIso8601String())
       .lt('date_rdv', end.toIso8601String())
       .neq('statut', 'annule');
    return (res as List).map((e) => e['creneau'] as String).toList();
  }

  Future<List<AppointmentModel>> getMyAppointments() async {
    final res = await _db.from('appointments').select().eq('patient_id', _uid).order('date_rdv');
    return (res as List).map((e) => AppointmentModel.fromJson(e)).toList();
  }

  Future<AppointmentModel> createAppointment({
    required String doctorId,
    required DateTime date,
    required String creneau,
    required String type,
    required String motif,
  }) async {
    final h = int.parse(creneau.split(':')[0]);
    final m = int.parse(creneau.split(':')[1]);
    final dateRdv = DateTime(date.year, date.month, date.day, h, m).toUtc();

    final taken = await getTakenSlots(doctorId: doctorId, date: date);
    if (taken.contains(creneau)) throw Exception('Créneau déjà réservé');

    final prix = type == 'Domicile'? 25000 : type == 'Téléconsultation'? 10000 : 15000;
    final duree = type == 'Domicile'? 60 : type == 'Téléconsultation'? 20 : 30;

    final inserted = await _db.from('appointments').insert({
      'patient_id': _uid,
      'doctor_id': doctorId,
      'date_rdv': dateRdv.toIso8601String(),
      'type': type,
      'motif': motif,
      'creneau': creneau,
      'statut': 'demande',
      'prix': prix,
      'duree_minutes': duree,
    }).select().single();

    return AppointmentModel.fromJson(inserted);
  }

  Future<void> cancelAppointment(String id) async {
    await _db.from('appointments').update({'statut': 'annule'}).eq('id', id).eq('patient_id', _uid);
  }
}
