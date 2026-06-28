// lib/presentation/network/widgets/post_actions_bar.dart
import 'package:flutter/material.dart';

class PostActionsBar extends StatelessWidget {
  final Map<String, int> reactions;
  final String? userReaction;
  final int comments;
  final bool isBookmarked;
  final void Function(String type)? onReact;
  final VoidCallback? onComments;
  final VoidCallback? onShare;
  final VoidCallback? onToggleBookmark;

  const PostActionsBar({
    Key? key,
    required this.reactions,
    required this.userReaction,
    required this.comments,
    required this.isBookmarked,
    this.onReact,
    this.onComments,
    this.onShare,
    this.onToggleBookmark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // reaction summary: show top reaction count
    final sorted = reactions.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topReaction = sorted.isNotEmpty ? '${sorted.first.key} ${sorted.first.value}' : '';

    return Row(
      children: [
        // Reaction button with popup menu
        GestureDetector(
          onTap: () => onReact?.call(userReaction == 'like' ? 'none' : 'like'),
          onLongPress: () async {
            final selected = await showMenu<String>(
              context: context,
              position: const RelativeRect.fromLTRB(100, 100, 0, 0),
              items: const [
                PopupMenuItem(value: 'like', child: Text('👍 J’aime')),
                PopupMenuItem(value: 'love', child: Text('❤️ Love')),
                PopupMenuItem(value: 'clap', child: Text('👏 Applaudir')),
                PopupMenuItem(value: 'celebrate', child: Text('🎉 Célébrer')),
                PopupMenuItem(value: 'insightful', child: Text('💡 Pertinent')),
              ],
            );
            if (selected != null) onReact?.call(selected);
          },
          child: Row(
            children: [
              Icon(userReaction != null ? Icons.thumb_up : Icons.thumb_up_off_alt, color: userReaction != null ? Colors.blue : null),
              const SizedBox(width: 6),
              Text(topReaction.isEmpty ? 'J\'aime' : topReaction),
            ],
          ),
        ),
        const SizedBox(width: 16),
        IconButton(onPressed: onComments, icon: const Icon(Icons.comment_outlined)),
        Text('$comments'),
        const Spacer(),
        IconButton(onPressed: onShare, icon: const Icon(Icons.share_outlined)),
        IconButton(onPressed: onToggleBookmark, icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_outline)),
      ],
    );
  }
}
