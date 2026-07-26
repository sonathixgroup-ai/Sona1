import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/model/app_user.dart';

class AuthController extends ChangeNotifier {
  AppUser? _cached;

  AppUser? get currentUser {
    if (_cached != null) return _cached;
    final u = Supabase.instance.client.auth.currentUser;
    if (u == null) return null;

    final now = DateTime.now();
    // On fabrique un AppUser minimal qui respecte tous tes required
    return AppUser(
      id: u.id,
      thixId: (u.userMetadata?['thix_id'] as String?) ?? 'THIX-PENDING',
      thixChat: '',
      thixScore: null,
      email: (u.email ?? '').toLowerCase(),
      phone: u.phone,
      displayName: (u.userMetadata?['display_name'] as String?) ?? u.email?.split('@').first ?? 'Utilisateur THIX',
      accountType: AccountType.personal,
      photoUrl: null,
      bio: null,
      countryOrOrigin: null,
      registrationStatus: null,
      education: const [],
      experience: const [],
      skills: const [],
      enrollments: const [],
      languages: const [],
      biometricsEnabled: true,
      twoFaEnabled: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  bool get isAuthenticated => Supabase.instance.client.auth.currentUser != null;

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    _cached = null;
    notifyListeners();
  }

  void setUser(AppUser? user) {
    _cached = user;
    notifyListeners();
  }
}
