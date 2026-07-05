import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/models/network_connection.dart';
import 'package:thix_id/models/network_post.dart';
import 'package:thix_id/models/network_story.dart';
import 'package:thix_id/providers/feed_provider.dart';
import 'package:thix_id/services/network_service.dart';
import 'widgets/create_post_dialog.dart';
import 'widgets/create_story_dialog.dart';
import 'widgets/post_card.dart';
import 'widgets/short_card.dart';

// ─── COULEURS THIX PRO ───
class ThixColors {
  static const Color background = Color(0xFFF5F7FA);
  static const Color white = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF1877F2);
  static const Color gold = Color(0xFFD4AF37);
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color border = Color(0xFFE5E7EB);
  static const Color red = Color(0xFFFF3B30);
  static const Color green = Color(0xFF059669);
  static const Color shadow = Color(0x0F000000);
}

// ─── PAGE PRINCIPALE ───
class NetworkProHome extends StatefulWidget {
  const NetworkProHome({super.key});

  @override
  State<NetworkProHome> createState() => _NetworkProHomeState();
}

class _NetworkProHomeState extends State<NetworkProHome>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  // ─── ÉTATS ───
  bool _loadingPosts = true;
  bool _isRefreshing = false;
  String _feedType = 'smart';
  int _selectedNavIndex = 0;

  List<NetworkStory> _stories = [];
  bool _loadingStories = false;

  List<NetworkConnection> _suggestions = [];
  bool _loadingSuggestions = false;

  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ─── CHARGEMENT DES DONNÉES ───
  Future<void> _loadAllData() async {
    final feedProvider = Provider.of<FeedProvider>(context, listen: false);
    await Future.wait([
      feedProvider.loadFeed(feedType: _feedType),
      _loadStories(),
      _loadSuggestions(),
    ]);
    if (mounted) setState(() => _loadingPosts = false);
  }

  Future<void> _loadStories() async {
    if (!mounted) return;
    setState(() => _loadingStories = true);
    try {
      final networkService = Provider.of<NetworkService>(context, listen: false);
      final stories = await networkService.getActiveStories();
      if (mounted) setState(() => _stories = stories);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement stories : $e'), backgroundColor: ThixColors.red),
        );
      }
    }
    if (mounted) setState(() => _loadingStories = false);
  }

  Future<void> _loadSuggestions() async {
    if (!mounted) return;
    setState(() => _loadingSuggestions = true);
    try {
      final networkService = Provider.of<NetworkService>(context, listen: false);
      final suggestions = await networkService.getSuggestedConnections(limit: 5);
      if (mounted) setState(() => _suggestions = suggestions);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur suggestions : $e'), backgroundColor: ThixColors.red),
        );
      }
    }
    if (mounted) setState(() => _loadingSuggestions = false);
  }

  Future<void> _loadPosts() async {
    if (!mounted) return;
    final feedProvider = Provider.of<FeedProvider>(context, listen: false);
    setState(() => _loadingPosts = true);
    try {
      await feedProvider.loadFeed(feedType: _feedType, force: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement posts : $e'), backgroundColor: ThixColors.red),
        );
      }
    }
    if (mounted) setState(() => _loadingPosts = false);
  }

  Future<void> _onRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    await _loadAllData();
    if (mounted) setState(() => _isRefreshing = false);
  }

  // ─── NAVIGATION ───
  void _goToSearch() => context.push('/network/search');
  void _goToNotifications() => context.push('/network/notifications');
  void _goToProfile() => context.push('/profile');
  void _goToConnections() => context.push('/network/connections');
  void _goToCommunities() => context.push('/network/communities');
  void _goToDiscover() => context.push('/network/discover');
  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  // ─── ACTIONS ───
  void _viewStory(NetworkStory story) {
    context.push('/network/story/${story.id}');
  }

  void _commentOnPost(NetworkPost post) {
    context.push('/network/comments/${post.id}');
  }

  void _sharePost(NetworkPost post) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Copier le lien'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Envoyer en message'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Partager ailleurs...'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _sendConnectionRequest(NetworkConnection user) async {
    try {
      final networkService = Provider.of<NetworkService>(context, listen: false);
      await networkService.sendConnectionRequest(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation envoyée !'), backgroundColor: ThixColors.green),
        );
        setState(() {
          _suggestions.removeWhere((u) => u.id == user.id);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: ThixColors.red),
        );
      }
    }
  }

  // ─── BUILD ───
  @override
  Widget build(BuildContext context) {
    super.build(context);

    final feedProvider = Provider.of<FeedProvider>(context);
    final posts = feedProvider.posts;
    final isLoading = feedProvider.isLoading;

    final auth = Provider.of<AuthController>(context);
    if (auth.currentUser == null) {
      return const Scaffold(body: Center(child: Text('Connectez-vous')));
    }

    final currentUserId = auth.currentUser!.id;

    return Scaffold(
      backgroundColor: ThixColors.background,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        color: ThixColors.primary,
        onRefresh: _onRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildStoriesRow()),
            SliverToBoxAdapter(child: _buildFilterChips()),
            SliverToBoxAdapter(child: _buildCreatePostBar()),
            if (isLoading && posts.isEmpty)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (posts.isEmpty)
              SliverToBoxAdapter(child: _buildEmptyState())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildPostCard(posts[index], currentUserId),
                  childCount: posts.length,
                ),
              ),
            if (_suggestions.isNotEmpty)
              SliverToBoxAdapter(child: _buildSuggestionsSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─── APP BAR ───
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: ThixColors.white,
      elevation: 0.5,
      automaticallyImplyLeading: false,
      title: const Text(
        'THIX PRO',
        style: TextStyle(
          color: ThixColors.primary,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        IconButton(
          onPressed: _goToSearch,
          icon: const Icon(Icons.search_rounded, color: ThixColors.textDark),
        ),
        Stack(
          children: [
            IconButton(
              onPressed: _goToNotifications,
              icon: const Icon(Icons.notifications_none_rounded, color: ThixColors.textDark),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: ThixColors.red,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '3',
                    style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: _goToProfile,
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: ThixColors.primary,
              child: Icon(Icons.person, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  // ─── STORIES ───
  Widget _buildStoriesRow() {
    return Container(
      color: ThixColors.white,
      padding: const EdgeInsets.only(left: 16, top: 14, bottom: 10),
      child: SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _stories.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) return _buildAddStory();
            final story = _stories[index - 1];
            return _buildStoryItem(story);
          },
        ),
      ),
    );
  }

  Widget _buildAddStory() {
    return GestureDetector(
      onTap: () async {
        final result = await showDialog<bool>(
          context: context,
          builder: (_) => const CreateStoryDialog(),
        );
        if (result == true) {
          _loadStories();
          _loadPosts();
        }
      },
      child: Container(
        width: 78,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ThixColors.gold, width: 2),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 12,
                    color: ThixColors.gold.withOpacity(0.15),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: ThixColors.gold, size: 28),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ma Story',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryItem(NetworkStory story) {
    final hasAvatar = story.userAvatar != null && story.userAvatar!.isNotEmpty;
    return GestureDetector(
      onTap: () => _viewStory(story),
      child: Container(
        width: 78,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [ThixColors.primary, Color(0xFF1565C0)],
                ),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10,
                    color: ThixColors.primary.withOpacity(0.18),
                  ),
                ],
              ),
              child: CircleAvatar(
                backgroundColor: Colors.grey.shade200,
                backgroundImage: hasAvatar ? NetworkImage(story.userAvatar!) : null,
                child: !hasAvatar ? Text(story.userName[0].toUpperCase()) : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              story.userName.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  // ─── FILTRES ───
  Widget _buildFilterChips() {
    final filters = [
      {'icon': Icons.auto_awesome, 'label': 'Pour vous', 'value': 'smart'},
      {'icon': Icons.people_outline, 'label': 'Réseau', 'value': 'network'},
      {'icon': Icons.video_collection_outlined, 'label': 'Shorts', 'value': 'shorts'},
      {'icon': Icons.local_fire_department_outlined, 'label': 'Tendance', 'value': 'popular'},
    ];

    return Container(
      color: ThixColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = _feedType == filter['value'];
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(40),
                onTap: () {
                  setState(() => _feedType = filter['value'] as String);
                  _loadPosts();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? ThixColors.primary : const Color(0xFFF2F4F7),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        filter['icon'] as IconData,
                        size: 17,
                        color: isSelected ? Colors.white : ThixColors.textSecondary,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        filter['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : ThixColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── BARRE DE CRÉATION ───
  Widget _buildCreatePostBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThixColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            offset: const Offset(0, 4),
            color: ThixColors.shadow,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: ThixColors.primary,
                child: Icon(Icons.person, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (_) => const CreatePostDialog(),
                    );
                    if (result == true) _loadPosts();
                  },
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: ThixColors.background,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Quoi de neuf dans votre monde pro ?',
                        style: TextStyle(fontSize: 13, color: ThixColors.textSecondary),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _miniAction(Icons.article_outlined, 'Publication', Colors.deepPurple, _openCreatePost),
              _miniAction(Icons.image_outlined, 'Photo', Colors.green, _openCreatePost),
              _miniAction(Icons.videocam_outlined, 'Vidéo', Colors.red, _openCreatePost),
              _miniAction(Icons.bolt_outlined, 'Short', Colors.orange, _openCreatePost),
            ],
          ),
        ],
      ),
    );
  }

  void _openCreatePost() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const CreatePostDialog(),
    );
    if (result == true) _loadPosts();
  }

  Widget _miniAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ─── POST CARD ───
  Widget _buildPostCard(NetworkPost post, String currentUserId) {
    return PostCard(
      post: post,
      currentProfileId: currentUserId,
      onLike: () {
        HapticFeedback.lightImpact();
        Provider.of<FeedProvider>(context, listen: false).toggleLike(post.id);
      },
      onComment: () => _commentOnPost(post),
      onShare: () => _sharePost(post),
      onSave: () => _loadPosts(),
      onEdit: () => _loadPosts(),
      onDelete: () => _loadPosts(),
    );
  }

  // ─── SUGGESTIONS ───
  Widget _buildSuggestionsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThixColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 4),
            color: ThixColors.shadow,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Suggestions de connexion',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _suggestions.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = _suggestions[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                  child: user.avatarUrl == null ? Text(user.name[0].toUpperCase()) : null,
                ),
                title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(user.title ?? '', style: TextStyle(color: ThixColors.textSecondary)),
                trailing: IconButton(
                  icon: const Icon(Icons.person_add_alt_1, color: ThixColors.primary),
                  onPressed: () => _sendConnectionRequest(user),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── FAB ───
  Widget _buildFab() {
    return Container(
      height: 64,
      width: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [ThixColors.gold, Color(0xFFE5C55E)],
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            offset: const Offset(0, 8),
            color: ThixColors.gold.withOpacity(0.4),
          ),
        ],
      ),
      child: FloatingActionButton(
        backgroundColor: Colors.transparent,
        elevation: 0,
        onPressed: _openCreatePost,
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),
    );
  }

  // ─── BOTTOM NAV ───
  Widget _buildBottomNav() {
    return BottomAppBar(
      height: 60,
      shape: const CircularNotchedRectangle(),
      notchMargin: 6,
      color: ThixColors.white,
      elevation: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_rounded, 'Accueil', _selectedNavIndex == 0, _scrollToTop),
          _navItem(Icons.explore_rounded, 'Découvrir', _selectedNavIndex == 1, _goToDiscover),
          const SizedBox(width: 40),
          _navItem(Icons.people_rounded, 'Connexions', _selectedNavIndex == 3, _goToConnections),
          _navItem(Icons.groups_rounded, 'Communautés', _selectedNavIndex == 4, _goToCommunities),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: active ? ThixColors.primary : Colors.grey.shade500,
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: active ? ThixColors.primary : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── ÉTAT VIDE ───
  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Center(
        child: Text(
          'Aucune publication\nCommencez à suivre des personnes !',
          textAlign: TextAlign.center,
          style: TextStyle(color: ThixColors.textSecondary, fontSize: 14),
        ),
      ),
    );
  }
}
