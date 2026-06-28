import 'package:flutter/material.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final String? avatarUrl;
  final bool isGroup;
  final int memberCount;
  final bool isOnline;
  final VoidCallback? onCall;
  final VoidCallback? onVideoCall;
  final VoidCallback? onInfo;
  final VoidCallback? onMore;

  const ChatAppBar({
    Key? key,
    required this.title,
    this.subtitle,
    this.avatarUrl,
    this.isGroup = false,
    this.memberCount = 0,
    this.isOnline = false,
    this.onCall,
    this.onVideoCall,
    this.onInfo,
    this.onMore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.grey),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: isGroup ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: isGroup ? BorderRadius.circular(6) : null,
              color: const Color(0xFF5A67D8),
              image: avatarUrl != null
                  ? DecorationImage(
                      image: NetworkImage(avatarUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: avatarUrl == null
                ? Center(
                    child: Text(
                      title[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isGroup
                      ? '$memberCount membres'
                      : isOnline
                          ? 'En ligne'
                          : 'Hors ligne',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (onCall != null)
          IconButton(
            icon: const Icon(Icons.call, color: Color(0xFF5A67D8)),
            onPressed: onCall,
          ),
        if (onVideoCall != null)
          IconButton(
            icon: const Icon(Icons.videocam, color: Color(0xFF5A67D8)),
            onPressed: onVideoCall,
          ),
        if (onInfo != null)
          IconButton(
            icon: const Icon(Icons.info_outline, color: Color(0xFF5A67D8)),
            onPressed: onInfo,
          ),
        if (onMore != null)
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onPressed: onMore,
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
