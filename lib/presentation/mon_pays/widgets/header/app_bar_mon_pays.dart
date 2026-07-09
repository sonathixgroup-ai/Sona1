// lib/presentation/mon_pays/widgets/header/app_bar_mon_pays.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'search_bar.dart';
import 'notification_icon.dart';
import 'profile_avatar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class MonPaysAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showSearch;
  final VoidCallback? onSearchToggle;

  const MonPaysAppBar({
    Key? key,
    this.showSearch = false,
    this.onSearchToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primaryWhite,
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          // Logo / Titre institutionnel
          _buildLogo(),
          const Spacer(),
          // Barre de recherche (si visible)
          if (showSearch)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: MonPaysSearchBar(
                  onSearch: (query) {
                    // La recherche sera gérée par le contrôleur
                    Get.find<MonPaysController>().search(query);
                  },
                ),
              ),
            ),
          // Icône de notification
          NotificationIcon(
            onTap: () {
              // Navigation vers la page des notifications
            },
            count: 3, // à récupérer depuis un service
          ),
          const SizedBox(width: 8),
          // Avatar du profil
          ProfileAvatar(
            onTap: () {
              // Navigation vers le profil
            },
            imageUrl: null, // ou l'URL de l'utilisateur
            name: 'Utilisateur',
          ),
        ],
      ),
      actions: [
        // Si on veut un bouton pour basculer la recherche
        if (!showSearch)
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.primaryBlue),
            onPressed: onSearchToggle ??
                () {
                  // Par défaut, on bascule l'état de recherche dans le contrôleur
                  // ou on navigue vers une page de recherche dédiée
                },
          ),
      ],
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        // Image du logo (à remplacer par votre asset)
        Image.asset(
          'assets/images/logo_rdc.png',
          height: 40,
          width: 40,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.flag,
            color: AppColors.primaryRed,
            size: 32,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Mon Pays',
              style: AppTextStyles.heading6.copyWith(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'République Démocratique du Congo',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primaryRed,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
