import 'package:flutter/material.dart';

class AntiScreenshotScreen extends StatelessWidget {
  const AntiScreenshotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Anti-capture d\'écran')),
      body: const Center(
        child: Text('Page anti-capture (à implémenter)'),
      ),
    );
  }
}
