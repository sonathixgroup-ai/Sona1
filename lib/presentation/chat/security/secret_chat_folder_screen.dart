import 'package:flutter/material.dart';

class SecretChatFolderScreen extends StatelessWidget {
  const SecretChatFolderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dossier secret')),
      body: const Center(
        child: Text('Page du dossier secret (à implémenter)'),
      ),
    );
  }
}
