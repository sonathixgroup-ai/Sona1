import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'network_view_model.dart';
import 'tabs/home_tab.dart';
import 'tabs/projects_tab.dart';
import 'tabs/team_tab.dart';
import 'tabs/messages_tab.dart';
import 'tabs/settings_tab.dart';

class NetworkPage extends StatefulWidget {
  const NetworkPage({super.key});

  @override
  State<NetworkPage> createState() => _NetworkPageState();
}

class _NetworkPageState extends State<NetworkPage> {
  int _selectedTab = 0;
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
        body: SafeArea(
          child: Consumer<NetworkViewModel>(
            builder: (context, vm, _) {
              if (vm.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (vm.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text('Erreur: ${vm.error}', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: vm.loadInitialData,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                );
              }
              return PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _selectedTab = index);
                },
                children: [
                  HomeTab(
                    posts: vm.posts,
                    stories: vm.stories,
                    metrics: vm.metrics,
                    chartData: vm.chartData,
                    onLike: vm.toggleLike,
                    onComment: (postId) => _openCommentModal(context, postId, vm),
                    onShare: vm.sharePost,
                    onSave: vm.toggleSave,
                  ),
                  const ProjectsTab(),
                  const TeamTab(),
                  const MessagesTab(),
                  const SettingsTab(),
                ],
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
        currentIndex: _selectedTab,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1A73E8),
        unselectedItemColor: Colors.grey.shade600,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        onTap: (index) {
          setState(() => _selectedTab = index);
          _pageController.jumpToPage(index);
        },
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
                    return Center(child: Text('Erreur: ${snapshot.error}'));
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
                          backgroundImage: c['avatar_url'] != null
                              ? NetworkImage(c['avatar_url'])
                              : null,
                          child: c['avatar_url'] == null
                              ? Text(c['user_name'][0].toUpperCase())
                              : null,
                        ),
                        title: Text(c['user_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(c['content']),
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
                        // Recharger les commentaires
                        // (on pourrait rafraîchir le snapshot via un StatefulBuilder)
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
}
