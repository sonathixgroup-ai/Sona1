import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:thix_id/models/app_user.dart';
import 'package:thix_id/auth/auth_manager.dart';
import 'package:thix_id/auth/supabase_auth_manager.dart';

part 'auth_controller.g.dart';

@Riverpod(keepAlive: true)
AuthManager authManager(AuthManagerRef ref) => SupabaseAuthManager();

@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  Future<AppUser?> build() async {
    final m = ref.watch(authManagerProvider);
    await m.init();
    return m.currentUser;
  }

  Future<void> signIn({required String identifier, required String password, required bool rememberMe}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(authManagerProvider).signInWithEmailOrThixId(identifier: identifier, password: password, rememberMe: rememberMe));
  }

  Future<void> registerPersonal({required String email, required String password, required String displayName, required bool rememberMe, Map<String, dynamic>? profileDraft}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(authManagerProvider).registerWithEmail(email: email, password: password, displayName: displayName, accountType: AccountType.personal, rememberMe: rememberMe, profileDraft: profileDraft));
  }

  Future<void> registerEnterprise({required String email, required String password, required String displayName, required bool rememberMe, Map<String, dynamic>? profileDraft}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(authManagerProvider).registerWithEmail(email: email, password: password, displayName: displayName, accountType: AccountType.enterprise, rememberMe: rememberMe, profileDraft: profileDraft));
  }

  Future<void> verifyOTP({required String email, required String token}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authManagerProvider).verifyOTP(email: email, token: token);
      return await ref.read(authManagerProvider).refreshCurrentUser();
    });
  }

  Future<void> resendOTP({required String email}) => ref.read(authManagerProvider).resendOTP(email: email);
  Future<PhoneAuthSession> startPhoneAuth({required String phoneNumber}) => ref.read(authManagerProvider).startPhoneAuth(phoneNumber: phoneNumber);
  Future<void> confirmPhoneCode({required PhoneAuthSession session, required String smsCode, String? displayName, AccountType accountType = AccountType.personal}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(authManagerProvider).confirmPhoneCode(session: session, smsCode: smsCode, displayName: displayName, accountType: accountType));
  }

  Future<void> signOut() async {
    await ref.read(authManagerProvider).signOut();
    state = const AsyncData(null);
  }
}
