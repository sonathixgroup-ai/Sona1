import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as app_provider;
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
  await SupabaseConfig.initialize();
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
  @override
  void initState() {
    super.initState();
    _locale = LocaleController()..init();
    _auth = AuthController(auth: SupabaseAuthManager(profiles: ProfileService()));
    _auth.init();
    _router = AppRouter.create(_auth, extraRefreshListenable: _locale);
  }
  @override
  Widget build(BuildContext context) {
    return app_provider.MultiProvider(
      providers: [
        app_provider.ChangeNotifierProvider<AuthController>.value(value: _auth),
        app_provider.ChangeNotifierProvider<LocaleController>.value(value: _locale),
        app_provider.Provider<ProfileService>(create: (_) => ProfileService()),
      ],
      child: MaterialApp.router(
        title: 'THIX ID CENTRAL', debugShowCheckedModeBanner: false,
        theme: lightTheme, darkTheme: darkTheme, routerConfig: _router,
        locale: _locale.locale, supportedLocales: LocaleController.supportedLocales,
        localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      ),
    );
  }
}
