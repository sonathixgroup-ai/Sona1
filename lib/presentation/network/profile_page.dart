// lib/presentation/network/profile_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/services/network_service.dart';
import 'package:thix_id/models/network_post.dart';
import 'widgets/pinned_post.dart';
import 'dart:async';

class ProfilePage extends StatefulWidget {
  final String? userId;
  const ProfilePage({super.key, this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  late NetworkService _networkService;
  Map<String, dynamic>? _user;
  List<NetworkPost> _posts = [];
  List<NetworkPost> _pinnedPosts = [];
  List<NetworkPost> _savedPosts = [];
  List<NetworkPost> _repostedPosts = [];
  bool _loading = true;
  bool _isFollowing = false;
  int _selectedTab = 0;
  bool _isGridView = true;
  
  late AnimationController _levelUpController;
  
  final List<String> _tabs = ['Posts', 'Photos', 'Vidéos', 'Reels', 'J\'aime', 'Sauvegardés'];

  @override
  void initState() {
    super.initState();
    _levelUpController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _networkService = NetworkService(Supabase.instance.client);
    _loadData();
  }

  @override
  void dispose() {
    _levelUpController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final userId = widget.userId ?? _networkService.currentUserId;
      final userData = await _networkService.getUserProfile(userId);
      final posts = await _networkService.getUserPosts(userId);
      final pinnedPosts = await _networkService.getPinnedPosts(userId);
      final savedPosts = await _networkService.getSavedPosts();
      final repostedPosts = await _networkService.getUserReposts(userId);
      
      setState(() {
        _user = userData;
        _posts = posts;
        _pinnedPosts = pinnedPosts;
        _savedPosts = savedPosts;
        _repostedPosts = repostedPosts;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _followUser() async {
    if (widget.userId == null) return;
    await _networkService.sendConnectionRequest(widget.userId!);
    setState(() => _isFollowing = true);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Demande envoyée'), backgroundColor: Colors.green),
    );
  }

  void _sendMessage() {
    context.push('/network/chat/${widget.userId}');
  }

  Future<void> _unpinPost(String postId) async {
    await _networkService.unpinPost(postId);
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post désépinglé'), backgroundColor: Colors.orange),
      );
    }
  }

  void _shareProfile() {
    final shareText = 'Découvrez le profil de ${_user?['display_name']} sur THIX Réseau Pro !';
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Partage bientôt disponible'), backgroundColor: Colors.orange),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);
    final isOwnProfile = widget.userId == null || widget.userId == auth.currentUser?.id;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFFD4AF37),
              child: CustomScrollView(
                controller: ScrollController(),
                slivers: [
                  SliverToBoxAdapter(child: _buildCoverBanner()),
                  SliverToBoxAdapter(child: _buildProfileHeader(isOwnProfile)),
                  
                  if (_pinnedPosts.isNotEmpty)
                    SliverToBoxAdapter(
                      child: PinnedPost(
                        post: _pinnedPosts.first,
                        onTap: () => context.push('/network/post/${_pinnedPosts.first.id}'),
                        onUnpin: isOwnProfile ? () => unawaited(_unpinPost(_pinnedPosts.first.id)) : null,
                      ),
                    ),
                  
                  SliverToBoxAdapter(child: _buildXpBar()),
                  SliverToBoxAdapter(child: _buildStatsGrid()),
                  SliverToBoxAdapter(child: _buildBadgesSection()),
                  
                  if (_user?['bio'] != null || _user?['skills'] != null)
                    SliverToBoxAdapter(child: _buildAboutSection()),
                  
                  SliverToBoxAdapter(child: _buildTabsAndSwitch()),
                  
                  if (_selectedTab == 0)
                    _buildPostsContent(_posts)
                  else if (_selectedTab == 1)
                    _buildPhotosContent()
                  else if (_selectedTab == 2)
                    _buildVideosContent()
                  else if (_selectedTab == 3)
                    _buildReelsContent()
                  else if (_selectedTab == 4)
                    _buildLikedContent()
                  else if (_selectedTab == 5)
                    _buildSavedContent(),
                  
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
    );
  }

  Widget _buildCoverBanner() {
    return Stack(
      children: [
        Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0B1B3D), Color(0xFF1A2B4D)],
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            image: _user?['cover_url'] != null
                ? DecorationImage(image: NetworkImage(_user!['cover_url']), fit: BoxFit.cover)
                : null,
          ),
        ),
        Positioned(
          bottom: -30,
          right: 16,
          child: CircleAvatar(
            backgroundColor: const Color(0xFFD4AF37),
            child: IconButton(
              icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              onPressed: () => _changeCover(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(bool isOwnProfile) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _user?['photo_url'] != null
                        ? NetworkImage(_user!['photo_url'])
                        : null,
                    child: _user?['photo_url'] == null
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0xFFD4AF37),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
                        onPressed: () => _changeAvatar(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (isOwnProfile)
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _shareProfile,
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('Partager'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _editProfile(),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Modifier'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _followUser,
                      icon: Icon(_isFollowing ? Icons.person_remove : Icons.person_add, size: 18),
                      label: Text(_isFollowing ? 'Abonné' : 'Suivre'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: const Color(0xFF0B1B3D),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _sendMessage,
                      icon: const Icon(Icons.message, size: 18),
                      label: const Text('Message'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            _user?['display_name'] ?? 'Utilisateur',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '@${_user?['display_name']?.toString().toLowerCase().replaceAll(' ', '') ?? 'user'}',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            _user?['profession'] ?? 'Membre THIX',
            style: const TextStyle(fontSize: 13, color: Color(0xFFD4AF37)),
          ),
          const SizedBox(height: 8),
          if (_user?['bio'] != null)
            Text(
              _user!['bio'],
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          const SizedBox(height: 8),
          
          Wrap(
            spacing: 12,
            children: [
              if (_user?['location'] != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(_user!['location'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('Membre depuis 2024', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          if (_user?['website'] != null)
            GestureDetector(
              onTap: () => _openUrl(_user!['website']),
              child: Row(
                children: [
                  const Icon(Icons.link, size: 14, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(_user!['website'], style: const TextStyle(fontSize: 12, color: Colors.blue)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildXpBar() {
    final level = _user?['level'] ?? 1;
    final xp = _user?['xp'] ?? 0;
    final xpNeeded = level * 100;
    final progress = (xp / xpNeeded).clamp(0.0, 1.0);
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.emoji_events, size: 20, color: Color(0xFFD4AF37)),
                  const SizedBox(width: 8),
                  Text('Niveau $level', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFE5C55E)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('DIAMANT', style: TextStyle(fontSize: 10, color: Colors.white)),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.local_fire_department, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text('Streak: ${_user?['streak'] ?? 0} jours', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              color: const Color(0xFFD4AF37),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text('$xp / $xpNeeded XP', style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      {'icon': Icons.people, 'value': _user?['followers_count'] ?? 0, 'label': 'Abonnés'},
      {'icon': Icons.visibility, 'value': _user?['profile_views'] ?? 0, 'label': 'Vues'},
      {'icon': Icons.article, 'value': _user?['posts_count'] ?? 0, 'label': 'Posts'},
      {'icon': Icons.favorite, 'value': _user?['total_likes'] ?? 0, 'label': 'Likes'},
      {'icon': Icons.groups, 'value': _user?['communities_count'] ?? 0, 'label': 'Communautés'},
      {'icon': Icons.stars, 'value': _user?['xp'] ?? 0, 'label': 'XP'},
    ];
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: stats.length,
        itemBuilder: (context, index) {
          final stat = stats[index];
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(stat['icon'] as IconData, size: 24, color: const Color(0xFFD4AF37)),
              const SizedBox(height: 4),
              Text(_formatNumber(stat['value'] as int), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(stat['label'] as String, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBadgesSection() {
    final badges = [
      {'icon': Icons.verified, 'name': 'Vérifié', 'color': Colors.blue},
      {'icon': Icons.local_fire_department, 'name': 'Streak 15', 'color': Colors.orange},
      {'icon': Icons.emoji_events, 'name': 'Pro', 'color': const Color(0xFFD4AF37)},
      {'icon': Icons.camera_alt, 'name': 'Photographe', 'color': Colors.purple},
      {'icon': Icons.edit, 'name': 'Créateur', 'color': Colors.green},
      {'icon': Icons.people, 'name': 'Influenceur', 'color': Colors.red},
    ];
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('🎖️ Badges & Succès', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {},
                child: const Text('Tout voir', style: TextStyle(color: Color(0xFFD4AF37))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: badges.length,
              itemBuilder: (context, index) {
                final badge = badges[index];
                return Container(
                  width: 70,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (badge['color'] as Color).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(badge['icon'] as IconData, color: badge['color'] as Color, size: 24),
                      ),
                      const SizedBox(height: 4),
                      Text(badge['name'] as String, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
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

  Widget _buildAboutSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📝 À propos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_user?['bio'] != null)
            Text(_user!['bio'], style: const TextStyle(fontSize: 13, height: 1.4)),
          const SizedBox(height: 12),
          if (_user?['skills'] != null)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (_user!['skills'] as List).map((skill) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(skill.toString(), style: const TextStyle(fontSize: 12, color: Color(0xFFD4AF37))),
              )).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTabsAndSwitch() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_tabs.length, (index) {
                  final isSelected = _selectedTab == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTab = index),
                    child: Container(
                      margin: const EdgeInsets.only(right: 24),
                      child: Column(
                        children: [
                          Text(
                            _tabs[index],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? const Color(0xFFD4AF37) : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 2,
                            width: 30,
                            color: isSelected ? const Color(0xFFD4AF37) : Colors.transparent,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          IconButton(
            icon: Icon(_isGridView ? Icons.grid_view : Icons.view_list),
            onPressed: () => setState(() => _isGridView = !_isGridView),
            color: const Color(0xFFD4AF37),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsContent(List<NetworkPost> posts) {
    if (posts.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    
    if (_isGridView) {
      return SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
          childAspectRatio: 1,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildPostGridItem(posts[index]),
          childCount: posts.length,
        ),
      );
    } else {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildPostListItem(posts[index]),
          childCount: posts.length,
        ),
      );
    }
  }

  // ⭐ CORRIGÉ - Récupération dynamique de mediaUrl
  Widget _buildPostGridItem(NetworkPost post) {
    final dynamicPost = post as dynamic;
    final mediaUrl = dynamicPost.mediaUrl;
    final hasImage = mediaUrl != null && mediaUrl.toString().isNotEmpty;
    final isPostPinned = _pinnedPosts.any((p) => p.id == post.id);
    
    return GestureDetector(
      onTap: () => context.push('/network/post/${post.id}'),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            Image.network(
              mediaUrl.toString(),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            )
          else
            Container(
              color: Colors.grey[200],
              child: const Icon(Icons.image, color: Colors.grey),
            ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.favorite, size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(_formatNumber(post.likesCount), style: const TextStyle(fontSize: 10, color: Colors.white)),
                ],
              ),
            ),
          ),
          if (isPostPinned)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.push_pin, size: 12, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  // ⭐ CORRIGÉ - Récupération dynamique de mediaUrl
  Widget _buildPostListItem(NetworkPost post) {
    final dynamicPost = post as dynamic;
    final mediaUrl = dynamicPost.mediaUrl;
    final hasImage = mediaUrl != null && mediaUrl.toString().isNotEmpty;
    final isPostPinned = _pinnedPosts.any((p) => p.id == post.id);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (hasImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                mediaUrl.toString(),
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.content ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.favorite, size: 14, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(_formatNumber(post.likesCount), style: const TextStyle(fontSize: 11)),
                    const SizedBox(width: 12),
                    Icon(Icons.comment, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(_formatNumber(post.commentsCount), style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          if (isPostPinned) const Icon(Icons.push_pin, size: 16, color: Color(0xFFD4AF37)),
        ],
      ),
    );
  }

  Widget _buildPhotosContent() {
    return _buildPostsContent(_posts);
  }

  Widget _buildVideosContent() {
    return _buildPostsContent(_posts);
  }

  Widget _buildReelsContent() {
    return _buildPostsContent(_posts);
  }

  Widget _buildLikedContent() {
    return _buildPostsContent(_posts);
  }

  Widget _buildSavedContent() {
    if (_savedPosts.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return _buildPostsContent(_savedPosts);
  }

  void _editProfile() {
    context.push('/network/profile-settings');
  }

  void _changeCover() {
    // TODO: Changer la bannière
  }

  void _changeAvatar() {
    // TODO: Changer l'avatar
  }

  void _openUrl(String url) async {
    // TODO: Ouvrir URL
  }

  String _formatNumber(int num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}k';
    return num.toString();
  }
}
