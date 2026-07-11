// lib/presentation/mon_pays/cards/government_card.dart
// Carte du Gouvernementcards/government_card.dart

import 'package:flutter/material.dart';
import '../models/government.dart';
import '../utils/helpers.dart';

class GovernmentCard extends StatelessWidget {
  final Government government;
  final VoidCallback onTap;

  const GovernmentCard({
    required this.government,
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
          backgroundImage: government.imageUrl != null && government.imageUrl!.isNotEmpty
              ? NetworkImage(government.imageUrl!)
              : null,
          backgroundColor: Colors.grey.shade300,
          child: government.imageUrl == null || government.imageUrl!.isEmpty
              ? Text(
                  MonPaysHelpers.getInitials(government.name),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A5276),
                  ),
                )
              : null,
        ),
        title: Text(
          government.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          government.primeMinister != null
              ? 'Premier Ministre: ${government.primeMinister}'
              : government.description,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (government.formationDate != null)
              Text(
                government.formationDate!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
