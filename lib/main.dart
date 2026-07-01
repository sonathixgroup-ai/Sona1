import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/auth/supabase_auth_manager.dart';
import 'package:thix_id/l10n/app_localizations.dart';
import 'package:thix_id/l10n/locale_controller.dart';
import 'package:thix_id/nav.dart';
// 🔽 Remplacé FirestoreUserService par notre nouveau service Supabase
import 'package:thix_id/services/supabase_user_service.dart';
import 'package:thix_id/services/network_service.dart';
import 'package:thix_id/providers/feed_provider.dart';
import 'package:thix_id/supabase/supabase_config.dart';
import 'package:thix_id/theme.dart';

/// Point d’entrée principal – sans Firestore, uniquement Supabase
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Gestion des erreurs (inchangée)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
    if (details.stack != null) debugPrint(details.stack.toString());
  };
  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint('ErrorWidget: ${details.exceptionAsString()}');
    if (details.stack != null) debugPrint(details.stack.toString());
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Une erreur est survenue.\n\n${kDebugMode ? details.exceptionAsString() : ''}',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  };

  runApp(const ProviderScope(child: BootstrapApp()));
}

// ─── Bootstrap ──────────────────────────────────────────────────────────────

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  late final Future<_BootstrapResult> _future = _bootstrap();

  Future<_BootstrapResult> _bootstrap() async {
    try {
      await SupabaseConfig.initialize();
    } catch (e, st) {
      debugPrint('Bootstrap: SupabaseConfig.initialize failed err=$e');
      debugPrint(st.toString());
    }

    // 🔽 Service utilisateur basé sur Supabase (remplace Firestore)
    final supabaseUserService = SupabaseUserService(SupabaseConfig.client);

    // On garde ProfileService (pour l’authentification) mais on lui passe
    // le service Supabase pour qu’il puisse lire/écrire les profils.
    // Vous pouvez aussi supprimer ProfileService et utiliser directement
    // SupabaseUserService dans AuthController si vous modifiez celui-ci.
    final profiles = ProfileService(supabaseUserService);

    // AuthController utilise toujours SupabaseAuthManager
    final auth = AuthController(
      auth: SupabaseAuthManager(profiles: profiles),
    );

    try {
      await auth.init();
    } catch (e, st) {
      debugPrint('Bootstrap: auth.init failed err=$e');
      debugPrint(st.toString());
    }

    final network = NetworkService(SupabaseConfig.client);
    final feed = FeedProvider(network, supabase: SupabaseConfig.client);
    feed.initRealtime();

    return _BootstrapResult(
      auth: auth,
      profiles: profiles,
      supabaseUserService: supabaseUserService, // nouveau service
      network: network,
      feed: feed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BootstrapResult>(
      future: _future,
      builder: (context, snap) {
        final child = snap.hasData
            ? MyApp(
                auth: snap.data!.auth,
                profiles: snap.data!.profiles,
                supabaseUserService: snap.data!.supabaseUserService,
                network: snap.data!.network,
                feed: snap.data!.feed,
              )
            : MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: lightTheme,
                darkTheme: darkTheme,
                themeMode: ThemeMode.system,
                home: const _StartupLoadingPage(),
              );

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: KeyedSubtree(
            key: ValueKey(snap.hasData),
            child: child,
          ),
        );
      },
    );
  }
}

// ─── Résultat du bootstrap ──────────────────────────────────────────────────

class _BootstrapResult {
  final AuthController auth;
  final ProfileService profiles;
  final SupabaseUserService supabaseUserService; // 🔥 nouveau type
  final NetworkService network;
  final FeedProvider feed;

  const _BootstrapResult({
    required this.auth,
    required this.profiles,
    required this.supabaseUserService,
    required this.network,
    required this.feed,
  });
}

// ─── Écran de chargement (inchangé) ───────────────────────────────────────

class _StartupLoadingPage extends StatelessWidget {
  const _StartupLoadingPage();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.verified_user_rounded, color: cs.primary),
              ),
              const SizedBox(height: 14),
              Text('THIX ID', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                'Chargement sécurisé…',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: 140,
                child: LinearProgressIndicator(
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Application principale ─────────────────────────────────────────────────

class MyApp extends StatefulWidget {
  final AuthController auth;
  final ProfileService profiles;
  final SupabaseUserService supabaseUserService; // 🔥 remplace FirestoreUserService
  final NetworkService network;
  final FeedProvider feed;

  const MyApp({
    super.key,
    required this.auth,
    required this.profiles,
    required this.supabaseUserService,
    required this.network,
    required this.feed,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final LocaleController _localeController;
  late final _router;

  @override
  void initState() {
    super.initState();
    _localeController = LocaleController()..init();
    _router = AppRouter.create(widget.auth, extraRefreshListenable: _localeController);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.auth),
        ChangeNotifierProvider.value(value: _localeController),
        Provider<ProfileService>.value(value: widget.profiles),
        // 🔽 Fournir le nouveau service Supabase (à la place de FirestoreUserService)
        Provider<SupabaseUserService>.value(value: widget.supabaseUserService),
        Provider<NetworkService>.value(value: widget.network),
        ChangeNotifierProvider.value(value: widget.feed),
      ],
      child: Builder(
        builder: (context) {
          final locale = context.watch<LocaleController>().locale;
          return MaterialApp.router(
            title: 'THIX ID',
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: ThemeMode.system,
            routerConfig: _router,
            locale: locale,
            supportedLocales: LocaleController.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) => child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
