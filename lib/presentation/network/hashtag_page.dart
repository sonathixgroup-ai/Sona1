import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/models/network_post.dart';
import 'package:thix_id/services/network_service.dart';

class HashtagPage extends StatefulWidget {
  final String tag;
  const HashtagPage({super.key, required this.tag});

  @override
  State<HashtagPage> createState() => _HashtagPageState();
}

class _HashtagPageState extends State<HashtagPage> {
  late NetworkService _networkService;
  List<NetworkPost> _posts = [];
  Map<String, dynamic>? _hashtagInfo;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _networkService = NetworkService(Supabase.instance.client);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Récupérer les posts avec ce hashtag
      final response = await Supabase.instance.client
          .from('posts')
          .select('''
            *,
            users:user_id (
              display_name,
              photo_url,
              profession
            )
          ''')
          .ilike('content', '%#${widget.tag}%')
          .order('created_at', ascending: false);
      
      final posts = <NetworkPost>[];
      for (var e in response as List) {
        final likesData = await Supabase.instance.client
            .from('post_likes')
            .select('id')
            .eq('post_id', e['id']);
        
        final commentsData = await Supabase.instance.client
            .from('comments')
            .select('id')
            .eq('post_id', e['id']);
        
        final userData = e['users'] as Map<String, dynamic>?;
        
        posts.add(NetworkPost.fromJson({
          ...e,
          'author_name': userData?['display_name'] ?? 'Utilisateur',
          'author_avatar': userData?['photo_url'],
          'author_title': userData?['profession'],
          'likes_count': (likesData as List).length,
          'comments_count': (commentsData as List).length,
          'is_liked': false,
          // ✅ CORRIGÉ : Construire media_urls depuis les colonnes existantes
          'media_urls': _extractMediaUrls(e),
        }));
      }
      
      setState(() {
        _posts = posts;
        _hashtagInfo = {
          'name': widget.tag,
          'posts_count': posts.length,
        };
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ Erreur chargement hashtag: $e');
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ✅ CORRIGÉ : Fonction pour extraire les URLs des médias
  List<String> _extractMediaUrls(Map<String, dynamic> row) {
    // Vérifier si la colonne media_urls existe
    if (row['media_urls'] != null) {
      return List<String>.from(row['media_urls'] as List);
    }
    // Sinon, utiliser media_url (une seule image)
    if (row['media_url'] != null && row['media_url'].toString().isNotEmpty) {
      return [row['media_url'].toString()];
    }
    // Sinon, utiliser image_urls si elle existe
    if (row['image_urls'] != null) {
      return List<String>.from(row['image_urls'] as List);
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(
          children: [
            const Icon(Icons.tag, size: 22, color: Color(0xFFD4AF37)),
            const SizedBox(width: 8),
            Text(
              '#${widget.tag}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_hashtagInfo?['posts_count'] ?? 0} posts',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFD4AF37),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
              ),
            )
          : _error != null
              ? _buildErrorState()
              : _posts.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: const Color(0xFFD4AF37),
                      child: GridView.builder(
                        padding: const EdgeInsets.all(2),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                        itemCount: _posts.length,
                        itemBuilder: (context, index) => _buildPostItem(_posts[index]),
                      ),
                    ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 56, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red.shade700),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: const Color(0xFF0B1B3D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.tag, size: 64, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Text(
            '#${widget.tag}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Aucun post pour ce hashtag',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Soyez le premier à utiliser #${widget.tag} !',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Retour'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: const Color(0xFF0B1B3D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ CORRIGÉ - Utilisation correcte de mediaUrls
  Widget _buildPostItem(NetworkPost post) {
    final hasImage = post.imageUrls.isNotEmpty;
    final imageUrl = hasImage ? post.imageUrls.first : null;

    return GestureDetector(
      onTap: () => context.push('/network/post/${post.id}'),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage && imageUrl != null)
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            )
          else
            Container(
              color: Colors.grey.shade200,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.text_fields, size: 32, color: Colors.grey),
                  const SizedBox(height: 4),
                  Text(
                    post.content.length > 20
                        ? '${post.content.substring(0, 20)}...'
                        : post.content,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          // Compteur de likes en bas à droite
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.favorite, size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    _formatNumber(post.likesCount),
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          // Si le post est épinglé
          if (post.isPinned ?? false)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.push_pin, size: 12, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  String _formatNumber(int num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}k';
    return num.toString();
  }
}
