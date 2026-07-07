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
import 'widgets/post_card.dart';    // ✅ Utilise la version corrigée
import 'widgets/short_card.dart';

// ─── COULEURS THIX PRO — Élite lumineux, bleu institutionnel ───
class ThixColors {
  static const Color background = Color(0xFFF6F9FF); // fond bleuté lumineux, pas gris terne
  static const Color white = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF2D6CDF);     // bleu vif premium
  static const Color primaryDeep = Color(0xFF123B7A);
  static const Color softBlue = Color(0xFFEAF1FF);
  static const Color gold = Color(0xFFD9A63C);
  static const Color textDark = Color(0xFF10192E);
  static const Color textSecondary = Color(0xFF7386A8);
  static const Color border = Color(0xFFE7EEFC);
  static const Color red = Color(0xFFFF3B30);
  static const Color green = Color(0xFF059669);
  static const Color shadow = Color(0x142D6CDF); // ombre teintée bleue, pas grise
}

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
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: ThixColors.primary)))
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

  // ─── APP BAR — compacte, lumineuse ───
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: ThixColors.white,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      surfaceTintColor: ThixColors.white,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [ThixColors.primaryDeep, ThixColors.primary],
        ).createShader(bounds),
        child: const Text(
          'THIX PRO',
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
      ),
      actions: [
        _appBarIcon(Icons.search_rounded, _goToSearch),
        Stack(
          clipBehavior: Clip.none,
          children: [
            _appBarIcon(Icons.notifications_none_rounded, _goToNotifications),
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                width: 15,
                height: 15,
                decoration: const BoxDecoration(color: ThixColors.red, shape: BoxShape.circle),
                child: const Center(
                  child: Text('3', style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 14, left: 2),
          child: GestureDetector(
            onTap: _goToProfile,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [ThixColors.primaryDeep, ThixColors.primary]),
                boxShadow: [BoxShadow(color: ThixColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _appBarIcon(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: ThixColors.textDark, size: 21),
    );
  }

  // ─── STORIES — compactes, style Facebook, peu d'espace vertical ───
  Widget _buildStoriesRow() {
    return Container(
      color: ThixColors.white,
      padding: const EdgeInsets.only(left: 14, top: 10, bottom: 8),
      child: SizedBox(
        height: 68, // ✅ hauteur réduite (vs 100 avant) — bandeau compact type FB
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
        width: 56,
        margin: const EdgeInsets.only(right: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [ThixColors.softBlue, Color(0xFFE3EDFF)]),
                border: Border.all(color: ThixColors.gold, width: 1.6),
                boxShadow: [BoxShadow(blurRadius: 10, color: ThixColors.gold.withOpacity(0.18), offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.add_rounded, color: ThixColors.gold, size: 21),
            ),
            const SizedBox(height: 4),
            const Text(
              'Story',
              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: ThixColors.textDark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
        width: 56,
        margin: const EdgeInsets.only(right: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [ThixColors.primary, ThixColors.primaryDeep]),
                boxShadow: [BoxShadow(blurRadius: 8, color: ThixColors.primary.withOpacity(0.22), offset: const Offset(0, 3))],
              ),
              child: CircleAvatar(
                backgroundColor: ThixColors.softBlue,
                backgroundImage: hasAvatar ? NetworkImage(story.userAvatar!) : null,
                child: !hasAvatar
                    ? Text(story.userName[0].toUpperCase(),
                        style: const TextStyle(fontSize: 13, color: ThixColors.primaryDeep, fontWeight: FontWeight.w700))
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              story.userName.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: ThixColors.textDark),
            ),
          ],
        ),
      ),
    );
  }

  // ─── FILTRES — pilules compactes ───
  Widget _buildFilterChips() {
    final filters = [
      {'icon': Icons.auto_awesome_rounded, 'label': 'Pour vous', 'value': 'smart'},
      {'icon': Icons.people_alt_rounded, 'label': 'Réseau', 'value': 'network'},
      {'icon': Icons.play_circle_fill_rounded, 'label': 'Shorts', 'value': 'shorts'},
      {'icon': Icons.local_fire_department_rounded, 'label': 'Tendance', 'value': 'popular'},
    ];

    return Container(
      color: ThixColors.white,
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = _feedType == filter['value'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () {
                  setState(() => _feedType = filter['value'] as String);
                  _loadPosts();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(colors: [ThixColors.primaryDeep, ThixColors.primary])
                        : null,
                    color: isSelected ? null : ThixColors.softBlue,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: isSelected
                        ? [BoxShadow(color: ThixColors.primary.withOpacity(0.28), blurRadius: 10, offset: const Offset(0, 4))]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        filter['icon'] as IconData,
                        size: 14,
                        color: isSelected ? Colors.white : ThixColors.primaryDeep,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        filter['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
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

  // ─── BARRE DE CRÉATION — compacte, lumineuse ───
  Widget _buildCreatePostBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ThixColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ThixColors.border),
        boxShadow: [BoxShadow(blurRadius: 14, offset: const Offset(0, 6), color: ThixColors.shadow)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [ThixColors.primaryDeep, ThixColors.primary]),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
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
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: ThixColors.softBlue,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Quoi de neuf dans votre monde pro ?',
                        style: TextStyle(fontSize: 12, color: ThixColors.textSecondary),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _miniAction(Icons.article_rounded, 'Post', const Color(0xFF6C4DE6), _openCreatePost),
              _miniAction(Icons.image_rounded, 'Photo', ThixColors.green, _openCreatePost),
              _miniAction(Icons.videocam_rounded, 'Vidéo', const Color(0xFFE5484D), _openCreatePost),
              _miniAction(Icons.bolt_rounded, 'Short', ThixColors.gold, _openCreatePost),
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
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: ThixColors.textDark)),
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

  // ─── SUGGESTIONS — compact ───
  Widget _buildSuggestionsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ThixColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ThixColors.border),
        boxShadow: [BoxShadow(blurRadius: 12, offset: const Offset(0, 5), color: ThixColors.shadow)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Suggestions de connexion',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: ThixColors.textDark),
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _suggestions.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: ThixColors.border),
            itemBuilder: (context, index) {
              final user = _suggestions[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: ThixColors.softBlue,
                      backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                      child: user.avatarUrl == null
                          ? Text(user.name[0].toUpperCase(), style: const TextStyle(fontSize: 12, color: ThixColors.primaryDeep))
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: ThixColors.textDark)),
                          if ((user.title ?? '').isNotEmpty)
                            Text(user.title!, style: const TextStyle(fontSize: 10.5, color: ThixColors.textSecondary)),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => _sendConnectionRequest(user),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(color: ThixColors.softBlue, shape: BoxShape.circle),
                        child: const Icon(Icons.person_add_alt_1_rounded, color: ThixColors.primary, size: 16),
                      ),
                    ),
                  ],
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
      height: 58,
      width: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(colors: [ThixColors.gold, Color(0xFFEFC777)]),
        boxShadow: [BoxShadow(blurRadius: 18, offset: const Offset(0, 8), color: ThixColors.gold.withOpacity(0.4))],
      ),
      child: FloatingActionButton(
        backgroundColor: Colors.transparent,
        elevation: 0,
        onPressed: _openCreatePost,
        child: const Icon(Icons.add_rounded, size: 27, color: Colors.white),
      ),
    );
  }

  // ─── BOTTOM NAV — flottante, incurvée ───
  Widget _buildBottomNav() {
    return BottomAppBar(
      height: 58,
      shape: const CircularNotchedRectangle(),
      notchMargin: 6,
      color: ThixColors.white,
      elevation: 0,
      surfaceTintColor: ThixColors.white,
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
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: active ? ThixColors.softBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: active ? ThixColors.primary : ThixColors.textSecondary, size: 20),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: active ? ThixColors.primary : ThixColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ÉTAT VIDE ───
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: ThixColors.softBlue, shape: BoxShape.circle),
              child: const Icon(Icons.dynamic_feed_rounded, color: ThixColors.primary, size: 30),
            ),
            const SizedBox(height: 14),
            const Text(
              'Aucune publication\nCommencez à suivre des personnes !',
              textAlign: TextAlign.center,
              style: TextStyle(color: ThixColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
