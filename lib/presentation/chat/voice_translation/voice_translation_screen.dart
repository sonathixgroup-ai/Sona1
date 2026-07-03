// lib/presentation/chat/voice_translation/voice_translation_screen.dart
// Écran d'accès à la traduction vocale (ouvre le dialogue VoiceTranslation)

import 'package:flutter/material.dart';
import '../translation/voice_translation.dart';

class VoiceTranslationScreen extends StatelessWidget {
  const VoiceTranslationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Traduction vocale')),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.mic),
          label: const Text('Démarrer la traduction vocale'),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => VoiceTranslation(
                onTranslated: (translatedText) {
                  Navigator.pop(context, translatedText);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
