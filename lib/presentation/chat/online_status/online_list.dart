// lib/presentation/chat/online_status/online_list.dart
// Liste des contacts actuellement en ligne (pour l'écran d'accueil ou tiroir)

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/chat_models.dart';

class OnlineList extends StatelessWidget {
  final List<ChatUser> onlineUsers;

  const OnlineList({Key? key, required this.onlineUsers}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (onlineUsers.isEmpty) {
      return const Center(child: Text('Aucun contact en ligne'));
    }
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: onlineUsers.length,
        itemBuilder: (context, index) {
          final user = onlineUsers[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: user.avatarUrl != null
                          ? CachedNetworkImageProvider(user.avatarUrl!)
                          : const AssetImage('assets/default_avatar.png') as ImageProvider,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: StatusIndicator(isOnline: true, radius: 8),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(user.displayName, style: const TextStyle(fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }
}
