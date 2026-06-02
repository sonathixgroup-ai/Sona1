import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/models/app_user.dart';
import 'package:thix_id/services/profile_service.dart';
import 'package:thix_id/services/thix_id_service.dart';
import 'package:thix_id/supabase/supabase_config.dart';

class FirestoreUserService {
  final SupabaseClient _client;
  final ProfileService _profiles;

  FirestoreUserService({SupabaseClient? client, ProfileService? profiles})
      : _client = client ?? SupabaseConfig.client,
        _profiles = profiles ?? ProfileService();

  static const _table = ProfileService.table;

  String _requireAuthedUid() {
    final uid = _client.auth.currentSession?.user.id;
    if (uid == null || uid.trim().isEmpty) {
      throw StateError('Non authentifié.');
    }
    return uid;
  }

  /// Convertit une ligne de la table profiles en objet AppUser
  AppUser _appUserFromProfileRow(Map<String, dynamic> row) {
    DateTime dt(Object? v) {
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    List<String> strList(Object? v) => (v is List) 
        ? v.whereType<String>().toList(growable: false) 
        : const <String>[];
        
    List<Map<String, dynamic>> mapList(Object? v) => (v is List) 
        ? v.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList(growable: false) 
        : const <Map<String, dynamic>>[];

    final accountTypeRaw = (row['account_type'] ?? row['accountType'] ?? 'personal').toString();
    final accountType = AccountType.values.firstWhere(
      (e) => e.name == accountTypeRaw,
      orElse: () => AccountType.personal,
    );

    return AppUser(
      id: (row['user_id'] ?? row['id'] ?? '').toString(),
      thixId: (row['thix_id'] ?? 'THIX-PENDING').toString(),
      thixChat: (row['thix_chat'] ?? '').toString(),
      thixScore: (row['thix_score'] as num?)?.toInt(),
      email: row['email']?.toString() ?? '',
      phone: row['phone']?.toString(),
      displayName: (row['display_name'] ?? 'Utilisateur THIX').toString(),
      accountType: accountType,
      photoUrl: (row['photo_url'] ?? row['avatar_url'])?.toString(),
      bio: row['bio']?.toString(),
      countryOrOrigin: row['country_or_origin']?.toString(),
      contactPhone: row['contact_phone']?.toString(),
      maritalStatus: row['marital_status']?.toString(),
      gender: row['gender']?.toString(),
      occupation: (row['occupation'] ?? row['occupation_title'])?.toString(),
      profession: (row['profession'] ?? row['job_title'])?.toString(),
      dateOfBirth: row['date_of_birth']?.toString(),
      placeOfBirth: row['place_of_birth']?.toString(),
      nationality: row['nationality']?.toString(),
      address: row['address']?.toString(),
      fatherName: row['father_name']?.toString(),
      motherName: row['mother_name']?.toString(),
      emergencyContactName: row['emergency_contact_name']?.toString(),
      emergencyContactPhone: row['emergency_contact_phone']?.toString(),
      emergencyContactRelation: row['emergency_contact_relation']?.toString(),
      registrationStatus: row['registration_status']?.toString(),
      education: mapList(row['education']),
      experience: mapList(row['experience']),
      skills: mapList(row['skills']),
      enrollments: mapList(row['enrollments']),
      languages: strList(row['languages']),
      biometricsEnabled: (row['biometrics_enabled'] as bool?) ?? true,
      twoFaEnabled: (row['two_fa_enabled'] as bool?) ?? false,
      createdAt: dt(row['created_at']),
      updatedAt: dt(row['updated_at']),
    );
  }

  Future<AppUser?> fetchUserByUid(String uid) async {
    try {
      final row = await _client.from(_table).select('*').eq('id', uid).maybeSingle();
      if (row == null) return null;
      return _appUserFromProfileRow((row as Map).cast<String, dynamic>());
    } catch (e) {
      debugPrint('Erreur fetchUserByUid: $e');
      return null;
    }
  }

  /// Met à jour le profil utilisateur avec tous les champs possibles
  Future<void> updateProfile({
    required String uid,
    // Informations personnelles
    String? fullName,
    String? displayName,
    String? countryOrOrigin,
    String? contactPhone,
    String? dateOfBirth,
    String? placeOfBirth,
    String? nationality,
    String? maritalStatus,
    String? gender,
    String? occupation,
    String? address,
    String? fatherName,
    String? motherName,
    // Contacts d'urgence
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelation,
    List<Map<String, dynamic>>? emergencyContacts,
    // Origine et résidence
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
    // Informations physiques
    String? height,
    String? weight,
    String? bloodGroup,
    bool? hasPhysicalDisability,
    String? physicalDisabilityDescription,
    // Documents d'identité
    String? nationalIdNumber,
    String? idDocumentType,
    String? idDocumentIssueDate,
    String? idDocumentExpiryDate,
    String? idDocumentIssuePlace,
    // Parcours
    String? bio,
    String? competence,
    List<Map<String, dynamic>>? education,
    List<Map<String, dynamic>>? experience,
    // Statut
    String? registrationStatus,
    String? photoUrl,
    String? thixChat,
  }) async {
    final sessionUid = _requireAuthedUid();
    final patch = <String, dynamic>{
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    
    // Informations personnelles
    if (fullName != null) patch['full_name'] = fullName;
    if (displayName != null) patch['display_name'] = displayName;
    if (countryOrOrigin != null) patch['country_or_origin'] = countryOrOrigin;
    if (contactPhone != null) patch['contact_phone'] = contactPhone;
    if (dateOfBirth != null) patch['date_of_birth'] = dateOfBirth;
    if (placeOfBirth != null) patch['place_of_birth'] = placeOfBirth;
    if (nationality != null) patch['nationality'] = nationality;
    if (maritalStatus != null) patch['marital_status'] = maritalStatus;
    if (gender != null) patch['gender'] = gender;
    if (occupation != null) patch['occupation'] = occupation;
    if (address != null) patch['address'] = address;
    if (fatherName != null) patch['father_name'] = fatherName;
    if (motherName != null) patch['mother_name'] = motherName;
    
    // Contacts d'urgence
    if (emergencyContactName != null) patch['emergency_contact_name'] = emergencyContactName;
    if (emergencyContactPhone != null) patch['emergency_contact_phone'] = emergencyContactPhone;
    if (emergencyContactRelation != null) patch['emergency_contact_relation'] = emergencyContactRelation;
    if (emergencyContacts != null) patch['emergency_contacts'] = emergencyContacts;
    
    // Origine et résidence
    if (originProvince != null) patch['origin_province'] = originProvince;
    if (originTerritory != null) patch['origin_territory'] = originTerritory;
    if (originSector != null) patch['origin_sector'] = originSector;
    if (residenceCountry != null) patch['residence_country'] = residenceCountry;
    if (residenceProvince != null) patch['residence_province'] = residenceProvince;
    if (residenceTerritory != null) patch['residence_territory'] = residenceTerritory;
    if (residenceCity != null) patch['residence_city'] = residenceCity;
    if (residenceCommune != null) patch['residence_commune'] = residenceCommune;
    if (residenceQuarter != null) patch['residence_quarter'] = residenceQuarter;
    if (residenceAvenue != null) patch['residence_avenue'] = residenceAvenue;
    if (residenceNumber != null) patch['residence_number'] = residenceNumber;
    
    // Informations physiques
    if (height != null) patch['height'] = height;
    if (weight != null) patch['weight'] = weight;
    if (bloodGroup != null) patch['blood_group'] = bloodGroup;
    if (hasPhysicalDisability != null) patch['has_physical_disability'] = hasPhysicalDisability;
    if (physicalDisabilityDescription != null) patch['physical_disability_description'] = physicalDisabilityDescription;
    
    // Documents d'identité
    if (nationalIdNumber != null) patch['national_id_number'] = nationalIdNumber;
    if (idDocumentType != null) patch['id_document_type'] = idDocumentType;
    if (idDocumentIssueDate != null) patch['id_document_issue_date'] = idDocumentIssueDate;
    if (idDocumentExpiryDate != null) patch['id_document_expiry_date'] = idDocumentExpiryDate;
    if (idDocumentIssuePlace != null) patch['id_document_issue_place'] = idDocumentIssuePlace;
    
    // Parcours
    if (bio != null) patch['bio'] = bio;
    if (competence != null) patch['competence'] = competence;
    if (education != null) patch['education'] = education;
    if (experience != null) patch['experience'] = experience;
    
    // Statut
    if (registrationStatus != null) patch['registration_status'] = registrationStatus;
    if (photoUrl != null) patch['photo_url'] = photoUrl;
    if (thixChat != null) patch['thix_chat'] = thixChat;

    await _client.from(_table).update(patch).eq('id', sessionUid);
  }

  /// Génère ou récupère le THIX ID unique de l'utilisateur
  Future<String> ensureThixId({required String uid}) async {
    final sessionUid = _requireAuthedUid();
    final row = await _client.from(_table).select('thix_id').eq('id', sessionUid).maybeSingle();
    final existing = (row?['thix_id'] ?? '').toString().trim();
    
    if (existing.isNotEmpty && existing != 'THIX-PENDING') return existing;

    final candidate = ThixIdService.generate();
    await _client.from(_table).update({'thix_id': candidate}).eq('id', sessionUid);
    return candidate;
  }

  /// Alias de ensureThixId pour compatibilité
  Future<String> assignRealThixIdIfMissing({required String uid}) async {
    return ensureThixId(uid: uid);
  }

  /// Valide, vérifie l'unicité et assigne un THIX CHAT à l'utilisateur
  Future<String> ensureThixChat({
    required String uid,
    required String desired,
  }) async {
    final sessionUid = _requireAuthedUid();
    
    // Vérifier si déjà assigné
    final row = await _client.from(_table).select('thix_chat').eq('id', sessionUid).maybeSingle();
    final existing = (row?['thix_chat'] ?? '').toString().trim();
    if (existing.isNotEmpty) return existing;
    
    // Valider le format
    final sanitized = desired.trim();
    if (sanitized.isEmpty) {
      throw Exception('THIX CHAT ne peut pas être vide.');
    }
    
    // Format: @nom (3-20 caractères alphanumériques, point ou underscore)
    if (!RegExp(r'^@[a-zA-Z0-9._]{3,20}$').hasMatch(sanitized)) {
      throw Exception('THIX CHAT invalide. Format: @suivi de 3 à 20 caractères (lettres, chiffres, . ou _)');
    }
    
    // Convertir en minuscules pour l'unicité
    final normalized = sanitized.toLowerCase();
    
    // Vérifier l'unicité
    final existingChat = await _client.from(_table).select('id').eq('thix_chat', normalized).maybeSingle();
    if (existingChat != null) {
      throw Exception('THIX CHAT déjà utilisé. Choisissez un autre identifiant.');
    }
    
    // Assigner le THIX CHAT
    await _client.from(_table).update({'thix_chat': normalized}).eq('id', sessionUid);
    return normalized;
  }
}
