// lib/presentation/chat/security_advanced/theft_protection.dart
// Protection en cas de vol (localisation, wipe distant, affichage de faux contenu)

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TheftProtection {
  static const String _wipeTriggeredKey = 'wipe_triggered';
  static const String _fakeModeKey = 'fake_mode_enabled';

  static Future<void> enableFakeMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_fakeModeKey, true);
  }

  static Future<void> disableFakeMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_fakeModeKey);
  }

  static Future<bool> isFakeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_fakeModeKey) ?? false;
  }

  static Future<void> triggerWipe() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_wipeTriggeredKey, true);
    // Effacer toutes les données locales (messages, clés)
    await prefs.clear();
    // Optionnel : envoyer une alerte au serveur
  }

  static Future<bool> isWiped() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_wipeTriggeredKey) ?? false;
  }
}
