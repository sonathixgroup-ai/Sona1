import 'package:flutter/material.dart';

class TheftProtectionScreen extends StatelessWidget {
  const TheftProtectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Protection contre le vol')),
      body: const Center(
        child: Text('Page de protection contre le vol (à implémenter)'),
      ),
    );
  }
}
