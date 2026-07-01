// lib/presentation/feed/comments_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// 🔽 Remplacer les imports
import 'package:thix_id/models/network_post.dart';
// Plus besoin de 'comment.dart' car NetworkService retourne des Map
import 'package:thix_id/presentation/feed/post_card.dart';
import 'package:thix_id/services/network_service.dart';

class CommentsPage extends StatefulWidget {
  final NetworkPost post;  // ← type corrigé
  final String currentProfileId;

  const CommentsPage({Key? key, required this.post, required this.currentProfileId}) : super(key: key);

  static Future<void> open(BuildContext context, {required NetworkPost post, required String currentProfileId}) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => CommentsPage(post: post, currentProfileId: currentProfileId)));
  }

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String, dynamic>> _comments = [];  // ← type modifié
  bool _loading = false;
  // RealtimeChannel? _sub; // Plus de stream pour les commentaires dans NetworkService

  @override
  void initState() {
    super.initState();
    _loadComments();
    // Le stream de commentaires n'est pas disponible dans NetworkService.
    // On peut éventuellement mettre en place un timer pour rafraîchir, mais on se contente du chargement initial
    // et du rechargement après envoi.
  }

  @override
  void dispose() {
    // _sub?.unsubscribe();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _loading = true);
    try {
      final svc = context.read<NetworkService>();
      final items = await svc.getComments(widget.post.id);  // ← utilise getComments
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
      final svc = context.read<NetworkService>();
      await svc.addComment(widget.post.id, text);  // ← utilise addComment de NetworkService
      _controller.clear();
      await _loadComments();
      // scroll to bottom
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent + 80, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Widget _buildComment(Map<String, dynamic> c) {
    // Les données sont sous forme de Map
    final user = c['users'] ?? {};
    final name = user['display_name']?.toString() ?? 'Utilisateur';
    final avatar = user['photo_url']?.toString() ?? '';
    final content = c['content']?.toString() ?? '';
    final createdAt = c['created_at']?.toString() ?? '';

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
        child: avatar.isEmpty ? const Icon(Icons.person) : null,
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(content),
          const SizedBox(height: 6),
          Text(createdAt, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
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
                const Divider(),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? const Center(child: Text('Aucun commentaire'))
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
                      decoration: const InputDecoration(
                        hintText: 'Écrire un commentaire...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.vertical()),
                      ),
                      minLines: 1,
                      maxLines: 4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _submitComment,
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
