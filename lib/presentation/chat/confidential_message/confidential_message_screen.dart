// presentation/chat/confidential_message/confidential_message_screen.dart
import 'package:flutter/material.dart';
import '../confidential_message/confidential_message.dart'; // si ce fichier existe

class ConfidentialMessageScreen extends StatelessWidget {
  const ConfidentialMessageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Message confidentiel')),
      body: const Center(child: Text('Messages confidentiels (à implémenter)')),
    );
  }
}
