import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/models/network_post.dart';
import 'package:thix_id/services/network_service.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:provider/provider.dart';

// ─── COULEURS THIX PRO — identiques à NetworkProHome pour cohérence ───
class _PostColors {
  static const Color background = Color(0xFFF6F9FF);
  static const Color white = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF2D6CDF);
  static const Color primaryDeep = Color(0xFF123B7A);
  static const Color softBlue = Color(0xFFEAF1FF);
  static const Color gold = Color(0xFFD9A63C);
  static const Color textDark = Color(0xFF10192E);
  static const Color textSecondary = Color(0xFF7386A8);
  static const Color border = Color(0xFFE7EEFC);
  static const Color red = Color(0xFFE5484D);
  static const Color green = Color(0xFF059669);
  static const Color shadow = Color(0x142D6CDF);
}

class PostCard extends StatefulWidget {
  final NetworkPost post;
  final String currentProfileId;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onTap;
  final VoidCallback? onShare;
  final VoidCallback? onRefresh;
  final VoidCallback? onPin;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onSave;

  const PostCard({
    super.key,
    required this.post,
    required this.currentProfileId,
    this.onLike,
    this.onComment,
    this.onTap,
    this.onShare,
    this.onRefresh,
    this.onPin,
    this.onEdit,
    this.onDelete,
    this.onSave,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  late NetworkService _networkService;
  late NetworkPost _post;
  late AnimationController _likeAnimationController;
  bool _isPressed = false;
  bool _isSaving = false;
  bool _isReposting = false;

  final TextEditingController _quoteController = TextEditingController();

  // ✅ Regex combinée : couleur {c:#HEX}...{c}, gras **...**, italique *...*, mention @, hashtag #
  static final RegExp _richContentRegex = RegExp(
    r'\{c:(#[0-9A-Fa-f]{6,8})\}([\s\S]*?)\{c\}'
    r'|\*\*([\s\S]+?)\*\*'
    r'|\*([\s\S]+?)\*'
    r'|@(\w+)'
    r'|#(\w+)',
  );

  @override
  void initState() {
    super.initState();
    _networkService = NetworkService(Supabase.instance.client);
    _post = widget.post;
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    _quoteController.dispose();
    super.dispose();
  }

  // ─── FORMATAGE DE LA DATE ───
  String _getTimeAgo(DateTime dateTime) {
    return timeago.format(dateTime, locale: 'fr');
  }

  // ─── PARSING ENRICHI : gras / italique / couleur / mentions / hashtags ───
  List<InlineSpan> _parseContent(String content, TextStyle baseStyle) {
    final List<InlineSpan> spans = [];
    int lastIndex = 0;

    for (final match in _richContentRegex.allMatches(content)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: content.substring(lastIndex, match.start), style: baseStyle));
      }

      if (match.group(1) != null) {
        // ── Couleur {c:#HEX}texte{c}
        final hex = match.group(1)!.replaceFirst('#', '');
        final inner = match.group(2) ?? '';
        Color color;
        try {
          final argb = hex.length == 8 ? hex : 'FF$hex';
          color = Color(int.parse(argb, radix: 16));
        } catch (_) {
          color = baseStyle.color ?? _PostColors.textDark;
        }
        spans.add(TextSpan(children: _parseContent(inner, baseStyle.copyWith(color: color))));
      } else if (match.group(3) != null) {
        // ── Gras **texte**
        final inner = match.group(3)!;
        spans.add(TextSpan(children: _parseContent(inner, baseStyle.copyWith(fontWeight: FontWeight.w800))));
      } else if (match.group(4) != null) {
        // ── Italique *texte*
        final inner = match.group(4)!;
        spans.add(TextSpan(children: _parseContent(inner, baseStyle.copyWith(fontStyle: FontStyle.italic))));
      } else if (match.group(5) != null) {
        // ── Mention @user
        final value = match.group(5)!;
        spans.add(
          TextSpan(
            text: '@$value',
            style: baseStyle.merge(const TextStyle(color: _PostColors.primary, fontWeight: FontWeight.w700)),
            recognizer: TapGestureRecognizer()..onTap = () => _navigateToUser(value),
          ),
        );
      } else if (match.group(6) != null) {
        // ── Hashtag #tag
        final value = match.group(6)!;
        spans.add(
          TextSpan(
            text: '#$value',
            style: baseStyle.merge(const TextStyle(color: _PostColors.gold, fontWeight: FontWeight.w700)),
            recognizer: TapGestureRecognizer()..onTap = () => _navigateToHashtag(value),
          ),
        );
      }
      lastIndex = match.end;
    }

