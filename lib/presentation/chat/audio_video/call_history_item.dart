// lib/presentation/chat/audio_video/call_history_item.dart
// Élément de l'historique des appels (dans une liste)

import 'package:flutter/material.dart';

enum CallType { audio, video }
enum CallDirection { incoming, outgoing, missed }

class CallHistoryItem extends StatelessWidget {
  final String contactName;
  final String? avatarUrl;
  final CallType type;
  final CallDirection direction;
  final DateTime timestamp;
  final int durationSeconds; // 0 si non décroché
  final VoidCallback onTap;

  const CallHistoryItem({
    Key? key,
    required this.contactName,
    this.avatarUrl,
    required this.type,
    required this.direction,
    required this.timestamp,
    required this.durationSeconds,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor;
    if (direction == CallDirection.missed) {
      icon = Icons.call_missed;
      iconColor = Colors.red;
    } else if (direction == CallDirection.incoming) {
      icon = Icons.call_received;
      iconColor = Colors.green;
    } else {
      icon = Icons.call_made;
      iconColor = Colors.blue;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: avatarUrl != null
            ? NetworkImage(avatarUrl!)
            : const AssetImage('assets/default_avatar.png') as ImageProvider,
        child: avatarUrl == null ? Text(contactName[0]) : null,
      ),
      title: Text(contactName),
      subtitle: Text(
        '${_formatTime(timestamp)} • ${_durationString(durationSeconds)} • ${type == CallType.audio ? 'Audio' : 'Vidéo'}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Icon(icon, color: iconColor),
      onTap: onTap,
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return 'Aujourd\'hui ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  String _durationString(int seconds) {
    if (seconds == 0) return 'Sans réponse';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return 'Durée ${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
