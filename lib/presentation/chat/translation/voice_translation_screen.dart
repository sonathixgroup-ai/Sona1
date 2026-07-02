// presentation/chat/voice_translation/voice_translation_screen.dart
import 'package:flutter/material.dart';

class VoiceTranslationScreen extends StatelessWidget {
  const VoiceTranslationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Traduction vocale')),
      body: const Center(child: Text('Traduction vocale en temps réel (à implémenter)')),
    );
  }
}
