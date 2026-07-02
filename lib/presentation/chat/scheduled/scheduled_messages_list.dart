// lib/presentation/chat/scheduled/scheduled_messages_list.dart
// Liste des messages programmés pour une conversation (avec possibilité d'annuler)

import 'package:flutter/material.dart';
import '../core/chat_models.dart';

class ScheduledMessagesList extends StatelessWidget {
  final List<ScheduledMessage> scheduledMessages;
  final Function(String messageId) onCancel;

  const ScheduledMessagesList({
    Key? key,
    required this.scheduledMessages,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (scheduledMessages.isEmpty) {
      return const Center(child: Text('Aucun message programmé'));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: scheduledMessages.length,
      itemBuilder: (context, index) {
        final msg = scheduledMessages[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: const Icon(Icons.schedule, color: Colors.blue),
            title: Text(msg.content ?? '(Message vide)', maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              'Programmé le : ${_formatDateTime(msg.scheduledAt)}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.cancel_outlined, color: Colors.red),
              onPressed: () => onCancel(msg.id),
            ),
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// Modèle simplifié (à étendre dans chat_models.dart)
class ScheduledMessage {
  final String id;
  final String conversationId;
  final String? content;
  final String? mediaUrl;
  final DateTime scheduledAt;
  final bool isRecurring;

  ScheduledMessage({
    required this.id,
    required this.conversationId,
    this.content,
    this.mediaUrl,
    required this.scheduledAt,
    this.isRecurring = false,
  });
}
