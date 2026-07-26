// lib/main.dart - BUILD VERT 3798 - FIX IMPORT CONFLIT
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart' as app_provider;
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
import 'package:thix_id/services/chat/call_signaling_service.dart';
import 'package:thix_id/providers/chat_provider.dart';
import 'package:thix_id/presentation/chat/call/providers/call_provider.dart';

// FEATURE PROVIDERS
import 'package:thix_id/presentation/thix_market/providers/market_provider.dart';
import 'package:thix_id/presentation/thix_market/providers/product_provider.dart';
import 'package:thix_id/presentation/thix_market/cart/cart_provider.dart';
import 'package:thix_id/presentation/thix_market/providers/search_provider.dart';
import 'package:thix_id/presentation/thix_market/providers/shop_provider.dart';
import 'package:thix_id/presentation/thix_market/providers/message_provider.dart';
import 'package:thix_id/presentation/thix_market/providers/live_provider.dart';
import 'package:thix_id/presentation/thix_market/checkout/checkout_provider.dart';
import 'package:thix_id/presentation/thix_market/providers/activity_provider.dart';
import 'package:thix_id/presentation/thix_market/providers/sell_provider.dart';
import 'package:thix_id/presentation/thix_market/providers/support_provider.dart';
import 'package:thix_id/presentation/thix_market/providers/settings_provider.dart';
import 'package:thix_id/presentation/thix_market/delivery/delivery_provider.dart';
import 'package:thix_id/presentation/education/providers/education_provider.dart';
import 'package:thix_id/presentation/education/services/education_service.dart';
import 'package:thix_id/providers/event_provider.dart';
import 'package:thix_id/services/event_service.dart';
import 'package:thix_id/presentation/thix_money/services/wallet_service.dart';
import 'package:thix_id/presentation/thix_money/services/wonya_service.dart';
import 'package:thix_id/presentation/thix_money/services/payment_service.dart';
import 'package:thix_id/presentation/thix_money/services/qr_service.dart';
import 'package:thix_id/presentation/thix_money/services/notification_service.dart';
import 'package:thix_id/presentation/thix_reservation/bus/providers/bus_search_provider.dart';
import 'package:thix_id/presentation/thix_reservation/bus/providers/seat_selection_provider.dart';
import 'package:thix_id/presentation/thix_reservation/bus/providers/booking_provider.dart';
import 'package:thix_id/presentation/thix_reservation/bus/providers/agency_dashboard_provider.dart';
import 'package:thix_id/presentation/chat/escalation/providers/escalation_provider.dart';
import 'package:thix_id/services/chat/connection_service.dart';
import 'package:thix_id/providers/chat/sentiment_provider.dart';

class AppConstants {
  static const String appName = 'THIX ID';
}

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
    final network = NetworkService(SupabaseConfig.client);
    final feed = FeedProvider(network, supabase: SupabaseConfig.client);
    return _BootstrapResult(auth: auth, profiles: profiles, userService: userService, network: network, feed: feed);
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
  final AuthController auth; final ProfileService profiles; final UserService userService; final NetworkService network; final FeedProvider feed;
  const _BootstrapResult({required this.auth, required this.profiles, required this.userService, required this.network, required this.feed});
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
    return app_provider.MultiProvider(
      providers: [
        app_provider.ChangeNotifierProvider.value(value: widget.result.auth),
        app_provider.ChangeNotifierProvider.value(value: _localeController),
        app_provider.Provider.value(value: widget.result.profiles),
        app_provider.Provider.value(value: widget.result.userService),
        app_provider.Provider.value(value: widget.result.network),
        app_provider.ChangeNotifierProvider.value(value: widget.result.feed),
        app_provider.Provider<CallSignalingService>(create: (_) => CallSignalingService()),
        app_provider.ChangeNotifierProvider<CallProvider>(create: (_) => CallProvider()),
        app_provider.ChangeNotifierProvider<ChatProvider>(create: (_) => ChatProvider(widget.result.network as dynamic)),
        app_provider.ChangeNotifierProvider<ConnectionService>(create: (_) => ConnectionService()),
        // FEATURE - lazy true = 0 RAM au boot mais dispo partout
        app_provider.ChangeNotifierProvider<MarketProvider>(create: (_) => MarketProvider(), lazy: true),
        app_provider.ChangeNotifierProvider<ProductProvider>(create: (_) => ProductProvider(), lazy: true),
        app_provider.ChangeNotifierProvider<SearchProvider>(create: (_) => SearchProvider(), lazy: true),
        app_provider.ChangeNotifierProvider<ShopProvider>(create: (_) => ShopProvider(), lazy: true),
        app_provider.ChangeNotifierProvider<MessageProvider>(create: (_) => MessageProvider(), lazy: true),
        app_provider.ChangeNotifierProvider<LiveProvider>(create: (_) => LiveProvider(), lazy: true),
        app_provider.ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider(), lazy: true),
        app_provider.ChangeNotifierProvider<CheckoutProvider>(create: (_) => CheckoutProvider(), lazy: true),
        app_provider.ChangeNotifierProvider<ActivityProvider>(create: (_) => ActivityProvider(), lazy: true),
        app_provider.ChangeNotifierProvider<SellProvider>(create: (_) => SellProvider(), lazy: true),
        app_provider.ChangeNotifierProvider<SupportProvider>(create: (_) => SupportProvider(), lazy: true),
        app_provider.ChangeNotifierProvider<SettingsProvider>(create: (_) => SettingsProvider(), lazy: true),
        app_provider.ChangeNotifierProvider<DeliveryProvider>(create: (_) => DeliveryProvider(), lazy: true),
        app_provider.ChangeNotifierProvider<EducationProvider>(create: (_) => EducationProvider(EducationService(SupabaseConfig.client)), lazy: true),
        app_provider.ChangeNotifierProvider<EventProvider>(create: (_) => EventProvider(EventService(SupabaseConfig.client)), lazy: true),
        app_provider.ChangeNotifierProvider<BusSearchProvider>(create: (_) => BusSearchProvider(), lazy: true),
        app_provider.ChangeNotifierProvider<SeatSelectionProvider>(create: (_) => SeatSelectionProvider(), lazy: true),
        app_provider.ChangeNotifierProvider<BookingProvider>(create: (_) => BookingProvider(), lazy: true),
        app_provider.ChangeNotifierProvider<AgencyDashboardProvider>(create: (_) => AgencyDashboardProvider(), lazy: true),
        app_provider.ChangeNotifierProvider<EscalationProvider>(create: (_) => EscalationProvider(), lazy: true),
        app_provider.ChangeNotifierProvider<SentimentProvider>(create: (_) => SentimentProvider(), lazy: true),
        app_provider.Provider<WalletService>(create: (_) => WalletService(), lazy: true),
        app_provider.Provider<WonyaService>(create: (_) => WonyaService(), lazy: true),
        app_provider.Provider<PaymentService>(create: (_) => PaymentService(), lazy: true),
        app_provider.Provider<QrService>(create: (_) => QrService(), lazy: true),
        app_provider.Provider<NotificationService>(create: (_) => NotificationService(), lazy: true),
      ],
      child: app_provider.Builder(builder: (context) {
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
        );
      }),
    );
  }
}
