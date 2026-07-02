// lib/auth/supabase_auth_manager.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/models/app_user.dart';
import 'package:thix_id/models/phone_auth_session.dart';
import 'auth_manager.dart';

class SupabaseAuthManager extends AuthManager {
  AppUser? _currentUser;
  final ValueNotifier<AppUser?> _currentUserNotifier = ValueNotifier(null);

  @override
  AppUser? get currentUser => _currentUser;

  @override
  ValueListenable<AppUser?> get currentUserListenable => _currentUserNotifier;

  SupabaseAuthManager() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        _currentUser = _fromSupabaseUser(session.user);
      } else {
        _currentUser = null;
      }
      _currentUserNotifier.value = _currentUser;
    });
  }

  @override
  Future<void> init() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      _currentUser = _fromSupabaseUser(session.user);
      _currentUserNotifier.value = _currentUser;
    }
  }

  @override
  Future<AppUser> signInWithEmailOrThixId({
    required String identifier,
    required String password,
    required bool rememberMe,
  }) async {
    // Supabase utilise l'email pour la connexion.
    // Si l'identifiant est un THIX ID, il faudrait d'abord récupérer l'email correspondant.
    // Pour l'instant, on suppose que c'est un email.
    final response = await Supabase.instance.client.auth.signInWithPassword(
      email: identifier,
      password: password,
    );
    final user = _fromSupabaseUser(response.user!);
    _currentUser = user;
    _currentUserNotifier.value = user;
    return user;
  }

  @override
  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
    required AccountType accountType,
    required bool rememberMe,
    Map<String, dynamic>? profileDraft,
  }) async {
    final response = await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
      data: {
        'display_name': displayName,
        'account_type': accountType.name,
        ...?profileDraft,
        // On peut ajouter un thixId provisoire
        'thix_id': 'THIX-PENDING',
      },
    );
    final user = _fromSupabaseUser(response.user!);
    _currentUser = user;
    _currentUserNotifier.value = user;
    return user;
  }

  @override
  Future<PhoneAuthSession> startPhoneAuth({required String phoneNumber}) async {
    // Supabase n'a pas d'API native pour l'authentification par SMS.
    // Vous devrez utiliser un service externe (ex: Twilio) et stocker le token.
    // Ici on simule.
    await Future.delayed(const Duration(seconds: 1));
    return PhoneAuthSession(
      verificationId: 'fake_verification_id_${DateTime.now().millisecondsSinceEpoch}',
      phoneNumber: phoneNumber,
    );
  }

  @override
  Future<AppUser> confirmPhoneCode({
    required PhoneAuthSession session,
    required String smsCode,
    String? displayName,
    AccountType accountType = AccountType.personal,
  }) async {
    // Simulation : on crée un utilisateur avec un email fictif.
    // En réalité, vous utiliseriez le service SMS pour vérifier le code.
    // Puis vous créeriez l'utilisateur dans Supabase avec un email généré.
    final tempEmail = '${DateTime.now().millisecondsSinceEpoch}@temp.thix.id';
    final response = await Supabase.instance.client.auth.signUp(
      email: tempEmail,
      password: 'TempPassword123!',
      data: {
        'display_name': displayName ?? 'Utilisateur téléphone',
        'account_type': accountType.name,
        'phone': session.phoneNumber,
        'thix_id': 'THIX-PENDING',
      },
    );
    final user = _fromSupabaseUser(response.user!);
    _currentUser = user;
    _currentUserNotifier.value = user;
    return user;
  }

  @override
  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    _currentUser = null;
    _currentUserNotifier.value = null;
  }

  @override
  Future<void> updateCurrentUser(AppUser user) async {
    await Supabase.instance.client.auth.updateUser(
      UserAttributes(
        data: {
          'display_name': user.displayName,
          'account_type': user.accountType.name,
          'thix_id': user.thixId,
          'thix_chat': user.thixChat,
          'thix_score': user.thixScore,
          'bio': user.bio,
          'country_or_origin': user.countryOrOrigin,
          'contact_phone': user.contactPhone,
          'marital_status': user.maritalStatus,
          'gender': user.gender,
          'occupation': user.occupation,
          'profession': user.profession,
          'date_of_birth': user.dateOfBirth,
          'place_of_birth': user.placeOfBirth,
          'nationality': user.nationality,
          'address': user.address,
          'father_name': user.fatherName,
          'mother_name': user.motherName,
          'emergency_contact_name': user.emergencyContactName,
          'emergency_contact_phone': user.emergencyContactPhone,
          'emergency_contact_relation': user.emergencyContactRelation,
          'registration_status': user.registrationStatus,
          'education': user.education,
          'experience': user.experience,
          'skills': user.skills,
          'enrollments': user.enrollments,
          'languages': user.languages,
          'biometrics_enabled': user.biometricsEnabled,
          'two_fa_enabled': user.twoFaEnabled,
        },
      ),
    );
    _currentUser = user;
    _currentUserNotifier.value = user;
  }

  // Helper pour convertir un User Supabase en AppUser
  AppUser _fromSupabaseUser(User user) {
    final meta = user.userMetadata ?? {};
    final now = DateTime.now();

    return AppUser(
      id: user.id,
      thixId: meta['thix_id'] ?? 'THIX-PENDING',
      thixChat: meta['thix_chat'] ?? '',
      thixScore: (meta['thix_score'] as num?)?.toInt(),
      email: user.email ?? '',
      phone: meta['phone'] ?? user.phone,
      displayName: meta['display_name'] ?? user.email?.split('@').first ?? 'Utilisateur',
      accountType: _parseAccountType(meta['account_type']),
      photoUrl: meta['photo_url'],
      bio: meta['bio'],
      countryOrOrigin: meta['country_or_origin'],
      contactPhone: meta['contact_phone'],
      maritalStatus: meta['marital_status'],
      gender: meta['gender'],
      occupation: meta['occupation'],
      profession: meta['profession'],
      dateOfBirth: meta['date_of_birth'],
      placeOfBirth: meta['place_of_birth'],
      nationality: meta['nationality'],
      address: meta['address'],
      fatherName: meta['father_name'],
      motherName: meta['mother_name'],
      emergencyContactName: meta['emergency_contact_name'],
      emergencyContactPhone: meta['emergency_contact_phone'],
      emergencyContactRelation: meta['emergency_contact_relation'],
      registrationStatus: meta['registration_status'],
      education: (meta['education'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [],
      experience: (meta['experience'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [],
      skills: (meta['skills'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [],
      enrollments: (meta['enrollments'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [],
      languages: (meta['languages'] as List?)?.map((e) => e.toString()).toList() ?? [],
      biometricsEnabled: meta['biometrics_enabled'] ?? true,
      twoFaEnabled: meta['two_fa_enabled'] ?? false,
      createdAt: _parseDate(meta['created_at']) ?? now,
      updatedAt: _parseDate(meta['updated_at']) ?? now,
      passwordSaltB64: '',
      passwordHashHex: '',
    );
  }

  AccountType _parseAccountType(dynamic value) {
    if (value == 'enterprise') return AccountType.enterprise;
    return AccountType.personal;
  }

  DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
