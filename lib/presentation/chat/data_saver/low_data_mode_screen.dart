// lib/presentation/chat/data_saver/low_data_mode_screen.dart
import 'package:flutter/material.dart';
import 'low_data_mode_toggle.dart';

class LowDataModeScreen extends StatelessWidget {
  const LowDataModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Redirige directement vers le hub "LowDataModeToggle" existant
    return const LowDataModeToggle();
  }
}
