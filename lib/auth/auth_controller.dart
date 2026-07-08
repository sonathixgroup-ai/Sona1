import 'package:flutter/foundation.dart';
import 'package:thix_id/auth/auth_manager.dart';
import 'package:thix_id/auth/supabase_auth_manager.dart';
import 'package:thix_id/models/app_user.dart';

class AuthController extends ChangeNotifier {
  static AuthController? _instance;
  static AuthController get instance => _instance ??= AuthController();

  final AuthManager _auth;

  AuthController({AuthManager? auth}) : _auth = auth ?? SupabaseAuthManager() {
    _instance ??= this;
    _auth.currentUserListenable.addListener(notifyListeners);
  }

  AppUser? get currentUser => _auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  Future<void> init() => _auth.init();

  Future<AppUser> signIn({required String identifier, required String password, required bool rememberMe}) async {
    final u = await _auth.signInWithEmailOrThixId(identifier: identifier, password: password, rememberMe: rememberMe);
    notifyListeners();
    return u;
  }

  Future<AppUser> registerPersonal({
    required String email,
    required String password,
    required String displayName,
    required bool rememberMe,
    Map<String, dynamic>? profileDraft,
  }) async {
    try {
      final u = await _auth.registerWithEmail(
        email: email,
        password: password,
        displayName: displayName,
        accountType: AccountType.personal,
        rememberMe: rememberMe,
        profileDraft: profileDraft,
      );
      notifyListeners();
      return u;
    } catch (e) {
      rethrow; // ← on relance l'exception pour que l'UI puisse la traiter
    }
  }

  Future<AppUser> registerEnterprise({...}) async {
    // similaire
  }

  Future<PhoneAuthSession> startPhoneAuth({required String phoneNumber}) => _auth.startPhoneAuth(phoneNumber: phoneNumber);

  Future<AppUser> confirmPhoneCode({...}) async {
    // ...
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  Future<void> updateCurrentUser(AppUser user) async {
    await _auth.updateCurrentUser(user);
    notifyListeners();
  }

  // ========== MÉTHODES OTP ==========
  Future<void> verifyOTP({required String email, required String token}) async {
    await _auth.verifyOTP(email: email, token: token);
    notifyListeners();
  }

  Future<void> resendOTP({required String email}) async {
    await _auth.resendOTP(email: email);
  }
}
