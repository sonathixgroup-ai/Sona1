// lib/presentation/chat/read_receipts/read_by_list.dart
import 'package:flutter/material.dart';

// Définition locale du modèle (si non disponible ailleurs)
class ReadReceiptUser {
  final String id;
  final String name;
  final String? avatarUrl;
  final DateTime readAt;

  ReadReceiptUser({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.readAt,
  });
}

class ReadByList extends StatelessWidget {
  final List<ReadReceiptUser> readers;
  final int maxAvatars;

  const ReadByList({
    Key? key,
    required this.readers,
    this.maxAvatars = 3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (readers.isEmpty) return const SizedBox.shrink();

    final displayed = readers.take(maxAvatars).toList();
    final remaining = readers.length - maxAvatars;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...displayed.map((user) => Container(
              margin: const EdgeInsets.only(right: 4),
              child: CircleAvatar(
                radius: 12,
                backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                    ? NetworkImage(user.avatarUrl!) as ImageProvider
                    : const AssetImage('assets/default_avatar.png'),
                child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                    ? const Icon(Icons.person, size: 12)
                    : null,
              ),
            )),
        if (remaining > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('+$remaining', style: const TextStyle(fontSize: 10)),
          ),
      ],
    );
  }
}
