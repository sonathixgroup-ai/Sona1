// presentation/chat/video_message/video_message_screen.dart
import 'package:flutter/material.dart';
import '../video_message/video_message_widget.dart'; // si ce fichier existe

class VideoMessageScreen extends StatelessWidget {
  const VideoMessageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Message vidéo')),
      body: const Center(child: Text('Envoi de message vidéo (à implémenter)')),
    );
  }
}
