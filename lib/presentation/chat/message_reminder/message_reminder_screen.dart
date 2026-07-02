// presentation/chat/message_reminder/message_reminder_screen.dart
import 'package:flutter/material.dart';
import '../message_reminder/message_reminder.dart'; // si ce fichier existe

class MessageReminderScreen extends StatelessWidget {
  const MessageReminderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rappel de message')),
      body: const Center(child: Text('Gestion des rappels (à implémenter)')),
    );
  }
}
