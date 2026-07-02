// lib/presentation/chat/home_widgets/chat_home_appbar.dart
// AppBar personnalisée pour l'écran d'accueil du chat

import 'package:flutter/material.dart';

class ChatHomeAppbar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onSearchTap;
  final VoidCallback? onSettingsTap;

  const ChatHomeAppbar({
    Key? key,
    this.onSearchTap,
    this.onSettingsTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text(
        'THIX CHAT',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.search_outlined),
          onPressed: onSearchTap ?? () {},
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: onSettingsTap ?? () {},
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
