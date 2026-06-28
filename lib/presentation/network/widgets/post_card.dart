import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../data/models/post_model.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onSave;

  const PostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: post.userAvatarUrl != null
                    ? NetworkImage(post.userAvatarUrl!)
                    : null,
                child: post.userAvatarUrl == null
                    ? Text(post.userName[0].toUpperCase())
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (post.userTitle != null)
                      Text(
                        post.userTitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    Row(
                      children: [
                        Text(
                          timeago.format(post.createdAt, locale: 'fr'),
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.public, size: 12, color: Colors.grey),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz, size: 18),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Contenu
          Text(
            post.content,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          if (post.mediaUrls != null && post.mediaUrls!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                post.mediaUrls!.first,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(Icons.error, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Stats
          Row(
            children: [
              Text(
                '${post.likesCount} J’aime',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const Spacer(),
              Text(
                '${post.commentsCount} commentaires · ${post.sharesCount} partages',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const Divider(height: 20),
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _actionButton(
                icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                label: 'J’aime',
                color: post.isLiked ? Colors.red : null,
                onTap: onLike,
              ),
              _actionButton(
                icon: Icons.comment_outlined,
                label: 'Commenter',
                onTap: onComment,
              ),
              _actionButton(
                icon: Icons.repeat_outlined,
                label: 'Reposter',
                onTap: () {},
              ),
              _actionButton(
                icon: Icons.share_outlined,
                label: 'Partager',
                onTap: onShare,
              ),
              _actionButton(
                icon: post.isSaved ? Icons.bookmark : Icons.bookmark_border,
                label: 'Enregistrer',
                color: post.isSaved ? Colors.blue : null,
                onTap: onSave,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color ?? Colors.grey.shade700),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color ?? Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
