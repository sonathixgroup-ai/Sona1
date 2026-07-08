import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:thix_id/auth/auth_manager.dart';
import 'package:thix_id/models/app_user.dart';
import 'package:thix_id/models/thix_profile.dart';
import 'package:thix_id/services/profile_service.dart';
import 'package:thix_id/services/push_notification_service.dart';
import 'package:thix_id/services/supabase_safe_write.dart';
import 'package:thix_id/supabase/supabase_config.dart';

class SupabaseAuthManager implements AuthManager {
  final SupabaseClient _client;
  final ProfileService _profiles;
  final ValueNotifier<AppUser?> _currentUser = ValueNotifier<AppUser?>(null);
  StreamSubscription<AuthState>? _sub;
  StreamSubscription<ThixProfile?>? _profileSub;

  SupabaseAuthManager({SupabaseClient? client, ProfileService? profiles})
      : _client = client ?? SupabaseConfig.client,
        _profiles = profiles ?? ProfileService();

  @override
  ValueListenable<AppUser?> get currentUserListenable => _currentUser;

  @override
  AppUser? get currentUser => _currentUser.value;

  @override
  Future<void> init() async {
    // ... (votre code init inchangé)
  }

  void _bindProfileSync(String uid) {
    // ... (votre code inchangé)
  }

  Future<AppUser> _hydrateUser(User user) async {
    // ... (votre code inchangé)
  }

  AccountType _accountTypeFromMeta(Map<String, dynamic>? meta) {
    // ... (votre code inchangé)
  }

  AppUser _appUserFromProfileRow({...}) {
    // ... (votre code inchangé)
  }

  Future<Map<String, dynamic>?> _selectProfileRow(String uid) async {
    // ... (votre code inchangé)
  }

  Future<void> _ensureProfileRow({...}) async {
    // ... (votre code inchangé)
  }

  // ==========================================================================
  // MÉTHODES PUBLIQUES
  // ==========================================================================

  @override
  Future<AppUser> signInWithEmailOrThixId({...}) async {
    // ... (votre code inchangé)
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
    final normalizedEmail = email.trim().toLowerCase();
    if (!_isValidEmail(normalizedEmail)) throw AuthException('Email invalide.');
    if (password.trim().length < 8) throw AuthException('Le mot de passe doit contenir au moins 8 caractères.');

    try {
      final userMeta = <String, dynamic>{
        'display_name': displayName.trim().isEmpty ? 'Utilisateur THIX' : displayName.trim(),
        'account_type': accountType.name,
        ...?profileDraft,
      };

      final res = await _client.auth.signUp(
        email: normalizedEmail,
        password: password,
        data: userMeta,
      );

      final session = res.session;
      final user = res.user;
      if (user == null || session == null) {
        // Inscription en attente de confirmation email : l'utilisateur n'est pas encore connecté
        throw AuthException(
          'Inscription enregistrée. Confirmez votre email puis connectez-vous: votre profil sera créé automatiquement.',
        );
      }

      final now = DateTime.now();
      final appUser = AppUser(
        id: user.id,
        thixId: 'THIX-PENDING',
        thixChat: '',
        thixScore: null,
        email: normalizedEmail,
        phone: user.phone,
        displayName: (() {
          final m = userMeta['display_name']?.toString().trim() ?? '';
          if (m.isNotEmpty) return m;
          final d = displayName.trim();
          return d.isEmpty ? 'Utilisateur THIX' : d;
        })(),
        accountType: accountType,
        photoUrl: null,
        bio: null,
        countryOrOrigin: (userMeta['country_or_origin'] ?? userMeta['countryOrOrigin'])?.toString(),
        contactPhone: (userMeta['contact_phone'] ?? userMeta['contactPhone'])?.toString(),
        maritalStatus: (userMeta['marital_status'] ?? userMeta['maritalStatus'])?.toString(),
        gender: userMeta['gender']?.toString(),
        occupation: userMeta['occupation']?.toString(),
        profession: userMeta['profession']?.toString(),
        dateOfBirth: (userMeta['date_of_birth'] ?? userMeta['dateOfBirth'])?.toString(),
        placeOfBirth: (userMeta['place_of_birth'] ?? userMeta['placeOfBirth'])?.toString(),
        nationality: userMeta['nationality']?.toString(),
        address: userMeta['address']?.toString(),
        fatherName: (userMeta['father_name'] ?? userMeta['fatherName'])?.toString(),
        motherName: (userMeta['mother_name'] ?? userMeta['motherName'])?.toString(),
        emergencyContactName: (userMeta['emergency_contact_name'] ?? userMeta['emergencyContactName'])?.toString(),
        emergencyContactPhone: (userMeta['emergency_contact_phone'] ?? userMeta['emergencyContactPhone'])?.toString(),
        emergencyContactRelation: (userMeta['emergency_contact_relation'] ?? userMeta['emergencyContactRelation'])?.toString(),
        education: const [],
        experience: const [],
        skills: const [],
        enrollments: const [],
        languages: (userMeta['languages'] is List) ? (userMeta['languages'] as List).whereType<String>().toList(growable: false) : const [],
        biometricsEnabled: true,
        twoFaEnabled: false,
        createdAt: now,
        updatedAt: now,
      );

      await _ensureProfileRow(userId: user.id, user: appUser);
      await _profiles.ensureProfileExists(user: appUser);

      _currentUser.value = appUser;
      return appUser;
    } catch (e) {
      debugPrint('SupabaseAuthManager: register failed err=$e');
      String msg;
      if (e is PostgrestException) {
        msg = '${e.message} (code: ${e.code})';
      } else if (e is AuthException) {
        msg = e.message;
      } else {
        msg = e.toString();
      }
      throw AuthException(msg); // ← on propage le vrai message
    }
  }

  @override
  Future<AppUser> registerPersonal({...}) {
    return registerWithEmail(
      email: email,
      password: password,
      displayName: displayName,
      accountType: AccountType.personal,
      rememberMe: rememberMe,
      profileDraft: profileDraft,
    );
  }

  @override
  Future<void> verifyOTP({required String email, required String token}) async {
    try {
      await _client.auth.verifyOTP(
        email: email.trim().toLowerCase(),
        token: token.trim(),
        type: OtpType.email,
      );
      await _refreshCurrentUser();
    } catch (e) {
      debugPrint('SupabaseAuthManager: verifyOTP failed err=$e');
      String msg;
      if (e is PostgrestException) {
        msg = '${e.message} (code: ${e.code})';
      } else {
        msg = e.toString();
      }
      throw AuthException(msg);
    }
  }

  @override
  Future<void> resendOTP({required String email}) async {
    try {
      await _client.auth.resend(
        type: OtpType.signup,
        email: email.trim().toLowerCase(),
      );
    } catch (e) {
      debugPrint('SupabaseAuthManager: resendOTP failed err=$e');
      String msg;
      if (e is PostgrestException) {
        msg = '${e.message} (code: ${e.code})';
      } else {
        msg = e.toString();
      }
      throw AuthException(msg);
    }
  }

  Future<void> _refreshCurrentUser() async {
    final session = _client.auth.currentSession;
    if (session != null) {
      final hydrated = await _hydrateUser(session.user);
      _currentUser.value = hydrated;
      _bindProfileSync(session.user.id);
    }
  }

  // ... autres méthodes (signOut, deleteAccount, updateEmail, etc.) inchangées
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => 'AuthException: $message';
}
