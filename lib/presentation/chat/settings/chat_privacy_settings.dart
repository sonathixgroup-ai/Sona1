// ============================================================
// 📁 lib/presentation/chat/settings/chat_privacy_settings.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/chat/chat_settings_provider.dart';
import 'widgets/chat_settings_switch.dart';

class ChatPrivacySettings extends StatelessWidget {
  const ChatPrivacySettings({super.key});

  // Couleurs THIX ID
  static const Color primaryBlue = Color(0xFF4A8BFF);
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color ivory = Color(0xFFF3F5FA);
  static const Color darkText = Color(0xFF10182B);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatSettingsProvider>();
    final settings = provider.settings;

    // SCÉNARIO SÉCURISÉ : Si les paramètres chargent ou sont nulls
    if (settings == null || provider.isLoading) {
      return Scaffold(
        backgroundColor: ivory,
        appBar: AppBar(
          title: const Text('Confidentialité', style: TextStyle(fontWeight: FontWeight.w800)),
          backgroundColor: navyDeep,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator(color: primaryBlue)),
      );
    }

    return Scaffold(
      backgroundColor: ivory,
      appBar: AppBar(
        title: const Text('Confidentialité', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: navyDeep,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Container(
            color: Colors.white,
            child: ListTile(
              title: const Text('Dernière activité', style: TextStyle(fontWeight: FontWeight.bold, color: darkText)),
              trailing: DropdownButton<String>(
                value: settings.lastSeenVisibility,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'everyone', child: Text('Tout le monde')),
                  DropdownMenuItem(value: 'contacts', child: Text('Mes contacts')),
                  DropdownMenuItem(value: 'nobody', child: Text('Personne')),
                ],
                onChanged: (val) async {
                  if (val != null) {
                    final newSettings = settings.copyWith(lastSeenVisibility: val);
                    await provider.updateSettings(newSettings);
                  }
                },
              ),
            ),
          ),
          const Divider(height: 1, color: ivory),
          Container(
            color: Colors.white,
            child: ListTile(
              title: const Text('Photo de profil', style: TextStyle(fontWeight: FontWeight.bold, color: darkText)),
              trailing: DropdownButton<String>(
                value: settings.profilePhotoVisibility,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'everyone', child: Text('Tout le monde')),
                  DropdownMenuItem(value: 'contacts', child: Text('Mes contacts')),
                  DropdownMenuItem(value: 'nobody', child: Text('Personne')),
                ],
                onChanged: (val) async {
                  if (val != null) {
                    final newSettings = settings.copyWith(profilePhotoVisibility: val);
                    await provider.updateSettings(newSettings);
                  }
                },
              ),
            ),
          ),
          const Divider(height: 1, color: ivory),
          Container(
            color: Colors.white,
            child: ChatSettingsSwitch(
              title: 'Confirmations de lecture',
              subtitle: 'Afficher quand vous lisez un message',
              value: settings.readReceipts,
              onChanged: (val) async {
                final newSettings = settings.copyWith(readReceipts: val);
                await provider.updateSettings(newSettings);
              },
            ),
          ),
          const Divider(height: 1, color: ivory),
          Container(
            color: Colors.white,
            child: ChatSettingsSwitch(
              title: 'Indicateur de saisie',
              subtitle: 'Afficher quand vous tapez un message',
              value: settings.typingIndicator,
              onChanged: (val) async {
                final newSettings = settings.copyWith(typingIndicator: val);
                await provider.updateSettings(newSettings);
              },
            ),
          ),
        ],
      ),
    );
  }
}
