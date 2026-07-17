
// lib/presentation/network/post_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/services/network_service.dart';
import 'package:thix_id/models/network_post.dart';
import 'widgets/report_dialog.dart';

class PostDetailPage extends StatefulWidget {
  final String postId;
  const PostDetailPage({super.key, required this.postId});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  late NetworkService _networkService;
  NetworkPost? _post;
  List<Map<String, dynamic>> _comments = [];
  bool _loading = true;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    debugPrint('🔍 PostDetailPage - postId reçu: ${widget.postId}');
    _networkService = NetworkService(Supabase.instance.client);
    _loadData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      debugPrint('🔍 Chargement post: ${widget.postId}');
      final post = await _networkService.getPostById(widget.postId);
      debugPrint('🔍 Post chargé: ${post != null}');
      if (post != null) {
        debugPrint('🔍 Contenu du post: ${post.content}');
        debugPrint('🔍 Auteur du post: ${post.authorName}');
      } else {
        debugPrint('❌ Post est NULL! Vérifie l\'ID: ${widget.postId}');
      }
      final comments = await _networkService.getComments(widget.postId);
      debugPrint('🔍 Commentaires chargés: ${comments.length}');
      setState(() {
        _post = post;
        _comments = comments;
      });
    } catch (e) {
      debugPrint('❌ Error loading post: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    _commentController.clear();
    await _networkService.addComment(widget.postId, content);
    await _loadData();
  }

  // ⭐ CORRIGÉ - Utilisation dynamique pour isLikedByCurrentUser
  Future<void> _toggleLike() async {
    if (_post == null) return;
    final dynamicPost = _post as dynamic;
    final isLiked = dynamicPost.isLikedByCurrentUser ?? false;
    
    if (isLiked) {
      await _networkService.unlikePost(widget.postId);
    } else {
      await _networkService.likePost(widget.postId);
    }
    await _loadData();
  }

  // ==================== GESTION DU POST ====================

  Future<void> _editPost() async {
    final controller = TextEditingController(text: _post?.content);
    final newContent = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier la publication'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Modifiez votre publication...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    
    if (newContent != null && newContent != _post?.content) {
      await _networkService.updatePost(widget.postId, newContent);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publication modifiée'), backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> _deletePost() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la publication'),
        content: const Text('Voulez-vous vraiment supprimer cette publication ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await _networkService.deletePost(widget.postId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publication supprimée'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _hidePost() async {
    await _networkService.hidePost(widget.postId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publication masquée'), backgroundColor: Colors.orange),
      );
      Navigator.pop(context);
    }
  }

  void _reportPost() {
    showDialog(
      context: context,
      builder: (_) => ReportDialog(
        contentType: 'post',
        contentId: widget.postId,
        reportedUserId: _post?.userId,
        postId: widget.postId,
      ),
    );
  }

  // ==================== GESTION DES COMMENTAIRES ====================

  Future<void> _deleteComment(String commentId, String commentUserId) async {
    final auth = Provider.of<AuthController>(context, listen: false);
    final isOwner = auth.currentUser?.id == commentUserId;
    
    if (!isOwner) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le commentaire'),
        content: const Text('Voulez-vous vraiment supprimer ce commentaire ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await _networkService.deleteComment(commentId);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commentaire supprimé'), backgroundColor: Colors.green),
        );
      }
    }
  }

  void _reportComment(Map<String, dynamic> comment) {
    showDialog(
      context: context,
      builder: (_) => ReportDialog(
        contentType: 'comment',
        contentId: comment['id'],
        reportedUserId: comment['user_id'],
        postId: widget.postId,
      ),
    );
  }

  // ==================== OPTIONS ====================

  void _showPostOptions() {
    final auth = Provider.of<AuthController>(context, listen: false);
    final isOwner = auth.currentUser?.id == _post?.userId;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            if (isOwner) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Gérer ma publication', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Modifier'),
                onTap: () {
                  Navigator.pop(context);
                  _editPost();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deletePost();
                },
              ),
              const Divider(),
            ],
            ListTile(
              leading: const Icon(Icons.visibility_off, color: Colors.orange),
              title: const Text('Masquer cette publication'),
              onTap: () {
                Navigator.pop(context);
                _hidePost();
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.red),
              title: const Text('Signaler', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _reportPost();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ==================== UI ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Publication', style: TextStyle(color: Color(0xFF0B1B3D), fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF0B1B3D)),
            onPressed: _showPostOptions,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _post == null
              ? const Center(child: Text('Publication non trouvée'))
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPostCard(),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),
                            Text(
                              'Commentaires (${_comments.length})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 12),
                            ..._comments.map((c) => _buildCommentCard(c)),
                            if (_comments.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(32),
                                child: Center(child: Text('Aucun commentaire pour le moment')),
                              ),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                    _buildCommentInput(),
                  ],
                ),
    );
  }

  // ⭐ CORRIGÉ - Utilisation dynamique pour toutes les propriétés
  Widget _buildPostCard() {
    final dynamicPost = _post as dynamic;
    
    // Récupération sécurisée des propriétés manquantes
    final mediaUrl = dynamicPost.mediaUrl;
    final isLikedByCurrentUser = dynamicPost.isLikedByCurrentUser ?? false;
    final sharesCount = dynamicPost.sharesCount ?? 0;
    
    final hasImage = mediaUrl != null && mediaUrl.toString().isNotEmpty;
    final hasContent = _post!.content != null && _post!.content!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: _post!.authorAvatar != null && _post!.authorAvatar!.isNotEmpty
                    ? NetworkImage(_post!.authorAvatar!)
                    : null,
                child: _post!.authorAvatar == null || _post!.authorAvatar!.isEmpty
                    ? const Icon(Icons.person, size: 24)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_post!.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    if (_post!.authorTitle != null && _post!.authorTitle!.isNotEmpty)
                      Text(_post!.authorTitle!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Text(_formatTime(_post!.createdAt), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
          const SizedBox(height: 12),
          
          // Contenu
          if (hasContent)
            Text(_post!.content!, style: const TextStyle(fontSize: 15, height: 1.4)),
          
          // Image
          if (hasImage) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                mediaUrl.toString(),
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 250,
                    color: Colors.grey.shade200,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 250,
                  color: Colors.grey.shade200,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 50, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Image non disponible', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 12),
          
          // Actions
          Row(
            children: [
              _buildActionButton(
                icon: isLikedByCurrentUser ? Icons.favorite : Icons.favorite_border,
                label: _formatCount(_post!.likesCount),
                color: isLikedByCurrentUser ? Colors.red : null,
                onTap: _toggleLike,
              ),
              const SizedBox(width: 24),
              _buildActionButton(
                icon: Icons.comment_outlined,
                label: _formatCount(_post!.commentsCount),
                onTap: () {},
              ),
              const SizedBox(width: 24),
              _buildActionButton(
                icon: Icons.share_outlined,
                label: _formatCount(sharesCount),
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(Map<String, dynamic> comment) {
    final auth = Provider.of<AuthController>(context, listen: false);
    final isOwner = auth.currentUser?.id == comment['user_id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: comment['user_avatar'] != null 
                ? NetworkImage(comment['user_avatar'])
                : null,
            child: comment['user_avatar'] == null 
                ? const Icon(Icons.person, size: 16) 
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(comment['user_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 8),
                    Text(_formatTime(DateTime.parse(comment['created_at'])), style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment['content'], style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_horiz, size: 18, color: Colors.grey),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'report', child: Row(children: [Icon(Icons.flag, size: 18), SizedBox(width: 8), Text('Signaler')])),
              if (isOwner) const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Supprimer', style: TextStyle(color: Colors.red))])),
            ],
            onSelected: (value) {
              if (value == 'report') {
                _reportComment(comment);
              } else if (value == 'delete') {
                _deleteComment(comment['id'], comment['user_id']);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Écrire un commentaire...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _addComment,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(color: Color(0xFFD4AF37), shape: BoxShape.circle),
              child: const Icon(Icons.send, size: 20, color: Color(0xFF0B1B3D)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return 'il y a ${diff.inDays}j';
    if (diff.inHours > 0) return 'il y a ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'il y a ${diff.inMinutes}min';
    return 'à l\'instant';
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}
