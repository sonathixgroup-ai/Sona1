// lib/presentation/chat/security_advanced/security_lock.dart
// Verrouillage de l'application ou de conversations spécifiques (PIN / biométrie)

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityLock {
  static const String _pinKey = 'app_lock_pin';
  static const String _enabledKey = 'app_lock_enabled';
  static const String _biometricKey = 'app_lock_biometric';

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  static Future<void> setEnabled(bool enabled, {String? pin, bool useBiometric = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
    if (enabled && pin != null) {
      await prefs.setString(_pinKey, pin);
      await prefs.setBool(_biometricKey, useBiometric);
    }
  }

  static Future<bool> verify(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final useBiometric = prefs.getBool(_biometricKey) ?? false;
    if (useBiometric) {
      final localAuth = LocalAuthentication();
      final canCheck = await localAuth.canCheckBiometrics;
      if (canCheck) {
        return await localAuth.authenticate(
          localizedReason: 'Déverrouillez l\'application',
          options: const AuthenticationOptions(biometricOnly: true),
        );
      }
    }
    final storedPin = prefs.getString(_pinKey);
    if (storedPin == null) return true;
    final entered = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Verrouillage'),
        content: TextField(
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Code PIN'),
          keyboardType: TextInputType.number,
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
    return entered == storedPin;
  }

  // Verrouillage par conversation
  static Future<void> setConversationLock(String conversationId, String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lock_conv_$conversationId', pin);
  }

  static Future<bool> isConversationLocked(String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('lock_conv_$conversationId');
  }

  static Future<bool> verifyConversationLock(String conversationId, BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final storedPin = prefs.getString('lock_conv_$conversationId');
    if (storedPin == null) return true;
    final entered = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conversation verrouillée'),
        content: TextField(
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Code PIN'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
    return entered == storedPin;
  }
}
