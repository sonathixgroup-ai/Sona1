// lib/presentation/chat/home_widgets/widget_preview_screen.dart
import 'package:flutter/material.dart';
import 'widget_preview.dart'; // ← corrigé (underscore)

class WidgetPreviewScreen extends StatelessWidget {
  const WidgetPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const WidgetPreview(
      showConversations: true,
      conversationCount: 3,
      showShortcuts: true,
      shortcutNewMessage: true,
      shortcutNewCall: true,
      shortcutCamera: false,
    );
  }
}
