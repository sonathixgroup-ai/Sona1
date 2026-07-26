import 'dart:async';
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
  // 🔑 CORRECTIF : runZonedGuarded attrape TOUTES les erreurs asynchrones
  // non capturées (ex: dans redirect de GoRouter, dans un Future oublié,
  // dans un listener déclenché par notifyListeners()...). Sans ça, une
  // telle erreur ne remonte nulle part et l'app reste figée sur l'écran
  // gris par défaut du moteur Flutter, sans aucun message.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 🔑 CORRECTIF : si un widget plante pendant son build (erreur rouge
    // Flutter classique), on affiche un écran bleu visible et exploitable
    // au lieu du "grey screen of death" par défaut en profil release/web.
    ErrorWidget.builder = (FlutterErrorDetails details) {
      debugPrint('ErrorWidget: ${details.exceptionAsString()}');
      return Material(
        color: const Color(0xFF0B3D91),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Une erreur est survenue :\n${details.exceptionAsString()}',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    };

    try {
      await SupabaseConfig.initialize().timeout(const Duration(seconds: 6));
    } catch (e) {
      debugPrint('Supabase init: $e');
    }

    FlutterError.onError = (d) {
      debugPrint('FlutterError: ${d.exceptionAsString()}');
      if (kDebugMode) FlutterError.presentError(d);
    };

    // 🔑 CORRECTIF : capture aussi les erreurs qui remontent au niveau
    // plateforme (web notamment), en plus de FlutterError.onError.
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('PlatformDispatcher error: $error\n$stack');
      return true; // erreur gérée, ne fait pas planter le moteur
    };

    runApp(const ProviderScope(child: MyApp()));
  }, (error, stack) {
    debugPrint('Uncaught zone error: $error\n$stack');
  });
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});
  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final AuthController _auth;
  late final LocaleController _locale;
  dynamic _router;
  String? _error;

  @override
  void initState() {
    super.initState();
    _locale = LocaleController()..init();
    _auth = AuthController(auth: SupabaseAuthManager(profiles: ProfileService()));

    // Auth en background, ne bloque JAMAIS le first frame
    _auth.init().catchError((e) {
      debugPrint('Auth error: $e');
      // 🔑 CORRECTIF : on ne bloque PAS l'app sur une erreur d'auth async.
      // L'ancien code faisait setState(() => _error = e.toString()), ce
      // qui affichait un écran d'erreur permanent même si l'app avait déjà
      // démarré normalement (ex: juste un souci réseau transitoire lors de
      // la restauration de session). On journalise seulement.
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
    if (_error != null || _router == null) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF0B3D91),
          body: Center(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Erreur: ${_error ?? "Initialisation du routeur impossible"}', style: const TextStyle(color: Colors.white)),
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
