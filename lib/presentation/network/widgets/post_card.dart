// lib/presentation/network/widgets/post_card.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/models/network_post.dart';
import 'package:thix_id/services/network_service.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:provider/provider.dart';

class PostCard extends StatefulWidget {
  final NetworkPost post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onTap;
  final VoidCallback onShare;
  final VoidCallback? onRefresh;
  final VoidCallback? onPin;

  const PostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onTap,
    required this.onShare,
    this.onRefresh,
    this.onPin,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  late NetworkService _networkService;
  late NetworkPost _post;
  late AnimationController _likeAnimationController;
  bool _isPressed = false;
  bool _isSaved = false;
  bool _isReposted = false;
  final TextEditingController _quoteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _networkService = NetworkService(Supabase.instance.client);
    _post = widget.post;
    // ⭐ CORRIGÉ - Récupération dynamique de isSavedByCurrentUser
    final dynamicPost = _post as dynamic;
    _isSaved = dynamicPost.isSavedByCurrentUser ?? false;
    _isReposted = false;
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

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 7) {
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } else if (difference.inDays >= 1) {
      return 'il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours >= 1) {
      return 'il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes >= 1) {
      return 'il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'à l\'instant';
    }
  }

  List<TextSpan> _parseContent(String content) {
    final RegExp mentionRegex = RegExp(r'@(\w+)');
    final RegExp hashtagRegex = RegExp(r'#(\w+)');
    final List<TextSpan> spans = [];
    int lastIndex = 0;
    
    final allMatches = <RegExpMatch>[
      ...mentionRegex.allMatches(content),
      ...hashtagRegex.allMatches(content),
    ]..sort((a, b) => a.start.compareTo(b.start));
    
    for (final match in allMatches) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: content.substring(lastIndex, match.start)));
      }
      
      final isMention = match.pattern == mentionRegex;
      final text = match.group(0)!;
      final value = match.group(1)!;
      
      spans.add(TextSpan(
        text: text,
        style: TextStyle(
          color: isMention ? Colors.blue : const Color(0xFFD4AF37),
          fontWeight: FontWeight.w500,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            if (isMention) {
              _navigateToUser(value);
            } else {
              _navigateToHashtag(value);
            }
          },
      ));
      lastIndex = match.end;
    }
    
    if (lastIndex < content.length) {
      spans.add(TextSpan(text: content.substring(lastIndex)));
    }
    
    return spans;
  }

  void _navigateToUser(String username) {
    try {
      Navigator.pushNamed(context, '/profile/$username').catchError((error) {
        print('❌ Erreur navigation profil: $error');
        _showNavigationError('profil de $username');
      });
    } catch (e) {
      print('❌ Exception navigation: $e');
      _showNavigationError('profil de $username');
    }
  }

  void _navigateToHashtag(String hashtag) {
    try {
      Navigator.pushNamed(context, '/hashtag/$hashtag').catchError((error) {
        print('❌ Erreur navigation hashtag: $error');
        _showNavigationError('hashtag #$hashtag');
      });
    } catch (e) {
      print('❌ Exception navigation: $e');
      _showNavigationError('hashtag #$hashtag');
    }
  }

  // ✅ CORRECTION: Nouvelle fonction pour Thix Inf
  void _navigateToThixInf() {
    try {
      print('📘 Navigation vers Thix Inf...');
      Navigator.pushNamed(context, '/thix-inf').then((result) {
        print('✅ Thix Inf fermé avec résultat: $result');
      }).catchError((error) {
        print('❌ Erreur navigation Thix Inf: $error');
        _showNavigationError('Thix Inf');
      });
    } catch (e) {
      print('❌ Exception Thix Inf: $e');
      _showNavigationError('Thix Inf');
    }
  }

  // ✅ CORRECTION: Nouvelle fonction pour Thix Événement
  void _navigateToThixEvenement() {
    try {
      print('📅 Navigation vers Thix Événement...');
      Navigator.pushNamed(context, '/thix-evenement').then((result) {
        print('✅ Thix Événement fermé avec résultat: $result');
      }).catchError((error) {
        print('❌ Erreur navigation Thix Événement: $error');
        _showNavigationError('Thix Événement');
      });
    } catch (e) {
      print('❌ Exception Thix Événement: $e');
      _showNavigationError('Thix Événement');
    }
  }

  void _showNavigationError(String page) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Impossible d\'accéder à $page'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _toggleSave() async {
    setState(() => _isSaved = !_isSaved);
    
    if (_isSaved) {
      await _networkService.savePost(_post.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post sauvegardé'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
        );
      }
    } else {
      await _networkService.unsavePost(_post.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post retiré des sauvegardes'), backgroundColor: Colors.orange, duration: Duration(seconds: 1)),
        );
      }
    }
  }

  Future<void> _repost() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reposter'),
        content: TextField(
          controller: _quoteController,
          decoration: const InputDecoration(
            hintText: 'Ajouter un commentaire (optionnel)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
            child: const Text('Reposter'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      await _networkService.repost(_post.id, _quoteController.text);
      setState(() => _isReposted = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post reposté'), backgroundColor: Colors.green),
        );
        widget.onRefresh?.call();
      }
    }
    _quoteController.clear();
  }

  Future<void> _pinPost() async {
    try {
      await _networkService.pinPost(_post.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post épinglé sur votre profil'), backgroundColor: Colors.green),
        );
        widget.onRefresh?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
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
      try {
        await _networkService.deletePost(_post.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Publication supprimée'), backgroundColor: Colors.green),
          );
          widget.onRefresh?.call();
          widget.onLike();
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
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _reportPost() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
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
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Contenu inapproprié'),
              onTap: () => Navigator.pop(context, 'Contenu inapproprié'),
            ),
            ListTile(
              leading: const Icon(Icons.person_off, color: Colors.purple),
              title: const Text('Harcèlement'),
              onTap: () => Navigator.pop(context, 'Harcèlement'),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.blue),
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
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
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
    
    if (newContent != null && newContent != _post.content) {
      try {
        await _networkService.updatePost(_post.id, newContent);
        setState(() {
          _post = _post.copyWith(content: newContent);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Publication modifiée'), backgroundColor: Colors.green),
          );
          widget.onRefresh?.call();
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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);
    final isOwner = auth.currentUser?.id == _post.userId;
    final hasUserTitle = _post.authorTitle != null && _post.authorTitle!.isNotEmpty;
    final dynamicPost = _post as dynamic;
    
    // ⭐ CORRIGÉ - Récupération dynamique des propriétés manquantes
    final mediaUrl = dynamicPost.mediaUrl;
    final hasImage = mediaUrl != null && mediaUrl.toString().isNotEmpty;
    final hasContent = _post.content != null && _post.content!.isNotEmpty;
    final isLiked = dynamicPost.isLikedByCurrentUser ?? false;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: _isPressed ? 0 : 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: () {
            print('🔍 Clic sur le post ID: ${_post.id}');
            widget.onTap();
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: _post.authorAvatar != null && _post.authorAvatar!.isNotEmpty
                          ? NetworkImage(_post.authorAvatar!)
                          : null,
                      child: _post.authorAvatar == null || _post.authorAvatar!.isEmpty
                          ? const Icon(Icons.person, size: 20)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _post.authorName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          if (hasUserTitle)
                            Text(
                              _post.authorTitle!,
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    Text(
                      _getTimeAgo(_post.createdAt),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 18),
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
                            widget.onShare();
                            break;
                          case 'save':
                            _toggleSave();
                            break;
                          case 'repost':
                            _repost();
                            break;
                          case 'thix-inf':
                            _navigateToThixInf();
                            break;
                          case 'thix-evenement':
                            _navigateToThixEvenement();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        if (isOwner) ...[
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text('Modifier'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'pin',
                            child: Row(
                              children: [
                                Icon(Icons.push_pin, size: 18, color: Color(0xFFD4AF37)),
                                SizedBox(width: 8),
                                Text('Épingler sur le profil'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Supprimer', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                        const PopupMenuItem<String>(
                          value: 'save',
                          child: Row(
                            children: [
                              Icon(Icons.bookmark_border, size: 18),
                              SizedBox(width: 8),
                              Text('Sauvegarder'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'repost',
                          child: Row(
                            children: [
                              Icon(Icons.repeat, size: 18),
                              SizedBox(width: 8),
                              Text('Reposter'),
                            ],
                          ),
                        ),
                        // ✅ CORRECTION: Ajout des boutons Thix Inf et Thix Événement
                        const PopupMenuItem<String>(
                          value: 'thix-inf',
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 18, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('📘 Thix Inf'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'thix-evenement',
                          child: Row(
                            children: [
                              Icon(Icons.event, size: 18, color: Colors.purple),
                              SizedBox(width: 8),
                              Text('📅 Thix Événement'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'hide',
                          child: Row(
                            children: [
                              Icon(Icons.visibility_off, size: 18),
                              SizedBox(width: 8),
                              Text('Masquer'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'report',
                          child: Row(
                            children: [
                              Icon(Icons.flag, size: 18),
                              SizedBox(width: 8),
                              Text('Signaler'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share, size: 18),
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

                // Contenu avec mentions et hashtags
                if (hasContent)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87),
                        children: _parseContent(_post.content!),
                      ),
                    ),
                  ),
                
                // Image (CORRIGÉ)
                if (hasImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      mediaUrl.toString(),
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200,
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
                        height: 200,
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
                
                if (hasImage) const SizedBox(height: 12),

                // Actions (CORRIGÉ)
                Row(
                  children: [
                    // Like
                    InkWell(
                      onTap: () {
                        _likeAnimationController.forward(from: 0.0);
                        widget.onLike();
                        setState(() {
                          if (isLiked) {
                            _post = _post.copyWith(
                              likesCount: _post.likesCount - 1,
                            );
                          } else {
                            _post = _post.copyWith(
                              likesCount: _post.likesCount + 1,
                            );
                          }
                        });
                      },
                      child: Row(
                        children: [
                          ScaleTransition(
                            scale: _likeAnimationController,
                            child: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : Colors.grey,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(_formatCount(_post.likesCount), style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    
                    // Comment
                    InkWell(
                      onTap: widget.onComment,
                      child: Row(
                        children: [
                          const Icon(Icons.chat_bubble_outline, size: 20, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(_formatCount(_post.commentsCount), style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    
                    // Share
                    InkWell(
                      onTap: widget.onShare,
                      child: const Row(
                        children: [
                          Icon(Icons.share, size: 20, color: Colors.grey),
                          SizedBox(width: 4),
                          Text('Partager', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    
                    // Save
                    InkWell(
                      onTap: _toggleSave,
                      child: Icon(
                        _isSaved ? Icons.bookmark : Icons.bookmark_border,
                        size: 20,
                        color: _isSaved ? const Color(0xFFD4AF37) : Colors.grey,
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

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}
