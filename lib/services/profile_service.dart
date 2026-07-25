import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/models/thix_profile.dart';
import 'package:thix_id/models/app_user.dart';

class ProfileService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Récupère un profil public via le THIX ID
  Future<ThixProfile?> fetchPublicProfileByThixId(String thixId) async {
    try {
      final res = await _client
          .from('profiles')
          .select()
          .eq('thix_id', thixId)
          .maybeSingle();
      if (res == null) return null;
      return ThixProfile.fromPrivateRow(res);
    } catch (e) {
      debugPrint('Error fetchPublicProfileByThixId: $e');
      return null;
    }
  }

  /// Récupère un profil via l'ID utilisateur (UUID)
  Future<ThixProfile?> fetchPublicProfileByUserId(String userId) async {
    try {
      final res = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (res == null) return null;
      return ThixProfile.fromPrivateRow(res);
    } catch (e) {
      debugPrint('Error fetchPublicProfileByUserId: $e');
      return null;
    }
  }

  /// Flux en temps réel du profil personnel
  Stream<ThixProfile?> streamMyProfile(String userId) {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((list) {
          if (list.isEmpty) return null;
          return ThixProfile.fromPrivateRow(list.first);
        });
  }

  /// Flux en temps réel du profil public (Utilisé par notifications_sheet)
  Stream<ThixProfile?> streamPublicProfileByUserId(String userId) {
    return streamMyProfile(userId); // Réutilise la même logique que streamMyProfile
  }

  /// Met à jour les paramètres de visibilité du profil
  Future<void> updateVisibility({
    required String userId,
    required ThixVisibilitySettings visibility,
  }) async {
    try {
      await _client.from('profiles').update({
        'visibility_settings': visibility.toJson(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      debugPrint('Error updateVisibility: $e');
      rethrow;
    }
  }

  /// S'assure que le profil existe (Création silencieuse à la connexion si besoin)
  Future<void> ensureProfileExists({required AppUser user}) async {
    try {
      final existing = await fetchPublicProfileByUserId(user.id);
      if (existing == null) {
        await _client.from('profiles').insert({
          'id': user.id,
          'thix_id': user.thixId,
          'display_name': user.displayName,
          'full_name': user.displayName,
          'contact_phone': user.phone,
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Error ensureProfileExists: $e');
    }
  }

  /// MISE À JOUR GLOBALE DU PROFIL
  Future<void> updateProfile({
    required String userId,
    String? displayName,
    String? fullName,
    String? bio,
    String? competence,
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
    String? fatherName,
    String? motherName,
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
    List<Map<String, dynamic>>? education,
    List<Map<String, dynamic>>? experience,
    List<Map<String, dynamic>>? skills,
    List<Map<String, dynamic>>? certifications,
    List<Map<String, dynamic>>? emergencyContacts,
    String? photoUrl,
    bool? biometricsEnabled,
    bool? twoFaEnabled,
  }) async {
    try {
      final data = <String, dynamic>{};

      // FIX CRITIQUE: Transforme les String vides ("") en null pour éviter l'erreur PostgreSQL 22007
      void put(String k, Object? v) {
        if (v is String) {
          final trimmed = v.trim();
          data[k] = trimmed.isEmpty ? null : trimmed;
        } else {
          if (v != null) data[k] = v;
        }
      }

      data['updated_at'] = DateTime.now().toUtc().toIso8601String();

      // Identité & Pro
      put('display_name', displayName);
      put('full_name', fullName);
      put('bio', bio);
      put('competence', competence);
      put('profession', profession);
      put('occupation', occupation);
      put('thix_chat', thixChat);
      if (photoUrl != null) put('avatar_url', photoUrl);

      // Identité Civile
      put('date_of_birth', dateOfBirth);
      put('place_of_birth', placeOfBirth);
      put('nationality', nationality);
      put('marital_status', maritalStatus);
      put('gender', gender);
      put('address', address);
      put('contact_phone', contactPhone);
      put('father_name', fatherName);
      put('mother_name', motherName);
      put('country_or_origin', countryOrOrigin);

      // Origine
      put('origin_province', originProvince);
      put('origin_territory', originTerritory);
      put('origin_sector', originSector);

      // Résidence
      put('residence_country', residenceCountry);
      put('residence_province', residenceProvince);
      put('residence_territory', residenceTerritory);
      put('residence_city', residenceCity);
      put('residence_commune', residenceCommune);
      put('residence_quarter', residenceQuarter);
      put('residence_avenue', residenceAvenue);
      put('residence_number', residenceNumber);

      // Informations Physiques
      put('height', height);
      put('weight', weight);
      put('blood_group', bloodGroup);
      put('has_physical_disability', hasPhysicalDisability);
      put('physical_disability_description', physicalDisabilityDescription);

      // Identité Nationale (Documents)
      put('national_id_number', nationalIdNumber);
      put('id_document_type', idDocumentType);
      put('id_document_issue_date', idDocumentIssueDate);
      put('id_document_expiry_date', idDocumentExpiryDate);
      put('id_document_issue_place', idDocumentIssuePlace);
      put('id_document_front_doc_id', idDocumentFrontDocId);
      put('id_document_back_doc_id', idDocumentBackDocId);
      put('id_document_selfie_doc_id', idDocumentSelfieDocId);
      put('id_verification_status', idVerificationStatus);

      // Contact Urgence Simple
      put('emergency_contact_name', emergencyContactName);
      put('emergency_contact_phone', emergencyContactPhone);
      put('emergency_contact_relation', emergencyContactRelation);

      // Sécurité
      put('biometrics_enabled', biometricsEnabled);
      put('two_fa_enabled', twoFaEnabled);

      // Tableaux / JSONB
      if (languages != null) put('languages', languages);
      if (languagesDetailed != null) put('languages_detailed', languagesDetailed);
      if (education != null) put('education', education);
      if (experience != null) put('experience', experience);
      if (skills != null) put('skills', skills);
      if (certifications != null) put('certifications', certifications);
      if (emergencyContacts != null) put('emergency_contacts', emergencyContacts);

      if (data.keys.length > 1) {
        await _client.from('profiles').update(data).eq('id', userId);
      }
      
    } catch (e) {
      debugPrint('Error in ProfileService.updateProfile: $e');
      rethrow;
    }
  }
}
