// lib/presentation/chat/offline/offline_settings_screen.dart
import 'package:flutter/material.dart';
import 'offline_settings.dart'; // ← même dossier, pas de sous-dossier

class OfflineSettingsScreen extends StatelessWidget {
  const OfflineSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mode hors ligne')),
      body: const OfflineSettings(),
    );
  }
}
