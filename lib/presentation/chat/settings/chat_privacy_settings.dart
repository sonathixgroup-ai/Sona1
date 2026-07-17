// ============================================================
// 📁 lib/presentation/chat/settings/chat_privacy_settings.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/chat/chat_settings_provider.dart';
import 'widgets/chat_settings_switch.dart';

class ChatPrivacySettings extends StatelessWidget {
  const ChatPrivacySettings({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatSettingsProvider>();
    final settings = provider.settings;

    if (settings == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('Confidentialité')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Dernière activité'),
            trailing: DropdownButton<String>(
              value: settings.lastSeenVisibility,
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
          ListTile(
            title: const Text('Photo de profil'),
            trailing: DropdownButton<String>(
              value: settings.profilePhotoVisibility,
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
          ChatSettingsSwitch(
            title: 'Confirmations de lecture',
            subtitle: 'Afficher quand vous lisez un message',
            value: settings.readReceipts,
            onChanged: (val) async {
              final newSettings = settings.copyWith(readReceipts: val);
              await provider.updateSettings(newSettings);
            },
          ),
          ChatSettingsSwitch(
            title: 'Indicateur de saisie',
            subtitle: 'Afficher quand vous tapez un message',
            value: settings.typingIndicator,
            onChanged: (val) async {
              final newSettings = settings.copyWith(typingIndicator: val);
              await provider.updateSettings(newSettings);
            },
          ),
        ],
      ),
    );
  }
}
