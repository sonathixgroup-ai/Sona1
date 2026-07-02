// lib/presentation/chat/read_receipts/priority_message_widget.dart
// Widget pour les messages prioritaires (exige un accusé de lecture forcé)

import 'package:flutter/material.dart';

class PriorityMessageWidget extends StatelessWidget {
  final String content;
  final bool isMe;
  final DateTime sentAt;
  final VoidCallback onConfirmRead;

  const PriorityMessageWidget({
    Key? key,
    required this.content,
    required this.isMe,
    required this.sentAt,
    required this.onConfirmRead,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? Colors.red[100] : Colors.red[50],
          border: Border.all(color: Colors.red.shade300),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.priority_high, size: 16, color: Colors.red),
                const SizedBox(width: 4),
                const Text('Message prioritaire', style: TextStyle(fontSize: 10, color: Colors.red)),
              ],
            ),
            const SizedBox(height: 4),
            Text(content, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatTime(sentAt), style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                if (!isMe)
                  ElevatedButton(
                    onPressed: onConfirmRead,
                    child: const Text('Accuser réception'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
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
