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
import 'package:thix_id/nav.dart' show AppRoutes;
import 'package:thix_id/app_router.dart';
import 'package:thix_id/services/profile_service.dart';
import 'package:thix_id/services/user_service.dart';
import 'package:thix_id/services/network_service.dart';
import 'package:thix_id/services/news_service.dart';
import 'package:thix_id/providers/feed_provider.dart';
import 'package:thix_id/providers/news_provider.dart';
import 'package:thix_id/supabase/supabase_config.dart';
import 'package:thix_id/theme.dart';

// ─── THIX MARKET ───
import 'package:thix_id/presentation/thix_market/delivery/delivery_provider.dart';
import 'package:thix_id/presentation/thix_market/cart/cart_provider.dart';
import 'package:thix_id/presentation/thix_market/providers/activity_provider.dart';
import 'package:thix_id/presentation/thix_market/providers/live_provider.dart';
import 'package:thix_id/presentation/thix_market/providers/market_provider.dart';
import 'package:thix_id/presentation/thix_market/providers/message_provider.dart';
import 'package:thix_id/presentation/thix_market/providers/product_provider.dart';
import 'package:thix_id/presentation/thix_market/providers/search_provider.dart';
import 'package:thix_id/presentation/thix_market/providers/shop_provider.dart';
import 'package:thix_id/presentation/thix_market/providers/support_provider.dart';
import 'package:thix_id/presentation/thix_market/providers/settings_provider.dart';
import 'package:thix_id/presentation/thix_market/providers/sell_provider.dart';
import 'package:thix_id/presentation/thix_market/checkout/checkout_provider.dart';

// ─── EDUCATION ───
import 'package:thix_id/presentation/education/providers/education_provider.dart';
import 'package:thix_id/presentation/education/providers/progress_provider.dart';
import 'package:thix_id/presentation/education/providers/certificate_provider.dart';
import 'package:thix_id/presentation/education/providers/forum_provider.dart';
import 'package:thix_id/presentation/education/providers/recommendation_provider.dart';
import 'package:thix_id/presentation/education/services/education_service.dart';

// ─── MODERATEUR ───
import 'package:thix_id/providers/auth_provider.dart';
import 'package:thix_id/providers/moderator_provider.dart';

// ─── THIX ÉVÉNEMENT ───
import 'package:thix_id/providers/event_provider.dart';
import 'package:thix_id/services/event_service.dart';

// ═══════════════════════════════════════════════════════════════════════
// THIX CHAT — Imports
// ═══════════════════════════════════════════════════════════════════════
import 'package:thix_id/services/chat/chat_service.dart';
import 'package:thix_id/services/chat/presence_service.dart';
import 'package:thix_id/services/chat/audio_service.dart';
import 'package:thix_id/services/chat/group_service.dart';
import 'package:thix_id/presentation/chat/escalation/providers/escalation_provider.dart';
import 'package:thix_id/presentation/chat/call/global_call_listener.dart';
import 'package:thix_id/services/chat/connection_service.dart';
// ─── CALL MODULE PROD ───
import 'package:thix_id/presentation/chat/call/providers/call_provider.dart';
import 'package:thix_id/services/chat/call_signaling_service.dart';


// ═══════════════════════════════════════════════════════════════════════
// THIX RESERVATION BUS — SaaS Providers
// ═══════════════════════════════════════════════════════════════════════
import 'package:thix_id/presentation/thix_reservation/bus/providers/bus_search_provider.dart';
import 'package:thix_id/presentation/thix_reservation/bus/providers/seat_selection_provider.dart';
import 'package:thix_id/presentation/thix_reservation/bus/providers/booking_provider.dart';
import 'package:thix_id/presentation/thix_reservation/bus/providers/agency_dashboard_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// STATIC CONST GLOBALES
// ═══════════════════════════════════
class AppConstants {
  static const String appName = 'THIX ID';
  static const String agoraAppIdKey = 'AGORA_APP_ID';
  static const int agoraTokenExpireSec = 3600;
  static const int callTimeoutSec = 45;
  static const String callChannelPrefix = 'thix_';
  static const String tableCallInvites = 'call_invites';
  static const String funcAgoraToken = 'agora-token';
}

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

  await SupabaseConfig.initialize();

  runApp(const ProviderScope(child: BootstrapApp()));
}

