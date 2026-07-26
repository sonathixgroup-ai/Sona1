import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/models/network_post.dart';
import 'package:thix_id/features/network/data/network_service_provider.dart';
part 'feed_provider.g.dart';

@riverpod
class Feed extends _$Feed {
  static const _limit = 15;
  int _offset = 0;
  bool _hasMore = true;
  String _feedType = 'smart';
  RealtimeChannel? _channel;

  bool get hasMore => _hasMore;
  String get feedType => _feedType;

  @override
  Future<List<NetworkPost>> build() async {
    _offset = 0;
    _hasMore = true;
    final service = ref.read(networkServiceProvider);
    final posts = await service.getFeedPosts(limit: _limit, offset: 0, feedType: _feedType);
    _offset = posts.length;
    _hasMore = posts.length >= _limit;
    _initRealtime();
    return posts;
  }

  Future<void> loadFeed({String? feedType, bool force = false}) async {
    if (feedType!= null) _feedType = feedType;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(networkServiceProvider);
      final p = await service.getFeedPosts(limit: _limit, offset: 0, feedType: _feedType);
      _offset = p.length;
      _hasMore = p.length >= _limit;
      return p;
    });
  }

  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading) return;
    final current = state.valueOrNull?? [];
    final service = ref.read(networkServiceProvider);
    final more = await service.getFeedPosts(limit: _limit, offset: _offset, feedType: _feedType);
    if (more.isEmpty) { _hasMore = false; return; }
    _offset += more.length;
    _hasMore = more.length >= _limit;
    state = AsyncData([...current,...more]);
  }

  Future<void> toggleLike(String postId) async {
    final current = state.valueOrNull; if (current == null) return;
    final i = current.indexWhere((p) => p.id == postId); if (i == -1) return;
    final old = current[i];
    final updated = [...current];
    updated[i] = old.copyWith(isLiked:!old.isLiked, likesCount: old.isLiked? old.likesCount - 1 : old.likesCount + 1);
    state = AsyncData(updated);
    try {
      final s = ref.read(networkServiceProvider);
      old.isLiked? await s.unlikePost(postId) : await s.likePost(postId);
    } catch (_) { state = AsyncData(current); }
  }

  void _initRealtime() {
    final client = ref.read(supabaseClientProvider);
    _channel = client.channel('posts_feed').onPostgresChanges(event: PostgresChangeEvent.insert, schema: 'public', table: 'posts', callback: (_) => loadFeed(force: true)).subscribe();
  }

  @override
  void dispose() { _channel?.unsubscribe(); }
}
