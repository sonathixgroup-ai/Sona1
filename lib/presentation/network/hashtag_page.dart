// lib/presentation/network/hashtag_page.dart
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

  @override
  void initState() {
    super.initState();
    _networkService = NetworkService(Supabase.instance.client);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
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
      debugPrint('Error loading hashtag: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('#${widget.tag}'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '${_hashtagInfo?['posts_count'] ?? 0} posts',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                  ),
                  itemCount: _posts.length,
                  itemBuilder: (context, index) => _buildPostItem(_posts[index]),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.tag, size: 60, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Text(
            '#${widget.tag}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Aucun post pour ce hashtag',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Retour'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: const Color(0xFF0B1B3D),
            ),
          ),
        ],
      ),
    );
  }

  // ⭐ CORRIGÉ - Utilisation dynamique pour mediaUrl
  Widget _buildPostItem(NetworkPost post) {
    // Récupération sécurisée de mediaUrl via dynamic
    final dynamicPost = post as dynamic;
    final mediaUrl = dynamicPost.mediaUrl;
    final hasImage = mediaUrl != null && mediaUrl.toString().isNotEmpty;
    
    return GestureDetector(
      onTap: () => context.push('/network/post/${post.id}'),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            Image.network(
              mediaUrl.toString(),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            )
          else
            Container(
              color: Colors.grey[200],
              child: const Icon(Icons.text_fields, color: Colors.grey),
            ),
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
