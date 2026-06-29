// lib/presentation/network/network_pro_home.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/models/network_post.dart';
import 'package:thix_id/providers/feed_provider.dart';
import 'widgets/create_post_dialog.dart';

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
  final Map<String, AnimationController> _likeAnimations = {};
  RealtimeChannel? _realtimeChannel;

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
      final feedProvider = Provider.of<FeedProvider>(context, listen: false);
      feedProvider.initRealtime();
    });

    _setupRealtimeSubscriptions();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    for (var controller in _likeAnimations.values) {
      controller.dispose();
    }
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  void _setupRealtimeSubscriptions() {
    try {
      final supabase = Supabase.instance.client;
      final feedProvider = Provider.of<FeedProvider>(context, listen: false);

      _realtimeChannel = supabase
          .channel('public:posts')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'posts',
            callback: (payload) async {
              debugPrint('📬 [REALTIME] Nouvelle publication détectée en BDD!');
              if (mounted) {
                await feedProvider.loadFeed(feedType: _feedType);
                setState(() {});
              }
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'posts',
            callback: (payload) async {
              debugPrint('📝 [REALTIME] Publication mise à jour');
              if (mounted) {
                await feedProvider.loadFeed(feedType: _feedType);
                setState(() {});
              }
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: 'posts',
            callback: (payload) async {
              debugPrint('🗑️ [REALTIME] Publication supprimée');
              if (mounted) {
                await feedProvider.loadFeed(feedType: _feedType);
                setState(() {});
              }
            },
          )
          .subscribe((status, err) {
            if (err != null) {
              debugPrint('❌ Erreur Realtime: $err');
            } else {
              debugPrint('✅ Realtime connecté au feed - status: $status');
            }
          });
    } catch (e) {
      debugPrint('❌ Erreur setup realtime: $e');
    }
  }

  Future<void> _loadAllData() async {
    final feedProvider = Provider.of<FeedProvider>(context, listen: false);
    await feedProvider.loadFeed(feedType: _feedType);
    if (mounted) {
      setState(() => _loadingPosts = false);
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

    final feedProvider = Provider.of<FeedProvider>(context, listen: false);
    await feedProvider.loadFeed(feedType: _feedType);

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
              SliverFillRemaining(child: _buildEmptyState())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildPostCard(posts[index]),
                  childCount: posts.length,
                ),
              ),
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
      title: const Text(
        'Réseau Pro',
        style: TextStyle(color: Color(0xFF0B1B3D), fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(icon: const Icon(Icons.search, color: Color(0xFF0B1B3D)), onPressed: _goToSearch),
        IconButton(icon: const Icon(Icons.notifications_none, color: Color(0xFF0B1B3D)), onPressed: _goToNotifications),
        IconButton(icon: const Icon(Icons.mail_outline, color: Color(0xFF0B1B3D)), onPressed: _goToMessages),
      ],
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

  // ============================================================
  // ✅ CARTE DE POST CORRIGÉE - SANS mediaUrl ni sharesCount
  // ============================================================
  Widget _buildPostCard(NetworkPost post) {
    // ✅ Utilisation UNIQUEMENT des propriétés qui existent dans votre modèle
    final isLiked = post.isLiked;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Post
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: post.authorAvatar != null && post.authorAvatar!.isNotEmpty
                      ? NetworkImage(post.authorAvatar!)
                      : null,
                  radius: 20,
                  child: post.authorAvatar == null || post.authorAvatar!.isEmpty
                      ? const Icon(Icons.person, size: 20)
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
            const SizedBox(height: 12),
            
            // Contenu texte
            if (post.content != null && post.content!.isNotEmpty)
              Text(
                post.content!,
                style: const TextStyle(fontSize: 13),
              ),
            
            // Pas d'image car mediaUrl n'existe pas dans votre modèle
            // Si vous avez des images, elles sont dans une autre propriété
            
            const SizedBox(height: 12),
            
            // Statistiques d'engagement
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${post.likesCount} ${post.likesCount == 1 ? 'J\'aime' : 'J\'aimes'}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Text(
                  '${post.commentsCount} ${post.commentsCount == 1 ? 'Commentaire' : 'Commentaires'}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const Text(
                  '0 Partages',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            
            const Divider(height: 16),
            
            // Boutons d'actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.red : Colors.grey[600],
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Provider.of<FeedProvider>(context, listen: false).toggleLike(post.id);
                  },
                ),
                _buildActionButton(
                  icon: Icons.comment_outlined,
                  color: Colors.grey[600],
                  onTap: () => _showCommentDialog(post),
                ),
                _buildActionButton(
                  icon: Icons.bookmark_border,
                  color: Colors.grey[600],
                  onTap: () {},
                ),
                _buildActionButton(
                  icon: Icons.share_outlined,
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
    required Color? color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Icon(icon, size: 18, color: color),
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
            hintText: 'Écrivez votre commentaire...',
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

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => const CreatePostDialog(),
        ).then((_) => _loadPosts());
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
            case 0: break;
            case 1: _goToSearch(); break;
            case 2: _goToConnexions(); break;
            case 3: _goToProfile(); break;
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFD4AF37),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontSize: 10),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home, size: 20), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.search, size: 20), label: 'Recherche'),
          BottomNavigationBarItem(icon: Icon(Icons.people, size: 20), label: 'Connexions'),
          BottomNavigationBarItem(icon: Icon(Icons.person, size: 20), label: 'Profil'),
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
                ).then((_) => _loadPosts());
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
