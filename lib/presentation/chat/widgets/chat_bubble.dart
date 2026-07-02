// lib/presentation/chat/widgets/chat_bubble.dart
import 'package:flutter/material.dart';
import '../core/chat_models.dart';
import '../core/chat_constants.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final VoidCallback? onReactionTap;
  final VoidCallback? onConfidentialTap;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.isMe,
    this.onReactionTap,
    this.onConfidentialTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isConfidential = message.type == ChatConstants.messageTypeConfidential;
    final isEphemeral = message.type == ChatConstants.messageTypeEphemeral;
    final isVoice = message.type == ChatConstants.messageTypeVoice;

    return GestureDetector(
      onLongPress: onReactionTap,
      child: Align(
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
              if (isConfidential)
                _buildConfidentialContent()
              else if (isEphemeral)
                _buildEphemeralContent()
              else if (isVoice)
                _buildVoiceContent()
              else
                _buildTextContent(),
              const SizedBox(height: 4),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextContent() {
    return Text(
      message.content ?? '',
      style: const TextStyle(fontSize: 14),
    );
  }

  Widget _buildConfidentialContent() {
    return InkWell(
      onTap: onConfidentialTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            const Text('Message confidentiel (appuyer pour ouvrir)',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  Widget _buildEphemeralContent() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.timer_outlined, size: 16, color: Colors.orange),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message.content ?? 'Message éphémère',
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceContent() {
    return Row(
      children: [
        Icon(Icons.play_circle_outline, color: isMe ? Colors.blue[800] : Colors.grey[700]),
        const SizedBox(width: 8),
        Expanded(
          child: LinearProgressIndicator(
            value: 0.3, // À remplacer par un vrai contrôleur
            backgroundColor: Colors.grey[300],
            color: isMe ? Colors.blue : Colors.grey,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${message.durationSeconds ?? 0}s',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(message.sentAt),
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
        if (message.reactions.isNotEmpty) ...[
          const SizedBox(width: 8),
          Row(
            children: message.reactions.map((r) => Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Text(r, style: const TextStyle(fontSize: 12)),
            )).toList(),
          ),
        ],
      ],
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
