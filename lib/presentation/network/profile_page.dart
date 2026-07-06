// lib/presentation/network/profile_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/services/network_service.dart';
import 'package:thix_id/models/network_post.dart';
import 'widgets/pinned_post.dart';
import 'dart:async';

class ProfilePage extends StatefulWidget { // ✅ StatefulWidget
  final String? userId;
  final String? currentProfileId; // ✅ paramètre ajouté

  const ProfilePage({
    super.key,
    this.userId,
    this.currentProfileId,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  // ... tout le reste du code reste inchangé
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
    _checkFollowStatus();
  }

  @override
  void dispose() {
    _levelUpController.dispose();
    super.dispose();
  }

  // ─── CHARGEMENT DES DONNÉES ───
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

  // ─── SUIVI ───
  Future<void> _checkFollowStatus() async {
    if (widget.userId == null || widget.userId == _networkService.currentUserId) {
      setState(() => _isFollowing = false);
      return;
    }
    try {
      final userId = widget.userId!;
      final response = await Supabase.instance.client
          .from('connections')
          .select('id')
          .eq('user_id', _networkService.currentUserId)
          .eq('connection_id', userId)
          .eq('status', 'accepted')
          .maybeSingle();
      setState(() => _isFollowing = response != null);
    } catch (e) {
      debugPrint('Error checking follow status: $e');
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

  // ─── MESSAGERIE ───
  void _sendMessage() {
    context.push('/network/chat/${widget.userId}');
  }

  // ─── ÉPINGLER ───
  Future<void> _unpinPost(String postId) async {
    await _networkService.unpinPost(postId);
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post désépinglé'), backgroundColor: Colors.orange),
      );
    }
  }

  // ─── PARTAGE ───
  void _shareProfile() {
    final name = _user?['display_name'] ?? 'Utilisateur';
    final url = 'Découvrez le profil de $name sur THIX Réseau Pro !';
    Share.share(url);
  }

  // ─── CHANGER COUVERTURE ───
  Future<void> _changeCover() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final url = await _networkService.uploadImageBytes(
      bytes,
      fileExtension: picked.path.split('.').last,
      bucket: 'covers',
    );
    if (url != null) {
      await Supabase.instance.client
          .from('users')
          .update({'cover_url': url})
          .eq('id', _networkService.currentUserId);
      await _loadData();
    }
  }

  // ─── CHANGER AVATAR ───
  Future<void> _changeAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final url = await _networkService.uploadImageBytes(
      bytes,
      fileExtension: picked.path.split('.').last,
      bucket: 'avatars',
    );
    if (url != null) {
      await Supabase.instance.client
          .from('users')
          .update({'photo_url': url})
          .eq('id', _networkService.currentUserId);
      await _loadData();
    }
  }

  // ─── OUVRIR URL ───
  void _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Impossible d\'ouvrir $url';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d\'ouvrir le lien: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ─── ÉDITER PROFIL ───
  void _editProfile() {
    context.push('/network/profile-settings');
  }

  // ─── FORMATAGE ───
  String _formatNumber(int num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}k';
    return num.toString();
  }

  // ─── BUILD ───
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
                  SliverToBoxAdapter(child: _buildCoverBanner(isOwnProfile)),
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

                  _buildTabContent(),

                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
    );
  }

  // ─── COUVERTURE ───
  Widget _buildCoverBanner(bool isOwnProfile) {
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
        if (isOwnProfile)
          Positioned(
            bottom: -30,
            right: 16,
            child: CircleAvatar(
              backgroundColor: const Color(0xFFD4AF37),
              child: IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                onPressed: _changeCover,
              ),
            ),
          ),
      ],
    );
  }

  // ─── EN-TÊTE PROFIL ───
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
                  if (isOwnProfile)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: const Color(0xFFD4AF37),
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
                          onPressed: _changeAvatar,
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
                      onPressed: _editProfile,
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

  // ─── XP BAR ───
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

  // ─── STATISTIQUES ───
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

  // ─── BADGES ───
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

  // ─── À PROPOS ───
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

  // ─── TABS ───
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

  // ─── CONTENU DES ONGLETS ───
  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildPostsContent(_posts);
      case 1:
        return _buildFilteredContent('image');
      case 2:
        return _buildFilteredContent('video');
      case 3:
        return _buildFilteredContent('reel');
      case 4:
        return _buildPostsContent(_posts); // J'aime (tous, mais on pourrait filtrer)
      case 5:
        return _buildSavedContent();
      default:
        return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
  }

  Widget _buildFilteredContent(String mediaType) {
    final filtered = _posts.where((post) {
      if (mediaType == 'image') return post.imageUrls.isNotEmpty;
      if (mediaType == 'video') return post.videoUrls.isNotEmpty;
      if (mediaType == 'reel') return post.videoUrls.isNotEmpty; // reel = vidéo courte
      return false;
    }).toList();
    if (filtered.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text('Aucun contenu de ce type.', style: TextStyle(color: Colors.grey)),
          ),
        ),
      );
    }
    return _buildPostsContent(filtered);
  }

  Widget _buildSavedContent() {
    if (_savedPosts.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text('Aucun post sauvegardé.', style: TextStyle(color: Colors.grey)),
          ),
        ),
      );
    }
    return _buildPostsContent(_savedPosts);
  }

  // ─── AFFICHAGE DES POSTS (Grille/Liste) ───
  Widget _buildPostsContent(List<NetworkPost> posts) {
    if (posts.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text('Aucun post pour le moment.', style: TextStyle(color: Colors.grey)),
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

  Widget _buildPostGridItem(NetworkPost post) {
    final mediaUrl = post.imageUrls.isNotEmpty ? post.imageUrls.first : null;
    final isPostPinned = _pinnedPosts.any((p) => p.id == post.id);

    return GestureDetector(
      onTap: () => context.push('/network/post/${post.id}'),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (mediaUrl != null)
            Image.network(
              mediaUrl,
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

  Widget _buildPostListItem(NetworkPost post) {
    final mediaUrl = post.imageUrls.isNotEmpty ? post.imageUrls.first : null;
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
          if (mediaUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                mediaUrl,
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
                Text(
                  post.content.isNotEmpty ? post.content : 'Sans description',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
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
}
