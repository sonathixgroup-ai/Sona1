// lib/presentation/thix_sante/patient/services/patient_link_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/doctor_profile_model.dart';
import '../../core/thix_id_validator.dart';

class PatientLinkService {
  final _db = Supabase.instance.client;
  String get _uid => _db.auth.currentUser!.id;

  // Recherche par THIX ID - cherche dans doctors.thix_id
  Future<DoctorProfileModel> findDoctorByThixId(String thixId) async {
    final clean = ThixIdValidator.clean(thixId);
    // 1. Cherche exact
    var data = await _db.from('doctors').select().eq('thix_id', clean).maybeSingle();
    // 2. Cherche sans THIX- prefix
    if(data==null && clean.startsWith('THIX-')){
      data = await _db.from('doctors').select().eq('thix_id', clean.replaceFirst('THIX-', '')).maybeSingle();
    }
    // 3. Cherche id direct (si scan QR donne UUID)
    if(data==null){
      try{
        data = await _db.from('doctors').select().eq('id', clean).maybeSingle();
      }catch(_){}
    }
    if(data==null) throw Exception('Médecin introuvable avec THIX ID $clean');
    if(data['is_active']==false) throw Exception('Médecin inactif');
    return DoctorProfileModel.fromJson(data);
  }

  // Crée le lien health_links
  Future<void> requestDoctorByThixId({required String doctorThixId}) async {
    final doctor = await findDoctorByThixId(doctorThixId);

    // Vérifie si déjà lié
    final existing = await _db.from('health_links').select('id, is_active').eq('patient_id', _uid).eq('doctor_id', doctor.uid).maybeSingle();
    if(existing!=null){
      if(existing['is_active']==true) throw Exception('Déjà lié au Dr ${doctor.fullName}');
      // réactive
      await _db.from('health_links').update({'is_active': true}).eq('id', existing['id']);
      return;
    }

    await _db.from('health_links').insert({
      'patient_id': _uid,
      'doctor_id': doctor.uid,
      'is_active': true,
    });
  }

  Future<List<DoctorProfileModel>> getMyLinkedDoctors() async {
    final links = await _db.from('health_links').select('doctor_id').eq('patient_id', _uid).eq('is_active', true);
    if((links as List).isEmpty) return [];
    final ids = links.map((e)=>e['doctor_id'].toString()).toList();
    final res = await _db.from('doctors').select().inFilter('id', ids);
    return (res as List).map((e)=>DoctorProfileModel.fromJson(e)).toList();
  }
}
