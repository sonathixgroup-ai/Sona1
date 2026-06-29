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
import 'package:thix_id/services/network_service.dart';
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

  Color get _primaryColor => const Color(0xFF1877F2);
  Color get _mutedColor => const Color(0xFF6B7280);
  Color get _backgroundColor => const Color(0xFFF0F2F5);

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
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Se connecter'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: _primaryColor,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildFilterChips()),
            if (isLoading && posts.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
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
                     Icon(filter['icon'] as IconData, size: 14, color: isSelected ? _primaryColor : Colors.grey[600]),
                    const SizedBox(width: 4),
                     Text(filter['label'] as String, style: TextStyle(fontSize: 11, color: isSelected ? _primaryColor : Colors.grey[600])),
                  ],
                ),
                onSelected: (selected) {
                  setState(() => _feedType = filter['value'] as String);
                  _loadPosts();
                },
                 backgroundColor: Colors.white,
                 selectedColor: _primaryColor.withOpacity(0.08),
                 side: BorderSide(color: isSelected ? _primaryColor : Colors.grey[300]!),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPostCard(NetworkPost post) {
    final primary = _primaryColor;
    final muted = _mutedColor;
    final surface = Colors.white;
    final radius = BorderRadius.circular(16);
    final isLiked = post.isLiked;
    final views = post.views ?? 0;
    final imageUrl = post.imageUrls.isNotEmpty ? post.imageUrls.first : post.mediaUrl;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty && (post.mediaType == null || post.mediaType == 'image');
    final hasVideo = (post.mediaType == 'video' || (post.videoUrls?.isNotEmpty ?? false)) && (post.mediaUrl?.isNotEmpty ?? post.videoUrls?.isNotEmpty ?? false);
    final hasPoll = (post.pollOptions?.isNotEmpty ?? false);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 0,
      color: surface,
      shape: RoundedRectangleBorder(borderRadius: radius),
      child: InkWell(
        borderRadius: radius,
        onTap: () async {
          await _registerView(post);
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: primary.withOpacity(0.1),
                    backgroundImage: post.authorAvatar != null && post.authorAvatar!.isNotEmpty
                        ? NetworkImage(post.authorAvatar!)
                        : null,
                    child: post.authorAvatar == null || post.authorAvatar!.isEmpty
                        ? Icon(Icons.person, size: 18, color: primary)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                post.authorName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A)),
                              ),
                            ),
                            Text(_timeAgo(post.createdAt), style: TextStyle(fontSize: 11, color: muted)),
                          ],
                        ),
                        if (post.authorTitle != null && post.authorTitle!.isNotEmpty)
                          Text(post.authorTitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: muted)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_horiz, size: 18),
                    color: muted,
                    onPressed: () {},
                  ),
                ],
              ),
              if (post.content.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(post.content, style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF111827))),
              ],
              if (hasImage) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl!,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              if (hasVideo) ...[
                const SizedBox(height: 12),
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(colors: [primary.withOpacity(0.8), Colors.black.withOpacity(0.7)]),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
                      child: Icon(Icons.play_arrow_rounded, color: primary, size: 28),
                    ),
                  ),
                ),
              ],
              if (hasPoll) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primary.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.poll_outlined, size: 18, color: primary),
                          const SizedBox(width: 8),
                          Text('Sondage', style: TextStyle(fontWeight: FontWeight.w600, color: primary)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...post.pollOptions!.map((option) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: primary.withOpacity(0.08)),
                            ),
                            child: Text(option, style: const TextStyle(fontSize: 13, color: Color(0xFF111827))),
                          )),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _statIcon(Icons.favorite, _formatCount(post.likesCount), isLiked ? Colors.red : muted),
                  const SizedBox(width: 16),
                  _statIcon(Icons.chat_bubble_outline, _formatCount(post.commentsCount), muted),
                  const SizedBox(width: 16),
                  _statIcon(Icons.visibility_outlined, _formatCount(views), muted),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _actionChip(
                    icon: isLiked ? Icons.favorite : Icons.favorite_border,
                    label: 'J\'aime',
                    color: isLiked ? Colors.red : muted,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Provider.of<FeedProvider>(context, listen: false).toggleLike(post.id);
                    },
                  ),
                  _actionChip(
                    icon: Icons.mode_comment_outlined,
                    label: 'Commenter',
                    color: muted,
                    onTap: () => _showCommentDialog(post),
                  ),
                  _actionChip(
                    icon: Icons.share_outlined,
                    label: 'Partager',
                    color: muted,
                    onTap: () {},
                  ),
                  _actionChip(
                    icon: Icons.bookmark_border,
                    label: 'Enregistrer',
                    color: muted,
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statIcon(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  Widget _actionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, color: color)),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 1) return '${diff.inDays} j';
    if (diff.inHours >= 1) return '${diff.inHours} h';
    if (diff.inMinutes >= 1) return '${diff.inMinutes} min';
    return 'Maintenant';
  }

  Future<void> _registerView(NetworkPost post) async {
    final service = NetworkService(Supabase.instance.client);
    final newViews = await service.incrementViewCount(post.id);
    if (!mounted) return;
    Provider.of<FeedProvider>(context, listen: false).updateViews(post.id, newViews);
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
            style: TextButton.styleFrom(foregroundColor: _primaryColor),
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
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
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
        selectedItemColor: _primaryColor,
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
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
