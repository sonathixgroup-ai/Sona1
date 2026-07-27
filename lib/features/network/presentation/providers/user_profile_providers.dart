import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thix_id/features/network/data/network_service_provider.dart';
import 'package:thix_id/models/network_post.dart';

// Profil
final userProfileProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, userId) async {
  final service = ref.read(networkServiceProvider);
  return await service.getUserProfile(userId);
});

// Pinned
final pinnedPostsProvider = FutureProvider.family<List<NetworkPost>, String>((ref, userId) async {
  final service = ref.read(networkServiceProvider);
  return await service.getPinnedPosts(userId);
});

// Posts avec pagination scalable
final userPostsProvider = AsyncNotifierProviderFamily<UserPostsNotifier, List<NetworkPost>, String>(UserPostsNotifier.new);

class UserPostsNotifier extends FamilyAsyncNotifier<List<NetworkPost>, String> {
  int _offset = 0;
  static const _limit = 15;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  @override
  Future<List<NetworkPost>> build(String userId) async {
    _offset = 0;
    final service = ref.read(networkServiceProvider);
    final posts = await service.getUserPosts(userId, offset: 0, limit: _limit);
    _offset = posts.length;
    _hasMore = posts.length == _limit;
    return posts;
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    _isLoadingMore = true;
    try {
      final service = ref.read(networkServiceProvider);
      final more = await service.getUserPosts(arg, offset: _offset, limit: _limit);
      _hasMore = more.length == _limit;
      _offset += more.length;
      final current = state.valueOrNull?? [];
      state = AsyncData([...current,...more]);
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(networkServiceProvider);
      final posts = await service.getUserPosts(arg, offset: 0, limit: _limit);
      _offset = posts.length;
      _hasMore = posts.length == _limit;
      return posts;
    });
  }
}

// Follow status - robuste, ne plante plus sur connection_id
final followStatusProvider = FutureProvider.family<bool, String>((ref, targetId) async {
  final service = ref.read(networkServiceProvider);
  try {
    final res = await service.supabase.from('connections').select().eq('user_id', service.currentUserId).eq('status', 'accepted');
    return (res as List).any((r) => (r['connection_id']?? r['friend_id']?? r['connected_user_id']) == targetId);
  } catch (_) { return false; }
});
