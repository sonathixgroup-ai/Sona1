import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';

class UserService {
  final SupabaseClient _supabase;

  UserService(this._supabase);

  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? fullName,
    String? photoUrl,
    String? registrationStatus,
    String? thixChat,
    String? bio,
    String? competence,
    String? countryOrOrigin,
    String? contactPhone,
    String? dateOfBirth,
    String? placeOfBirth,
    String? nationality,
    String? maritalStatus,
    String? gender,
    String? occupation,
    String? profession,
    String? address,
    String? fatherName,
    String? motherName,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelation,
    List<Map<String, dynamic>>? education,
    List<Map<String, dynamic>>? experience,
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
    List<Map<String, dynamic>>? emergencyContacts,
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
    bool? biometricsEnabled,
    bool? twoFaEnabled,
    List<String>? languages,
    List<Map<String, dynamic>>? languagesDetailed,
  }) async {
    final Map<String, dynamic> updates = {};
    
    // Informations personnelles
    if (displayName != null) updates['display_name'] = displayName;
    if (fullName != null) updates['full_name'] = fullName;
    if (photoUrl != null) updates['photo_url'] = photoUrl;
    if (registrationStatus != null) updates['registration_status'] = registrationStatus;
    if (thixChat != null) updates['thix_chat'] = thixChat;
    if (bio != null) updates['bio'] = bio;
    if (competence != null) updates['competence'] = competence;
    if (countryOrOrigin != null) updates['country_or_origin'] = countryOrOrigin;
    if (contactPhone != null) updates['contact_phone'] = contactPhone;
    if (dateOfBirth != null) updates['date_of_birth'] = dateOfBirth;
    if (placeOfBirth != null) updates['place_of_birth'] = placeOfBirth;
    if (nationality != null) updates['nationality'] = nationality;
    if (maritalStatus != null) updates['marital_status'] = maritalStatus;
    if (gender != null) updates['gender'] = gender;
    if (occupation != null) updates['occupation'] = occupation;
    if (profession != null) updates['profession'] = profession;
    if (address != null) updates['address'] = address;
    if (fatherName != null) updates['father_name'] = fatherName;
    if (motherName != null) updates['mother_name'] = motherName;
    if (emergencyContactName != null) updates['emergency_contact_name'] = emergencyContactName;
    if (emergencyContactPhone != null) updates['emergency_contact_phone'] = emergencyContactPhone;
    if (emergencyContactRelation != null) updates['emergency_contact_relation'] = emergencyContactRelation;
    if (education != null) updates['education'] = education;
    if (experience != null) updates['experience'] = experience;
    
    // Origine
    if (originProvince != null) updates['origin_province'] = originProvince;
    if (originTerritory != null) updates['origin_territory'] = originTerritory;
    if (originSector != null) updates['origin_sector'] = originSector;
    
    // Résidence
    if (residenceCountry != null) updates['residence_country'] = residenceCountry;
    if (residenceProvince != null) updates['residence_province'] = residenceProvince;
    if (residenceTerritory != null) updates['residence_territory'] = residenceTerritory;
    if (residenceCity != null) updates['residence_city'] = residenceCity;
    if (residenceCommune != null) updates['residence_commune'] = residenceCommune;
    if (residenceQuarter != null) updates['residence_quarter'] = residenceQuarter;
    if (residenceAvenue != null) updates['residence_avenue'] = residenceAvenue;
    if (residenceNumber != null) updates['residence_number'] = residenceNumber;
    
    // Contacts d'urgence
    if (emergencyContacts != null) updates['emergency_contacts'] = emergencyContacts;
    
    // Informations physiques
    if (height != null) updates['height'] = height;
    if (weight != null) updates['weight'] = weight;
    if (bloodGroup != null) updates['blood_group'] = bloodGroup;
    if (hasPhysicalDisability != null) updates['has_physical_disability'] = hasPhysicalDisability;
    if (physicalDisabilityDescription != null) updates['physical_disability_description'] = physicalDisabilityDescription;
    
    // Documents d'identité
    if (nationalIdNumber != null) updates['national_id_number'] = nationalIdNumber;
    if (idDocumentType != null) updates['id_document_type'] = idDocumentType;
    if (idDocumentIssueDate != null) updates['id_document_issue_date'] = idDocumentIssueDate;
    if (idDocumentExpiryDate != null) updates['id_document_expiry_date'] = idDocumentExpiryDate;
    if (idDocumentIssuePlace != null) updates['id_document_issue_place'] = idDocumentIssuePlace;
    if (idDocumentFrontDocId != null) updates['id_document_front_doc_id'] = idDocumentFrontDocId;
    if (idDocumentBackDocId != null) updates['id_document_back_doc_id'] = idDocumentBackDocId;
    if (idDocumentSelfieDocId != null) updates['id_document_selfie_doc_id'] = idDocumentSelfieDocId;
    if (idVerificationStatus != null) updates['id_verification_status'] = idVerificationStatus;
    
    // Sécurité
    if (biometricsEnabled != null) updates['biometrics_enabled'] = biometricsEnabled;
    if (twoFaEnabled != null) updates['two_fa_enabled'] = twoFaEnabled;
    
    // Langues
    if (languages != null) updates['languages'] = languages;
    if (languagesDetailed != null) updates['languages_detailed'] = languagesDetailed;

    if (updates.isNotEmpty) {
      updates['updated_at'] = DateTime.now().toIso8601String();
      await _supabase.from('profiles').update(updates).eq('id', uid);
    }
  }

  // ==================== MÉTHODES DE PAIEMENT ====================

  Future<void> addPaymentTransaction({
    required String uid,
    required String title,
    required double amount,
    required String currency,
    required String method,
    required String status,
  }) async {
    final payment = {
      'user_id': uid,
      'title': title,
      'amount': amount,
      'currency': currency,
      'method': method,
      'status': status,
      'tx_ref': 'TX-${DateTime.now().millisecondsSinceEpoch}',
      'created_at': DateTime.now().toIso8601String(),
    };
    await _supabase.from('thix_payments').insert(payment);
  }

  Stream<List<Map<String, dynamic>>> streamPayments(String uid) {
    return _supabase
        .from('thix_payments')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .map((list) => list.cast<Map<String, dynamic>>());
  }

  // ==================== MÉTHODES DE SÉCURITÉ ====================

  Future<void> logSecurityEvent({
    required String uid,
    required String type,
    required String label,
  }) async {
    final event = {
      'user_id': uid,
      'type': type,
      'label': label,
      'created_at': DateTime.now().toIso8601String(),
    };
    await _supabase.from('security_events').insert(event);
  }

  Stream<List<Map<String, dynamic>>> streamSecurityEvents(String uid) {
    return _supabase
        .from('security_events')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .map((list) => list.cast<Map<String, dynamic>>());
  }

  // ==================== MÉTHODES POUR THIX ID ====================

  Future<String> ensureThixId({required String uid}) async {
    final row = await _supabase.from('profiles').select('thix_id').eq('id', uid).maybeSingle();
    final existing = (row?['thix_id'] ?? '').toString().trim();
    if (existing.isNotEmpty && existing != 'THIX-PENDING') return existing;
    final candidate = 'THIX-${DateTime.now().millisecondsSinceEpoch}';
    await _supabase.from('profiles').update({'thix_id': candidate}).eq('id', uid);
    return candidate;
  }

  Future<String> ensureThixChat({required String uid, required String desired}) async {
    final normalized = desired.trim().toLowerCase();
    await _supabase.from('profiles').update({'thix_chat': normalized}).eq('id', uid);
    return normalized;
  }

  // ==================== MÉTHODES POUR HOME PAGE ====================

  Future<AppUser?> getUserByThixId(String thixId) async {
    final row = await _supabase
        .from('profiles')
        .select()
        .eq('thix_id', thixId)
        .maybeSingle();
    if (row == null) return null;
    return _mapToAppUser(row as Map<String, dynamic>);
  }

  Future<AppUser?> getUserById(String userId) async {
    final row = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;
    return _mapToAppUser(row as Map<String, dynamic>);
  }

  AppUser _mapToAppUser(Map<String, dynamic> row) {
    return AppUser(
      id: row['id'],
      thixId: row['thix_id'] ?? 'THIX-PENDING',
      thixChat: row['thix_chat'] ?? '',
      displayName: row['display_name'] ?? 'Utilisateur',
      email: row['email'] ?? '',
      phone: row['phone'],
      photoUrl: row['photo_url'],
      bio: row['bio'],
      occupation: row['occupation'],
      countryOrOrigin: row['country_or_origin'],
      accountType: row['account_type'] == 'enterprise' ? AccountType.enterprise : AccountType.personal,
      registrationStatus: row['registration_status'],
      createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at']) ?? DateTime.now() : DateTime.now(),
      updatedAt: row['updated_at'] != null ? DateTime.tryParse(row['updated_at']) ?? DateTime.now() : DateTime.now(),
    );
  }
}
