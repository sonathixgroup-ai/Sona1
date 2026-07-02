// lib/presentation/chat/ephemeral/ephemeral_bubble.dart
// Bulle spéciale pour l'affichage d'un message éphémère (avec timer intégré)

import 'package:flutter/material.dart';
import '../core/chat_models.dart';
import 'ephemeral_timer.dart';
import 'ephemeral_indicator.dart';

class EphemeralBubble extends StatelessWidget {
  final EphemeralMessage message;
  final bool isMe;
  final VoidCallback onExpired;

  const EphemeralBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.onExpired,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isExpired = message.openedAt != null &&
        DateTime.now().difference(message.openedAt!).inSeconds >= message.durationSeconds;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue[50] : Colors.grey[100],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
          ),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                EphemeralIndicator(isExpired: isExpired),
                const SizedBox(width: 6),
                Text(
                  isExpired ? 'Message expiré' : 'Message éphémère',
                  style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: isExpired ? Colors.grey : Colors.orange,
                  ),
                ),
                const Spacer(),
                if (!isExpired && message.openedAt == null)
                  EphemeralTimer(
                    message: message,
                    onExpired: onExpired,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            if (!isExpired && message.openedAt == null)
              Text(
                message.content ?? '',
                style: const TextStyle(fontSize: 14),
              )
            else if (!isExpired && message.openedAt != null)
              Text(
                message.content ?? '',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              )
            else
              const Text(
                'Ce message a été supprimé après sa lecture.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.sentAt),
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
