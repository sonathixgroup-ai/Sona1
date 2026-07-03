// lib/presentation/chat/settings/bubble_customizer_screen.dart
import 'package:flutter/material.dart';
import 'bubble_customizer.dart';   // ✅ même dossier

class BubbleCustomizerScreen extends StatelessWidget {
  const BubbleCustomizerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BubbleCustomizer();
  }
}
