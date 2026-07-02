import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseConfig {
  /// Supabase credentials pour Thix Central
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://lldgnysfiabakhaibgzq.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxsZGdueXNmaWFiYWtoYWliZ3pxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI1NzgxNjcsImV4cCI6MjA5ODE1NDE2N30.AmrEd5RECLsamIjYiUBk_F4azYtBeMV3drL5RPzFhjo',
  );

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (supabaseUrl.trim().isEmpty || anonKey.trim().isEmpty) {
        throw Exception('Supabase URL ou Anon Key manquant !');
      }

      debugPrint('🔄 SupabaseConfig: Initialisation sur Thix Central...');
      debugPrint('📡 URL: $supabaseUrl');

      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: anonKey,
        debug: kDebugMode,
      );

      _initialized = true;
      debugPrint('✅ Supabase initialisé avec succès');
    } catch (e) {
      debugPrint('❌ Échec de l\'initialisation Supabase: $e');
      rethrow;
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;
  static SupabaseStorageClient get storage => client.storage;

  static User? get currentUser => auth.currentUser;
  static Stream<AuthState> get onAuthStateChange => auth.onAuthStateChange;
}
