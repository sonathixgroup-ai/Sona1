// lib/presentation/thix_sante/patient/services/patient_link_service.dart
// =============================================================================
// Service: PatientLinkService
// Role: Gestion des liaisons Docteur-Patient via THIX ID UID
// Workflow academique: pending -> active -> revoked
// Table: public.health_links
// =============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/thix_id_validator.dart';
import '../models/patient_link_model.dart';
import 'patient_service.dart';

class PatientLinkService {
  PatientLinkService({SupabaseClient? client, PatientService? patientService})
      : _db = client?? Supabase.instance.client,
        _patientService = patientService?? PatientService(client: client?? Supabase.instance.client);

  final SupabaseClient _db;
  final PatientService _patientService;

  /// Etape 1: Patient ajoute son medecin traitant par THIX ID UID.
  /// C'est la fonction principale demandee par le cahier des charges.
  Future<PatientLinkModel> requestDoctorByThixId({
    required String doctorThixId,
    AccessLevel accessLevel = AccessLevel.full,
  }) async {
    final User? currentUser = _db.auth.currentUser;
    if (currentUser == null) throw Exception('Session expiree');

    final String cleanDoctorId = ThixIdValidator.clean(doctorThixId);
    if (!ThixIdValidator.isValidFormat(cleanDoctorId)) {
      throw const FormatException('THIX ID medecin invalide');
    }

    // 1. Verifier que le docteur existe
    final Map<String, dynamic> doctorData =
        await _patientService.findProfileByThixId(cleanDoctorId);
    final String doctorUid = doctorData['uid'] as String;

    // 2. Recuperer mon propre THIX ID
    final Map<String, dynamic> myProfile =
        await _patientService.getCurrentProfile();
    final String myThixId = myProfile['thix_id'] as String;
    final String myUid = myProfile['uid'] as String;

    if (myUid == doctorUid) {
      throw Exception('Vous ne pouvez pas vous ajouter vous-meme');
    }

    // 3. Verifier doublon
    final existing = await _db
      .from('health_links')
      .select('id, status')
      .eq('doctor_uid', doctorUid)
      .eq('patient_uid', myUid)
      .maybeSingle();

    if (existing!= null) {
      throw Exception('Liaison deja existante: ${existing['status']}');
    }

    // 4. Creer liaison en pending
    final Map<String, dynamic> inserted = await _db
      .from('health_links')
      .insert({
         'doctor_uid': doctorUid,
         'patient_uid': myUid,
         'doctor_thix_id': cleanDoctorId,
         'patient_thix_id': myThixId,
         'status': LinkStatus.pending.name,
         'access_level': accessLevel.name,
       })
      .select()
      .single();

    return PatientLinkModel.fromJson(inserted);
  }

  /// Etape 2: Medecin accepte la demande (ou patient confirme).
  Future<void> acceptLink(String linkId) async {
    await _db.from('health_links').update({
      'status': LinkStatus.active.name,
      'accepted_at': DateTime.now().toIso8601String(),
    }).eq('id', linkId);
  }

  /// Revoquer une liaison.
  Future<void> revokeLink(String linkId) async {
    await _db.from('health_links').update({
      'status': LinkStatus.revoked.name,
    }).eq('id', linkId);
  }

  /// Stream temps reel de mes medecins lies (pour UI reactive).
  Stream<List<PatientLinkModel>> watchMyDoctors() {
    final String uid = _db.auth.currentUser!.id;
    return _db
      .from('health_links')
      .stream(primaryKey: ['id'])
      .eq('patient_uid', uid)
      .order('created_at', ascending: false)
      .map((rows) => rows.map(PatientLinkModel.fromJson).toList());
  }

  /// Liste mes medecins actifs uniquement.
  Future<List<PatientLinkModel>> getActiveDoctors() async {
    final String uid = _db.auth.currentUser!.id;
    final List<dynamic> data = await _db
      .from('health_links')
      .select('*, doctor_profile:profiles!health_links_doctor_uid_fkey(uid, full_name, thix_id, avatar_url, speciality)')
      .eq('patient_uid', uid)
      .eq('status', 'active')
      .order('accepted_at', ascending: false);

    return data
      .map((e) => PatientLinkModel.fromJson(e as Map<String, dynamic>))
      .toList();
  }

  /// Nombre de medecins lies (pour dashboard stats).
  Future<int> countMyDoctors() async {
    final String uid = _db.auth.currentUser!.id;
    final List<dynamic> res = await _db
      .from('health_links')
      .select('id')
      .eq('patient_uid', uid)
      .eq('status', 'active');
    return res.length;
  }
}
