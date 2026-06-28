import 'package:flutter/material.dart';

class ConversationScreen extends StatelessWidget {
  final String conversationId;

  const ConversationScreen({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conversation')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'La conversation $conversationId doit être ouverte depuis THIX CHAT.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
