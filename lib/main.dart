// lib/main.dart - FIX ECRAN BLANC - BUILD VERT #3801
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
import 'package:thix_id/services/user_service.dart';
import 'package:thix_id/supabase/supabase_config.dart';
import 'package:thix_id/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Supabase avec timeout - ne bloque jamais
  try {
    await SupabaseConfig.initialize().timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint('⚠️ Supabase init failed, continue: $e');
  }

  FlutterError.onError = (d) {
    if (kDebugMode) FlutterError.presentError(d);
    debugPrint('[THIX-ERROR] ${d.exceptionAsString()}');
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
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _locale = LocaleController()..init();
    final profiles = ProfileService();
    _auth = AuthController(auth: SupabaseAuthManager(profiles: profiles));
    
    // Auth en arrière-plan, ne bloque pas le first frame
    _auth.init().timeout(const Duration(seconds: 4)).whenComplete(() {
      if (mounted) setState(() => _ready = true);
    }).catchError((e) {
      debugPrint('Auth init error: $e');
      if (mounted) setState(() => _ready = true);
    });

    // Router créé IMMÉDIATEMENT - même si auth pas prêt
    _router = AppRouter.create(_auth, extraRefreshListenable: _locale);

    // Fallback : si auth met trop longtemps, on affiche quand même
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_ready) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    // UN SEUL MaterialApp.router - jamais 2, c'est ça qui faisait l'écran gris
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
      // Loader Flutter natif pendant que router charge
      builder: (context, child) {
        if (!_ready) {
          return Scaffold(
            backgroundColor: const Color(0xFF0B3D91),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('icons/Icon-192.png', width: 120, errorBuilder: (_,__,___) => const Icon(Icons.verified_user, color: Colors.white, size: 48)),
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(color: Color(0xFFF7C948), strokeWidth: 2),
                  const SizedBox(height: 12),
                  const Text('THIX ID CENTRAL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  const Text('By Sonathix Group', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1)),
                ],
              ),
            ),
          );
        }
        return child!;
      },
    );
  }
}
