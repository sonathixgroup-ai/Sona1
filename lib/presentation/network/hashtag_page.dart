import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:thix_id/models/network_post.dart';
import 'package:thix_id/services/network_service.dart';

class HashtagPage extends StatefulWidget {
  final String tag;
  const HashtagPage({super.key, required this.tag});

  @override
  State<HashtagPage> createState() => _HashtagPageState();
}

class _HashtagPageState extends State<HashtagPage> {
  final ScrollController _scrollController = ScrollController();
  final List<NetworkPost> _posts = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _page = 0;
  static const int _pageSize = 20;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  // Validation simple du tag
  String get safeTag => widget.tag.replaceAll(RegExp(r'[^\w\-\u00C0-\u024F]'), '');

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final networkService = context.read<NetworkService>();
      final result = await networkService.getPostsByHashtag(
        safeTag,
        page: 0,
        limit: _pageSize,
      );
      setState(() {
        _posts.clear();
        _posts.addAll(result.posts);
        _totalCount = result.total;
        _page = 1;
        _hasMore = _posts.length < _totalCount;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final networkService = context.read<NetworkService>();
      final result = await networkService.getPostsByHashtag(
        safeTag,
        page: _page,
        limit: _pageSize,
      );
      setState(() {
        _posts.addAll(result.posts);
        _totalCount = result.total;
        _page++;
        _hasMore = _posts.length < _totalCount;
        _loadingMore = false;
      });
    } catch (e) {
      setState(() => _loadingMore = false);
    }
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
              '$_totalCount posts',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFD4AF37),
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildErrorState();
    }
    if (_posts.isEmpty) {
      return _buildEmptyState();
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: _posts.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _posts.length) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildPostItem(_posts[index]);
        },
      ),
    );
  }

  Widget _buildErrorState() {
    // ... (reste similaire)
  }

  Widget _buildEmptyState() {
    // ... (reste similaire)
  }

  Widget _buildPostItem(NetworkPost post) {
    final hasImage = post.imageUrls.isNotEmpty;
    final imageUrl = hasImage ? post.imageUrls.first : null;

    return GestureDetector(
      onTap: () => context.push('/network/post/${post.id}'),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null)
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: Colors.grey.shade200),
              errorWidget: (_, __, ___) => Container(
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
          if (post.isPinned)
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
