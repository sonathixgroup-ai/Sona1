// lib/presentation/chat/home_widgets/widget_preview.dart
import 'package:flutter/material.dart';

class WidgetPreview extends StatelessWidget {
  final bool showConversations;
  final int conversationCount;
  final bool showShortcuts;
  final bool shortcutNewMessage;
  final bool shortcutNewCall;
  final bool shortcutCamera;

  const WidgetPreview({
    super.key,
    this.showConversations = true,
    this.conversationCount = 3,
    this.showShortcuts = true,
    this.shortcutNewMessage = true,
    this.shortcutNewCall = true,
    this.shortcutCamera = false,
  });

  @override
  Widget build(BuildContext context) {
    // Le contenu existant de ton widget (tu peux le reprendre intégralement)
    return Scaffold(
      appBar: AppBar(title: const Text('Aperçu du widget')),
      body: const Center(child: Text('Aperçu')),
    );
  }
}
