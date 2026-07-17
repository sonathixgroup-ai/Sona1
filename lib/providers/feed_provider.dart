import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/network_service.dart';
import '../models/network_post.dart';

class FeedProvider extends ChangeNotifier {
  final NetworkService _service;
  final SupabaseClient _supabase;
  FeedProvider(this._service, {required SupabaseClient supabase}) : _supabase = supabase;

  List<NetworkPost> _posts = [];
  bool _isLoading = false, _isLoadingMore = false, _hasMore = true;
  String _feedType = 'smart';
  int _offset = 0;
  static const _limit = 15;
  RealtimeChannel? _channel;

  List<NetworkPost> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String get currentFeedType => _feedType;

  Future<void> loadFeed({String? feedType, bool force = false}) async {
    if (_isLoading &&!force) return;
    if (feedType!= null) _feedType = feedType;
    _isLoading = true; _offset = 0; _hasMore = true;
    notifyListeners();
    try {
      final newPosts = await _service.getFeedPosts(limit: _limit, offset: 0, feedType: _feedType);
      _posts = newPosts; _offset = newPosts.length; _hasMore = newPosts.length >= _limit;
    } finally { _isLoading = false; notifyListeners(); }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore ||!_hasMore || _isLoading) return;
    _isLoadingMore = true; notifyListeners();
    try {
      final more = await _service.getFeedPosts(limit: _limit, offset: _offset, feedType: _feedType);
      if (more.isEmpty) { _hasMore = false; }
      else { _posts.addAll(more); _offset += more.length; _hasMore = more.length >= _limit; }
    } finally { _isLoadingMore = false; notifyListeners(); }
  }

  Future<void> toggleLike(String postId) async {
    final i = _posts.indexWhere((p) => p.id == postId); if (i == -1) return;
    final old = _posts[i];
    _posts[i] = old.copyWith(isLiked:!old.isLiked, likesCount: old.isLiked? old.likesCount - 1 : old.likesCount + 1);
    notifyListeners();
    try { old.isLiked? await _service.unlikePost(postId) : await _service.likePost(postId); }
    catch (_) { _posts[i] = old; notifyListeners(); }
  }

  void initRealtime() {
    _channel = _supabase.channel('posts_feed').onPostgresChanges(event: PostgresChangeEvent.insert, schema: 'public', table: 'posts', callback: (_) => loadFeed(force: true)).subscribe();
  }
  @override void dispose() { _channel?.unsubscribe(); super.dispose(); }
}
