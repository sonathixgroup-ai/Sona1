// lib/main.dart - SCALABLE 10M - SANS PROVIDER - BUILD VERT
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
  FlutterError.onError = (d) { if (kDebugMode) FlutterError.presentError(d); };
  await SupabaseConfig.initialize();
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
  void initState() { super.initState(); _future = _bootstrap(); }
  Future<_BootstrapResult> _bootstrap() async {
    final profiles = ProfileService();
    final userService = UserService(SupabaseConfig.client);
    final auth = AuthController(auth: SupabaseAuthManager(profiles: profiles));
    await auth.init();
    return _BootstrapResult(auth: auth, profiles: profiles, userService: userService);
  }
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BootstrapResult>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return MaterialApp(theme: lightTheme, home: const Scaffold(body: Center(child: CircularProgressIndicator())));
        }
        return MyApp(result: snap.data!);
      },
    );
  }
}

class _BootstrapResult {
  final AuthController auth; final ProfileService profiles; final UserService userService;
  const _BootstrapResult({required this.auth, required this.profiles, required this.userService});
}

class MyApp extends StatefulWidget {
  final _BootstrapResult result;
  const MyApp({super.key, required this.result});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final LocaleController _localeController;
  late final dynamic _router;
  @override
  void initState() {
    super.initState();
    _localeController = LocaleController()..init();
    _router = AppRouter.create(widget.result.auth, extraRefreshListenable: _localeController);
  }
  @override
  Widget build(BuildContext context) {
    // ZERO provider ici - seulement Riverpod ProviderScope au dessus
    // Tous les feature providers seront créés LAZY dans app_router.dart par route
    return MaterialApp.router(
      title: 'THIX ID',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      routerConfig: _router,
      locale: _localeController.locale,
      supportedLocales: LocaleController.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
