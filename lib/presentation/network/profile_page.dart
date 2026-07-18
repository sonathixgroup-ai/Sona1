import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/services/network_service.dart';
import 'package:thix_id/models/network_post.dart';
import 'widgets/pinned_post.dart';

class ProfilePage extends StatefulWidget {
  final String? userId;
  const ProfilePage({super.key, this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late NetworkService _networkService;
  final ScrollController _scrollController = ScrollController();

  Map<String, dynamic>? _user;
  List<NetworkPost> _posts = [];
  List<NetworkPost> _pinnedPosts = [];
  
  // Pagination
  bool _loading = true;
  bool _isLoadingMore = false;
  bool _hasMorePosts = true;
  final int _postsLimit = 15;
  int _postsOffset = 0;

  bool _isFollowing = false;
  int _selectedTab = 0;
  bool _isGridView = true;

  // Couleurs de la charte THIX PRO (basé sur la maquette d'accueil)
  final Color _thixBgColor = const Color(0xFFF5F8FA);
  final Color _thixPrimaryBlue = const Color(0xFF2B5CFF); // Bleu vif du bouton "Pour vous"
  final Color _thixDarkText = const Color(0xFF1A1A2E); // Bleu très sombre du titre
  final Color _thixGold = const Color(0xFFE7BE59);

  final List<String> _tabs = ['Posts', 'Photos', 'Vidéos'];

  @override
  void initState() {
    super.initState();
    _networkService = NetworkService(Supabase.instance.client);
    _scrollController.addListener(_onScroll);
    _loadInitialData();
    _checkFollowStatus();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      if (!_isLoadingMore && _hasMorePosts) {
        _loadMorePosts();
      }
    }
  }

  // CHARGEMENT INITIAL (Parallèle, sans bloquer le thread)
  Future<void> _loadInitialData() async {
    setState(() => _loading = true);
    final userId = widget.userId ?? _networkService.currentUserId;

    try {
      final results = await Future.wait([
        _networkService.getUserProfile(userId),
        _networkService.getPinnedPosts(userId),
        _networkService.getUserPosts(userId, offset: 0, limit: _postsLimit),
      ]);

      if (mounted) {
        setState(() {
          _user = results[0] as Map<String, dynamic>?;
          _pinnedPosts = results[1] as List<NetworkPost>;
          _posts = results[2] as List<NetworkPost>;
          
          _postsOffset = _posts.length;
          _hasMorePosts = _posts.length == _postsLimit;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement profil: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  // RAFRAÎCHISSEMENT DU FLUX UNIQUEMENT
  Future<void> _onRefreshFeed() async {
    final userId = widget.userId ?? _networkService.currentUserId;
    try {
      final newPosts = await _networkService.getUserPosts(userId, offset: 0, limit: _postsLimit);
      if (mounted) {
        setState(() {
          _posts = newPosts;
          _postsOffset = newPosts.length;
          _hasMorePosts = newPosts.length == _postsLimit;
        });
      }
    } catch (e) {
      debugPrint('Erreur refresh feed: $e');
    }
  }

  // CHARGEMENT INFINI
  Future<void> _loadMorePosts() async {
    setState(() => _isLoadingMore = true);
    final userId = widget.userId ?? _networkService.currentUserId;

    try {
      final newPosts = await _networkService.getUserPosts(userId, offset: _postsOffset, limit: _postsLimit);
      if (mounted) {
        setState(() {
          _posts.addAll(newPosts);
          _postsOffset += newPosts.length;
          _hasMorePosts = newPosts.length == _postsLimit;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _checkFollowStatus() async {
    if (widget.userId == null || widget.userId == _networkService.currentUserId) return;
    try {
      final response = await Supabase.instance.client
          .from('connections')
          .select('id')
          .eq('user_id', _networkService.currentUserId)
          .eq('connection_id', widget.userId!)
          .eq('status', 'accepted')
          .maybeSingle();
      if (mounted) setState(() => _isFollowing = response != null);
    } catch (e) {
      debugPrint('Follow status error: $e');
    }
  }

  Future<void> _followUser() async {
    if (widget.userId == null) return;
    try {
      await _networkService.sendConnectionRequest(widget.userId!);
      setState(() => _isFollowing = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande envoyée'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _formatNumber(int num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}k';
    return num.toString();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context, listen: false);
    final isOwnProfile = widget.userId == null || widget.userId == auth.currentUser?.id;

    return Scaffold(
      backgroundColor: _thixBgColor,
      body: _loading
          ? Center(child: CircularProgressIndicator(color: _thixPrimaryBlue))
          : RefreshIndicator(
              onRefresh: _onRefreshFeed, // Ne rafraîchit que les posts !
              color: _thixPrimaryBlue,
              backgroundColor: Colors.white,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildCoverBanner(isOwnProfile)),
                  SliverToBoxAdapter(child: _buildProfileHeader(isOwnProfile)),
                  
                  if (_pinnedPosts.isNotEmpty)
                    SliverToBoxAdapter(
                      child: PinnedPost(
                        post: _pinnedPosts.first,
                        onTap: () => context.push('/network/post/${_pinnedPosts.first.id}'),
                        onUnpin: null,
                      ),
                    ),
                    
                  SliverToBoxAdapter(child: _buildStatsRow()),
                  
                  if (_user?['bio'] != null || _user?['location'] != null)
                    SliverToBoxAdapter(child: _buildAboutSection()),
                    
                  SliverToBoxAdapter(child: _buildTabsAndSwitch()),
                  
                  _buildTabContent(),
                  
                  if (_isLoadingMore)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(child: CircularProgressIndicator(color: _thixPrimaryBlue)),
                      ),
                    ),
                    
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
    );
  }

  // ─── WIDGETS D'INTERFACE ───

  Widget _buildCoverBanner(bool isOwnProfile) {
    return Stack(
      children: [
        Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _thixDarkText,
            image: _user?['cover_url'] != null
                ? DecorationImage(
                    image: CachedNetworkImageProvider(_user!['cover_url']),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
        ),
        if (isOwnProfile)
          Positioned(
            bottom: 12,
            right: 12,
            child: CircleAvatar(
              backgroundColor: Colors.black45,
              radius: 18,
              child: IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                onPressed: () {}, // Fonctionnalité à connecter plus tard
                padding: EdgeInsets.zero,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileHeader(bool isOwnProfile) {
    return Container(
      transform: Matrix4.translationValues(0.0, -30.0, 0.0), // Fait remonter l'avatar sur la couverture
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _thixBgColor, width: 4),
                    ),
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: Colors.white,
                      backgroundImage: _user?['photo_url'] != null
                          ? CachedNetworkImageProvider(_user!['photo_url'])
                          : null,
                      child: _user?['photo_url'] == null
                          ? Icon(Icons.person, size: 40, color: _thixPrimaryBlue.withOpacity(0.5))
                          : null,
                    ),
                  ),
                  if (isOwnProfile)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: _thixPrimaryBlue,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
                          onPressed: () {}, // Fonctionnalité à connecter
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              if (isOwnProfile)
                OutlinedButton(
                  onPressed: () => context.push('/network/profile-settings'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    foregroundColor: _thixDarkText,
                  ),
                  child: const Text('Modifier le profil', style: TextStyle(fontWeight: FontWeight.w600)),
                )
              else
                ElevatedButton.icon(
                  onPressed: _followUser,
                  icon: Icon(_isFollowing ? Icons.check : Icons.person_add, size: 18),
                  label: Text(_isFollowing ? 'Abonné' : 'Suivre'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFollowing ? Colors.grey.shade200 : _thixPrimaryBlue,
                    foregroundColor: _isFollowing ? _thixDarkText : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _user?['display_name'] ?? 'Utilisateur',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _thixDarkText),
          ),
          const SizedBox(height: 4),
          Text(
            _user?['profession'] ?? 'Membre THIX PRO',
            style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    // Vraies données de la DB, sans fausses stats générées.
    final stats = [
      {'value': _user?['followers_count'] ?? 0, 'label': 'Abonnés'},
      {'value': _user?['following_count'] ?? 0, 'label': 'Abonnements'},
      {'value': _user?['posts_count'] ?? 0, 'label': 'Publications'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      transform: Matrix4.translationValues(0.0, -10.0, 0.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: stats.map((stat) => Padding(
          padding: const EdgeInsets.only(right: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_formatNumber(stat['value'] as int)}', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _thixDarkText)),
              Text(stat['label'] as String, 
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_user?['bio'] != null) ...[
            Text(_user!['bio'], style: TextStyle(fontSize: 14, color: _thixDarkText.withOpacity(0.8), height: 1.5)),
            const SizedBox(height: 12),
          ],
          if (_user?['location'] != null)
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(_user!['location'], style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTabsAndSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_tabs.length, (index) {
                  final isSelected = _selectedTab == index;
                  // Design exact des pilules de la page d'accueil (Pour vous / Réseau)
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTab = index),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? _thixPrimaryBlue : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? _thixPrimaryBlue : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        _tabs[index],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : _thixDarkText,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          // Bouton d'affichage discret
          IconButton(
            icon: Icon(_isGridView ? Icons.grid_view_rounded : Icons.view_agenda_rounded),
            color: Colors.grey.shade600,
            onPressed: () => setState(() => _isGridView = !_isGridView),
          )
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    List<NetworkPost> displayedPosts = _posts;

    // Filtrage simple basé sur media_type (à adapter si ta DB utilise imageUrls)
    if (_selectedTab == 1) {
      displayedPosts = _posts.where((p) => p.mediaType == 'image' || p.imageUrls.isNotEmpty).toList();
    } else if (_selectedTab == 2) {
      displayedPosts = _posts.where((p) => p.mediaType == 'video' || p.videoUrls.isNotEmpty).toList();
    }

    if (displayedPosts.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.feed_outlined, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('Aucune publication', style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
              ],
            ),
          ),
        ),
      );
    }

    if (_isGridView) {
      return SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildPostGridItem(displayedPosts[index]),
          childCount: displayedPosts.length,
          addAutomaticKeepAlives: false, // Protection RAM !
          addRepaintBoundaries: true,
        ),
      );
    } else {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildPostListItem(displayedPosts[index]),
          childCount: displayedPosts.length,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
        ),
      );
    }
  }

      Widget _buildPostGridItem(NetworkPost post) {
    // On utilise directement imageUrls qui existe dans ton modèle
    final mediaUrl = post.imageUrls.isNotEmpty ? post.imageUrls.first : null;


    return GestureDetector(
      onTap: () => context.push('/network/post/${post.id}'),
      child: Container(
        color: Colors.white,
        child: mediaUrl != null
            ? CachedNetworkImage(
                imageUrl: mediaUrl,
                fit: BoxFit.cover,
                memCacheWidth: 300, // Limite la taille en RAM pour la miniature
                placeholder: (context, url) => Container(color: Colors.grey.shade100),
                errorWidget: (context, url, error) => Icon(Icons.broken_image, color: Colors.grey.shade300),
              )
            : Container(
                padding: const EdgeInsets.all(8),
                color: Colors.white,
                child: Center(
                  child: Text(
                    post.content,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: _thixDarkText.withOpacity(0.7)),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildPostListItem(NetworkPost post) {
    return GestureDetector(
      onTap: () => context.push('/network/post/${post.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(post.content, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(color: _thixDarkText, height: 1.4)),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.favorite_border, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(_formatNumber(post.likesCount), style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                const SizedBox(width: 16),
                Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(_formatNumber(post.commentsCount), style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
