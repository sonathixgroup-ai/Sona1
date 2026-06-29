// lib/presentation/network/network_pro_home.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/models/network_post.dart';
import 'package:thix_id/models/network_story.dart';
import 'package:thix_id/models/network_connection.dart';
import 'package:thix_id/providers/feed_provider.dart';
import 'package:thix_id/services/network_service.dart';
import 'widgets/create_post_dialog.dart';
import 'widgets/create_story_dialog.dart';

class NetworkProHome extends StatefulWidget {
  const NetworkProHome({super.key});

  @override
  State<NetworkProHome> createState() => _NetworkProHomeState();
}

class _NetworkProHomeState extends State<NetworkProHome> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _fabAnimationController;
  bool _loadingPosts = true;
  bool _isRefreshing = false;
  String _feedType = 'smart';
  int _selectedNavIndex = 0;

  // Stories
  List<NetworkStory> _stories = [];
  bool _loadingStories = false;

  // Suggestions
  List<NetworkConnection> _suggestions = [];
  bool _loadingSuggestions = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    final feedProvider = Provider.of<FeedProvider>(context, listen: false);
    await Future.wait([
      feedProvider.loadFeed(feedType: _feedType),
      _loadStories(),
      _loadSuggestions(),
    ]);
    if (mounted) {
      setState(() => _loadingPosts = false);
    }
  }

  Future<void> _loadStories() async {
    if (!mounted) return;
    setState(() => _loadingStories = true);
    try {
      final networkService = Provider.of<NetworkService>(context, listen: false);
      final stories = await networkService.getActiveStories();
      if (mounted) setState(() => _stories = stories);
    } catch (e) {
      debugPrint('❌ Erreur _loadStories: $e');
    } finally {
      if (mounted) setState(() => _loadingStories = false);
    }
  }

  Future<void> _loadSuggestions() async {
    if (!mounted) return;
    setState(() => _loadingSuggestions = true);
    try {
      final networkService = Provider.of<NetworkService>(context, listen: false);
      final suggestions = await networkService.getSuggestedConnections(limit: 5);
      if (mounted) setState(() => _suggestions = suggestions);
    } catch (e) {
      debugPrint('❌ Erreur _loadSuggestions: $e');
    } finally {
      if (mounted) setState(() => _loadingSuggestions = false);
    }
  }

  Future<void> _loadPosts() async {
    if (!mounted) return;
    final feedProvider = Provider.of<FeedProvider>(context, listen: false);
    setState(() => _loadingPosts = true);
    try {
      await feedProvider.loadFeed(feedType: _feedType);
      if (mounted) setState(() => _loadingPosts = false);
    } catch (e) {
      debugPrint('❌ Erreur _loadPosts: $e');
      if (mounted) setState(() => _loadingPosts = false);
    }
  }

  Future<void> _onRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    await _loadAllData();
    if (mounted) setState(() => _isRefreshing = false);
  }

  void _goToSearch() => context.push('/network/search');
  void _goToNotifications() => context.push('/network/notifications');
  void _goToMessages() => context.push('/network/messages');
  void _goToConnexions() => context.push('/network/connections');
  void _goToProfile() => context.push('/profile');

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final feedProvider = Provider.of<FeedProvider>(context);
    final posts = feedProvider.posts;
    final isLoading = feedProvider.isLoading;
    final auth = Provider.of<AuthController>(context);

    if (auth.currentUser == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Connectez-vous pour accéder au Réseau Pro',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.push('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: const Color(0xFF0B1B3D),
                ),
                child: const Text('Se connecter'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: const Color(0xFFD4AF37),
        child: CustomScrollView(
          slivers: [
            // Search bar
            SliverToBoxAdapter(child: _buildSearchBar()),
            // Stories row
            SliverToBoxAdapter(child: _buildStoriesRow()),
            // Feed filter chips
            SliverToBoxAdapter(child: _buildFilterChips()),
            if (isLoading && posts.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                  ),
                ),
              )
            else if (posts.isEmpty && !isLoading)
              SliverToBoxAdapter(child: _buildEmptyState())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildPostCard(posts[index]),
                  childCount: posts.length,
                ),
              ),
            // Suggestions section
            if (_suggestions.isNotEmpty)
              SliverToBoxAdapter(child: _buildSuggestionsSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF0B1B3D),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('T', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Réseau Pro',
            style: TextStyle(color: Color(0xFF0B1B3D), fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Color(0xFF0B1B3D)),
          onPressed: _goToNotifications,
        ),
        IconButton(
          icon: const Icon(Icons.mail_outline, color: Color(0xFF0B1B3D)),
          onPressed: _goToMessages,
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: GestureDetector(
        onTap: _goToSearch,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.grey[300]!),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.grey[500], size: 20),
              const SizedBox(width: 8),
              Text(
                'Rechercher des personnes, posts…',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoriesRow() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Stories',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0B1B3D)),
              ),
              TextButton(
                onPressed: () async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) => const CreateStoryDialog(),
                  );
                  if (result == true) _loadStories();
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFD4AF37),
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                ),
                child: const Text('+ Ajouter', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 88,
            child: _loadingStories
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Color(0xFFD4AF37))))
                : _stories.isEmpty
                    ? Center(
                        child: GestureDetector(
                          onTap: () async {
                            final result = await showDialog<bool>(
                              context: context,
                              builder: (context) => const CreateStoryDialog(),
                            );
                            if (result == true) _loadStories();
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4AF37).withOpacity(0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFD4AF37), width: 2, style: BorderStyle.solid),
                                ),
                                child: const Icon(Icons.add, color: Color(0xFFD4AF37), size: 28),
                              ),
                              const SizedBox(height: 4),
                              const Text('Votre story', style: TextStyle(fontSize: 10, color: Color(0xFFD4AF37))),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _stories.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return GestureDetector(
                              onTap: () async {
                                final result = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => const CreateStoryDialog(),
                                );
                                if (result == true) _loadStories();
                              },
                              child: Container(
                                width: 64,
                                margin: const EdgeInsets.only(right: 12),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD4AF37).withOpacity(0.15),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                                      ),
                                      child: const Icon(Icons.add, color: Color(0xFFD4AF37), size: 24),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text('Ajouter', style: TextStyle(fontSize: 9, color: Color(0xFFD4AF37)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            );
                          }
                          final story = _stories[index - 1];
                          final hasAvatar = story.userAvatar != null && story.userAvatar!.isNotEmpty;
                          return Container(
                            width: 64,
                            margin: const EdgeInsets.only(right: 12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(colors: [Color(0xFFD4AF37), Colors.orange]),
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  child: CircleAvatar(
                                    backgroundImage: hasAvatar ? NetworkImage(story.userAvatar!) : null,
                                    backgroundColor: Colors.grey[200],
                                    child: !hasAvatar
                                        ? Text(
                                            story.userName.trim().isNotEmpty ? story.userName.trim()[0].toUpperCase() : '?',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  story.userName.split(' ').first,
                                  style: const TextStyle(fontSize: 9),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'icon': Icons.smart_toy_outlined, 'label': 'Smart Feed', 'value': 'smart'},
      {'icon': Icons.trending_up, 'label': 'Populaires', 'value': 'popular'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SizedBox(
        height: 36,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: filters.length,
          itemBuilder: (context, index) {
            final filter = filters[index];
            final isSelected = _feedType == filter['value'];
            return Container(
              margin: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(filter['icon'] as IconData, size: 14, color: isSelected ? const Color(0xFFD4AF37) : Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(filter['label'] as String, style: TextStyle(fontSize: 11, color: isSelected ? const Color(0xFFD4AF37) : Colors.grey[600])),
                  ],
                ),
                onSelected: (selected) {
                  setState(() => _feedType = filter['value'] as String);
                  _loadPosts();
                },
                backgroundColor: Colors.white,
                selectedColor: const Color(0xFFD4AF37).withOpacity(0.1),
                side: BorderSide(color: isSelected ? const Color(0xFFD4AF37) : Colors.grey[300]!),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPostCard(NetworkPost post) {
    final isLiked = post.isLiked;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: post.authorAvatar != null && post.authorAvatar!.isNotEmpty
                      ? NetworkImage(post.authorAvatar!)
                      : null,
                  radius: 20,
                  backgroundColor: Colors.grey[200],
                  child: post.authorAvatar == null || post.authorAvatar!.isEmpty
                      ? Text(
                          post.authorName.trim().isNotEmpty ? post.authorName.trim()[0].toUpperCase() : '?',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      if (post.authorTitle != null && post.authorTitle!.isNotEmpty)
                        Text(
                          post.authorTitle!,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(child: Text('Signaler')),
                    const PopupMenuItem(child: Text('Ne plus voir')),
                  ],
                  icon: const Icon(Icons.more_horiz, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Content
            if (post.content.isNotEmpty)
              Text(post.content, style: const TextStyle(fontSize: 13)),

            // Images
            if (post.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 8),
              if (post.imageUrls.length == 1)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    post.imageUrls.first,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => Container(
                      height: 80,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                )
              else
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: post.imageUrls.take(4).map((url) => ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  )).toList(),
                ),
            ],

            const SizedBox(height: 10),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${post.likesCount} ${post.likesCount == 1 ? 'J\'aime' : 'J\'aimes'}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Text(
                  '${post.commentsCount} commentaire${post.commentsCount == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),

            const Divider(height: 14),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  label: 'J\'aime',
                  color: isLiked ? Colors.red : Colors.grey[600],
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Provider.of<FeedProvider>(context, listen: false).toggleLike(post.id);
                  },
                ),
                _buildActionButton(
                  icon: Icons.comment_outlined,
                  label: 'Commenter',
                  color: Colors.grey[600],
                  onTap: () => _showCommentDialog(post),
                ),
                _buildActionButton(
                  icon: Icons.share_outlined,
                  label: 'Partager',
                  color: Colors.grey[600],
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color? color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }

  Future<void> _showCommentDialog(NetworkPost post) async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un commentaire'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Écrivez votre commentaire…',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          autofocus: true,
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFD4AF37)),
            child: const Text('Publier'),
          ),
        ],
      ),
    );

    if (result == true && controller.text.trim().isNotEmpty && mounted) {
      final feedProvider = Provider.of<FeedProvider>(context, listen: false);
      await feedProvider.addComment(post.id, controller.text.trim());
    }
  }

  Widget _buildSuggestionsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Personnes à connaître',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0B1B3D)),
              ),
              TextButton(
                onPressed: _goToConnexions,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFD4AF37),
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                ),
                child: const Text('Voir tout', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._suggestions.take(3).map((suggestion) => _buildSuggestionItem(suggestion)),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(NetworkConnection suggestion) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.grey[200],
            backgroundImage: suggestion.avatar != null && suggestion.avatar!.isNotEmpty
                ? NetworkImage(suggestion.avatar!)
                : null,
            child: suggestion.avatar == null || suggestion.avatar!.isEmpty
                ? Text(
                    suggestion.name.trim().isNotEmpty ? suggestion.name.trim()[0].toUpperCase() : '?',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600]),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(suggestion.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(suggestion.title, style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () async {
              try {
                final networkService = Provider.of<NetworkService>(context, listen: false);
                await networkService.sendConnectionRequest(suggestion.id);
                if (mounted) {
                  setState(() => _suggestions.removeWhere((s) => s.id == suggestion.id));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Demande envoyée!'), backgroundColor: Colors.green, duration: Duration(seconds: 2)),
                  );
                }
              } catch (e) {
                debugPrint('Error sending connection request: $e');
              }
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFD4AF37)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: const Size(80, 28),
            ),
            child: const Text('Connecter', style: TextStyle(fontSize: 11, color: Color(0xFFD4AF37))),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => const CreatePostDialog(),
        ).then((_) {
          // Reload feed after dialog closes as a safety net (CreatePostDialog
          // already reloads internally, but this guards against edge cases).
          if (mounted) _loadPosts();
        });
      },
      label: const Text('Publier'),
      icon: const Icon(Icons.edit),
      backgroundColor: const Color(0xFFD4AF37),
      foregroundColor: const Color(0xFF0B1B3D),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: (index) {
          setState(() => _selectedNavIndex = index);
          HapticFeedback.lightImpact();
          switch (index) {
            case 0:
              break;
            case 1:
              _goToSearch();
              break;
            case 2:
              _goToConnexions();
              break;
            case 3:
              _goToProfile();
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFD4AF37),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontSize: 10),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        backgroundColor: Colors.white,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined, size: 22), activeIcon: Icon(Icons.home, size: 22), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.search, size: 22), label: 'Recherche'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline, size: 22), activeIcon: Icon(Icons.people, size: 22), label: 'Connexions'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline, size: 22), activeIcon: Icon(Icons.person, size: 22), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
              child: const Icon(Icons.post_add, size: 48, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text('Aucune publication', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF4B5563))),
            const SizedBox(height: 8),
            const Text('Soyez le premier à publier!', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const CreatePostDialog(),
                ).then((_) {
                  if (mounted) _loadPosts();
                });
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Créer une publication'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: const Color(0xFF0B1B3D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
