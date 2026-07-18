import 'package:supabase_flutter/supabase_flutter.dart';

class AdminGuard {
  static bool get isAdmin {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;
    // Méthode 1 : via user_metadata {role: admin}
    final role = user.userMetadata?['role'] ?? user.appMetadata['role'];
    if (role == 'admin') return true;
    // Méthode 2 : via email whitelist (en attendant ta table roles)
    const admins = ['admin@thix.id', 'thix@thix.id'];
    return admins.contains(user.email);
  }

  static Future<bool> canAccess() async {
    return isAdmin;
  }
}
