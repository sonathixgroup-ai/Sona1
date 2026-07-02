// lib/presentation/chat/translation/auto_translate_settings.dart
// Écran de paramètres pour la traduction automatique (globale ou par conversation)

import 'package:flutter/material.dart';

class AutoTranslateSettings extends StatefulWidget {
  final bool isAutoTranslateEnabled;
  final String targetLanguageCode;
  final Function(bool enabled, String languageCode) onSettingsChanged;

  const AutoTranslateSettings({
    Key? key,
    required this.isAutoTranslateEnabled,
    required this.targetLanguageCode,
    required this.onSettingsChanged,
  }) : super(key: key);

  @override
  State<AutoTranslateSettings> createState() => _AutoTranslateSettingsState();
}

class _AutoTranslateSettingsState extends State<AutoTranslateSettings> {
  late bool _enabled;
  late String _targetLanguage;

  @override
  void initState() {
    super.initState();
    _enabled = widget.isAutoTranslateEnabled;
    _targetLanguage = widget.targetLanguageCode;
  }

  @override
  Widget build(BuildContext context) {
    final languageNames = {
      'fr': 'Français',
      'en': 'Anglais',
      'es': 'Espagnol',
      'de': 'Allemand',
      'it': 'Italien',
      'pt': 'Portugais',
      'ar': 'Arabe',
      'zh': 'Chinois',
      'ru': 'Russe',
      'ja': 'Japonais',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Traduction automatique')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Activer la traduction automatique'),
            subtitle: const Text('Traduire automatiquement les messages dans votre langue'),
            value: _enabled,
            onChanged: (val) => setState(() => _enabled = val),
          ),
          if (_enabled)
            ListTile(
              title: const Text('Langue cible'),
              subtitle: Text(languageNames[_targetLanguage] ?? 'Français'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () async {
                final newLang = await showDialog<String>(
                  context: context,
                  builder: (context) => LanguageSelectorSheet(
                    currentLanguageCode: _targetLanguage,
                    onLanguageSelected: (code) => Navigator.pop(context, code),
                  ),
                );
                if (newLang != null) setState(() => _targetLanguage = newLang);
              },
            ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                widget.onSettingsChanged(_enabled, _targetLanguage);
                Navigator.pop(context);
              },
              child: const Text('Enregistrer'),
            ),
          ),
        ],
      ),
    );
  }
}
