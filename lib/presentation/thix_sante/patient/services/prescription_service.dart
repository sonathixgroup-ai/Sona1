// lib/presentation/thix_sante/patient/services/prescription_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/prescription_model.dart';

class PrescriptionService {
  final _db = Supabase.instance.client;
  String get _uid => _db.auth.currentUser!.id;

  Future<List<PrescriptionModel>> getMyPrescriptions() async {
    try{
      final res = await _db.from('prescriptions').select().eq('patient_id', _uid).order('created_at', ascending: false);
      return (res as List).map((e)=>PrescriptionModel.fromJson(e)).toList();
    }catch(_){
      final res = await _db.from('health_records').select().eq('patient_id', _uid).eq('type', 'ordonnance').order('created_at', ascending: false);
      return (res as List).map((e)=>PrescriptionModel.fromJson({
        'id': e['id'], 'title': e['title'], 'created_at': e['created_at'],
        'doctor_name': e['description'], 'status': 'active'
      })).toList();
    }
  }

  Future<void> sendToPharmacy({required String prescriptionId, required String pharmacyThixId}) async {
    if(pharmacyThixId.trim().isEmpty) throw Exception('THIX ID pharmacie requis');
    try{
      await _db.from('pharmacy_orders').insert({
        'prescription_id': prescriptionId,
        'pharmacy_thix_id': pharmacyThixId.toUpperCase().trim(),
        'patient_id': _uid,
        'status': 'sent',
      });
    }catch(_){
      await _db.from('health_records').update({'description': 'Envoye pharmacie $pharmacyThixId'}).eq('id', prescriptionId);
    }
  }
}
