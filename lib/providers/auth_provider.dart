// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase;
  bool _isModerator = false;

  AuthProvider(this._supabase) {
    _checkRole();
  }

  bool get isModerator => _isModerator;

  Future<void> _checkRole() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        final response = await _supabase
            .from('users')
            .select('role')
            .eq('id', user.id)
            .maybeSingle();
        _isModerator = response != null &&
            (response['role'] == 'moderator' || response['role'] == 'admin');
      } catch (e) {
        debugPrint('❌ Erreur récupération rôle: $e');
        _isModerator = false;
      }
      notifyListeners();
    }
  }

  void refresh() => _checkRole();
}
