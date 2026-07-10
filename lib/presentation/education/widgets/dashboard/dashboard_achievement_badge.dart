// lib/presentation/education/widgets/dashboard/dashboard_achievement_badge.dart
import 'package:flutter/material.dart';

class DashboardAchievementBadge extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? color;
  final bool isUnlocked;
  final VoidCallback? onTap;

  const DashboardAchievementBadge({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.color,
    this.isUnlocked = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color badgeColor = color ?? const Color(0xFFE3B23C);
    final bool locked = !isUnlocked;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: locked ? Colors.grey[100] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: locked ? Colors.grey[200]! : badgeColor.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: locked
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF0A1F44).withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: locked ? Colors.grey[200] : badgeColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: locked ? Colors.grey[400] : badgeColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: locked ? Colors.grey[500] : const Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    locked ? '🔒 Verrouillé' : subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: locked ? Colors.grey[400] : const Color(0xFF7386A8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!locked)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF2ECC71),
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}
