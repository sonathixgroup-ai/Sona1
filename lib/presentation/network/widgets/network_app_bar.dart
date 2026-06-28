// lib/presentation/network/widgets/network_app_bar.dart
import 'package:flutter/material.dart';
import 'package:thix_id/presentation/network/components/user_avatar.dart';
import 'package:thix_id/presentation/network/utils/network_colors.dart';

class NetworkAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NetworkAppBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: NetworkColors.primary,
      elevation: 0,
      titleSpacing: 16,
      title: Row(
        children: const [
          UserAvatar(size: 36),
          SizedBox(width: 12),
          Text('THIX RÉSEAU PRO', style: TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
      actions: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
        IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}
