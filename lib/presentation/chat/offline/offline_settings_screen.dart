// presentation/chat/offline/offline_settings_screen.dart
import 'package:flutter/material.dart';
import '../offline_mode/offline_settings.dart';

class OfflineSettingsScreen extends StatelessWidget {
  const OfflineSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Si `offline_settings.dart` n’existe pas, crée-le avec un contenu minimal
    return Scaffold(
      appBar: AppBar(title: const Text('Mode hors ligne')),
      body: const Center(child: Text('Paramètres hors ligne (à implémenter)')),
    );
  }
}
