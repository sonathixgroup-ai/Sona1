import 'package:flutter/material.dart';

class NewStoryPage extends StatelessWidget {
  const NewStoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle story')),
      body: const Center(child: Text('Créer une story (à implémenter)')),
    );
  }
}
