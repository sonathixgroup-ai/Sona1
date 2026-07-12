// lib/presentation/thix_sante/patient/services/prescription_service.dart
// =============================================================================
// Service: PrescriptionService
// Role: Ordonnances digitales avec QR code verifiable et envoi pharmacie
// Fonctionnalites modernes: QR hash SHA256, statut temps reel, partage
// Table: public.prescriptions
// =============================================================================

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/prescription_model.dart';

class PrescriptionService {
  PrescriptionService({SupabaseClient? client})
      : _db = client?? Supabase.instance.client;

  final SupabaseClient _db;
  static const String _table = 'prescriptions';

  /// Genere un hash unique verifiable pour QR code.
  String _generateQrHash(String patientThixId, String doctorThixId) {
    final String raw =
        '$patientThixId-$doctorThixId-${DateTime.now().millisecondsSinceEpoch}-${Random.secure().nextInt(999999)}';
    final List<int> bytes = utf8.encode(raw);
    final Digest digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16).toUpperCase();
  }

  /// Recupere mes ordonnances en tant que patient.
  Future<List<PrescriptionModel>> getMyPrescriptions() async {
    final String uid = _db.auth.currentUser!.id;
    final List<dynamic> data = await _db
      .from(_table)
      .select()
      .eq('patient_uid', uid)
      .order('created_at', ascending: false);

    return data
      .map((e) => PrescriptionModel.fromJson(e as Map<String, dynamic>))
      .toList();
  }

  /// Stream temps reel pour badge Medicaments En cours = 5 dans ta capture.
  Stream<List<PrescriptionModel>> watchActivePrescriptions() {
    final String uid = _db.auth.currentUser!.id;
    return _db
      .from(_table)
      .stream(primaryKey: ['id'])
      .eq('patient_uid', uid)
      .order('created_at', ascending: false)
      .map((rows) => rows
        .map((e) => PrescriptionModel.fromJson(e as Map<String, dynamic>))
        .where((p) => p.status!= PrescriptionStatus.delivree && p.status!= PrescriptionStatus.expiree)
        .toList());
  }

  /// Cree une ordonnance cote medecin - genere QR automatiquement.
  Future<PrescriptionModel> createPrescription({
    required String patientUid,
    required String patientThixId,
    required String consultationId,
    required List<PrescriptionItem> items,
    String? notes,
    DateTime? expiryDate,
  }) async {
    final User? user = _db.auth.currentUser;
    if (user == null) throw Exception('Non authentifie');

    final Map<String, dynamic> myProfile = await _db
      .from('profiles')
      .select('thix_id, full_name')
      .eq('uid', user.id)
      .single();

    final String qrHash = _generateQrHash(
      patientThixId,
      myProfile['thix_id'] as String,
    );

    final Map<String, dynamic> payload = {
      'patient_uid': patientUid,
      'patient_thix_id': patientThixId,
      'doctor_uid': user.id,
      'doctor_thix_id': myProfile['thix_id'],
      'doctor_name': myProfile['full_name'],
      'consultation_id': consultationId,
      'items': items.map((e) => e.toJson()).toList(),
      'status': PrescriptionStatus.prescrite.name,
      'qr_hash': qrHash,
      'notes': notes,
      'expiry_date': expiryDate?.toIso8601String()??
          DateTime.now().add(const Duration(days: 30)).toIso8601String(),
    };

    final Map<String, dynamic> inserted =
        await _db.from(_table).insert(payload).select().single();

    return PrescriptionModel.fromJson(inserted);
  }

  /// Envoyer ordonnance a une pharmacie par THIX ID pharmacie.
  Future<void> sendToPharmacy({
    required String prescriptionId,
    required String pharmacyThixId,
  }) async {
    // 1. Trouver pharmacie par THIX ID
    final Map<String, dynamic>? pharmacy = await _db
      .from('profiles')
      .select('uid')
      .eq('thix_id', pharmacyThixId)
      .eq('role', 'pharmacy')
      .maybeSingle();

    if (pharmacy == null) {
      throw Exception('Pharmacie introuvable avec THIX ID: $pharmacyThixId');
    }

    await _db.from(_table).update({
      'pharmacy_uid': pharmacy['uid'],
      'status': PrescriptionStatus.envoyee.name,
    }).eq('id', prescriptionId);
  }

  /// Verifie une ordonnance via QR hash - pour pharmacie.
  Future<PrescriptionModel?> verifyByQrHash(String qrHash) async {
    final Map<String, dynamic>? data = await _db
      .from(_table)
      .select()
      .eq('qr_hash', qrHash.toUpperCase())
      .maybeSingle();

    if (data == null) return null;
    return PrescriptionModel.fromJson(data);
  }

  Future<int> countActive() async {
    final String uid = _db.auth.currentUser!.id;
    final List<dynamic> res = await _db
      .from(_table)
      .select('id')
      .eq('patient_uid', uid)
      .neq('status', 'delivree');
    return res.length;
  }
}
