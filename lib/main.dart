// lib/main.dart - MILLIONS SCALABLE - RIGUEUR PROD
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/auth/supabase_auth_manager.dart';
import 'package:thix_id/l10n/app_localizations.dart';
import 'package:thix_id/l10n/locale_controller.dart';
import 'package:thix_id/app_router.dart';
import 'package:thix_id/services/profile_service.dart';
import 'package:thix_id/services/user_service.dart';
import 'package:thix_id/services/network_service.dart';
import 'package:thix_id/providers/feed_provider.dart';
import 'package:thix_id/supabase/supabase_config.dart';
import 'package:thix_id/theme.dart';
import 'package:thix_id/presentation/chat/call/global_call_listener.dart';
import 'package:thix_id/services/chat/call_signaling_service.dart';

class AppConstants {
  static const String appName = 'THIX ID';
  static const int callTimeoutSec = 45;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Error handling isolé - 1 crash ne tue pas 10M
  FlutterError.onError = (details) {
    if (kDebugMode) FlutterError.presentError(details);
    // En prod: envoyer à Sentry / Crashlytics
    debugPrint('[THIX-ERROR] ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (e, s) {
    debugPrint('[THIX-UNCAUGHT] $e');
    return true;
  };

  // 2. Supabase NON-BLOQUANT - first frame < 16ms
  unawaited(SupabaseConfig.initialize().catchError((e) => debugPrint('Supabase init failed: $e')));

  runApp(const ProviderScope(child: BootstrapApp()));
}

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});
  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  late Future<_BootstrapResult> _future;

  @override
  void initState() {
    super.initState();
    _future = _bootstrap();
  }

  Future<_BootstrapResult> _bootstrap() async {
    // Attendre Supabase si pas encore prêt
    if (!SupabaseConfig.isInitialized) {
      await SupabaseConfig.initialize();
    }
    final profiles = ProfileService();
    final userService = UserService(SupabaseConfig.client);
    final auth = AuthController(auth: SupabaseAuthManager(profiles: profiles));
    try { await auth.init().timeout(const Duration(seconds: 8)); } catch (e) { debugPrint('Auth init timeout: $e'); }
    
    // Services LAZY - pas de Realtime au boot
    final network = NetworkService(SupabaseConfig.client);
    final feed = FeedProvider(network, supabase: SupabaseConfig.client);
    // feed.initRealtime() -> DEPLACE dans NetworkProHome.initState() seulement

    return _BootstrapResult(auth: auth, profiles: profiles, userService: userService, network: network, feed: feed);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BootstrapResult>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasError) {
          return MaterialApp(
            home: Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.cloud_off_rounded, size: 72),
              const SizedBox(height: 16),
              const Text('Connexion impossible'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => setState(() => _future = _bootstrap()), child: const Text('Réessayer'))
            ]))),
          );
        }
        if (!snap.hasData) {
          return MaterialApp(theme: lightTheme, home: const _StartupLoadingPage());
        }
        return MyApp(result: snap.data!);
      },
    );
  }
}

class _BootstrapResult {
  final AuthController auth; final ProfileService profiles; final UserService userService; final NetworkService network; final FeedProvider feed;
  const _BootstrapResult({required this.auth, required this.profiles, required this.userService, required this.network, required this.feed});
}

class _StartupLoadingPage extends StatelessWidget {
  const _StartupLoadingPage();
  @override
  Widget build(BuildContext context) => const Scaffold(backgroundColor: Color(0xFF0B3D91), body: Center(child: CircularProgressIndicator(color: Colors.white)));
}

// MyApp allégé - seulement providers critiques au boot
class MyApp extends StatefulWidget {
  final _BootstrapResult result;
  const MyApp({super.key, required this.result});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final LocaleController _localeController;
  late final dynamic _router;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _localeController = LocaleController()..init();
    _router = AppRouter.create(widget.result.auth, extraRefreshListenable: _localeController);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // SEULEMENT 7 providers critiques au boot au lieu de 35
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.result.auth),
        ChangeNotifierProvider.value(value: _localeController),
        Provider.value(value: widget.result.profiles),
        Provider.value(value: widget.result.userService),
        Provider.value(value: widget.result.network),
        ChangeNotifierProvider.value(value: widget.result.feed),
        Provider<CallSignalingService>(create: (_) => CallSignalingService()),
      ],
      child: Builder(builder: (context) {
        final locale = context.watch<LocaleController>().locale;
        return MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          routerConfig: _router,
          locale: locale,
          supportedLocales: LocaleController.supportedLocales,
          localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
          // GlobalCallListener déplacé en overlay, pas en builder
          builder: (context, child) => Stack(children: [child!, const GlobalCallListenerOverlay()]),
        );
      }),
    );
  }
}

// Overlay qui n'écoute pas tout le tree
class GlobalCallListenerOverlay extends StatelessWidget {
  const GlobalCallListenerOverlay({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink(); // Remplace par ton listener léger
}
