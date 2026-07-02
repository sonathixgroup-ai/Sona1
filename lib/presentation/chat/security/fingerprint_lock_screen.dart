import 'package:flutter/material.dart';

class FingerprintLockScreen extends StatelessWidget {
  const FingerprintLockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verrouillage par empreinte')),
      body: const Center(
        child: Text('Page de verrouillage par empreinte (à implémenter)'),
      ),
    );
  }
}
