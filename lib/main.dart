import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/auth/supabase_auth_manager.dart';
import 'package:thix_id/l10n/app_localizations.dart';
import 'package:thix_id/l10n/locale_controller.dart';
import 'package:thix_id/nav.dart' show AppRoutes; // Pour AppRoutes
import 'package:thix_id/app_router.dart'; // ✅ IMPORT AJOUTÉ pour AppRouter
import 'package:thix_id/services/profile_service.dart';
import 'package:thix_id/services/user_service.dart';
import 'package:thix_id/services/network_service.dart';
import 'package:thix_id/services/news_service.dart';
import 'package:thix_id/providers/feed_provider.dart';
import 'package:thix_id/providers/news_provider.dart';
import 'package:thix_id/supabase/supabase_config.dart';
import 'package:thix_id/theme.dart';
import 'package:thix_id/presentation/chat/core/chat_bloc.dart';
import 'package:thix_id/presentation/chat/core/chat_repository.dart';
import 'package:thix_id/presentation/chat/tasks/task_notification.dart';
import 'package:thix_id/presentation/thix_market/cart/cart_provider.dart';
import 'package:thix_id/presentation/thix_market/providers/activity_provider.dart';
import 'package:thix_id/presentation/thix_market/providers/live_provider.dart';
import 'package:thix_id/presentation/thix_market/providers/market_provider.dart';
import 'package:thix_id/presentation/thix_market/providers/message_provider.dart';
import 'package:thix_id/presentation/thix_market/providers/product_provider.dart';
import 'package:thix_id/presentation/thix_market/providers/search_provider.dart';
import 'package:thix_id/presentation/thix_market/providers/sell_provider.dart';
import 'package:thix_id/presentation/thix_market/providers/settings_provider.dart';
import 'package:thix_id/presentation/thix_market/providers/shop_provider.dart';
import 'package:thix_id/presentation/thix_market/providers/support_provider.dart';
import 'package:thix_id/providers/event_provider.dart';
import 'package:thix_id/services/event_service.dart';

// ============================================================
// ✅ IMPORTS EDUCATION
// ============================================================
import 'package:thix_id/presentation/education/providers/education_provider.dart';
import 'package:thix_id/presentation/education/providers/progress_provider.dart';
import 'package:thix_id/presentation/education/providers/certificate_provider.dart';
import 'package:thix_id/presentation/education/providers/forum_provider.dart';
import 'package:thix_id/presentation/education/providers/recommendation_provider.dart';
import 'package:thix_id/presentation/education/services/education_service.dart';

