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
import 'package:thix_id/nav.dart';
import 'package:thix_id/services/profile_service.dart';
import 'package:thix_id/services/user_service.dart';
import 'package:thix_id/services/network_service.dart';
import 'package:thix_id/providers/feed_provider.dart';
import 'package:thix_id/supabase/supabase_config.dart';
import 'package:thix_id/theme.dart';
import 'package:thix_id/presentation/chat/core/chat_bloc.dart';
import 'package:thix_id/presentation/chat/core/chat_repository.dart';
import 'package:thix_id/presentation/chat/core/chat_events.dart';
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

// ═══════════════════════════════════════════════════════════════════════
// 🆕 IMPORTS POUR LES ÉVÉNEMENTS
// ═══════════════════════════════════════════════════════════════════════
import 'package:thix_id/providers/event_provider.dart';
import 'package:thix_id/services/event_service.dart';

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
    try {
      await SupabaseConfig.initialize();
    } catch (e, st) {
      debugPrint('Bootstrap: SupabaseConfig.initialize failed err=$e');
      debugPrint(st.toString());
    }

    // 🔥 Services Supabase
    final profiles = ProfileService();
    final userService = UserService(SupabaseConfig.client);

    // AuthController utilise SupabaseAuthManager (qui a besoin de ProfileService)
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

    // 🔔 Notifications de tâches (THIX Chat)
    try {
      await TaskNotification.init();
    } catch (e, st) {
      debugPrint('Bootstrap: TaskNotification.init failed err=$e');
      debugPrint(st.toString());
    }

    // 💬 THIX Chat — Bloc global, disponible dans toute l'app
    final chatBloc = ChatBloc(ChatRepository());
    chatBloc.add(LoadConversations());

    // 🆕 Service des événements (utilise le client Supabase déjà initialisé)
    final eventService = EventService(SupabaseConfig.client);

    return _BootstrapResult(
      auth: auth,
      profiles: profiles,
      userService: userService,
      network: network,
      feed: feed,
      chatBloc: chatBloc,
      eventService: eventService,   // 👈 on le passe
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
                userService: snap.data!.userService,
                network: snap.data!.network,
                feed: snap.data!.feed,
                chatBloc: snap.data!.chatBloc,
                eventService: snap.data!.eventService,   // 👈 on le transmet
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
  final EventService eventService;   // 🆕

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

// ─── Écran de chargement ───────────────────────────────────────────────

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

// ─── Application principale ─────────────────────────────────────────────

class MyApp extends StatefulWidget {
  final AuthController auth;
  final ProfileService profiles;
  final UserService userService;
  final NetworkService network;
  final FeedProvider feed;
  final ChatBloc chatBloc;
  final EventService eventService;   // 🆕

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
  void dispose() {
    widget.chatBloc.close();
    super.dispose();
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
        // On crée l'EventProvider en lui passant l'EventService déjà instancié
        ChangeNotifierProvider(
          create: (_) => EventProvider(widget.eventService),
        ),
        ChangeNotifierProvider(create: (_) => MarketProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => ShopProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
        ChangeNotifierProvider(create: (_) => LiveProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
        ChangeNotifierProvider(create: (_) => SellProvider()),
        ChangeNotifierProvider(create: (_) => SupportProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
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
