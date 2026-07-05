// lib/presentation/feed/post_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thix_id/models/network_post.dart';
import 'package:thix_id/services/network_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostCard extends StatelessWidget {
  final NetworkPost post;
  final String currentProfileId;          // 👈 Paramètre requis
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onSave;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PostCard({
    Key? key,
    required this.post,
    required this.currentProfileId,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onSave,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isOwner = post.authorId == currentProfileId;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── HEADER ───
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
                // ─── MENU ───
                if (isOwner)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditDialog(context);
                      } else if (value == 'delete') {
                        _showDeleteConfirmation(context);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Modifier'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Supprimer', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {},
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // ─── CONTENU ───
            if (post.content.isNotEmpty)
              Text(post.content, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),

            // ─── MÉDIAS ───
            if (post.mediaUrls.isNotEmpty)
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: post.mediaUrls.map((url) {
                  final isVideo = url.endsWith('.mp4') || url.endsWith('.mov') || url.endsWith('.avi');
                  return _buildMediaItem(url, isVideo);
                }).toList(),
              ),
            const SizedBox(height: 8),

            // ─── STATS ───
            Row(
              children: [
                Text('${post.likesCount} J\'aime${post.likesCount > 1 ? 's' : ''}'),
                const SizedBox(width: 16),
                Text('${post.commentsCount} Commentaire${post.commentsCount > 1 ? 's' : ''}'),
                const SizedBox(width: 16),
                Text('${post.sharesCount} Partage${post.sharesCount > 1 ? 's' : ''}'),
              ],
            ),
            const Divider(),

            // ─── ACTIONS ───
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                  label: 'J\'aime',
                  color: post.isLiked ? Colors.red : null,
                  onTap: onLike ?? () {
                    final networkService = context.read<NetworkService>();
                    if (post.isLiked) {
                      networkService.unlikePost(post.id);
                    } else {
                      networkService.likePost(post.id);
                    }
                  },
                ),
                _buildActionButton(
                  icon: Icons.comment,
                  label: 'Commenter',
                  onTap: onComment ?? () => _showCommentDialog(context),
                ),
                _buildActionButton(
                  icon: Icons.repeat,
                  label: 'Reposter',
                  onTap: () {
                    final networkService = context.read<NetworkService>();
                    networkService.repostPost(post.id);
                  },
                ),
                _buildActionButton(
                  icon: post.isSaved ? Icons.bookmark : Icons.bookmark_border,
                  label: 'Enregistrer',
                  color: post.isSaved ? Colors.blue : null,
                  onTap: onSave ?? () {
                    final networkService = context.read<NetworkService>();
                    if (post.isSaved) {
                      networkService.unsavePost(post.id);
                    } else {
                      networkService.savePost(post.id);
                    }
                  },
                ),
                _buildActionButton(
                  icon: Icons.share,
                  label: 'Partager',
                  onTap: onShare ?? () {
                    final networkService = context.read<NetworkService>();
                    networkService.sharePost(post.id);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── MÉDIA ───
  Widget _buildMediaItem(String url, bool isVideo) {
    if (isVideo) {
      return Stack(
        children: [
          ClipRRect(
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
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black26,
              child: const Center(
                child: Icon(Icons.play_circle_filled, size: 40, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    }
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
  }

  // ─── ACTION BUTTON ───
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

  // ─── DIALOGUES ───

  void _showCommentDialog(BuildContext context) {
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
                onComment?.call();
              }
            },
            child: const Text('Publier'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: post.content);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier la publication'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nouveau contenu…'),
          maxLines: 5,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              final newContent = controller.text.trim();
              if (newContent.isNotEmpty && newContent != post.content) {
                final networkService = context.read<NetworkService>();
                await networkService.updatePost(post.id, newContent);
                if (context.mounted) Navigator.pop(context);
                onEdit?.call();
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la publication'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette publication ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              final networkService = context.read<NetworkService>();
              await networkService.deletePost(post.id);
              if (context.mounted) Navigator.pop(context);
              onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
