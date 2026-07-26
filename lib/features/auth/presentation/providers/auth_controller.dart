import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:thix_id/models/app_user.dart';
import 'package:thix_id/auth/supabase_auth_manager.dart';
import 'package:thix_id/auth/auth_manager.dart';

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

  Future<void> registerPersonal({required String email, required String password, required String displayName, required bool rememberMe, Map<String, dynamic>? profileDraft}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(authManagerProvider).registerWithEmail(email: email, password: password, displayName: displayName, accountType: AccountType.personal, rememberMe: rememberMe, profileDraft: profileDraft));
  }

  Future<void> registerEnterprise({required String email, required String password, required String displayName, required bool rememberMe, Map<String, dynamic>? profileDraft}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(authManagerProvider).registerWithEmail(email: email, password: password, displayName: displayName, accountType: AccountType.enterprise, rememberMe: rememberMe, profileDraft: profileDraft));
  }
}
