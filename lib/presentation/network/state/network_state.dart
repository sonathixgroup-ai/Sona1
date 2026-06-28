// lib/presentation/network/state/network_state.dart
import 'package:thix_id/presentation/network/models/post_model.dart';
import 'package:thix_id/presentation/network/models/story_model.dart';
import 'package:thix_id/presentation/network/models/opportunity_model.dart';

class NetworkState {
  final List<PostModel> posts;
  final List<StoryModel> stories;
  final List<OpportunityModel> opportunities;
  final bool isLoading;
  final bool initialized;
  final String? error;

  NetworkState({required this.posts, required this.stories, required this.opportunities, required this.isLoading, required this.initialized, this.error});

  factory NetworkState.initial() => NetworkState(posts: [], stories: [], opportunities: [], isLoading: false, initialized: false);

  NetworkState copyWith({List<PostModel>? posts, List<StoryModel>? stories, List<OpportunityModel>? opportunities, bool? isLoading, bool? initialized, String? error}) {
    return NetworkState(
      posts: posts ?? this.posts,
      stories: stories ?? this.stories,
      opportunities: opportunities ?? this.opportunities,
      isLoading: isLoading ?? this.isLoading,
      initialized: initialized ?? this.initialized,
      error: error ?? this.error,
    );
  }
}
