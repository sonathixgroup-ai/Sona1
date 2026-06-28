// lib/presentation/network/state/network_provider.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'network_state.dart';
import 'package:thix_id/presentation/network/services/network_service.dart';
import 'package:thix_id/presentation/network/controllers/network_controller.dart';

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
    await init();
  }

  Future<void> createPost(String content) async {
    // For production you'd pass the profile id; here we assume service handles auth mapping
    state = state.copyWith(isLoading: true);
    notifyListeners();
    try {
      await controller.createPost('', content);
      await init();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  void openComments(BuildContext context, dynamic post) {
    // delegate to navigator or emit event; left to consumer
  }
}
