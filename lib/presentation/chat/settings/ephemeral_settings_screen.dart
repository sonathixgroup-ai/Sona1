// presentation/chat/settings/ephemeral_settings_screen.dart
import 'package:flutter/material.dart';
import '../ephemeral/ephemeral_settings.dart';

class EphemeralSettingsScreen extends StatelessWidget {
  const EphemeralSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EphemeralSettings(onDurationSelected: null);
  }
}
