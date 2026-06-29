import 'package:flutter/material.dart';

/// Simple message bubble used by legacy chat screens.
///
/// The advanced version previously depended on Riverpod; this lightweight
/// widget keeps the project compiling.
class MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final DateTime? timestamp;

  const MessageBubble({super.key, required this.text, required this.isMe, this.timestamp});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: isMe ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: isMe ? cs.onPrimary : cs.onSurface)),
      ),
    );
  }
}
