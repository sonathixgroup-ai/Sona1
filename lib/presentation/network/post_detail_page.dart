import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thix_id/models/network_post.dart';
import 'package:thix_id/models/comment.dart';
import 'package:thix_id/services/network_service.dart';
import 'package:thix_id/presentation/network/widgets/post_card.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'widgets/report_dialog.dart'; // Assurez-vous que ce fichier existe

class PostDetailPage extends StatefulWidget {
  final String postId;
  final String currentProfileId;

  const PostDetailPage({
    super.key,
    required this.postId,
    required this.currentProfileId,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  NetworkPost? _post;
  List<Comment> _comments = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _replyingTo;
  String? _replyingToName;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final networkService = context.read<NetworkService>();
      final post = await networkService.getPostById(widget.postId);
      final comments = await networkService.getCommentsWithReplies(widget.postId);
      if (mounted) {
        setState(() {
          _post = post;
          _comments = comments;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement : $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  // ────────── Actions sur le post (utilisées par le PostCard) ──────────
  Future<void> _editPost() async {
    if (_post == null) return;
    final controller = TextEditingController(text: _post!.content);
    final newContent = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Modifier la publication'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Modifiez votre publication...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D6CDF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (newContent != null && newContent != _post!.content) {
      try {
        await context.read<NetworkService>().updatePost(widget.postId, newContent);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Publication modifiée'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _deletePost() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la publication'),
        content: const Text('Voulez-vous vraiment supprimer cette publication ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await context.read<NetworkService>().deletePost(widget.postId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Publication supprimée'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _hidePost() async {
    try {
      await context.read<NetworkService>().hidePost(widget.postId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publication masquée'), backgroundColor: Colors.orange),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
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

  void _sharePost() {
    // Implémentez le partage (ex. Share.share)
  }

  // ────────── Commentaires ──────────
  Future<void> _submitComment({String? parentId}) async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final networkService = context.read<NetworkService>();
      final newComment = await networkService.addComment(
        widget.postId,
        text,
        parentId: parentId,
      );
      setState(() {
        if (parentId == null) {
          _comments.insert(0, newComment);
        } else {
          _addReplyTo(_comments, parentId, newComment);
        }
      });
      _commentController.clear();
      _clearReply();
      _scrollController.animateTo(0, duration: Duration(milliseconds: 300), curve: Curves.easeOut);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  bool _addReplyTo(List<Comment> comments, String parentId, Comment reply) {
    for (int i = 0; i < comments.length; i++) {
      if (comments[i].id == parentId) {
        comments[i].replies.insert(0, reply);
        return true;
      }
      if (_addReplyTo(comments[i].replies, parentId, reply)) return true;
    }
    return false;
  }

  void _clearReply() {
    setState(() {
      _replyingTo = null;
      _replyingToName = null;
    });
  }

  Future<void> _toggleLikeComment(Comment comment) async {
    final oldLiked = comment.isLiked;
    final oldCount = comment.likesCount;
    setState(() {
      comment.isLiked = !oldLiked;
      comment.likesCount = oldLiked ? oldCount - 1 : oldCount + 1;
    });
    try {
      if (comment.isLiked) {
        await context.read<NetworkService>().likeComment(comment.id);
      } else {
        await context.read<NetworkService>().unlikeComment(comment.id);
      }
    } catch (e) {
      setState(() {
        comment.isLiked = oldLiked;
        comment.likesCount = oldCount;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _startReply(String userName, String commentId) {
    setState(() {
      _replyingTo = commentId;
      _replyingToName = userName;
    });
    _focusNode.requestFocus();
  }

  void _editComment(Comment comment) async {
    final controller = TextEditingController(text: comment.content);
    final newContent = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Modifier le commentaire'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Modifiez votre commentaire...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (newContent != null && newContent != comment.content) {
      try {
        await context.read<NetworkService>().updateComment(comment.id, newContent);
        setState(() => comment.content = newContent);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // ────────── UI ──────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Publication', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded, color: Colors.grey),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _post == null
              ? Center(child: Text('Publication introuvable', style: TextStyle(color: Colors.grey)))
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadData,
                        child: CustomScrollView(
                          controller: _scrollController,
                          slivers: [
                            // Post qui défile avec les commentaires
                            SliverToBoxAdapter(
                              child: PostCard(
                                post: _post!,
                                currentProfileId: widget.currentProfileId,
                                onRefresh: _loadData,
                                onEdit: _editPost,
                                onDelete: _deletePost,
                                onPin: () async {
                                  await context.read<NetworkService>().pinPost(widget.postId);
                                  _loadData();
                                },
                                onShare: _sharePost,
                                // onHide et onReport sont gérés dans le menu du PostCard,
                                // mais on peut les passer aussi si besoin.
                              ),
                            ),
                            // Commentaires
                            _comments.isEmpty
                                ? SliverFillRemaining(
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.comment_outlined, size: 60, color: Colors.grey[300]),
                                          const SizedBox(height: 12),
                                          Text('Aucun commentaire', style: TextStyle(color: Colors.grey[600])),
                                          const SizedBox(height: 8),
                                          Text('Soyez le premier à réagir !', style: TextStyle(color: Colors.grey[400])),
                                        ],
                                      ),
                                    ),
                                  )
                                : SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) => _buildCommentTile(_comments[index], isRoot: true),
                                      childCount: _comments.length,
                                    ),
                                  ),
                            // Espace pour ne pas être collé à la barre du bas
                            const SliverToBoxAdapter(child: SizedBox(height: 80)),
                          ],
                        ),
                      ),
                    ),
                    _buildInputBar(),
                  ],
                ),
    );
  }

  Widget _buildCommentTile(Comment comment, {bool isRoot = true}) {
    final auth = context.read<AuthController>();
    final isOwn = comment.userId == auth.currentUser?.id;
    final hasReplies = comment.replies.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(left: isRoot ? 16 : 24, right: 16, bottom: 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              leading: CircleAvatar(
                radius: 18,
                backgroundImage: comment.userAvatar != null && comment.userAvatar!.isNotEmpty
                    ? NetworkImage(comment.userAvatar!)
                    : null,
                child: comment.userAvatar == null || comment.userAvatar!.isEmpty
                    ? Icon(Icons.person, size: 18, color: Colors.grey[600])
                    : null,
              ),
              title: Row(
                children: [
                  Text(comment.userName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(
                    timeago.format(comment.createdAt, locale: 'fr'),
                    style: TextStyle(color: Colors.grey[500], fontSize: 10),
                  ),
                ],
              ),
              trailing: PopupMenuButton(
                icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                onSelected: (value) {
                  // actions gérées localement si besoin
                },
                itemBuilder: (context) => [
                  if (isOwn)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('Supprimer', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(Icons.flag_outlined, color: Colors.orange, size: 18),
                        SizedBox(width: 8),
                        Text('Signaler'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(comment.content, style: const TextStyle(fontSize: 14, height: 1.4)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  _actionButton(
                    icon: comment.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    iconColor: comment.isLiked ? Colors.red : Colors.grey[600]!,
                    label: comment.likesCount > 0 ? '${comment.likesCount}' : '',
                    onTap: () => _toggleLikeComment(comment),
                  ),
                  const SizedBox(width: 12),
                  _actionButton(
                    icon: Icons.reply_rounded,
                    iconColor: Colors.grey[600]!,
                    label: 'Répondre',
                    onTap: () => _startReply(comment.userName, comment.id),
                  ),
                  if (isOwn) ...[
                    const SizedBox(width: 12),
                    _actionButton(
                      icon: Icons.edit_outlined,
                      iconColor: Colors.grey[600]!,
                      label: 'Modifier',
                      onTap: () => _editComment(comment),
                    ),
                  ],
                ],
              ),
            ),
            if (hasReplies) ...[
              Divider(height: 1, thickness: 0.8, color: Colors.grey[200]),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  children: comment.replies.map((reply) => _buildCommentTile(reply, isRoot: false)).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _actionButton({required IconData icon, required Color iconColor, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: Offset(0, -2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyingTo != null)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.reply_rounded, size: 14, color: Colors.blue[700]),
                  const SizedBox(width: 6),
                  Text('Réponse à $_replyingToName', style: TextStyle(fontSize: 12, color: Colors.blue[700])),
                  const Spacer(),
                  InkWell(onTap: _clearReply, child: const Icon(Icons.close, size: 16, color: Colors.grey)),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: _focusNode,
                  onSubmitted: (_) => _submitComment(parentId: _replyingTo),
                  decoration: InputDecoration(
                    hintText: _replyingTo != null ? 'Écrire une réponse...' : 'Écrire un commentaire...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.blue,
                child: IconButton(
                  icon: _isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  onPressed: _isSubmitting ? null : () => _submitComment(parentId: _replyingTo),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
