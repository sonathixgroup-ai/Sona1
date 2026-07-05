import 'package:flutter/material.dart';

class OnlineUsersPage extends StatelessWidget {
  const OnlineUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Utilisateurs en ligne')),
      body: const Center(child: Text('Liste des utilisateurs en ligne (à implémenter)')),
    );
  }
}