// ─── Bootstrap ──────────────────────────────────────────────────────────────
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

  void _retryBootstrap() {
    setState(() {
      _future = _bootstrap();
    });
  }

  Future<_BootstrapResult> _bootstrap() async {
    final profiles = ProfileService();
    final userService = UserService(SupabaseConfig.client);

    final auth = AuthController(auth: SupabaseAuthManager(profiles: profiles));

    try {
      await auth.init();
    } catch (e) {
      debugPrint("⚠️ Échec initialisation auth : $e");
    }

    final network = NetworkService(SupabaseConfig.client);
    final feed = FeedProvider(network, supabase: SupabaseConfig.client);

    try {
      feed.initRealtime();
    } catch (e) {
      debugPrint("⚠️ Échec Realtime : $e");
    }

    final eventService = EventService(SupabaseConfig.client);

    final chatService = ChatService(SupabaseConfig.client);
    final presenceService = PresenceService(SupabaseConfig.client);
    final audioService = AudioService(SupabaseConfig.client);
    final groupService = GroupService(SupabaseConfig.client);

    final callSignaling = CallSignalingService();

    return _BootstrapResult(
      auth: auth,
      profiles: profiles,
      userService: userService,
      network: network,
      feed: feed,
      eventService: eventService,
      chatService: chatService,
      presenceService: presenceService,
      audioService: audioService,
      groupService: groupService,
      callSignaling: callSignaling,
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
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_off_rounded, size: 72, color: Theme.of(context).colorScheme.error),
                      const SizedBox(height: 16),
                      Text('Connexion impossible', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      const Text('Vérifiez votre connexion internet.', textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _retryBootstrap, 
                        icon: const Icon(Icons.refresh), 
                        label: const Text('Réessayer')
                      ),
                      if (kDebugMode) ...[
                        const SizedBox(height: 16),
                        Text('Erreur : ${snap.error}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red, fontFamily: 'monospace'), textAlign: TextAlign.center),
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
                eventService: snap.data!.eventService,
                chatService: snap.data!.chatService,
                presenceService: snap.data!.presenceService,
                audioService: snap.data!.audioService,
                groupService: snap.data!.groupService,
                callSignaling: snap.data!.callSignaling,
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
          child: KeyedSubtree(key: ValueKey(snap.hasData), child: child),
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
  final EventService eventService;
  final ChatService chatService;
  final PresenceService presenceService;
  final AudioService audioService;
  final GroupService groupService;
  final CallSignalingService callSignaling;

  const _BootstrapResult({
    required this.auth,
    required this.profiles,
    required this.userService,
    required this.network,
    required this.feed,
    required this.eventService,
    required this.chatService,
    required this.presenceService,
    required this.audioService,
    required this.groupService,
    required this.callSignaling,
  });
}

class _StartupLoadingPage extends StatelessWidget {
  const _StartupLoadingPage();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: 56, width: 56, decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(18)), child: Icon(Icons.verified_user_rounded, color: cs.primary)),
            const SizedBox(height: 14),
            Text(AppConstants.appName, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text('Chargement sécurisé…', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 14),
            SizedBox(width: 140, child: LinearProgressIndicator(minHeight: 6, borderRadius: BorderRadius.circular(999))),
          ],
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  final AuthController auth;
  final ProfileService profiles;
  final UserService userService;
  final NetworkService network;
  final FeedProvider feed;
  final EventService eventService;
  final ChatService chatService;
  final PresenceService presenceService;
  final AudioService audioService;
  final GroupService groupService;
  final CallSignalingService callSignaling;

  const MyApp({
    super.key,
    required this.auth,
    required this.profiles,
    required this.userService,
    required this.network,
    required this.feed,
    required this.eventService,
    required this.chatService,
    required this.presenceService,
    required this.audioService,
    required this.groupService,
    required this.callSignaling,
  });

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
    _router = AppRouter.create(widget.auth, extraRefreshListenable: _localeController);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('L\'application sort de veille (resumed). Reconnexion du Realtime...');
      try {
        widget.feed.reconnectRealtime();
      } catch (e) {
        debugPrint('Erreur lors de la reconnexion Realtime : $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ─── AUTH ───
        ChangeNotifierProvider.value(value: widget.auth),
        ChangeNotifierProvider.value(value: _localeController),
        Provider<ProfileService>.value(value: widget.profiles),
        Provider<UserService>.value(value: widget.userService),
        Provider<NetworkService>.value(value: widget.network),
        Provider<CallSignalingService>.value(value: widget.callSignaling),
        ChangeNotifierProvider<CallProvider>(create: (_) => CallProvider()),
        ChangeNotifierProvider.value(value: widget.feed),
        ChangeNotifierProvider<EventProvider>(create: (_) => EventProvider(widget.eventService)),
        ChangeNotifierProvider<NewsProvider>(create: (_) => NewsProvider(NewsService(SupabaseConfig.client))),

        // ─── THIX MARKET ───
        ChangeNotifierProvider<MarketProvider>(create: (_) => MarketProvider()),
        ChangeNotifierProvider<ProductProvider>(create: (_) => ProductProvider()),
        ChangeNotifierProvider<SearchProvider>(create: (_) => SearchProvider()),
        ChangeNotifierProvider<ShopProvider>(create: (_) => ShopProvider()),
        ChangeNotifierProvider<MessageProvider>(create: (_) => MessageProvider()),
        ChangeNotifierProvider<LiveProvider>(create: (_) => LiveProvider()),
        ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
        ChangeNotifierProvider<CheckoutProvider>(create: (_) => CheckoutProvider()),
        ChangeNotifierProvider<ActivityProvider>(create: (_) => ActivityProvider()),
        ChangeNotifierProvider<SellProvider>(create: (_) => SellProvider()),
        ChangeNotifierProvider<SupportProvider>(create: (_) => SupportProvider()),
        ChangeNotifierProvider<SettingsProvider>(create: (_) => SettingsProvider()),
        ChangeNotifierProvider<DeliveryProvider>(create: (_) => DeliveryProvider()),

        // ─── EDUCATION ───
        ChangeNotifierProvider<EducationProvider>(create: (_) => EducationProvider(EducationService(SupabaseConfig.client))),
        ChangeNotifierProvider<ProgressProvider>(create: (_) => ProgressProvider(EducationService(SupabaseConfig.client))),
        ChangeNotifierProvider<CertificateProvider>(create: (_) => CertificateProvider(EducationService(SupabaseConfig.client))),
        ChangeNotifierProvider<ForumProvider>(create: (_) => ForumProvider(EducationService(SupabaseConfig.client))),
        ChangeNotifierProvider<RecommendationProvider>(create: (_) => RecommendationProvider(EducationService(SupabaseConfig.client))),

        // ─── MODERATEUR ───
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider(SupabaseConfig.client)),
        ChangeNotifierProvider<ModeratorProvider>(create: (_) => ModeratorProvider(widget.eventService)),

        // ─── THIX CHAT ───
        Provider<ChatService>.value(value: widget.chatService),
        Provider<PresenceService>.value(value: widget.presenceService),
        Provider<AudioService>.value(value: widget.audioService),
        Provider<GroupService>.value(value: widget.groupService),
        ChangeNotifierProvider<EscalationProvider>(create: (_) => EscalationProvider()),
         ChangeNotifierProvider<ChatSettingsProvider>(create: (_) => ChatSettingsProvider()),
        // ✅ PROVIDER DE CONNEXION (ajout direct ici, sans MultiProvider imbriqué)
        ChangeNotifierProvider<ConnectionService>(create: (_) => ConnectionService()),

        // ─── THIX RESERVATION BUS ───
        ChangeNotifierProvider<BusSearchProvider>(create: (_) => BusSearchProvider()),
        ChangeNotifierProvider<SeatSelectionProvider>(create: (_) => SeatSelectionProvider()),
        ChangeNotifierProvider<BookingProvider>(create: (_) => BookingProvider()),
        ChangeNotifierProvider<AgencyDashboardProvider>(create: (_) => AgencyDashboardProvider()),
      ],
      child: Builder(
        builder: (context) {
          final locale = context.watch<LocaleController>().locale;
          return MaterialApp.router(
            title: AppConstants.appName,
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
            builder: (context, child) {
              return GlobalCallListener(child: child ?? const SizedBox.shrink());
            },
          );
        },
      ),
    );
  }
}
