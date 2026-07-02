// lib/presentation/chat/translation/language_selector_sheet.dart
// Feuille modale pour choisir la langue cible de traduction

import 'package:flutter/material.dart';

class LanguageSelectorSheet extends StatelessWidget {
  final Function(String languageCode) onLanguageSelected;
  final String? currentLanguageCode;

  const LanguageSelectorSheet({
    Key? key,
    required this.onLanguageSelected,
    this.currentLanguageCode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final languages = {
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

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Langue de traduction', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...languages.entries.map((entry) {
            return RadioListTile<String>(
              title: Text(entry.value),
              value: entry.key,
              groupValue: currentLanguageCode,
              onChanged: (val) {
                if (val != null) onLanguageSelected(val);
                Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }
}
