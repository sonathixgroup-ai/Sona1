import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thix_id/models/network_post.dart';
import 'package:thix_id/features/network/data/network_service_provider.dart';
import 'package:flutter/foundation.dart';

final feedProvider = AsyncNotifierProvider<Feed, List<NetworkPost>>(Feed.new);

class Feed extends AsyncNotifier<List<NetworkPost>> {
  // 🌟 MODIFICATION : 'all' devient le flux par défaut
  String _currentType = 'all';
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  @override
  Future<List<NetworkPost>> build() async {
    _hasMore = true;
    try {
      final service = ref.read(networkServiceProvider);
      // Pour 'all', on charge un plus grand nombre de posts d'un coup (100 au lieu de 20)
      final limit = _currentType == 'all' ? 100 : 20;
      final posts = await service.getFeedPosts(feedType: _currentType, limit: limit, offset: 0);
      
      _hasMore = posts.length >= limit;
      
      // 🌟 LE SMART MIX : On mélange la liste si on est sur l'onglet Tous
      if (_currentType == 'all') {
        posts.shuffle();
      }
      
      return posts;
    } catch (e) {
      debugPrint('🔥 Erreur dans Feed.build: $e');
      return []; 
    }
  }

  Future<void> loadFeed({String? feedType, bool force = false}) async {
    if (feedType != null) _currentType = feedType;
    state = const AsyncLoading();
    
    try {
      final service = ref.read(networkServiceProvider);
      // 100 posts pour le Smart Mix, 30 sinon
      final limit = _currentType == 'all' ? 100 : 30;
      
      final posts = await service.getFeedPosts(feedType: _currentType, limit: limit, offset: 0);
      _hasMore = posts.length >= limit;
      
      // 🌟 LE SMART MIX
      if (_currentType == 'all') {
        posts.shuffle();
      }
      
      state = AsyncData(posts); 
    } catch (e, stack) {
      debugPrint('🔥 Erreur dans Feed.loadFeed: $e');
      state = AsyncError(e, stack); 
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
      final limit = _currentType == 'all' ? 100 : 20;
      final more = await service.getFeedPosts(feedType: _currentType, limit: limit, offset: current.length);
      
      _hasMore = more.length >= limit;
      
      // On mélange aussi les nouveaux résultats ajoutés en bas de page
      if (_currentType == 'all') {
        more.shuffle();
      }
      
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
