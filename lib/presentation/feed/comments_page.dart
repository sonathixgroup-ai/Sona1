// lib/presentation/feed/comments_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thix_id/models/post.dart';
import 'package:thix_id/models/comment.dart';
import 'package:thix_id/presentation/feed/post_card.dart';
import 'package:thix_id/services/post_service.dart';

class CommentsPage extends StatefulWidget {
  final Post post;
  final String currentProfileId;

  const CommentsPage({Key? key, required this.post, required this.currentProfileId}) : super(key: key);

  static Future<void> open(BuildContext context, {required Post post, required String currentProfileId}) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => CommentsPage(post: post, currentProfileId: currentProfileId)));
  }

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  List<Comment> _comments = [];
  bool _loading = false;
  RealtimeSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _loadComments();
    final svc = context.read<PostService>();
    _sub = svc.streamComments(postId: widget.post.id, onData: (comments) {
      if (mounted) setState(() => _comments = comments);
    });
  }

  @override
  void dispose() {
    _sub?.unsubscribe();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _loading = true);
    try {
      final svc = context.read<PostService>();
      final items = await svc.fetchComments(postId: widget.post.id);
      if (mounted) setState(() => _comments = items);
    } catch (e) {
      debugPrint('CommentsPage._loadComments error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    try {
      final svc = context.read<PostService>();
      await svc.addComment(profileId: widget.currentProfileId, postId: widget.post.id, content: text);
      _controller.clear();
      await _loadComments();
      // scroll to bottom
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent + 80, duration: Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Widget _buildComment(Comment c) {
    final author = c.author ?? {};
    final name = author['display_name'] ?? 'Utilisateur';
    final avatar = author['photo_url'] ?? '';

    return ListTile(
      leading: CircleAvatar(backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null, child: avatar.isEmpty ? Icon(Icons.person) : null),
      title: Text(name, style: TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(c.content),
          const SizedBox(height: 6),
          Text('${c.createdAt}', style: TextStyle(fontSize: 11, color: Colors.grey[600]))
        ],
      ),
      isThreeLine: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Commentaires')),
      body: Column(
        children: [
          // show post summary
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                PostCard(post: widget.post, currentProfileId: widget.currentProfileId),
                const SizedBox(height: 8),
                Divider()
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? Center(child: Text('Aucun commentaire'))
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(8),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) => _buildComment(_comments[index]),
                      ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(hintText: 'Écrire un commentaire...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                      minLines: 1,
                      maxLines: 4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: _submitComment, child: Icon(Icons.send))
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