    if (lastIndex < content.length) {
      spans.add(TextSpan(text: content.substring(lastIndex), style: baseStyle));
    }
    return spans;
  }

  void _navigateToUser(String username) {
    try {
      Navigator.pushNamed(context, '/profile/$username');
    } catch (e) {
      _showNavigationError('profil de $username');
    }
  }

  void _navigateToHashtag(String hashtag) {
    try {
      Navigator.pushNamed(context, '/hashtag/$hashtag');
    } catch (e) {
      _showNavigationError('hashtag #$hashtag');
    }
  }

  void _showNavigationError(String page) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Impossible d\'accéder à $page'),
          backgroundColor: _PostColors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ─── ACTIONS ───

  Future<void> _toggleLike() async {
    _likeAnimationController.forward(from: 0.0);
    final newIsLiked = !_post.isLiked;
    final newCount = _post.likesCount + (newIsLiked ? 1 : -1);
    setState(() {
      _post = _post.copyWith(
        isLiked: newIsLiked,
        likesCount: newCount,
      );
    });

    try {
      if (newIsLiked) {
        await _networkService.likePost(_post.id);
      } else {
        await _networkService.unlikePost(_post.id);
      }
      widget.onRefresh?.call();
      widget.onLike?.call();
    } catch (e) {
      setState(() {
        _post = _post.copyWith(
          isLiked: !newIsLiked,
          likesCount: _post.likesCount + (newIsLiked ? -1 : 1),
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: _PostColors.red),
        );
      }
    }
  }

  Future<void> _toggleSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final newSaved = !_post.isSaved;
    setState(() {
      _post = _post.copyWith(isSaved: newSaved);
    });

    try {
      if (newSaved) {
        await _networkService.savePost(_post.id);
      } else {
        await _networkService.unsavePost(_post.id);
      }
      widget.onRefresh?.call();
      widget.onSave?.call();
    } catch (e) {
      setState(() {
        _post = _post.copyWith(isSaved: !newSaved);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: _PostColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _repost() async {
    if (_isReposting) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reposter'),
        content: TextField(
          controller: _quoteController,
          decoration: InputDecoration(
            hintText: 'Ajouter un commentaire (optionnel)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _PostColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Reposter'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() => _isReposting = true);
      try {
        await _networkService.repost(_post.id, _quoteController.text);
        setState(() {
          _post = _post.copyWith(
            repostsCount: _post.repostsCount + 1,
            isReposted: true,
          );
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post reposté'), backgroundColor: _PostColors.green),
          );
          widget.onRefresh?.call();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: _PostColors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isReposting = false);
        _quoteController.clear();
      }
    }
  }

  Future<void> _pinPost() async {
    try {
      await _networkService.pinPost(_post.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post épinglé sur votre profil'), backgroundColor: _PostColors.green),
        );
        widget.onRefresh?.call();
        widget.onPin?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: _PostColors.red),
        );
      }
    }
  }

  Future<void> _deletePost() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer la publication'),
        content: const Text(
          'Voulez-vous vraiment supprimer cette publication ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: _PostColors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _networkService.deletePost(_post.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Publication supprimée'), backgroundColor: _PostColors.green),
          );
          widget.onRefresh?.call();
          widget.onDelete?.call();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: _PostColors.red),
          );
        }
      }
    }
  }

  Future<void> _editPost() async {
    final controller = TextEditingController(text: _post.content);
    final newContent = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: _PostColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (newContent != null && newContent != _post.content) {
      try {
        await _networkService.updatePost(_post.id, newContent);
        setState(() {
          _post = _post.copyWith(content: newContent);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Publication modifiée'), backgroundColor: _PostColors.green),
          );
          widget.onRefresh?.call();
          widget.onEdit?.call();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: _PostColors.red),
          );
        }
      }
    }
  }

  Future<void> _hidePost() async {
    try {
      await _networkService.hidePost(_post.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publication masquée'), backgroundColor: Colors.orange),
        );
        widget.onRefresh?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: _PostColors.red),
        );
      }
    }
  }

  Future<void> _reportPost() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Signaler la publication'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.warning, color: Colors.orange),
              title: const Text('Spam'),
              onTap: () => Navigator.pop(context, 'Spam'),
            ),
            ListTile(
              leading: const Icon(Icons.block, color: _PostColors.red),
              title: const Text('Contenu inapproprié'),
              onTap: () => Navigator.pop(context, 'Contenu inapproprié'),
            ),
            ListTile(
              leading: const Icon(Icons.person_off, color: Colors.purple),
              title: const Text('Harcèlement'),
              onTap: () => Navigator.pop(context, 'Harcèlement'),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: _PostColors.primary),
              title: const Text('Fausse information'),
              onTap: () => Navigator.pop(context, 'Fausse information'),
            ),
          ],
        ),
      ),
    );

    if (reason != null) {
      try {
        await _networkService.reportPost(_post.id, reason);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Publication signalée'), backgroundColor: Colors.orange),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: _PostColors.red),
          );
        }
      }
    }
  }

  // ─── FORMATAGE DES NOMBRES ───
  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  // ─── BUILD ───
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);
    final isOwner = auth.currentUser?.id == _post.userId;

    final hasImage = _post.imageUrls.isNotEmpty;
    final imageUrl = hasImage ? _post.imageUrls.first : null;
    final hasContent = _post.content.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: _PostColors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _PostColors.border),
          boxShadow: [
            BoxShadow(
              color: _PostColors.shadow,
              blurRadius: _isPressed ? 6 : 16,
              offset: Offset(0, _isPressed ? 2 : 8),
            ),
          ],
        ),
        child: InkWell(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap ?? () {},
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── HEADER ───
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [_PostColors.primaryDeep, _PostColors.primary]),
                      ),
                      child: CircleAvatar(
                        radius: 19,
                        backgroundColor: _PostColors.softBlue,
                        backgroundImage: _post.authorAvatar != null && _post.authorAvatar!.isNotEmpty
                            ? NetworkImage(_post.authorAvatar!)
                            : null,
                        child: _post.authorAvatar == null || _post.authorAvatar!.isEmpty
                            ? const Icon(Icons.person_rounded, size: 18, color: _PostColors.primaryDeep)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _post.authorName,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: _PostColors.textDark),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_post.authorTitle != null && _post.authorTitle!.isNotEmpty)
                            Text(
                              _post.authorTitle!,
                              style: const TextStyle(fontSize: 10.5, color: _PostColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          Row(
                            children: [
                              Text(
                                _getTimeAgo(_post.createdAt),
                                style: const TextStyle(fontSize: 10, color: _PostColors.textSecondary),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.public_rounded, size: 11, color: _PostColors.textSecondary),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Menu (plus)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, size: 18, color: _PostColors.textSecondary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _editPost();
                            break;
                          case 'pin':
                            _pinPost();
                            break;
                          case 'delete':
                            _deletePost();
                            break;
                          case 'hide':
                            _hidePost();
                            break;
                          case 'report':
                            _reportPost();
                            break;
                          case 'share':
                            widget.onShare?.call();
                            break;
                          case 'save':
                            _toggleSave();
                            break;
                          case 'repost':
                            _repost();
                            break;
                          default:
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        if (isOwner) ...[
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_rounded, size: 18, color: _PostColors.primary),
                                SizedBox(width: 8),
                                Text('Modifier'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'pin',
                            child: Row(
                              children: [
                                Icon(Icons.push_pin_rounded, size: 18, color: _PostColors.gold),
                                SizedBox(width: 8),
                                Text('Épingler sur le profil'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_rounded, size: 18, color: _PostColors.red),
                                SizedBox(width: 8),
                                Text('Supprimer', style: TextStyle(color: _PostColors.red)),
                              ],
                            ),
                          ),
                        ],
                        const PopupMenuItem<String>(
                          value: 'save',
                          child: Row(
                            children: [
                              Icon(Icons.bookmark_border_rounded, size: 18, color: _PostColors.primaryDeep),
                              SizedBox(width: 8),
                              Text('Sauvegarder'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'repost',
                          child: Row(
                            children: [
                              Icon(Icons.repeat_rounded, size: 18, color: _PostColors.primaryDeep),
                              SizedBox(width: 8),
                              Text('Reposter'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'hide',
                          child: Row(
                            children: [
                              Icon(Icons.visibility_off_rounded, size: 18, color: _PostColors.textSecondary),
                              SizedBox(width: 8),
                              Text('Masquer'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'report',
                          child: Row(
                            children: [
                              Icon(Icons.flag_rounded, size: 18, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('Signaler'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share_rounded, size: 18, color: _PostColors.primaryDeep),
                              SizedBox(width: 8),
                              Text('Partager'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ─── CONTENU — gras / italique / couleur / mentions / hashtags interprétés ───
                if (hasContent)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: RichText(
                      text: TextSpan(
                        children: _parseContent(
                          _post.content,
                          const TextStyle(fontSize: 14, height: 1.45, color: _PostColors.textDark),
                        ),
                      ),
                    ),
                  ),

                // ─── IMAGE ───
                if (hasImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.network(
                      imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200,
                          color: _PostColors.softBlue,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: _PostColors.primary,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 200,
                        color: _PostColors.softBlue,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image_rounded, size: 44, color: _PostColors.primary.withOpacity(0.4)),
                            const SizedBox(height: 8),
                            const Text('Image non disponible', style: TextStyle(color: _PostColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (hasImage) const SizedBox(height: 12),

                // ─── ACTIONS ───
                Row(
                  children: [
                    // Like
                    InkWell(
                      onTap: _toggleLike,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            ScaleTransition(
                              scale: _likeAnimationController,
                              child: Icon(
                                _post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: _post.isLiked ? _PostColors.red : _PostColors.textSecondary,
                                size: 19,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _formatCount(_post.likesCount),
                              style: const TextStyle(fontSize: 12, color: _PostColors.textSecondary, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),

                    // Comment
                    InkWell(
                      onTap: widget.onComment ?? () {},
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: _PostColors.textSecondary),
                            const SizedBox(width: 5),
                            Text(
                              _formatCount(_post.commentsCount),
                              style: const TextStyle(fontSize: 12, color: _PostColors.textSecondary, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),

                    // Share
                    InkWell(
                      onTap: widget.onShare ?? () {},
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: const [
                            Icon(Icons.share_rounded, size: 18, color: _PostColors.textSecondary),
                            SizedBox(width: 5),
                            Text('Partager', style: TextStyle(fontSize: 12, color: _PostColors.textSecondary, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),

                    // Save
                    InkWell(
                      onTap: _toggleSave,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _post.isSaved ? _PostColors.softBlue : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _post.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          size: 19,
                          color: _post.isSaved ? _PostColors.gold : _PostColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
