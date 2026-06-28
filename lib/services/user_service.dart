import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Minimal user/account service used by the (large) dashboard page.
///
/// This implementation is intentionally defensive: it prefers to **not crash**
/// the UI if a table/RPC is missing while you iterate on your Supabase schema.
class UserService {
  final SupabaseClient _supabase;
  UserService(SupabaseClient client) : _supabase = client;

  Stream<List<Map<String, dynamic>>> streamPayments(String uid) {
    try {
      return _supabase
          .from('payment_transactions')
          .stream(primaryKey: ['id'])
          .eq('uid', uid)
          .order('created_at', ascending: false)
          .map((rows) => rows.map((e) => Map<String, dynamic>.from(e)).toList(growable: false));
    } catch (e) {
      debugPrint('UserService.streamPayments failed err=$e');
      return const Stream.empty();
    }
  }

  Stream<List<Map<String, dynamic>>> streamSecurityEvents(String uid) {
    try {
      return _supabase
          .from('security_events')
          .stream(primaryKey: ['id'])
          .eq('uid', uid)
          .order('created_at', ascending: false)
          .map((rows) => rows.map((e) => Map<String, dynamic>.from(e)).toList(growable: false));
    } catch (e) {
      debugPrint('UserService.streamSecurityEvents failed err=$e');
      return const Stream.empty();
    }
  }

  Future<void> addPaymentTransaction({
    required String uid,
    required String title,
    required num amount,
    required String currency,
    required String method,
    required String status,
    String? txRef,
    Map<String, dynamic>? extra,
  }) async {
    try {
      await _supabase.from('payment_transactions').insert({
        'uid': uid,
        'title': title,
        'amount': amount,
        'currency': currency,
        'method': method,
        'status': status,
        if (txRef != null) 'tx_ref': txRef,
        if (extra != null) 'extra': extra,
      });
    } on PostgrestException catch (e) {
      debugPrint('UserService.addPaymentTransaction error=${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('UserService.addPaymentTransaction error=$e');
      rethrow;
    }
  }

  Future<void> logSecurityEvent({required String uid, required String type, required String label}) async {
    try {
      await _supabase.from('security_events').insert({
        'uid': uid,
        'type': type,
        'label': label,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('UserService.logSecurityEvent failed err=$e');
    }
  }

  /// Updates `public.profiles` with any non-null values.
  ///
  /// NOTE: The dashboard passes a lot of fields. We keep them optional so the
  /// call site can evolve without forcing schema changes immediately.
  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? fullName,
    String? competence,
    String? bio,
    String? countryOrOrigin,
    String? contactPhone,
    String? maritalStatus,
    String? gender,
    String? profession,
    String? occupation,
    String? dateOfBirth,
    String? placeOfBirth,
    String? nationality,
    String? address,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelation,
    String? originProvince,
    String? originTerritory,
    String? originSector,
    String? residenceCountry,
    String? residenceProvince,
    String? residenceTerritory,
    String? residenceCity,
    String? residenceCommune,
    String? residenceQuarter,
    String? residenceAvenue,
    String? residenceNumber,
    String? height,
    String? weight,
    String? bloodGroup,
    bool? hasPhysicalDisability,
    String? physicalDisabilityDescription,
    String? nationalIdNumber,
    String? idDocumentType,
    String? idDocumentIssueDate,
    String? idDocumentExpiryDate,
    String? idDocumentIssuePlace,
    String? idDocumentFrontDocId,
    String? idDocumentBackDocId,
    String? idDocumentSelfieDocId,
    String? idVerificationStatus,
    String? thixChat,
    List<String>? languages,
    List<Map<String, dynamic>>? languagesDetailed,
    String? photoUrl,
    bool? biometricsEnabled,
    bool? twoFaEnabled,
  }) async {
    final payload = <String, dynamic>{
      'id': uid,
      'updated_at': DateTime.now().toIso8601String(),
      if (displayName != null) 'display_name': displayName,
      if (fullName != null) 'full_name': fullName,
      if (competence != null) 'competence': competence,
      if (bio != null) 'bio': bio,
      if (countryOrOrigin != null) 'country_or_origin': countryOrOrigin,
      if (contactPhone != null) 'contact_phone': contactPhone,
      if (maritalStatus != null) 'marital_status': maritalStatus,
      if (gender != null) 'gender': gender,
      if (profession != null) 'profession': profession,
      if (occupation != null) 'occupation': occupation,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
      if (placeOfBirth != null) 'place_of_birth': placeOfBirth,
      if (nationality != null) 'nationality': nationality,
      if (address != null) 'address': address,
      if (emergencyContactName != null) 'emergency_contact_name': emergencyContactName,
      if (emergencyContactPhone != null) 'emergency_contact_phone': emergencyContactPhone,
      if (emergencyContactRelation != null) 'emergency_contact_relation': emergencyContactRelation,
      if (originProvince != null) 'origin_province': originProvince,
      if (originTerritory != null) 'origin_territory': originTerritory,
      if (originSector != null) 'origin_sector': originSector,
      if (residenceCountry != null) 'residence_country': residenceCountry,
      if (residenceProvince != null) 'residence_province': residenceProvince,
      if (residenceTerritory != null) 'residence_territory': residenceTerritory,
      if (residenceCity != null) 'residence_city': residenceCity,
      if (residenceCommune != null) 'residence_commune': residenceCommune,
      if (residenceQuarter != null) 'residence_quarter': residenceQuarter,
      if (residenceAvenue != null) 'residence_avenue': residenceAvenue,
      if (residenceNumber != null) 'residence_number': residenceNumber,
      if (height != null) 'height': height,
      if (weight != null) 'weight': weight,
      if (bloodGroup != null) 'blood_group': bloodGroup,
      if (hasPhysicalDisability != null) 'has_physical_disability': hasPhysicalDisability,
      if (physicalDisabilityDescription != null) 'physical_disability_description': physicalDisabilityDescription,
      if (nationalIdNumber != null) 'national_id_number': nationalIdNumber,
      if (idDocumentType != null) 'id_document_type': idDocumentType,
      if (idDocumentIssueDate != null) 'id_document_issue_date': idDocumentIssueDate,
      if (idDocumentExpiryDate != null) 'id_document_expiry_date': idDocumentExpiryDate,
      if (idDocumentIssuePlace != null) 'id_document_issue_place': idDocumentIssuePlace,
      if (idDocumentFrontDocId != null) 'id_document_front_doc_id': idDocumentFrontDocId,
      if (idDocumentBackDocId != null) 'id_document_back_doc_id': idDocumentBackDocId,
      if (idDocumentSelfieDocId != null) 'id_document_selfie_doc_id': idDocumentSelfieDocId,
      if (idVerificationStatus != null) 'id_verification_status': idVerificationStatus,
      if (thixChat != null) 'thix_chat': thixChat,
      if (languages != null) 'languages': languages,
      if (languagesDetailed != null) 'languages_detailed': languagesDetailed,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (biometricsEnabled != null) 'biometrics_enabled': biometricsEnabled,
      if (twoFaEnabled != null) 'two_fa_enabled': twoFaEnabled,
    };

    try {
      // Upsert so first-time users do not fail.
      await _supabase.from('profiles').upsert(payload);
    } on PostgrestException catch (e) {
      debugPrint('UserService.updateProfile error=${e.message}');
      rethrow;
    }
  }
}
