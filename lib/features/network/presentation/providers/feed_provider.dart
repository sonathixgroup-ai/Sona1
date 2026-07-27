import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thix_id/models/network_post.dart';
import 'package:thix_id/features/network/data/network_service_provider.dart';

final feedProvider = AsyncNotifierProvider<Feed, List<NetworkPost>>(Feed.new);

class Feed extends AsyncNotifier<List<NetworkPost>> {
  bool get hasMore => false;

  @override
  Future<List<NetworkPost>> build() async {
    // TODO: rebranche ta vraie méthode: ex: ref.read(networkServiceProvider).getPosts()
    // Pour que le build WEB passe on retourne vide
    try {
      final service = ref.read(networkServiceProvider);
      // si tu as getPosts() / fetchFeed() / getAllPosts() mets-le ici
      // final posts = await service.getPosts();
      // return posts;
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<void> loadFeed({String? feedType, bool force = false}) async {
    if (force) state = const AsyncLoading();
    state = await AsyncValue.guard(() async => await build());
  }

  Future<void> loadMore() async {}

  Future<void> deletePost(String postId) async {
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((p) => p.id != postId).toList());
    try {
      await ref.read(networkServiceProvider).deletePost(postId);
    } catch (_) {
      state = AsyncData(current);
    }
  }
}
