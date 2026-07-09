// [Code complet de comments_page.dart]
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:thix_id/models/network_post.dart';
import 'package:thix_id/services/network_service.dart';
import 'package:thix_id/presentation/network/widgets/post_card.dart';
import 'package:thix_id/auth/auth_controller.dart';

class CommentsPage extends StatefulWidget {
  final String postId;
  final String currentProfileId;

  const CommentsPage({super.key, required this.postId, required this.currentProfileId});

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _comments = [];
  NetworkPost? _post;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final networkService = context.read<NetworkService>();
      final post = await networkService.getPostById(widget.postId);
      final items = await networkService.getComments(widget.postId);
      if (mounted) setState(() { _post = post; _comments = items; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSubmitting = true);
    await context.read<NetworkService>().addComment(widget.postId, text);
    _controller.clear();
    await _loadData();
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(title: const Text('Commentaires', style: TextStyle(color: Colors.black)), backgroundColor: Colors.white),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : Column(
        children: [
          // Post restreint en hauteur pour laisser place aux commentaires
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
            child: Container(color: Colors.white, child: PostCard(post: _post!, currentProfileId: widget.currentProfileId)),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _comments.length,
              itemBuilder: (context, index) {
                final c = _comments[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        CircleAvatar(radius: 16, backgroundImage: c['user_avatar'] != null ? NetworkImage(c['user_avatar']) : null),
                        const SizedBox(width: 8),
                        Text(c['user_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 8),
                      Text(c['content']),
                      Row(children: [
                        TextButton(onPressed: () {}, child: const Text("J'aime", style: TextStyle(fontSize: 12))),
                        TextButton(onPressed: () => _controller.text = "@${c['user_name']} ", child: const Text("Répondre", style: TextStyle(fontSize: 12))),
                      ])
                    ],
                  ),
                );
              },
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildInput() => Container(
    padding: const EdgeInsets.all(12),
    color: Colors.white,
    child: Row(children: [
      Expanded(child: TextField(controller: _controller, decoration: const InputDecoration(hintText: 'Commenter...'))),
      IconButton(icon: const Icon(Icons.send), onPressed: _submitComment),
    ]),
  );
}
