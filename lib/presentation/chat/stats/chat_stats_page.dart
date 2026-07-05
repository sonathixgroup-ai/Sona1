import 'package:flutter/material.dart';

class ChatStatsPage extends StatelessWidget {
  const ChatStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques du chat')),
      body: const Center(child: Text('Stats (à implémenter)')),
    );
  }
}
