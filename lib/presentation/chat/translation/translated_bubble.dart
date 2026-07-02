// lib/presentation/chat/translation/translated_bubble.dart
// Bulle de message avec traduction affichée (original + traduit)

import 'package:flutter/material.dart';

class TranslatedBubble extends StatelessWidget {
  final String originalText;
  final String translatedText;
  final bool isMe;
  final DateTime sentAt;
  final VoidCallback onTranslateAgain;

  const TranslatedBubble({
    Key? key,
    required this.originalText,
    required this.translatedText,
    required this.isMe,
    required this.sentAt,
    required this.onTranslateAgain,
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
          color: isMe ? Colors.blue[100] : Colors.grey[200],
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
            // Texte original (en petit grisé)
            Text(
              originalText,
              style: TextStyle(fontSize: 12, color: Colors.grey[700], fontStyle: FontStyle.italic),
            ),
            const Divider(height: 8, thickness: 0.5),
            // Texte traduit
            Text(
              translatedText,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTime(sentAt),
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
                InkWell(
                  onTap: onTranslateAgain,
                  child: const Row(
                    children: [
                      Icon(Icons.refresh, size: 12),
                      SizedBox(width: 4),
                      Text('Relire', style: TextStyle(fontSize: 10)),
                    ],
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
