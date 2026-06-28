// lib/presentation/feed/feed_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thix_id/models/post.dart';
import 'package:thix_id/presentation/feed/post_card.dart';
import 'package:thix_id/presentation/feed/create_post_sheet.dart';
import 'package:thix_id/services/post_service.dart';

class FeedPage extends StatefulWidget {
  final String profileId;

  const FeedPage({Key? key, required this.profileId}) : super(key: key);

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final _posts = <Post>[];
  bool _loading = false;
  int _page = 0;
  final _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    // subscribe realtime
    final svc = context.read<PostService>();
    svc.streamPosts(onData: (posts) {
      if (mounted) setState(() => _posts
        ..clear()
        ..addAll(posts));
    });
  }

  Future<void> _loadInitial() async {
    setState(() => _loading = true);
    try {
      final svc = context.read<PostService>();
      final items = await svc.fetchFeed(limit: _pageSize, offset: 0);
      if (mounted) setState(() {
        _posts.clear();
        _posts.addAll(items);
        _page = 1;
      });
    } catch (e) {
      debugPrint('FeedPage _loadInitial error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final svc = context.read<PostService>();
      final items = await svc.fetchFeed(limit: _pageSize, offset: _page * _pageSize);
      if (items.isNotEmpty && mounted) {
        setState(() {
          _posts.addAll(items);
          _page++;
        });
      }
    } catch (e) {
      debugPrint('FeedPage _loadMore error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fil d\'actualité')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => CreatePostSheet.show(context, profileId: widget.profileId),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _loadInitial,
        child: NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
              _loadMore();
            }
            return false;
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _posts.length + 1,
            itemBuilder: (context, index) {
              if (index >= _posts.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: _loading ? CircularProgressIndicator() : SizedBox.shrink()),
                );
              }
              final post = _posts[index];
              return PostCard(post: post, currentProfileId: widget.profileId);
            },
          ),
        ),
      ),
    );
  }
}
