// lib/presentation/chat/widgets/chat_stats_row.dart
import 'package:flutter/material.dart';
import '../core/chat_models.dart';

class ChatStatsRow extends StatelessWidget {
  final ChatStats stats;

  const ChatStatsRow({Key? key, required this.stats}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem('${stats.onlineCount}', 'En ligne', Icons.circle, Colors.green),
          _StatItem('${stats.newMessagesCount}', 'Nouveaux messages', Icons.message_outlined, Colors.blue),
          _StatItem('${stats.activeMeetingsCount}', 'Réunions actives', Icons.videocam_outlined, Colors.orange),
          _StatItem('${stats.securityAlertsCount}', 'Alertes sécurité', Icons.security_outlined, Colors.red),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatItem(this.value, this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
