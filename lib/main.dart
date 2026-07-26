import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/auth/supabase_auth_manager.dart';
import 'package:thix_id/l10n/locale_controller.dart';
import 'package:thix_id/app_router.dart';
import 'package:thix_id/services/profile_service.dart';
import 'package:thix_id/supabase/supabase_config.dart';
import 'package:thix_id/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try { await SupabaseConfig.initialize().timeout(const Duration(seconds:5)); } catch(e){ debugPrint('Supabase: $e'); }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget { const MyApp({super.key}); @override ConsumerState<MyApp> createState() => _MyAppState(); }

class _MyAppState extends ConsumerState<MyApp> {
  late final AuthController _auth;
  late final LocaleController _locale;
  late final _router;

  @override
  void initState() {
    super.initState();
    _locale = LocaleController()..init();
    _auth = AuthController(auth: SupabaseAuthManager(profiles: ProfileService()));
    _auth.init(); // ne bloque pas
    _router = AppRouter.create(_auth, extraRefreshListenable: _locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'THIX ID CENTRAL',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      routerConfig: _router,
      locale: _locale.locale,
    );
  }
}
