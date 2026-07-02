// lib/presentation/chat/home_widgets/no_conversation_placeholder.dart
// Widget affiché quand aucune conversation n'existe

import 'package:flutter/material.dart';

class NoConversationPlaceholder extends StatelessWidget {
  final VoidCallback onStartChat;

  const NoConversationPlaceholder({Key? key, required this.onStartChat}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune conversation',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez à discuter avec vos contacts',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onStartChat,
            icon: const Icon(Icons.add),
            label: const Text('Nouveau message'),
          ),
        ],
      ),
    );
  }
}
