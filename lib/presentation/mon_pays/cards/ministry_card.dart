// lib/presentation/mon_pays/cards/ministry_card.dart
// Carte d'un Ministère

import 'package:flutter/material.dart';
import '../models/ministry.dart';
import '../utils/helpers.dart';

class MinistryCard extends StatelessWidget {
  final Ministry ministry;
  final VoidCallback onTap;

  const MinistryCard({
    required this.ministry,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          radius: 28,
          backgroundImage: ministry.imageUrl != null && ministry.imageUrl!.isNotEmpty
              ? NetworkImage(ministry.imageUrl!)
              : null,
          backgroundColor: Colors.grey.shade300,
          child: ministry.imageUrl == null || ministry.imageUrl!.isEmpty
              ? Text(
                  MonPaysHelpers.getInitials(ministry.name),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A5276),
                  ),
                )
              : null,
        ),
        title: Text(
          ministry.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          ministry.minister != null
              ? 'Ministre: ${ministry.minister}'
              : ministry.description,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey.shade400,
        ),
        onTap: onTap,
      ),
    );
  }
}
