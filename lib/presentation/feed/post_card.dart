// lib/presentation/feed/post_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thix_id/models/network_post.dart';
import 'package:thix_id/services/network_service.dart';

class PostCard extends StatelessWidget {
  final NetworkPost post;
  final String currentProfileId;

  const PostCard({Key? key, required this.post, required this.currentProfileId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isLiked = post.isLiked;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: post.authorAvatar != null && post.authorAvatar!.isNotEmpty
                      ? NetworkImage(post.authorAvatar!)
                      : null,
                  child: Text(post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : '?'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (post.authorTitle != null && post.authorTitle!.isNotEmpty)
                        Text(post.authorTitle!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Content
            if (post.content.isNotEmpty)
              Text(post.content, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),

            // Images
            if (post.imageUrls.isNotEmpty)
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: post.imageUrls.map((url) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      url,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 8),

            // Stats
            Row(
              children: [
                Text('${post.likesCount} J\'aime${post.likesCount > 1 ? 's' : ''}'),
                const SizedBox(width: 16),
                Text('${post.commentsCount} Commentaire${post.commentsCount > 1 ? 's' : ''}'),
              ],
            ),
            const Divider(),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  label: 'J\'aime',
                  color: isLiked ? Colors.red : null,
                  onTap: () {
                    final networkService = context.read<NetworkService>();
                    if (isLiked) {
                      networkService.unlikePost(post.id);
                    } else {
                      networkService.likePost(post.id);
                    }
                  },
                ),
                _buildActionButton(
                  icon: Icons.comment,
                  label: 'Commenter',
                  onTap: () {
                    _showCommentDialog(context, post);
                  },
                ),
                _buildActionButton(
                  icon: Icons.share,
                  label: 'Partager',
                  onTap: () {
                    // Partager le post
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color ?? Colors.grey),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color ?? Colors.grey)),
          ],
        ),
      ),
    );
  }

  void _showCommentDialog(BuildContext context, NetworkPost post) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un commentaire'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Écrivez votre commentaire…'),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              final content = controller.text.trim();
              if (content.isNotEmpty) {
                final networkService = context.read<NetworkService>();
                await networkService.addComment(post.id, content);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Publier'),
          ),
        ],
      ),
    );
  }
}
