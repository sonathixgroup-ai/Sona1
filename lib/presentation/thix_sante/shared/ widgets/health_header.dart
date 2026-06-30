// presentation/thix_sante/shared/widgets/health_header.dart
import 'package:flutter/material.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/presentation/thix_sante/thix_role.dart';

/// En-tête avec dégradé, bienvenue et informations utilisateur
class HealthHeader extends StatelessWidget {
  final ThixRole role;
  final VoidCallback? onNotificationsTap;

  const HealthHeader({
    super.key,
    required this.role,
    this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    final user = AuthController.instance.currentUser;
    final dn = (user?.displayName ?? '').trim();
    final firstName = dn.isEmpty ? 'Utilisateur' : dn.split(RegExp(r'\s+')).first;

    return Container(
      decoration: BoxDecoration(
        gradient: role.gradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white.withOpacity(0.3),
                child: Text(
                  firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour, $firstName 🧠',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Votre santé entre de bonnes mains',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: onNotificationsTap ?? () {},
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Affichage du rôle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(role.icon, size: 16, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  role.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
