import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thix_id/models/network_post.dart';
import 'package:thix_id/features/network/data/network_service_provider.dart';

final feedProvider = AsyncNotifierProvider<Feed, List<NetworkPost>>(Feed.new);

class Feed extends AsyncNotifier<List<NetworkPost>> {
  @override
  Future<List<NetworkPost>> build() async {
    // CHARGE VRAIMENT LA DB AU DEMARRAGE
    final service = ref.read(networkServiceProvider);
    return await service.getPosts();
  }

  Future<void> loadFeed({String? feedType, bool force = false}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(networkServiceProvider);
      return await service.getPosts(feedType: feedType);
    });
  }

  void addPostOnTop(NetworkPost post) {
    final current = state.valueOrNull?? [];
    state = AsyncData([post,...current]);
  }

  Future<void> loadMore() async {}

  Future<void> deletePost(String postId) async {
    final current = state.valueOrNull?? [];
    state = AsyncData(current.where((p) => p.id!= postId).toList());
    await ref.read(networkServiceProvider).deletePost(postId);
  }

  Future<void> toggleLike(String postId) async {
    // garde ton code like existant
    final current = state.valueOrNull?? [];
    final idx = current.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final oldPost = current[idx];
    final wasLiked = (oldPost as dynamic).isLiked?? false;
    final oldCount = (oldPost as dynamic).likesCount?? 0;
    final updated = (oldPost as dynamic).copyWith(
      isLiked:!wasLiked,
      likesCount: wasLiked? oldCount - 1 : oldCount + 1,
    ) as NetworkPost;
    final newList = [...current];
    newList[idx] = updated;
    state = AsyncData(newList);
    try {
      final s = ref.read(networkServiceProvider);
      wasLiked? await s.unlikePost(postId) : await s.likePost(postId);
    } catch (_) {
      state = AsyncData(current);
    }
  }
}
