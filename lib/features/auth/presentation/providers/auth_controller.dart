import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thix_id/auth/auth_controller.dart' as legacy;
import 'package:thix_id/models/app_user.dart';
import 'package:thix_id/auth/auth_manager.dart' show PhoneAuthSession;

final authControllerProvider = AsyncNotifierProvider<AuthControllerNotifier, AppUser?>(AuthControllerNotifier.new);

class AuthControllerNotifier extends AsyncNotifier<AppUser?> {
  legacy.AuthController get _auth => legacy.AuthController.instance;

  @override
  Future<AppUser?> build() async {
    await _auth.init();
    return _auth.currentUser;
  }

  Future<void> signIn({required String identifier, required String password, required bool rememberMe}) async {
    state = const AsyncLoading();
    try {
      final user = await _auth.signIn(identifier: identifier, password: password, rememberMe: rememberMe);
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<PhoneAuthSession> startPhoneAuth({required String phoneNumber}) => _auth.startPhoneAuth(phoneNumber: phoneNumber);

  Future<void> confirmPhoneCode({required PhoneAuthSession session, required String smsCode}) async {
    state = const AsyncLoading();
    final user = await _auth.confirmPhoneCode(session: session, smsCode: smsCode);
    state = AsyncData(user);
  }
}
