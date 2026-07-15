import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ChangeNotifier {
  static const _key = 'app_locale_code';

  static const supportedLocales = [
    Locale('fr'),
    Locale('en'),
    Locale('ar'),
    Locale('zh'),
    Locale('pt'),
    Locale('ln'),
    Locale('kg'),
    Locale('sw'),
  ];

  static const Map<String, String> nativeNames = {
    'fr': 'Français',
    'en': 'English',
    'ar': 'العربية',
    'zh': '中文',
    'pt': 'Português',
    'ln': 'Lingála',
    'kg': 'Kikongo',
    'sw': 'Kiswahili',
  };

  Locale _locale = const Locale('fr');
  Locale get locale => _locale;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null && supportedLocales.any((l) => l.languageCode == code)) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    if (!supportedLocales.any((l) => l.languageCode == newLocale.languageCode)) return;
    _locale = newLocale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, newLocale.languageCode);
  }
}
