import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/models/account_type.dart';

class PhoneAuthSession { final String phone; PhoneAuthSession(this.phone); }

class AuthController extends ChangeNotifier {
  dynamic _cached;
  dynamic get currentUser => _cached;
  bool get isAuthenticated => _cached != null || Supabase.instance.client.auth.currentUser != null;

  Future<void> init() async {}

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    _cached = null;
    notifyListeners();
  }

  void setUser(dynamic user) { _cached = user; notifyListeners(); }
  Future<void> updateCurrentUser(dynamic user) async { _cached = user; notifyListeners(); }

  Future<void> registerPersonal({required String email, required String password, required String displayName, required bool rememberMe, Map<String, dynamic>? profileDraft}) async {}
  Future<void> registerEnterprise({required String email, required String password, required String displayName, required bool rememberMe, Map<String, dynamic>? profileDraft}) async {}
  Future<void> signIn({required String identifier, required String password, required bool rememberMe}) async {}
  Future<void> verifyOTP({required String email, required String token}) async {}
  Future<void> resendOTP({required String email}) async {}
  Future<PhoneAuthSession> startPhoneAuth({required String phoneNumber}) async => PhoneAuthSession(phoneNumber);
  Future<void> confirmPhoneCode({required PhoneAuthSession session, required String smsCode, String? displayName, AccountType accountType = AccountType.personal}) async {}
}
