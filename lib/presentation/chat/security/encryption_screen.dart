import 'package:flutter/material.dart';

class EncryptionScreen extends StatelessWidget {
  const EncryptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chiffrement')),
      body: const Center(
        child: Text('Page de chiffrement (à implémenter)'),
      ),
    );
  }
}
