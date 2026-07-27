import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:thix_id/models/network_post.dart';
import 'package:thix_id/features/network/data/network_service_provider.dart';

part 'feed_provider.g.dart';

@riverpod
class Feed extends _$Feed {
  static const int _limit = 15;
  int _offset = 0;
  bool _hasMore = true;
  String _feedType = 'all';

  bool get hasMore => _hasMore;

  @override
  Future<List<NetworkPost>> build() async {
    _offset = 0;
    _hasMore = true;
    final service = ref.read(networkServiceProvider);
    final posts = await service.getFeed(
      limit: _limit,
      offset: 0,
      feedType: _feedType,
    );
    _offset = posts.length;
    _hasMore = posts.length >= _limit;

    // init realtime comme ton ancien FeedProvider
    service.initRealtimeFeed(() {
      loadFeed(force: true);
    });

    return posts;
  }

  Future<void> loadFeed({String? feedType, bool force = false}) async {
    if (feedType!= null) _feedType = feedType;
    if (force) {
      _offset = 0;
      _hasMore = true;
      state = const AsyncLoading();
    }
    try {
      final posts = await ref.read(networkServiceProvider).getFeed(
        limit: _limit,
        offset: 0,
        feedType: _feedType,
      );
      _offset = posts.length;
      _hasMore = posts.length >= _limit;
      state = AsyncData(posts);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;
    final current = state.valueOrNull?? [];
    try {
      final more = await ref.read(networkServiceProvider).getFeed(
        limit: _limit,
        offset: _offset,
        feedType: _feedType,
      );
      if (more.isEmpty) {
        _hasMore = false;
        return;
      }
      _offset += more.length;
      _hasMore = more.length >= _limit;
      state = AsyncData([...current,...more]);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> toggleLike(String postId) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final idx = current.indexWhere((p) => p.id == postId);
    if (idx == -1) return;

    final post = current[idx];
    final updated = post.copyWith(
      isLiked:!post.isLiked,
      likesCount: post.likesCount + (post.isLiked? -1 : 1),
    );

    final newList = [...current];
    newList[idx] = updated;
    state = AsyncData(newList);

    try {
      if (updated.isLiked) {
        await ref.read(networkServiceProvider).likePost(postId);
      } else {
        await ref.read(networkServiceProvider).unlikePost(postId);
      }
    } catch (_) {
      // rollback si erreur
      state = AsyncData(current);
    }
  }

  Future<void> deletePost(String postId) async {
    final current = state.valueOrNull?? [];
    state = AsyncData(current.where((p) => p.id!= postId).toList());
    try {
      await ref.read(networkServiceProvider).deletePost(postId);
    } catch (e) {
      state = AsyncData(current);
      rethrow;
    }
  }
}
