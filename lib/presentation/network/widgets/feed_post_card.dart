// lib/presentation/network/widgets/feed_post_card.dart
import 'package:flutter/material.dart';
import 'package:thix_id/presentation/network/models/post_model.dart';
import 'package:thix_id/presentation/network/widgets/post_actions_bar.dart';

class FeedPostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback? onTapComments;
  final Future<void> Function(String type)? onReact;
  final VoidCallback? onShare;
  final VoidCallback? onToggleBookmark;

  const FeedPostCard({Key? key, required this.post, this.onTapComments, this.onReact, this.onShare, this.onToggleBookmark}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundImage: post.authorPhoto != null && post.authorPhoto!.isNotEmpty ? NetworkImage(post.authorPhoto!) : null, radius: 20, child: (post.authorPhoto == null || post.authorPhoto!.isEmpty) ? const Icon(Icons.person) : null),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.w800)), Text(post.timeAgo, style: const TextStyle(fontSize: 12))]),
                ),
                IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz))
              ],
            ),
            if (post.content.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(post.content),
            ],
            if (post.mediaUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: PageView(children: post.mediaUrls.map((u) => Image.network(u, fit: BoxFit.cover)).toList()),
              )
            ],
            const SizedBox(height: 8),
            PostActionsBar(
              reactions: post.reactionCounts,
              userReaction: post.userReaction,
              comments: post.commentCount,
              isBookmarked: post.isBookmarked,
              onComments: onTapComments,
              onReact: (type) async {
                if (onReact != null) await onReact(type);
              },
              onShare: onShare,
              onToggleBookmark: onToggleBookmark,
            ),
          ],
        ),
      ),
    );
  }
}
