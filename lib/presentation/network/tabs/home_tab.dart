import 'package:flutter/material.dart';
import '../widgets/feed.dart';

class HomeTab extends StatelessWidget {
  final List<Post> posts;
  final List<Story> stories;
  final List<Metric> metrics;
  final List<double> chartData;
  final Function(String) onLike;
  final Function(String) onComment;
  final Function(String) onShare;
  final Function(String) onSave;

  const HomeTab({
    super.key,
    required this.posts,
    required this.stories,
    required this.metrics,
    required this.chartData,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {}, // Géré par le parent
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 8),
          // Stories
          StoryCarousel(stories: stories),
          const SizedBox(height: 16),
          // Barre de création
          const CreatePostBar(),
          const SizedBox(height: 12),
          // Métriques
          MetricsGrid(metrics: metrics),
          const SizedBox(height: 12),
          // Graphique
          ActivityChart(data: chartData),
          const SizedBox(height: 12),
          // Posts
          ...posts.map((post) => PostCard(
                post: post,
                onLike: () => onLike(post.id),
                onComment: () => onComment(post.id),
                onShare: () => onShare(post.id),
                onSave: () => onSave(post.id),
              )),
          const SizedBox(height: 12),
          // Shorts (exemple : afficher le premier)
          if (shorts.isNotEmpty) ShortCard(short: shorts.first),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
