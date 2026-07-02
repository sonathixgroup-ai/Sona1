import 'package:flutter/material.dart';

class SessionManagerScreen extends StatelessWidget {
  const SessionManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestion des sessions')),
      body: const Center(
        child: Text('Page de gestion des sessions (à implémenter)'),
      ),
    );
  }
}
