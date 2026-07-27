import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thix_id/models/network_post.dart';
import 'package:thix_id/features/network/data/network_service_provider.dart';

final feedProvider = AsyncNotifierProvider<Feed, List<NetworkPost>>(Feed.new);

class Feed extends AsyncNotifier<List<NetworkPost>> {
  bool get hasMore => false;

  @override
  Future<List<NetworkPost>> build() async {
    return [];
  }

  Future<void> loadFeed({String? feedType, bool force = false}) async {
    if (force) state = const AsyncLoading();
    state = await AsyncValue.guard(() async => await build());
  }

  Future<void> loadMore() async {}

  Future<void> deletePost(String postId) async {
    final current = state.valueOrNull?? [];
    state = AsyncData(current.where((p) => p.id!= postId).toList());
    try {
      await ref.read(networkServiceProvider).deletePost(postId);
    } catch (_) {
      state = AsyncData(current);
    }
  }

  Future<void> toggleLike(String postId) async {
    final current = state.valueOrNull?? [];
    final idx = current.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final oldPost = current[idx];
    final wasLiked = (oldPost as dynamic).isLiked as bool??? false;
    final oldCount = (oldPost as dynamic).likesCount as int??? 0;

    try {
      final updated = (oldPost as dynamic).copyWith(
        isLiked:!wasLiked,
        likesCount: wasLiked? oldCount - 1 : oldCount + 1,
      ) as NetworkPost;
      final newList = [...current];
      newList[idx] = updated;
      state = AsyncData(newList);
    } catch (_) {}

    try {
      final service = ref.read(networkServiceProvider);
      if (wasLiked) {
        await service.unlikePost(postId);
      } else {
        await service.likePost(postId);
      }
    } catch (_) {
      state = AsyncData(current);
    }
  }
}
