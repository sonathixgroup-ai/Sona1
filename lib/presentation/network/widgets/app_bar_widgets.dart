import 'package:flutter/material.dart';

/// Badge d'identité sécurisée THIX ID
class ThixIdentityBadge extends StatelessWidget {
  const ThixIdentityBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.verified, size: 14, color: Colors.amber),
          SizedBox(width: 4),
          Text(
            'THIX ID',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
        ],
      ),
    );
  }
}

/// AppBar personnalisée du réseau professionnel
class NetworkAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationTap;

  const NetworkAppBar({
    super.key,
    this.onSearchTap,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      title: Row(
        children: [
          const Text(
            'DreamFlow',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A73E8),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF1A73E8).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Réseau Pro',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A73E8),
              ),
            ),
          ),
        ],
      ),
      actions: [
        const ThixIdentityBadge(),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.search, size: 20),
          onPressed: onSearchTap ?? () {},
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined, size: 20),
          onPressed: onNotificationTap ?? () {},
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
