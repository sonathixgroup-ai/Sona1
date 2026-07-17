// ============================================================
// 📁 lib/presentation/chat/settings/chat_appearance_settings.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/chat/chat_settings_provider.dart';
import 'widgets/chat_settings_switch.dart';

class ChatAppearanceSettings extends StatelessWidget {
  const ChatAppearanceSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatSettingsProvider>();
    final settings = provider.settings;

    if (settings == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('Apparence')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Thème'),
            trailing: DropdownButton<String>(
              value: settings.theme,
              items: const [
                DropdownMenuItem(value: 'light', child: Text('Clair')),
                DropdownMenuItem(value: 'dark', child: Text('Sombre')),
                DropdownMenuItem(value: 'system', child: Text('Système')),
              ],
              onChanged: (val) async {
                if (val != null) {
                  final newSettings = settings.copyWith(theme: val);
                  await provider.updateSettings(newSettings);
                }
              },
            ),
          ),
          ListTile(
            title: const Text('Taille de police'),
            trailing: DropdownButton<double>(
              value: settings.fontSize,
              items: const [
                DropdownMenuItem(value: 12.0, child: Text('Très petite')),
                DropdownMenuItem(value: 14.0, child: Text('Petite')),
                DropdownMenuItem(value: 16.0, child: Text('Normale')),
                DropdownMenuItem(value: 18.0, child: Text('Grande')),
                DropdownMenuItem(value: 20.0, child: Text('Très grande')),
              ],
              onChanged: (val) async {
                if (val != null) {
                  final newSettings = settings.copyWith(fontSize: val);
                  await provider.updateSettings(newSettings);
                }
              },
            ),
          ),
          ChatSettingsSwitch(
            title: 'Style des bulles',
            subtitle: 'Arrondies ou carrées',
            value: settings.bubbleStyle == 'rounded',
            onChanged: (val) async {
              final newSettings = settings.copyWith(
                bubbleStyle: val ? 'rounded' : 'square',
              );
              await provider.updateSettings(newSettings);
            },
          ),
        ],
      ),
    );
  }
}
