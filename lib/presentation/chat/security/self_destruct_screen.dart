import 'package:flutter/material.dart';

class SelfDestructScreen extends StatelessWidget {
  const SelfDestructScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auto-destruction')),
      body: const Center(
        child: Text('Page d’auto-destruction (à implémenter)'),
      ),
    );
  }
}
