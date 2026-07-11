// lib/presentation/mon_pays/cards/authority_card.dart
// Carte d'une autorité pour les listes

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/authority.dart';
import '../providers/favorites_provider.dart';
import '../utils/helpers.dart';

class AuthorityCard extends ConsumerWidget {
  final Authority authority;
  final VoidCallback onTap;

  const AuthorityCard({
    required this.authority,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(favoritesProvider).contains(authority.id);

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
          backgroundImage: authority.imageUrl != null && authority.imageUrl!.isNotEmpty
              ? NetworkImage(authority.imageUrl!)
              : null,
          backgroundColor: Colors.grey.shade300,
          child: authority.imageUrl == null || authority.imageUrl!.isEmpty
              ? Text(
                  MonPaysHelpers.getInitials(authority.name),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A5276),
                  ),
                )
              : null,
        ),
        title: Text(
          authority.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          authority.title,
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
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.grey.shade400,
                size: 22,
              ),
              onPressed: () {
                ref.read(favoritesProvider.notifier).toggleFavorite(authority.id);
              },
            ),
            IconButton(
              icon: Icon(
                Icons.share,
                size: 22,
                color: Colors.grey.shade400,
              ),
              onPressed: () {
                // TODO: Implémenter le partage
              },
            ),
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
