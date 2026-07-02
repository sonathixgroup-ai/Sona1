// lib/presentation/chat/home_widgets/floating_new_chat_button.dart
// Bouton flottant pour créer une nouvelle conversation

import 'package:flutter/material.dart';

class FloatingNewChatButton extends StatelessWidget {
  final VoidCallback onPressed;

  const FloatingNewChatButton({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      child: const Icon(Icons.chat_bubble_outline),
      tooltip: 'Nouvelle conversation',
    );
  }
}
