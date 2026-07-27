import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thix_id/models/network_post.dart';
import 'package:thix_id/features/network/data/network_service_provider.dart';

final feedProvider = AsyncNotifierProvider<Feed, List<NetworkPost>>(Feed.new);

class Feed extends AsyncNotifier<List<NetworkPost>> {
  String _currentType = 'recent';
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  @override
  Future<List<NetworkPost>> build() async {
    _hasMore = true;
    try {
      final service = ref.read(networkServiceProvider);
      final posts = await service.getFeedPosts(feedType: 'recent', limit: 20, offset: 0);
      _hasMore = posts.length >= 20;
      return posts;
    } catch (e) {
      debugPrint('🔥 Erreur dans Feed.build: $e');
      return []; // Si erreur, on renvoie une liste vide au lieu de bloquer l'appli
    }
  }

  Future<void> loadFeed({String? feedType, bool force = false}) async {
    if (feedType != null) _currentType = feedType;
    state = const AsyncLoading();
    
    try {
      final service = ref.read(networkServiceProvider);
      final posts = await service.getFeedPosts(feedType: _currentType, limit: 30, offset: 0);
      _hasMore = posts.length >= 30;
      state = AsyncData(posts); // On prévient l'interface que c'est fini et réussi !
    } catch (e, stack) {
      debugPrint('🔥 Erreur dans Feed.loadFeed: $e');
      state = AsyncError(e, stack); // On prévient l'interface qu'il y a eu un problème
    }
  }

  void addPostOnTop(NetworkPost post) {
    final current = state.valueOrNull ?? [];
    state = AsyncData([post, ...current]);
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;
    final current = state.valueOrNull ?? [];
    try {
      final service = ref.read(networkServiceProvider);
      final more = await service.getFeedPosts(feedType: _currentType, limit: 20, offset: current.length);
      _hasMore = more.length >= 20;
      state = AsyncData([...current, ...more]);
    } catch (e) {
      debugPrint('🔥 Erreur dans Feed.loadMore: $e');
    }
  }

  Future<void> deletePost(String postId) async {
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((p) => p.id != postId).toList());
    try { await ref.read(networkServiceProvider).deletePost(postId); } catch (_) { state = AsyncData(current); }
  }

  Future<void> toggleLike(String postId) async {
    final current = state.valueOrNull ?? [];
    final idx = current.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final old = current[idx];
    final wasLiked = (old as dynamic).isLiked ?? false;
    final count = (old as dynamic).likesCount ?? 0;
    try {
      final updated = (old as dynamic).copyWith(isLiked: !wasLiked, likesCount: wasLiked ? count - 1 : count + 1) as NetworkPost;
      final list = [...current]; list[idx] = updated;
      state = AsyncData(list);
    } catch (_) {}
    try {
      final s = ref.read(networkServiceProvider);
      wasLiked ? await s.unlikePost(postId) : await s.likePost(postId);
    } catch (_) { state = AsyncData(current); }
  }
}
