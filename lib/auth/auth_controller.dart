import 'package:flutter/foundation.dart';
import 'package:thix_id/auth/auth_manager.dart';
import 'package:thix_id/auth/supabase_auth_manager.dart';
import 'package:thix_id/models/app_user.dart';

class AuthController extends ChangeNotifier {
  static AuthController? _instance;

  /// Global singleton accessor used by some legacy pages (ex: THIX Santé).
  ///
  /// In Dreamflow, the app also injects an AuthController via Provider.
  /// We keep both worlds consistent by assigning the first constructed
  /// instance (usually the bootstrap instance) to this singleton.
  static AuthController get instance => _instance ??= AuthController();

  final AuthManager _auth;

  /// Defaults to SupabaseAuthManager to enforce Supabase-only backend.
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
  }

  Future<AppUser> registerEnterprise({
    required String email,
    required String password,
    required String displayName,
    required bool rememberMe,
    Map<String, dynamic>? profileDraft,
  }) async {
    final u = await _auth.registerWithEmail(
      email: email,
      password: password,
      displayName: displayName,
      accountType: AccountType.enterprise,
      rememberMe: rememberMe,
      profileDraft: profileDraft,
    );
    notifyListeners();
    return u;
  }

  Future<PhoneAuthSession> startPhoneAuth({required String phoneNumber}) => _auth.startPhoneAuth(phoneNumber: phoneNumber);

  Future<AppUser> confirmPhoneCode({
    required PhoneAuthSession session,
    required String smsCode,
    String? displayName,
    AccountType accountType = AccountType.personal,
  }) async {
    final u = await _auth.confirmPhoneCode(session: session, smsCode: smsCode, displayName: displayName, accountType: accountType);
    notifyListeners();
    return u;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  Future<void> updateCurrentUser(AppUser user) async {
    await _auth.updateCurrentUser(user);
    notifyListeners();
  }
}
