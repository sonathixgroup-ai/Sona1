// lib/presentation/network/network_pro_home.dart
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

// Constante pour la couleur primaire (bleu)
const Color primaryBlue = Color(0xFF1E88E5);

class NetworkProHome extends StatefulWidget {
  const NetworkProHome({super.key});

  @override
  State<NetworkProHome> createState() => _NetworkProHomeState();
}

class _NetworkProHomeState extends State<NetworkProHome>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  bool _loadingPosts = true;
  bool _isRefreshing = false;

  String _feedType = 'smart';
  int _selectedNavIndex = 0;

  List<NetworkStory> _stories = [];
  bool _loadingStories = false;

  List<NetworkConnection> _suggestions = [];
  bool _loadingSuggestions = false;

  final ScrollController _scrollController = ScrollController();

  // Map pour gérer l'état "expandé" de chaque post (par id)
  final Map<String, bool> _expandedPosts = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        Provider.of<FeedProvider>(
          context,
          listen: false,
        ).initRealtime();
      } catch (_) {}

      _loadAllData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    final feedProvider =
        Provider.of<FeedProvider>(context, listen: false);

    await Future.wait([
      feedProvider.loadFeed(feedType: _feedType),
      _loadStories(),
      _loadSuggestions(),
    ]);

    if (mounted) {
      setState(() {
        _loadingPosts = false;
      });
    }
  }

  Future<void> _loadStories() async {
    if (!mounted) return;

    setState(() => _loadingStories = true);

    try {
      final networkService =
          Provider.of<NetworkService>(context, listen: false);

      final stories = await networkService.getActiveStories();

      if (mounted) {
        setState(() {
          _stories = stories;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur chargement stories : $e'),
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _loadingStories = false);
    }
  }

  Future<void> _loadSuggestions() async {
    if (!mounted) return;

    setState(() => _loadingSuggestions = true);

    try {
      final networkService =
          Provider.of<NetworkService>(context, listen: false);

      final suggestions =
          await networkService.getSuggestedConnections(limit: 5);

      if (mounted) {
        setState(() {
          _suggestions = suggestions;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur suggestions : $e'),
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _loadingSuggestions = false);
    }
  }

  Future<void> _loadPosts() async {
    if (!mounted) return;

    final feedProvider =
        Provider.of<FeedProvider>(context, listen: false);

    setState(() => _loadingPosts = true);

    try {
      await feedProvider.loadFeed(feedType: _feedType, force: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur chargement posts : $e'),
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _loadingPosts = false);
    }
  }

  Future<void> _onRefresh() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    await _loadAllData();

    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  // --- Navigations ---
  void _goToSearch() => context.push('/network/search');
  void _goToNotifications() => context.push('/network/notifications');
  void _goToMessages() => context.push('/network/messages');
  void _goToConnexions() => context.push('/network/connections');
  void _goToProfile() => context.push('/profile');
  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _viewStory(NetworkStory story) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Story de ${story.userName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (story.mediaUrl != null)
              Image.network(story.mediaUrl!),
            const SizedBox(height: 8),
            Text(story.caption ?? ''),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _commentOnPost(NetworkPost post) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ajouter un commentaire',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Écrivez votre commentaire...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (text) {
                // Appeler le service pour ajouter le commentaire
                // Provider.of<FeedProvider>(context, listen: false)
                //     .addComment(post.id, text);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
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
              onTap: () {
                // Copier le lien
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Envoyer en message'),
              onTap: () {
                Navigator.pop(context);
                // Naviguer vers la messagerie
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Partager ailleurs...'),
              onTap: () {
                Navigator.pop(context);
                // Utiliser share_plus
              },
            ),
          ],
        ),
      ),
    );
  }

  void _sendConnectionRequest(NetworkConnection user) async {
    try {
      final networkService =
          Provider.of<NetworkService>(context, listen: false);
      await networkService.sendConnectionRequest(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation envoyée !'),
          ),
        );
        setState(() {
          _suggestions.removeWhere((u) => u.id == user.id);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
          ),
        );
      }
    }
  }

  void _openOpportunity(String title, String subtitle) {
    context.push('/opportunity-detail', extra: {'title': title, 'sub': subtitle});
  }

  // --- Création de challenge ---
  void _createChallenge() {
    // Ouvrir un dialog ou une page de création de challenge
    // Exemple simple avec un SnackBar (à remplacer par votre logique)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Créer un challenge (à implémenter)'),
      ),
    );
  }

  // --- Vidéo : rediriger vers le chargement ---
  void _goToVideoUpload() {
    context.push('/video-upload'); // ou /network/video-upload selon votre routing
  }

  // --- BUILD ---
  @override
  Widget build(BuildContext context) {
    super.build(context);

    final feedProvider = Provider.of<FeedProvider>(context);
    final posts = feedProvider.posts;
    final isLoading = feedProvider.isLoading;

    final auth = Provider.of<AuthController>(context);

    if (auth.currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Connectez-vous'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        color: primaryBlue,
        onRefresh: _onRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildStoriesRow(),
            ),
            SliverToBoxAdapter(
              child: _buildFilterChips(),
            ),
            SliverToBoxAdapter(
              child: _buildCreatePostBar(),
            ),
            if (isLoading && posts.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (posts.isEmpty)
              SliverToBoxAdapter(
                child: _buildEmptyState(),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _buildPostCard(posts[index]);
                  },
                  childCount: posts.length,
                ),
              ),
            SliverToBoxAdapter(
              child: _buildOpportunitySection(),
            ),
            if (_suggestions.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildSuggestionsSection(),
              ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 120),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // --- AppBar ---
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      title: const Text(
        'Réseau Pro',
        style: TextStyle(
          color: primaryBlue,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
      ),
      actions: [
        IconButton(
          onPressed: _goToSearch,
          icon: const Icon(Icons.search_rounded),
        ),
        Stack(
          children: [
            IconButton(
              onPressed: _goToNotifications,
              icon: const Icon(
                Icons.notifications_none_rounded,
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: primaryBlue,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '3',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: _goToMessages,
          icon: const Icon(Icons.chat_bubble_outline),
        ),
        const Padding(
          padding: EdgeInsets.only(right: 16),
          child: Stack(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFEAEAEA),
                child: Icon(Icons.person),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: CircleAvatar(
                  radius: 5,
                  backgroundColor: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Stories ---
  Widget _buildStoriesRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 14,
        bottom: 10,
      ),
      child: SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _stories.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildAddStory();
            }
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
                border: Border.all(
                  color: primaryBlue,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 12,
                    color: primaryBlue.withOpacity(0.15),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ma Story',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryItem(NetworkStory story) {
    final hasAvatar =
        story.userAvatar != null &&
            story.userAvatar!.isNotEmpty;

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
                  colors: [
                    primaryBlue,
                    Color(0xFF1565C0),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10,
                    color: primaryBlue.withOpacity(0.18),
                  ),
                ],
              ),
              child: CircleAvatar(
                backgroundColor: Colors.grey.shade200,
                backgroundImage: hasAvatar
                    ? NetworkImage(story.userAvatar!)
                    : null,
                child: !hasAvatar
                    ? Text(
                  story.userName[0].toUpperCase(),
                )
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              story.userName.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Filtres ---
  Widget _buildFilterChips() {
    final filters = [
      {
        'icon': Icons.auto_awesome,
        'label': 'Pour vous',
        'value': 'smart',
      },
      {
        'icon': Icons.people_outline,
        'label': 'Réseau',
        'value': 'network',
      },
      {
        'icon': Icons.video_collection_outlined,
        'label': 'Shorts',
        'value': 'shorts',
      },
      {
        'icon': Icons.local_fire_department_outlined,
        'label': 'Tendances',
        'value': 'popular',
      },
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected =
                _feedType == filter['value'];

            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(40),
                onTap: () {
                  setState(() {
                    _feedType =
                    filter['value'] as String;
                  });
                  _loadPosts();
                },
                child: AnimatedContainer(
                  duration:
                  const Duration(milliseconds: 250),
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF111827)
                        : const Color(0xFFF2F4F7),
                    borderRadius:
                    BorderRadius.circular(40),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        filter['icon'] as IconData,
                        size: 17,
                        color: isSelected
                            ? Colors.white
                            : Colors.black54,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        filter['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : Colors.black87,
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

  // --- Barre de création ---
  Widget _buildCreatePostBar() {
    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.04),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFFEAEAEA),
                child: Icon(Icons.person),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (_) =>
                      const CreatePostDialog(),
                    );
                    if (result == true) {
                      _loadPosts();
                    }
                  },
                  child: Container(
                    height: 46,
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 18,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FB),
                      borderRadius:
                      BorderRadius.circular(40),
                    ),
                    child: const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Quoi de neuf dans votre monde pro ?',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceAround,
            children: [
              _miniAction(
                Icons.article_outlined,
                'Publication',
                Colors.deepPurple,
                () => _createPostDialog(),
              ),
              _miniAction(
                Icons.image_outlined,
                'Photo',
                Colors.green,
                () => _createPostDialog(), // à adapter
              ),
              _miniAction(
                Icons.videocam_outlined,
                'Vidéo',
                Colors.red,
                _goToVideoUpload, // NOUVEAU : redirige vers chargement
              ),
              _miniAction(
                Icons.bolt_outlined,
                'Short',
                Colors.orange,
                () => _createPostDialog(),
              ),
              // AJOUT : Challenge
              _miniAction(
                Icons.emoji_events_outlined,
                'Challenge',
                Colors.amber,
                _createChallenge,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper pour ouvrir le dialog de création de post (pour Publication, Photo, Short)
  void _createPostDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const CreatePostDialog(),
    );
    if (result == true) {
      _loadPosts();
    }
  }

  Widget _miniAction(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Carte de post (avec "Voir plus") ---
  Widget _buildPostCard(NetworkPost post) {
    final isExpanded = _expandedPosts[post.id] ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.04),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage:
                  post.authorAvatar != null &&
                      post.authorAvatar!.isNotEmpty
                      ? NetworkImage(post.authorAvatar!)
                      : null,
                  child: post.authorAvatar == null
                      ? Text(post.authorName[0])
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight:
                          FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        post.authorTitle ?? '',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (_) => SafeArea(
                        child: Wrap(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.flag),
                              title: const Text('Signaler'),
                              onTap: () {
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.bookmark_border),
                              title: const Text('Sauvegarder'),
                              onTap: () {
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.more_horiz),
                ),
              ],
            ),
            // Contenu texte avec "Voir plus"
            if (post.content.isNotEmpty) ...[
              const SizedBox(height: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.content,
                    maxLines: isExpanded ? null : 3,
                    overflow: isExpanded ? null : TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  if (post.content.length > 100) // condition pour afficher le bouton
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _expandedPosts[post.id] = !isExpanded;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          isExpanded ? 'Voir moins' : 'Voir plus',
                          style: const TextStyle(
                            color: primaryBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            // Images
            if (post.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  post.imageUrls.first,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            // Statistiques
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.thumb_up,
                  color: Colors.blue,
                  size: 16,
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.favorite,
                  color: Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '${post.likesCount}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
                const Spacer(),
                Text(
                  '${post.commentsCount} commentaires',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Actions
            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceAround,
              children: [
                _actionButton(
                  icon: post.isLiked
                      ? Icons.favorite
                      : Icons.favorite_border,
                  label: 'J’aime',
                  color: post.isLiked
                      ? Colors.red
                      : Colors.grey.shade700,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Provider.of<FeedProvider>(
                      context,
                      listen: false,
                    ).toggleLike(post.id);
                  },
                ),
                _actionButton(
                  icon: Icons.mode_comment_outlined,
                  label: 'Commenter',
                  color: Colors.grey.shade700,
                  onTap: () => _commentOnPost(post),
                ),
                _actionButton(
                  icon: Icons.share_outlined,
                  label: 'Partager',
                  color: Colors.grey.shade700,
                  onTap: () => _sharePost(post),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(40),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Opportunités ---
  Widget _buildOpportunitySection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Text(
            'Opportunités pour vous',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _opportunityCard(
                  Icons.work_outline,
                  'UI/UX Designer',
                  'TechNova',
                ),
                _opportunityCard(
                  Icons.attach_money,
                  'Fonds Innovation',
                  'Afrique 2024',
                ),
                _opportunityCard(
                  Icons.rocket_launch_outlined,
                  'Impact Startup',
                  'Challenge',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _opportunityCard(
      IconData icon,
      String title,
      String subtitle,
      ) {
    return GestureDetector(
      onTap: () => _openOpportunity(title, subtitle),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              color: Colors.black.withOpacity(0.04),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: primaryBlue,
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Suggestions ---
  Widget _buildSuggestionsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Suggestions de connexion',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
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
                  backgroundImage: user.avatarUrl != null
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null
                      ? Text(user.name[0].toUpperCase())
                      : null,
                ),
                title: Text(user.name),
                subtitle: Text(user.headline ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.person_add_alt_1),
                  onPressed: () => _sendConnectionRequest(user),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- FAB ---
  Widget _buildFAB() {
    return Container(
      height: 68,
      width: 68,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            primaryBlue,
            Color(0xFF1565C0),
          ],
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            offset: const Offset(0, 10),
            color: primaryBlue.withOpacity(0.35),
          ),
        ],
      ),
      child: FloatingActionButton(
        backgroundColor: Colors.transparent,
        elevation: 0,
        onPressed: () async {
          final result = await showDialog<bool>(
            context: context,
            builder: (_) =>
            const CreatePostDialog(),
          );
          if (result == true) {
            _loadPosts();
          }
        },
        child: const Icon(
          Icons.add,
          size: 30,
          color: Colors.white,
        ),
      ),
    );
  }

  // --- Bottom Nav (hauteur réduite) ---
  Widget _buildBottomNav() {
    return BottomAppBar(
      height: 56, // Réduit de 74 à 56
      shape: const CircularNotchedRectangle(),
      notchMargin: 8, // Réduit pour s'adapter
      color: Colors.white,
      elevation: 8,
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.spaceAround,
        children: [
          _navItem(
            Icons.home_rounded,
            'Accueil',
            true,
            _scrollToTop,
          ),
          _navItem(
            Icons.explore_outlined,
            'Découvrir',
            false,
            _goToSearch,
          ),
          const SizedBox(width: 40), // Ajusté
          _navItem(
            Icons.people_outline,
            'Connexions',
            false,
            _goToConnexions,
          ),
          _navItem(
            Icons.person_outline,
            'Profil',
            false,
            _goToProfile,
          ),
        ],
      ),
    );
  }

  Widget _navItem(
      IconData icon,
      String label,
      bool active,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: active
                ? primaryBlue
                : Colors.grey,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: active
                  ? primaryBlue
                  : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Center(
        child: Text(
          'Aucune publication',
        ),
      ),
    );
  }
}
