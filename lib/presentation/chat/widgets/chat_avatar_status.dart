import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/chat/user_status.dart';

class _C {
  static const bg = Colors.white;
  static const searchBg = Color(0xFFF8FAFC);
  static const border = Color(0xFFE2E8F0);
  static const textMuted = Color(0xFF64748B);
  static const textMain = Color(0xFF0F172A);
}

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
        clipBehavior: Clip.none,
        children: [
          Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              color: _C.searchBg,
              shape: BoxShape.circle,
              border: Border.all(color: _C.bg, width: 2),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
              image: imageUrl != null
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(imageUrl!, maxWidth: (radius * 2 * 2).toInt()),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageUrl == null
                ? Center(child: Icon(Icons.person_rounded, size: radius * 0.9, color: _C.textMuted))
                : null,
          ),
          Positioned(
            bottom: -1,
            right: -1,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: _C.bg, shape: BoxShape.circle),
              child: UserStatus.presenceIndicator(status, size: radius * 0.55),
            ),
          ),
        ],
      ),
    );
  }
}
