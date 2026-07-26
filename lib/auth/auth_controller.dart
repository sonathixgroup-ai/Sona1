// lib/features/auth/presentation/providers/auth_controller.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:thix_id/auth/auth_manager.dart';
import 'package:thix_id/auth/supabase_auth_manager.dart';
import 'package:thix_id/model/app_user.dart';
import 'package:thix_id/services/profile_service.dart';
import '../../data/auth_repository.dart';

part 'auth_controller.g.dart';

@Riverpod(keepAlive: true)
AuthManager authManager(AuthManagerRef ref) {
  return SupabaseAuthManager(profiles: ProfileService());
}

@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  late final AuthManager _auth;

  @override
  Future<AppUser?> build() async {
    _auth = ref.watch(authManagerProvider);
    await _auth.init();
    
    // Écoute le stream Supabase au lieu de Listenable
    ref.listen(authUserStreamProvider, (prev, next) {
      if (next.valueOrNull == null) {
        state = const AsyncData(null);
      }
    });
    
    return _auth.currentUser;
  }

  bool get isAuthenticated => state.valueOrNull != null;
  AppUser? get currentUser => state.valueOrNull;

  // ===== MÉTHODES MODERNES (Sécurisées par AsyncValue.guard) =====

  Future<void> signIn({required String identifier, required String password, required bool rememberMe}) async {
    state = const AsyncLoading(); // L'UI passe en mode chargement
    state = await AsyncValue.guard(() async {
      return await _auth.signInWithEmailOrThixId(
        identifier: identifier, 
        password: password, 
        rememberMe: rememberMe
      );
    });
  }

  Future<void> registerPersonal({
    required String email, required String password, required String displayName,
    required bool rememberMe, Map<String, dynamic>? profileDraft,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return await _auth.registerWithEmail(
        email: email, 
        password: password, 
        displayName: displayName,
        accountType: AccountType.personal, 
        rememberMe: rememberMe, 
        profileDraft: profileDraft,
      );
    });
  }

  Future<void> registerEnterprise({
    required String email, required String password, required String displayName,
    required bool rememberMe, Map<String, dynamic>? profileDraft,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return await _auth.registerWithEmail(
        email: email, 
        password: password, 
        displayName: displayName,
        accountType: AccountType.enterprise, 
        rememberMe: rememberMe, 
        profileDraft: profileDraft,
      );
    });
  }

  Future<void> signOut() async {
    await _auth.signOut();
    state = const AsyncData(null);
  }

  Future<void> updateCurrentUser(AppUser user) async {
    await _auth.updateCurrentUser(user);
    state = AsyncData(user); // Met à jour l'UI instantanément
  }

  Future<void> verifyOTP({required String email, required String token}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _auth.verifyOTP(email: email, token: token);
      return await _auth.refreshCurrentUser();
    });
  }

  Future<void> refreshCurrentUser() async {
    state = await AsyncValue.guard(() async {
      return await _auth.refreshCurrentUser();
    });
  }

  Future<void> resendOTP({required String email}) async {
    await _auth.resendOTP(email: email);
  }

  Future<PhoneAuthSession> startPhoneAuth({required String phoneNumber}) {
    return _auth.startPhoneAuth(phoneNumber: phoneNumber);
  }

  Future<void> confirmPhoneCode({
    required PhoneAuthSession session, required String smsCode,
    String? displayName, AccountType accountType = AccountType.personal,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return await _auth.confirmPhoneCode(
        session: session, 
        smsCode: smsCode, 
        displayName: displayName, 
        accountType: accountType
      );
    });
  }
}
