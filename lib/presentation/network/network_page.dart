import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/thix_user_model.dart';
import '../../data/models/post_model.dart';
import '../../data/models/story_model.dart';
import '../../data/models/metric_model.dart';
import '../../data/models/short_model.dart';
import '../../data/repositories/network_repository.dart';
import 'network_view_model.dart';
import 'widgets/network_app_bar.dart';
import 'widgets/story_carousel.dart';
import 'widgets/create_post_bar.dart';
import 'widgets/metrics_grid.dart';
import 'widgets/activity_chart.dart';
import 'widgets/post_card.dart';
import 'widgets/short_item.dart';

class NetworkPage extends StatefulWidget {
  const NetworkPage({super.key});

  @override
  State<NetworkPage> createState() => _NetworkPageState();
}

class _NetworkPageState extends State<NetworkPage> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => NetworkViewModel(
        repository: NetworkRepository(
          supabaseClient: Supabase.instance.client,
        ),
        currentUser: ThixUser(
          id: Supabase.instance.client.auth.currentUser?.id ?? '',
          firstName: 'Jean',
          lastName: 'Dupont',
          email: Supabase.instance.client.auth.currentUser?.email ?? '',
          avatarUrl: null,
          isVerified: true,
        ),
      )..loadInitialData(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: const NetworkAppBar(),
        body: SafeArea(
          child: Consumer<NetworkViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (viewModel.error != null) {
                return Center(child: Text('Erreur: ${viewModel.error}'));
              }
              return RefreshIndicator(
                onRefresh: viewModel.loadInitialData,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    const SizedBox(height: 8),
                    // Stories
                    StoryCarousel(stories: viewModel.stories),
                    const SizedBox(height: 16),
                    // Barre de création
                    const CreatePostBar(),
                    const SizedBox(height: 12),
                    // Métriques
                    MetricsGrid(metrics: viewModel.metrics),
                    const SizedBox(height: 12),
                    // Graphique
                    ActivityChart(data: viewModel.chartData),
                    const SizedBox(height: 12),
                    // Posts
                    ...viewModel.posts.map((post) => PostCard(
                          post: post,
                          onLike: () => viewModel.toggleLike(post.id),
                          onComment: () => _openCommentModal(post.id),
                          onShare: () => viewModel.sharePost(post.id),
                          onSave: () => viewModel.toggleSave(post.id),
                        )),
                    const SizedBox(height: 12),
                    // Short
                    if (viewModel.shorts.isNotEmpty)
                      ShortItem(short: viewModel.shorts.first),
                    const SizedBox(height: 80),
                  ],
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedTabIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1A73E8),
        unselectedItemColor: Colors.grey.shade600,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        onTap: (index) => setState(() => _selectedTabIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, size: 24),
            activeIcon: Icon(Icons.home, size: 24),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined, size: 24),
            activeIcon: Icon(Icons.folder, size: 24),
            label: 'Projets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline, size: 24),
            activeIcon: Icon(Icons.people, size: 24),
            label: 'Équipe',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_outlined, size: 24),
            activeIcon: Icon(Icons.chat, size: 24),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined, size: 24),
            activeIcon: Icon(Icons.settings, size: 24),
            label: 'Paramètres',
          ),
        ],
      ),
    );
  }

  void _openCommentModal(String postId) {
    // Implémentez l'ouverture de la modale de commentaires
    // (à faire dans un fichier séparé)
  }
}
