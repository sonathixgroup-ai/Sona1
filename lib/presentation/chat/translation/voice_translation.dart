// lib/presentation/chat/translation/voice_translation.dart
// Fonctionnalité de traduction vocale (enregistrement vocal + traduction + envoi)

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceTranslation extends StatefulWidget {
  final Function(String translatedText) onTranslated;

  const VoiceTranslation({Key? key, required this.onTranslated}) : super(key: key);

  @override
  State<VoiceTranslation> createState() => _VoiceTranslationState();
}

class _VoiceTranslationState extends State<VoiceTranslation> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _recognizedText = '';
  bool _isTranslating = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    await _speech.initialize(
      onStatus: (status) => print('Status: $status'),
      onError: (error) => print('Error: $error'),
    );
  }

  void _startListening() async {
    if (!_speech.isAvailable) return;
    _speech.listen(
      onResult: (result) {
        setState(() {
          _recognizedText = result.recognizedWords;
        });
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
    setState(() => _isListening = true);
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _translateAndSend() async {
    if (_recognizedText.isEmpty) return;
    setState(() => _isTranslating = true);
    // Appel à votre API de traduction (ex: via ChatRepository)
    // Pour l'exemple, on simule une traduction en français
    final translated = await _callTranslationApi(_recognizedText);
    setState(() => _isTranslating = false);
    widget.onTranslated(translated);
    Navigator.pop(context);
  }

  Future<String> _callTranslationApi(String text) async {
    // Intégration réelle : repository.translateText(text, targetLang)
    await Future.delayed(const Duration(milliseconds: 500));
    return 'Traduction de : $text';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Traduction vocale'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_recognizedText.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_recognizedText),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(_isListening ? Icons.mic_off : Icons.mic, size: 32),
                onPressed: _isListening ? _stopListening : _startListening,
              ),
              if (_recognizedText.isNotEmpty)
                IconButton(
                  icon: _isTranslating
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : const Icon(Icons.translate, size: 32),
                  onPressed: _isTranslating ? null : _translateAndSend,
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}
