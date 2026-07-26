import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/models/app_user.dart';

class AuthController extends ChangeNotifier {
  AppUser? _cached;

  AppUser? get currentUser {
    // Si tu as déjà un cache Riverpod, on retourne null ici pour le build
    // Le vrai user vient du Supabase session pour la compatibilité
    if (_cached != null) return _cached;
    final u = Supabase.instance.client.auth.currentUser;
    if (u == null) return null;
    // On retourne un AppUser minimal pour que .id et .thixId existent
    // Adapte selon ton model AppUser
    try {
      return AppUser(
        id: u.id,
        email: u.email,
        thixId: u.userMetadata?['thix_id'] as String?,
        displayName: u.userMetadata?['display_name'] as String? ?? u.email?.split('@').first,
      );
    } catch (_) {
      return null;
    }
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
