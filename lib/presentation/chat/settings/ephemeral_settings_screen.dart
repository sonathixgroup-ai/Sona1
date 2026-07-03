// lib/presentation/chat/settings/ephemeral_settings_screen.dart
import 'package:flutter/material.dart';
import '../ephemeral/ephemeral_settings.dart';

class EphemeralSettingsScreen extends StatefulWidget {
  const EphemeralSettingsScreen({super.key});

  @override
  State<EphemeralSettingsScreen> createState() => _EphemeralSettingsScreenState();
}

class _EphemeralSettingsScreenState extends State<EphemeralSettingsScreen> {
  void _onDurationSelected(int duration) {
    // Gérer la sélection de durée
    // Par exemple, sauvegarder dans SharedPreferences ou dans le provider
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Durée sélectionnée : ${duration}s')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return EphemeralSettings(
      onDurationSelected: _onDurationSelected, // ✅ fonction valide
    );
  }
}
