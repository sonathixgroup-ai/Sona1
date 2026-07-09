// lib/presentation/mon_pays/widgets/app_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/mon_pays_colors.dart';
import '../utils/mon_pays_text_styles.dart'; // (à définir)
import 'search_bar.dart';
import 'notification_button.dart';
import 'profile_avatar.dart';

class MonPaysAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final VoidCallback? onSearchToggle;
  final bool showSearch;
  final String? title;

  const MonPaysAppBar({
    Key? key,
    this.onSearchToggle,
    this.showSearch = false,
    this.title = 'Mon Pays',
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      backgroundColor: MonPaysColors.primaryWhite,
      elevation: 0,
      title: Row(
        children: [
          Image.asset(
            'assets/images/logo_rdc.png',
            height: 30,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.flag,
              color: MonPaysColors.primaryRed,
              size: 30,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title!,
            style: MonPaysTextStyles.heading6.copyWith(
              color: MonPaysColors.primaryBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        if (!showSearch)
          IconButton(
            icon: Icon(Icons.search, color: MonPaysColors.primaryBlue),
            onPressed: onSearchToggle,
          ),
        const NotificationButton(),
        const ProfileAvatar(),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
