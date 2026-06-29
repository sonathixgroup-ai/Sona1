// 📁 lib/presentation/thix_sante/common/widgets/custom_app_bar.dart

import 'package:flutter/material.dart';
import '../../shared/providers/role_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App Bar personnalisée avec avatar, notifications et icône de rôle
class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBackButton;
  final List<Widget>? actions;
  final bool showNotificationBadge;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final Color? backgroundColor;

  const CustomAppBar({
    Key? key,
    this.title,
    this.showBackButton = false,
    this.actions,
    this.showNotificationBadge = true,
    this.onNotificationTap,
    this.onProfileTap,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(roleProvider);
    final unreadCount = 3; // À connecter à votre provider de notifications

    return AppBar(
      backgroundColor: backgroundColor ?? Colors.white,
      elevation: 0,
      centerTitle: false,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 18, color: Color(0xFF1A1A1A)),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      title: title != null
          ? Text(
              title!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
                letterSpacing: -0.3,
              ),
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(role.icon, size: 18, color: Colors.green.shade700),
                ),
                const SizedBox(width: 8),
                Text(
                  'THIX SANTÉ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                    letterSpacing: -0.3,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    role.label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
      actions: actions ?? [
        if (showNotificationBadge)
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, size: 20, color: Color(0xFF1A1A1A)),
                onPressed: onNotificationTap ??
                    () {
                      // Naviguer vers notifications
                    },
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        IconButton(
          icon: const Icon(Icons.person_outline, size: 20, color: Color(0xFF1A1A1A)),
          onPressed: onProfileTap ??
              () {
                // Naviguer vers profil
              },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
