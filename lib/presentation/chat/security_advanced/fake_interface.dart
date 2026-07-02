// lib/presentation/chat/security_advanced/fake_interface.dart
// Interface factice pour tromper en cas de mot de passe erroné

import 'package:flutter/material.dart';

class FakeInterface extends StatelessWidget {
  final VoidCallback onBack;

  const FakeInterface({Key? key, required this.onBack}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes conversations')),
      body: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) => ListTile(
          title: Text('Fake conversation $index'),
          subtitle: const Text('Aucun message'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
