// lib/presentation/chat/read_receipts/read_by_list.dart
// Affiche les avatars des utilisateurs ayant lu le message (miniatures)

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
            backgroundImage: user.avatarUrl != null
                ? CachedNetworkImageProvider(user.avatarUrl!)
                : const AssetImage('assets/default_avatar.png') as ImageProvider,
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
