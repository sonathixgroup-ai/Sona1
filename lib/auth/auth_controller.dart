import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/models/app_user.dart';
import 'package:thix_id/models/account_type.dart';
import 'package:thix_id/auth/auth_manager.dart' show PhoneAuthSession;

class AuthController extends ChangeNotifier {
  final dynamic _authManager;
  AuthController({dynamic auth}) : _authManager = auth;

  AppUser? _appUser;
  AppUser? get currentUser => _appUser;
  bool get isAuthenticated => Supabase.instance.client.auth.currentUser != null || _appUser != null;

  Future<void> init() async {
    try {
      await _authManager?.init();
      final supaUser = Supabase.instance.client.auth.currentUser;
      if (supaUser != null) {
        await _loadAppUser(supaUser.id);
      }
    } catch (e) {
      debugPrint('Auth init error: $e');
    }
  }

  Future<void> _loadAppUser(String userId) async {
    try {
      final data = await Supabase.instance.client.from('profiles').select().eq('id', userId).maybeSingle();
      if (data != null) {
        _appUser = AppUser.fromJson(data); // si tu as fromJson, sinon adapte
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Load profile error: $e');
    }
  }

  Future<void> signIn({required String identifier, required String password, required bool rememberMe}) async {
    String email = identifier.trim();
    // Si c'est un TX-ID, on cherche l'email
    if (!email.contains('@')) {
      final res = await Supabase.instance.client.from('profiles').select('email').eq('thix_id', email).maybeSingle();
      if (res == null || res['email'] == null) throw Exception('THIX ID introuvable');
      email = res['email'];
    }

    final res = await Supabase.instance.client.auth.signInWithPassword(email: email, password: password);
    if (res.user == null) throw Exception('Identifiants invalides');
    await _loadAppUser(res.user!.id);
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    _appUser = null;
    notifyListeners();
  }

  // Laisse le reste en délégation
  Future<void> registerPersonal({required String email, required String password, required String displayName, required bool rememberMe, Map<String, dynamic>? profileDraft}) async {
    await _authManager?.registerPersonal(email: email, password: password, displayName: displayName, rememberMe: rememberMe, profileDraft: profileDraft);
  }
  Future<void> registerEnterprise({required String email, required String password, required String displayName, required bool rememberMe, Map<String, dynamic>? profileDraft}) async {
    await _authManager?.registerEnterprise(email: email, password: password, displayName: displayName, rememberMe: rememberMe, profileDraft: profileDraft);
  }
  Future<PhoneAuthSession> startPhoneAuth({required String phoneNumber}) async => PhoneAuthSession();
  Future<void> confirmPhoneCode({required PhoneAuthSession session, required String smsCode, String? displayName, AccountType accountType = AccountType.personal}) async {}
  Future<void> verifyOTP({required String email, required String token}) async {}
  Future<void> resendOTP({required String email}) async {}
}
