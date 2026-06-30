// presentation/thix_sante/shared/widgets/health_header.dart
import 'package:flutter/material.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/presentation/thix_sante/thix_role.dart';

/// En-tête avec dégradé, bienvenue et informations utilisateur
class HealthHeader extends StatelessWidget {
  final ThixRole role;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onSwitchRoleTap;
  final String? subtitle;
  final bool showRole;

  const HealthHeader({
    super.key,
    required this.role,
    this.onNotificationsTap,
    this.onSwitchRoleTap,
    this.subtitle,
    this.showRole = true,
  });

  @override
  Widget build(BuildContext context) {
    final user = AuthController.instance.currentUser;
    final displayName = (user?.displayName ?? '').trim();
    final firstName = displayName.isEmpty ? 'Utilisateur' : displayName.split(RegExp(r'\s+')).first;
    final photoUrl = (user?.photoUrl ?? '').trim();

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
              // Menu de changement de rôle (optionnel)
              if (onSwitchRoleTap != null) ...[
                GestureDetector(
                  onTap: onSwitchRoleTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.menu, size: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              // Avatar utilisateur
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                child: photoUrl.isEmpty
                    ? Text(
                        firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // Texte de bienvenue
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
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle ?? 'Votre santé entre de bonnes mains',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Bouton notifications
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: onNotificationsTap ?? () {},
              ),
            ],
          ),
          // Affichage du rôle (optionnel)
          if (showRole) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
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
        ],
      ),
    );
  }
}
