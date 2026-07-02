import 'package:flutter/material.dart';

class FakeInterfaceScreen extends StatelessWidget {
  const FakeInterfaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fausse interface')),
      body: const Center(
        child: Text('Page de fausse interface (à implémenter)'),
      ),
    );
  }
}
