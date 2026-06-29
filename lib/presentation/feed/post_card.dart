// lib/presentation/feed/post_card.dart
import 'package:flutter/material.dart';
import 'package:thix_id/models/post.dart';
import 'package:thix_id/services/post_service.dart';
import 'package:provider/provider.dart';
import 'package:thix_id/utils/time_ago.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final String currentProfileId;

  const PostCard({Key? key, required this.post, required this.currentProfileId}) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _liked = false;
  int _likes = 0;

  @override
  void initState() {
    super.initState();
    _likes = widget.post.likeCount;
  }

  Future<void> _toggleLike() async {
    final svc = context.read<PostService>();
    try {
      if (_liked) {
        await svc.unlikePost(profileId: widget.currentProfileId, postId: widget.post.id);
        setState(() {
          _liked = false;
          _likes = (_likes - 1).clamp(0, 1 << 30);
        });
      } else {
        await svc.likePost(profileId: widget.currentProfileId, postId: widget.post.id);
        setState(() {
          _liked = true;
          _likes = _likes + 1;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final author = widget.post.author ?? {};
    final name = author['display_name'] ?? 'Utilisateur';
    final avatar = author['photo_url'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null, child: avatar.isEmpty ? Icon(Icons.person) : null),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(fontWeight: FontWeight.w800)),
                      Text(formatTimeAgo(widget.post.createdAt), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                PopupMenuButton(itemBuilder: (_) => [PopupMenuItem(child: Text('Signaler'))]),
              ],
            ),
            if (widget.post.content.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(widget.post.content),
            ],
            if (widget.post.media.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: PageView(
                  children: widget.post.media.map((m) => Image.network(m.url, fit: BoxFit.cover)).toList(),
                ),
              )
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(icon: Icon(_liked ? Icons.thumb_up : Icons.thumb_up_off_alt), onPressed: _toggleLike),
                Text('$_likes'),
                const SizedBox(width: 16),
                IconButton(icon: Icon(Icons.comment_outlined), onPressed: () {}),
                const Spacer(),
                IconButton(icon: Icon(Icons.share_outlined), onPressed: () {}),
              ],
            )
          ],
        ),
      ),
    );
  }
}
