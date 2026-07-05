import 'package:flutter/material.dart';

class NewChatPage extends StatelessWidget {
  const NewChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle conversation')),
      body: const Center(child: Text('Créer une nouvelle conversation (à implémenter)')),
    ); 
  }
}
