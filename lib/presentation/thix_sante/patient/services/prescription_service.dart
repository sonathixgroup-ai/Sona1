// lib/presentation/thix_sante/patient/services/prescription_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class PrescriptionModel {
  final String id;
  final String title;
  final DateTime createdAt;
  PrescriptionModel({required this.id, required this.title, required this.createdAt});
  factory PrescriptionModel.fromJson(Map<String,dynamic> j) => PrescriptionModel(id: j['id'].toString(), title: j['title']?.toString()??'Ordonnance', createdAt: DateTime.tryParse(j['created_at'].toString())??DateTime.now());
}

class PrescriptionService {
  final _db = Supabase.instance.client;
  String get _uid => _db.auth.currentUser!.id;

  Future<List<PrescriptionModel>> getMyPrescriptions() async {
    try{
      final res = await _db.from('prescriptions').select().eq('patient_id', _uid).order('created_at', ascending: false);
      return (res as List).map((e)=>PrescriptionModel.fromJson(e)).toList();
    }catch(_){
      // fallback sur health_records type ordonnance si table prescriptions n'existe pas encore
      final res = await _db.from('health_records').select().eq('patient_id', _uid).eq('type', 'ordonnance').order('created_at', ascending: false);
      return (res as List).map((e)=>PrescriptionModel.fromJson(e)).toList();
    }
  }

  Future<void> sendToPharmacy({required String prescriptionId, required String pharmacyThixId}) async {
    if(pharmacyThixId.trim().isEmpty) throw Exception('THIX ID pharmacie requis');
    // Logique simple: insère dans pharmacy_orders si existe, sinon update health_records
    try{
      await _db.from('pharmacy_orders').insert({'prescription_id': prescriptionId, 'pharmacy_thix_id': pharmacyThixId.toUpperCase(), 'patient_id': _uid, 'status': 'sent'});
    }catch(_){
      await _db.from('health_records').update({'description': 'Envoyé pharmacie $pharmacyThixId'}).eq('id', prescriptionId);
    }
  }
}