// ============================================================
// ✅ IMPORTS MODERATEUR
// ============================================================
import 'package:thix_id/providers/auth_provider.dart';
import 'package:thix_id/providers/moderator_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// MAIN
// ═══════════════════════════════════════════════════════════════════════

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    await SupabaseConfig.initialize();

    final profiles = ProfileService();
    final userService = UserService(SupabaseConfig.client);

    final auth = AuthController(
      auth: SupabaseAuthManager(profiles: profiles),
    );
    await auth.init();

    final network = NetworkService(SupabaseConfig.client);
    final feed = FeedProvider(network, supabase: SupabaseConfig.client);
    feed.initRealtime();

    await TaskNotification.init();

    final chatBloc = ChatBloc(ChatRepository());
    final eventService = EventService(SupabaseConfig.client);

    return _BootstrapResult(
      auth: auth,
      profiles: profiles,
      userService: userService,
      network: network,
      feed: feed,
      chatBloc: chatBloc,
      eventService: eventService,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BootstrapResult>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: ThemeMode.system,
            home: Scaffold(
              backgroundColor: const Color(0xFFF7FAFF),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEFF5FF),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.cloud_off_rounded,
                          size: 38,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Connexion impossible',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF10192E)),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Impossible de se connecter à Supabase.\nVérifiez votre connexion internet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Color(0xFF7386A8)),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          runApp(const ProviderScope(child: BootstrapApp()));
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Réessayer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF123B7A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                      if (kDebugMode) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Erreur : ${snap.error}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.red,
                            fontFamily: 'monospace',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final child = snap.hasData
            ? MyApp(
                auth: snap.data!.auth,
                profiles: snap.data!.profiles,
                userService: snap.data!.userService,
                network: snap.data!.network,
                feed: snap.data!.feed,
                chatBloc: snap.data!.chatBloc,
                eventService: snap.data!.eventService,
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

class _BootstrapResult {
  final AuthController auth;
  final ProfileService profiles;
  final UserService userService;
  final NetworkService network;
  final FeedProvider feed;
  final ChatBloc chatBloc;
  final EventService eventService;

  const _BootstrapResult({
    required this.auth,
    required this.profiles,
    required this.userService,
    required this.network,
    required this.feed,
    required this.chatBloc,
    required this.eventService,
  });
}

// ─── Écran de chargement — Premium Institutionnel Bleu/Blanc ────────────

class _StartupLoadingPage extends StatefulWidget {
  const _StartupLoadingPage();

  @override
  State<_StartupLoadingPage> createState() => _StartupLoadingPageState();
}

class _StartupLoadingPageState extends State<_StartupLoadingPage> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color navy = Color(0xFF123B7A);
  static const Color primaryBlue = Color(0xFF2D6CDF);
  static const Color softBlue = Color(0xFFEFF5FF);
  static const Color background = Color(0xFFF7FAFF);
  static const Color mutedText = Color(0xFF7386A8);
  static const Color darkText = Color(0xFF10192E);
  static const Color gold = Color(0xFFE3B23C);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          // ── Formes incurvées d'arrière-plan, lumineuses ──
          Positioned(
            top: -120,
            right: -90,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [primaryBlue.withOpacity(0.14), Colors.transparent]),
              ),
            ),
          ),
          Positioned(
            bottom: -140,
            left: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [navy.withOpacity(0.10), Colors.transparent]),
              ),
            ),
          ),

          // ── Contenu central ──
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final scale = 1.0 + (_pulseController.value * 0.06);
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Container(
                      height: 84,
                      width: 84,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [navyDeep, navy, primaryBlue],
                        ),
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(color: primaryBlue.withOpacity(0.35), blurRadius: 26, offset: const Offset(0, 12)),
                        ],
                      ),
                      child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 38),
                    ),
                  ),
                  const SizedBox(height: 22),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [navyDeep, primaryBlue],
                    ).createShader(bounds),
                    child: const Text(
                      'THIX ID',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Chargement sécurisé…',
                    style: TextStyle(fontSize: 13, color: mutedText, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: 160,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 6,
                        backgroundColor: softBlue,
                        valueColor: const AlwaysStoppedAnimation<Color>(primaryBlue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: softBlue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.lock_rounded, size: 12, color: navy),
                        SizedBox(width: 5),
                        Text(
                          'Connexion chiffrée',
                          style: TextStyle(fontSize: 10.5, color: navy, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Application principale ─────────────────────────────────────────────

class MyApp extends StatefulWidget {
  final AuthController auth;
  final ProfileService profiles;
  final UserService userService;
  final NetworkService network;
  final FeedProvider feed;
  final ChatBloc chatBloc;
  final EventService eventService;

  const MyApp({
    super.key,
    required this.auth,
    required this.profiles,
    required this.userService,
    required this.network,
    required this.feed,
    required this.chatBloc,
    required this.eventService,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

// ✅ WidgetsBindingObserver ajouté pour détecter le retour au premier plan
// et reconnecter Supabase Realtime + rafraîchir la session (fixe le bug
// où l'app "gèle" après un long moment en arrière-plan).
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final LocaleController _localeController;
  late final _router;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _localeController = LocaleController()..init();
    _router = AppRouter.create(widget.auth, extraRefreshListenable: _localeController);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.chatBloc.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _handleAppResumed();
    }
  }

  // ✅ Correctif : reconnecte le WebSocket Realtime de Supabase et rafraîchit
  // la session au retour au premier plan. Sans cela, iOS/Android suspendent
  // la connexion réseau en arrière-plan prolongé et l'app reste "figée"
  // (aucune donnée ne se recharge) même quand on revient dessus.
  Future<void> _handleAppResumed() async {
    try {
      final client = SupabaseConfig.client;

      // Relance le canal Realtime s'il a été coupé par l'OS
      client.realtime.connect();

      // Rafraîchit la session pour éviter un token expiré silencieusement
      await client.auth.refreshSession();

      // Recharge le fil d'actualité en temps réel
      widget.feed.initRealtime();
    } catch (e) {
      debugPrint('⚠️ Erreur lors de la reprise après mise en arrière-plan: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.auth),
        ChangeNotifierProvider.value(value: _localeController),
        Provider<ProfileService>.value(value: widget.profiles),
        Provider<UserService>.value(value: widget.userService),
        Provider<NetworkService>.value(value: widget.network),
        ChangeNotifierProvider.value(value: widget.feed),
        BlocProvider<ChatBloc>.value(value: widget.chatBloc),

        // 🆕 PROVIDER POUR LES ÉVÉNEMENTS
        ChangeNotifierProvider<EventProvider>(
          create: (_) => EventProvider(widget.eventService),
        ),
        // ✅ THIX INFO – correction
        ChangeNotifierProvider<NewsProvider>(
          create: (_) => NewsProvider(NewsService(SupabaseConfig.client)),
        ),
        // 🆕 THIX MARKET
        ChangeNotifierProvider<MarketProvider>(create: (_) => MarketProvider()),
        ChangeNotifierProvider<ProductProvider>(create: (_) => ProductProvider()),
        ChangeNotifierProvider<SearchProvider>(create: (_) => SearchProvider()),
        ChangeNotifierProvider<ShopProvider>(create: (_) => ShopProvider()),
        ChangeNotifierProvider<MessageProvider>(create: (_) => MessageProvider()),
        ChangeNotifierProvider<LiveProvider>(create: (_) => LiveProvider()),
        ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
        ChangeNotifierProvider<ActivityProvider>(create: (_) => ActivityProvider()),
        ChangeNotifierProvider<SellProvider>(create: (_) => SellProvider()),
        ChangeNotifierProvider<SupportProvider>(create: (_) => SupportProvider()),
        ChangeNotifierProvider<SettingsProvider>(create: (_) => SettingsProvider()),

        // ============================================================
        // ✅ NOUVEAUX PROVIDERS EDUCATION
        // ============================================================
        ChangeNotifierProvider<EducationProvider>(
          create: (_) => EducationProvider(EducationService(SupabaseConfig.client)),
        ),
        ChangeNotifierProvider<ProgressProvider>(
          create: (_) => ProgressProvider(EducationService(SupabaseConfig.client)),
        ),
        ChangeNotifierProvider<CertificateProvider>(
          create: (_) => CertificateProvider(EducationService(SupabaseConfig.client)),
        ),
        ChangeNotifierProvider<ForumProvider>(
          create: (_) => ForumProvider(EducationService(SupabaseConfig.client)),
        ),
        ChangeNotifierProvider<RecommendationProvider>(
          create: (_) => RecommendationProvider(EducationService(SupabaseConfig.client)),
        ),

        // ============================================================
        // ✅ NOUVEAUX PROVIDERS MODERATEUR
        // ============================================================
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(SupabaseConfig.client),
        ),
        ChangeNotifierProvider<ModeratorProvider>(
          create: (_) => ModeratorProvider(widget.eventService),
        ),
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
            routerConfig: _router, // AppRouter inclut déjà les routes Education et Moderator
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
