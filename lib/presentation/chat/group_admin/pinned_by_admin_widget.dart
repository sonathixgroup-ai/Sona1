// lib/presentation/chat/group_admin/pinned_by_admin_widget.dart
// Widget affichant un message épinglé par un administrateur (avec mise en avant)

import 'package:flutter/material.dart';

class PinnedByAdminWidget extends StatelessWidget {
  final String adminName;
  final String content;
  final DateTime pinnedAt;
  final VoidCallback onTap;

  const PinnedByAdminWidget({
    Key? key,
    required this.adminName,
    required this.content,
    required this.pinnedAt,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          border: Border(bottom: BorderSide(color: Colors.blue.shade200)),
        ),
        child: Row(
          children: [
            const Icon(Icons.push_pin, size: 16, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Épinglé par $adminName',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  const SizedBox(height: 2),
                  Text(content, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            Text(_formatTime(pinnedAt), style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}
