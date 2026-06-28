import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'network_view_model.dart';
import 'widgets/app_bar_widgets.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/feed_widgets.dart';
import 'tabs/discover_tab.dart';
import 'tabs/connections_tab.dart';
import 'tabs/profile_tab.dart';

class NetworkPage extends StatefulWidget {
  const NetworkPage({super.key});

  @override
  State<NetworkPage> createState() => _NetworkPageState();
}

class _NetworkPageState extends State<NetworkPage> {
  int _selectedIndex = 0; // 0: Accueil, 1: Découvrir, 2: Connexions, 3: Profil
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NetworkViewModel(
        supabase: Supabase.instance.client,
        currentUserId: Supabase.instance.client.auth.currentUser?.id ?? '',
      )..loadInitialData(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: const NetworkAppBar(),
        body: SafeArea(
          child: Consumer<NetworkViewModel>(
            builder: (context, vm, _) {
              if (vm.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A73E8)),
                  ),
                );
              }
              if (vm.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text('Erreur : ${vm.error}', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: vm.loadInitialData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A73E8),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                );
              }
              return PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _selectedIndex = index);
                },
                children: [
                  // Onglet Accueil (feed principal)
                  FeedWidgets(
                    stories: vm.stories,
                    metrics: vm.metrics,
                    chartData: vm.chartData,
                    posts: vm.posts,
                    shorts: vm.shorts,
                    opportunities: vm.opportunities,
                    onLike: vm.toggleLike,
                    onComment: (postId) => _openCommentModal(context, postId, vm),
                    onShare: vm.sharePost,
                    onSave: vm.toggleSave,
                    onCreatePost: () => _openCreatePost(context),
                  ),
                  // Onglet Découvrir
                  const DiscoverTab(),
                  // Onglet Connexions
                  const ConnectionsTab(),
                  // Onglet Profil
                  const ProfileTab(),
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: BottomNav(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() => _selectedIndex = index);
            _pageController.jumpToPage(index);
          },
        ),
      ),
    );
  }

  // Ouvre la modale des commentaires
  void _openCommentModal(BuildContext context, String postId, NetworkViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Commentaires', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: FutureBuilder(
                future: vm.getComments(postId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Erreur : ${snapshot.error}'));
                  }
                  final comments = snapshot.data ?? [];
                  if (comments.isEmpty) {
                    return const Center(child: Text('Aucun commentaire pour le moment.'));
                  }
                  return ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final c = comments[index];
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundImage: c['avatar_url'] != null
                              ? NetworkImage(c['avatar_url'])
                              : null,
                          child: c['avatar_url'] == null
                              ? Text(c['user_name'][0].toUpperCase())
                              : null,
                        ),
                        title: Text(
                          c['user_name'],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text(c['content'], style: const TextStyle(fontSize: 13)),
                        trailing: Text(
                          c['created_at'].toString().substring(0, 16),
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController(),
                    decoration: InputDecoration(
                      hintText: 'Écrire un commentaire...',
                      hintStyle: const TextStyle(fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onSubmitted: (value) async {
                      if (value.isNotEmpty) {
                        await vm.addComment(postId, value);
                        // Recharger les commentaires (on pourrait rafraîchir le snapshot)
                        // Pour simplifier, on referme la modale et on rouvre
                        Navigator.pop(context);
                        _openCommentModal(context, postId, vm);
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF1A73E8)),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openCreatePost(BuildContext context) {
    // Navigation vers l'écran de création
    // Pour l'exemple, on affiche une alerte
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Créer une publication'),
        content: const Text('Cette fonctionnalité sera bientôt disponible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
