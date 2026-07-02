// lib/presentation/chat/online_status/last_seen_text.dart
// Texte "Vu à..." ou "En ligne"

import 'package:flutter/material.dart';
import '../core/chat_models.dart';

class LastSeenText extends StatelessWidget {
  final ChatUser user;

  const LastSeenText({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (user.status == 'online') {
      return const Text('En ligne', style: TextStyle(fontSize: 12, color: Colors.green));
    }
    if (user.lastSeen == null) {
      return const Text('Hors ligne', style: TextStyle(fontSize: 12, color: Colors.grey));
    }
    final now = DateTime.now();
    final diff = now.difference(user.lastSeen!);
    String text;
    if (diff.inDays > 0) {
      text = 'Vu le ${user.lastSeen!.day}/${user.lastSeen!.month}/${user.lastSeen!.year}';
    } else if (diff.inHours > 0) {
      text = 'Vu il y a ${diff.inHours} h';
    } else if (diff.inMinutes > 0) {
      text = 'Vu il y a ${diff.inMinutes} min';
    } else {
      text = 'Vu à l\'instant';
    }
    return Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey));
  }
}
