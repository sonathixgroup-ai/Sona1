// lib/presentation/chat/widgets/chat_avatar_status.dart
import 'package:flutter/material.dart';
import '../../../models/chat/user_status.dart';

class ChatAvatarStatus extends StatelessWidget {
  final String? imageUrl;
  final String status;
  final double radius;
  final VoidCallback? onTap;

  const ChatAvatarStatus({
    super.key,
    this.imageUrl,
    this.status = UserStatus.offline,
    this.radius = 24,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          CircleAvatar(
            radius: radius,
            backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
            child: imageUrl == null
                ? Icon(Icons.person, size: radius, color: Colors.grey[400])
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: UserStatus.presenceIndicator(status, size: radius * 0.5),
          ),
        ],
      ),
    );
  }
}
