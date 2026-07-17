// ============================================================
// 📁 lib/presentation/chat/settings/chat_appearance_settings.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/chat/chat_settings_provider.dart';
import 'widgets/chat_settings_switch.dart';

class ChatAppearanceSettings extends StatelessWidget {
  const ChatAppearanceSettings({super.key});

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
          title: const Text('Apparence', style: TextStyle(fontWeight: FontWeight.w800)),
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
        title: const Text('Apparence', style: TextStyle(fontWeight: FontWeight.w800)),
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
              title: const Text('Thème', style: TextStyle(fontWeight: FontWeight.bold, color: darkText)),
              trailing: DropdownButton<String>(
                value: settings.theme,
                underline: const SizedBox(), // Enlève la ligne moche sous le dropdown
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
          ),
          const Divider(height: 1, color: ivory),
          Container(
            color: Colors.white,
            child: ListTile(
              title: const Text('Taille de police', style: TextStyle(fontWeight: FontWeight.bold, color: darkText)),
              trailing: DropdownButton<double>(
                value: settings.fontSize,
                underline: const SizedBox(),
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
          ),
          const Divider(height: 1, color: ivory),
          Container(
            color: Colors.white,
            child: ChatSettingsSwitch(
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
          ),
        ],
      ),
    );
  }
}
