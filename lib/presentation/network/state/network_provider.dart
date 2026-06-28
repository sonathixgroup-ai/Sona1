// lib/presentation/network/state/network_provider.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'network_state.dart';
import 'package:thix_id/presentation/network/services/network_service.dart';
import 'package:thix_id/presentation/network/controllers/network_controller.dart';
import 'package:thix_id/presentation/network/models/post_model.dart';
import 'package:thix_id/presentation/feed/comments_page.dart';
import 'package:thix_id/models/post.dart' as ThixPostModel;
import 'package:thix_id/models/post_media.dart' as ThixPostMedia;
import 'package:supabase_flutter/supabase_flutter.dart';

class NetworkProvider extends ChangeNotifier {
  final NetworkController controller;
  NetworkState state = NetworkState.initial();

  NetworkProvider({required NetworkService service}) : controller = NetworkController(service: service);

  static NetworkProvider of(BuildContext context) => Provider.of<NetworkProvider>(context, listen: false);

  Future<void> init() async {
    if (state.initialized) return;
    state = state.copyWith(isLoading: true);
    notifyListeners();

    try {
      final posts = await controller.fetchPosts();
      final stories = await controller.fetchStories();
      final opps = await controller.fetchOpportunities();
      state = state.copyWith(posts: posts, stories: stories, opportunities: opps, initialized: true);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  Future<void> refreshAll() async {
    // force reload
    state = state.copyWith(isLoading: true);
    notifyListeners();
    try {
      final posts = await controller.fetchPosts();
      state = state.copyWith(posts: posts);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  Future<void> createPost(String content) async {
    // For production you'd pass the profile id; here we assume service handles auth mapping
    state = state.copyWith(isLoading: true);
    notifyListeners();
    try {
      final supabase = Supabase.instance.client;
      final authUid = supabase.auth.currentUser?.id ?? '';
      // In production map authUid -> profiles.id. For now pass authUid as author.
      await controller.createPost('', content);
      await init();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  void openComments(BuildContext context, PostModel post) {
    // Map PostModel -> Thix Post (models/post.dart) used by CommentsPage
    final media = <ThixPostMedia.PostMedia>[];
    for (var i = 0; i < post.mediaUrls.length; i++) {
      media.add(ThixPostMedia.PostMedia(
        id: '',
        postId: post.id,
        storagePath: post.mediaUrls[i],
        url: post.mediaUrls[i],
        mime: '',
        size: 0,
        ordering: i,
      ));
    }

    final authorMap = {
      'id': post.authorId,
      'display_name': post.authorName,
      'photo_url': post.authorPhoto,
    };

    final thixPost = ThixPostModel.Post(
      id: post.id,
      authorId: post.authorId,
      content: post.content,
      privacy: 'public',
      likeCount: post.likeCount,
      commentCount: post.commentCount,
      createdAt: post.createdAt,
      updatedAt: null,
      author: authorMap,
      media: media,
    );

    final currentProfileId = Supabase.instance.client.auth.currentUser?.id ?? '';
    CommentsPage.open(context, post: thixPost, currentProfileId: currentProfileId);
  }
}
