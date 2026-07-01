// lib/presentation/feed/feed_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thix_id/models/network_post.dart';
import 'package:thix_id/presentation/feed/post_card.dart';
import 'package:thix_id/presentation/network/widgets/create_post_dialog.dart';
import 'package:thix_id/services/network_service.dart';

class FeedPage extends StatefulWidget {
  final String profileId;

  const FeedPage({Key? key, required this.profileId}) : super(key: key);

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final _posts = <NetworkPost>[];
  bool _loading = false;
  int _page = 0;
  final _pageSize = 20;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _startRealtime();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startRealtime() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && !_loading) {
        _loadInitial();
      }
    });
  }

  Future<void> _loadInitial() async {
    setState(() => _loading = true);
    try {
      final svc = context.read<NetworkService>();
      final items = await svc.getFeedPosts(limit: _pageSize);
      if (mounted) {
        setState(() {
          _posts.clear();
          _posts.addAll(items);
          _page = 1;
        });
      }
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
      final svc = context.read<NetworkService>();
      final items = await svc.getFeedPosts(limit: _pageSize, offset: _page * _pageSize);
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
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const CreatePostDialog(),
          ).then((_) {
            if (mounted) _loadInitial();
          });
        },
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
                  child: Center(child: _loading ? const CircularProgressIndicator() : const SizedBox.shrink()),
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
