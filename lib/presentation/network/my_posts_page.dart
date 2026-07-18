import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:thix_id/models/network_post.dart';
import 'package:thix_id/services/network_service.dart';
import 'package:thix_id/presentation/network/widgets/post_card.dart';

class MyPostsPage extends StatefulWidget {
  const MyPostsPage({super.key});

  @override
  State<MyPostsPage> createState() => _MyPostsPageState();
}

class _MyPostsPageState extends State<MyPostsPage> {
  late NetworkService _networkService;
  List<NetworkPost> _posts = [];
  bool _loading = true;
  bool _loadingMore = false;
  final ScrollController _scrollController = ScrollController();
  int _offset = 0;
  static const int _limit = 15;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _networkService = Provider.of<NetworkService>(context, listen: false);
    _loadPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _loadPosts() async {
    setState(() => _loading = true);
    try {
      final posts = await _networkService.getMyPosts(limit: _limit, offset: 0);
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _offset = posts.length;
        _hasMore = posts.length == _limit;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore ||!_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final more = await _networkService.getMyPosts(limit: _limit, offset: _offset);
      if (!mounted) return;
      setState(() {
        _posts.addAll(more);
        _offset += more.length;
        _hasMore = more.length == _limit;
        _loadingMore = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Mes publications', style: TextStyle(color: Color(0xFF0B1B3D), fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF0B1B3D)), onPressed: () => context.pop()),
      ),
      body: _loading
         ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : _posts.isEmpty
             ? const Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.post_add, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Aucune publication', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Vos posts apparaîtront ici', style: TextStyle(color: Colors.grey)),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: _loadPosts,
                  color: const Color(0xFFD4AF37),
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            if (i == _posts.length) {
                              return _loadingMore? const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())) : const SizedBox();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12, top: 8),
                              child: PostCard(post: _posts[i], currentProfileId: _networkService.currentUserId, onTap: () => context.push('/network/post/${_posts[i].id}')),
                            );
                          },
                          childCount: _posts.length + 1,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
