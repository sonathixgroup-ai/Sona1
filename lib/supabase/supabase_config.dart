class SupabaseConfig {
  /// Supabase credentials injected at build time.
  /// 
  /// Utilisez `--dart-define=SUPABASE_URL=...` et `--dart-define=SUPABASE_ANON_KEY=...`
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '', // Plus de valeur en dur ici
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '', // Plus de valeur en dur ici
  );

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // La vérification lèvera une exception claire si les variables ne sont pas fournies au build
      if (supabaseUrl.trim().isEmpty || anonKey.trim().isEmpty) {
        throw Exception(
          'Supabase URL ou Anon Key manquant ! Assurez-vous de compiler avec '
          '--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...',
        );
      }

      debugPrint('🔄 SupabaseConfig: Initialisation...');
      
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
