import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/auth/supabase_auth_manager.dart';
import 'package:thix_id/l10n/app_localizations.dart';
import 'package:thix_id/l10n/locale_controller.dart';
import 'package:thix_id/app_router.dart';
import 'package:thix_id/services/profile_service.dart';
import 'package:thix_id/supabase/supabase_config.dart';
import 'package:thix_id/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await SupabaseConfig.initialize().timeout(const Duration(seconds: 6));
  } catch (e) {
    debugPrint('Supabase init: $e');
  }
  FlutterError.onError = (d) {
    debugPrint('FlutterError: ${d.exceptionAsString()}');
    if (kDebugMode) FlutterError.presentError(d);
  };
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});
  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final AuthController _auth;
  late final LocaleController _locale;
  late final dynamic _router;
  String? _error;

  @override
  void initState() {
    super.initState();
    _locale = LocaleController()..init();
    _auth = AuthController(auth: SupabaseAuthManager(profiles: ProfileService()));
    
    // Auth en background, ne bloque JAMAIS le first frame
    _auth.init().catchError((e) {
      debugPrint('Auth error: $e');
      setState(() => _error = e.toString());
    });

    try {
      _router = AppRouter.create(_auth, extraRefreshListenable: _locale);
    } catch (e, st) {
      debugPrint('Router create failed: $e\n$st');
      _error = e.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF0B3D91),
          body: Center(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Erreur: $_error', style: const TextStyle(color: Colors.white)),
          )),
        ),
      );
    }

    return MaterialApp.router(
      title: 'THIX ID CENTRAL',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: _router,
      locale: _locale.locale,
      supportedLocales: LocaleController.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // Si erreur de route, on affiche au lieu d'écran gris
        if (child == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF0B3D91),
            body: Center(child: CircularProgressIndicator(color: Color(0xFFF7C948))),
          );
        }
        return child;
      },
    );
  }
}
