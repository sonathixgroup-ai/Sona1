// lib/presentation/chat/archive/archive_list_item.dart
import 'package:flutter/material.dart';

class Conversation {
  final String id;
  final String name;
  final String? lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isArchived;

  Conversation({
    required this.id,
    required this.name,
    this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isArchived = false,
  });
}

class ArchiveListItem extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onUnarchive;
  final VoidCallback onDelete;

  const ArchiveListItem({
    super.key,
    required this.conversation,
    required this.onUnarchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey[200],
          child: Text(
            conversation.name[0].toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          conversation.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          conversation.lastMessage ?? 'Aucun message',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.unarchive, color: Colors.blue),
              onPressed: onUnarchive,
              tooltip: 'Désarchiver',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
              tooltip: 'Supprimer définitivement',
            ),
          ],
        ),
        onTap: () {
          // Navigation vers la conversation (optionnel)
        },
      ),
    );
  }
}
