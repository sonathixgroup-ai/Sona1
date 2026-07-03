// lib/presentation/chat/settings/translation_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../translation/auto_translate_settings.dart';

class TranslationSettingsScreen extends StatefulWidget {
  const TranslationSettingsScreen({super.key});

  @override
  State<TranslationSettingsScreen> createState() => _TranslationSettingsScreenState();
}

class _TranslationSettingsScreenState extends State<TranslationSettingsScreen> {
  late bool _isAutoTranslateEnabled;
  late String _targetLanguageCode;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAutoTranslateEnabled = prefs.getBool('auto_translate_enabled') ?? false;
      _targetLanguageCode = prefs.getString('target_language_code') ?? 'fr';
    });
  }

  Future<void> _saveSettings(bool isEnabled, String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_translate_enabled', isEnabled);
    await prefs.setString('target_language_code', languageCode);
  }

  void _onSettingsChanged(bool isEnabled, String languageCode) {
    setState(() {
      _isAutoTranslateEnabled = isEnabled;
      _targetLanguageCode = languageCode;
    });
    _saveSettings(isEnabled, languageCode);
  }

  @override
  Widget build(BuildContext context) {
    // Si les données ne sont pas encore chargées, on attend
    if (!mounted || !_isAutoTranslateEnabled && _targetLanguageCode == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AutoTranslateSettings(
      isAutoTranslateEnabled: _isAutoTranslateEnabled,
      targetLanguageCode: _targetLanguageCode,
      onSettingsChanged: _onSettingsChanged,
    );
  }
}
