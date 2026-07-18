import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import 'package:thix_id/models/network_community.dart';
import 'package:thix_id/models/network_post.dart';
import 'package:thix_id/services/network_service.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/presentation/network/widgets/post_card.dart';

class CommunityDetailPage extends StatefulWidget {
  final String communityId;
  const CommunityDetailPage({super.key, required this.communityId});

  @override
  State<CommunityDetailPage> createState() => _CommunityDetailPageState();
}

class _CommunityDetailPageState extends State<CommunityDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late NetworkService _networkService;
  NetworkCommunity? _community;
  List<NetworkPost> _posts = [];
  List<Map<String, dynamic>> _members = [];
  bool _loading = true;
  bool _isMember = false;
  bool _isJoining = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // OPTIMISATION : Utilisation du Provider existant
    _networkService = Provider.of<NetworkService>(context, listen: false);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // OPTIMISATION : Parallélisation massive des requêtes
  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    
    try {
      final supabase = Supabase.instance.client;
      final currentUserId = supabase.auth.currentUser?.id;

      // On lance les 4 requêtes EN MÊME TEMPS
      final results = await Future.wait([
        supabase.from('communities').select('*').eq('id', widget.communityId).maybeSingle(),
        supabase.from('community_members').select('''
            users!user_id (id, display_name, photo_url, profession)
          ''').eq('community_id', widget.communityId).limit(20),
        supabase.from('posts').select('''
            *, users!user_id (display_name, photo_url, profession)
          ''').eq('community_id', widget.communityId).order('created_at', ascending: false).limit(20),
        currentUserId != null 
            ? supabase.from('community_members').select('id').eq('community_id', widget.communityId).eq('user_id', currentUserId).maybeSingle()
            : Future.value(null),
      ]);

      if (!mounted) return;

      final communityData = results[0] as Map<String, dynamic>?;
      if (communityData == null) throw Exception('Communauté non trouvée');

      final membersData = results[1] as List<dynamic>;
      final postsData = results[2] as List<dynamic>;
      final memberCheck = results[3] as Map<String, dynamic>?;

      // Traitement des données
      final posts = <NetworkPost>[];
      for (var e in postsData) {
        final userData = e['users'] as Map<String, dynamic>?;
        posts.add(NetworkPost.fromJson({
          ...e as Map<String, dynamic>,
          'author_name': userData?['display_name'] ?? 'Utilisateur',
          'author_avatar': userData?['photo_url'],
          'author_title': userData?['profession'],
          'media_urls': _extractMediaUrls(e),
        }));
      }

      setState(() {
        _community = NetworkCommunity.fromJson({
          ...communityData,
          'members_count': communityData['members_count'] ?? 0,
        });
        _members = membersData.map((e) => e['users'] as Map<String, dynamic>).toList();
        _posts = posts;
        _isMember = memberCheck != null;
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ Erreur chargement communauté: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  List<String> _extractMediaUrls(Map<String, dynamic> row) {
    if (row['media_urls'] != null) return List<String>.from(row['media_urls'] as List);
    if (row['media_url'] != null && row['media_url'].toString().isNotEmpty) return [row['media_url'].toString()];
    if (row['image_urls'] != null) return List<String>.from(row['image_urls'] as List);
    return [];
  }

  // OPTIMISATION : Vrai Optimistic UI avec Rollback de sécurité
  Future<void> _toggleJoin() async {
    if (_isJoining || _community == null) return;
    setState(() => _isJoining = true);

    // Sauvegarde de l'état précédent pour le Rollback
    final wasMember = _isMember;
    final previousCount = _community!.membersCount;

    // 1. Mise à jour Optimiste (Instantanée)
    setState(() {
      _isMember = !wasMember;
      _community = _community!.copyWith(
        membersCount: wasMember ? (previousCount - 1) : (previousCount + 1),
      );
    });

    try {
      final supabase = Supabase.instance.client;
      final currentUserId = supabase.auth.currentUser!.id;

      // 2. Appel réseau
      if (wasMember) {
        await supabase.from('community_members')
            .delete()
            .eq('community_id', widget.communityId)
            .eq('user_id', currentUserId);
      } else {
        await supabase.from('community_members').insert({
          'community_id': widget.communityId,
          'user_id': currentUserId,
          'joined_at': DateTime.now().toIso8601String(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isMember ? '✅ Vous avez rejoint la communauté' : '❌ Vous avez quitté la communauté'),
            backgroundColor: _isMember ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur Join/Leave: $e');
      // 3. Rollback en cas d'erreur
      if (mounted) {
        setState(() {
          _isMember = wasMember;
          _community = _community!.copyWith(membersCount: previousCount);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur réseau. Action annulée.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  void _shareCommunity() {
    final link = 'https://thix.app/community/${widget.communityId}';
    Share.share('Rejoins la communauté "${_community?.name ?? 'cette communauté'}" sur THIX PRO ! $link');
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);
    final currentUserId = auth.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          _community?.name ?? 'Communauté',
          style: const TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A1A2E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFF1A1A2E), size: 22),
            onPressed: _shareCommunity,
          ),
          if (_community != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton(
                onPressed: _isJoining ? null : _toggleJoin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isMember ? Colors.white : const Color(0xFFD4AF37),
                  foregroundColor: _isMember ? const Color(0xFFD4AF37) : Colors.white,
                  side: _isMember ? const BorderSide(color: Color(0xFFD4AF37)) : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: _isJoining
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_isMember ? 'Quitter' : 'Rejoindre'),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFD4AF37),
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: const Color(0xFFD4AF37),
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [
            Tab(text: '📝 À propos'),
            Tab(text: '👥 Membres'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37))))
          : _error != null
              ? _buildErrorState()
              : _community == null
                  ? _buildNotFoundState()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAboutTab(currentUserId),
                        _buildMembersTab(),
                      ],
                    ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red.shade400),
            const SizedBox(height: 16),
            const Text('Erreur de chargement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.groups, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('Communauté non trouvée', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Cette communauté n\'existe pas ou a été supprimée.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Retour'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTab(String currentUserId) {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFFD4AF37),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bannière
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B1B3D), Color(0xFF1A2B4D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                image: _community?.bannerUrl != null && _community!.bannerUrl!.isNotEmpty
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(_community!.bannerUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _community?.bannerUrl == null || _community!.bannerUrl!.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.groups, size: 56, color: const Color(0xFFD4AF37).withOpacity(0.6)),
                          const SizedBox(height: 8),
                          Text(
                            _community?.name ?? 'Communauté',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),

            // Titre et description
            Row(
              children: [
                Expanded(
                  child: Text(
                    _community!.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _community?.privacy ?? 'Public',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFD4AF37)),
                  ),
                ),
              ],
            ),
            if (_community?.description != null && _community!.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _community!.description!,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
              ),
            ],
            const SizedBox(height: 16),

            // Statistiques
            Row(
              children: [
                _buildStatItem('${_community?.membersCount ?? 0}', 'membres', Icons.people),
                const SizedBox(width: 24),
                _buildStatItem('${_posts.length}', 'publications', Icons.article),
              ],
            ),
            const SizedBox(height: 24),

            // Publications
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('📄 Dernières publications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                if (_posts.isNotEmpty)
                  TextButton(
                    onPressed: () {},
                    child: const Text('Voir tout', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 13)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_posts.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.article_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      const Text('Aucune publication', style: TextStyle(color: Colors.grey)),
                      if (_isMember) const SizedBox(height: 8),
                      if (_isMember)
                        TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Publier dans la communauté'),
                          style: TextButton.styleFrom(foregroundColor: const Color(0xFFD4AF37)),
                        ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: _posts.map((post) => PostCard(
                  post: post,
                  currentProfileId: currentUserId,
                  onLike: () => _toggleLike(post.id),
                  onComment: () => _openComments(post.id),
                  onTap: () => context.push('/network/post/${post.id}'),
                  onShare: () => _sharePost(post.id),
                  onRefresh: _loadData,
                )).cast<Widget>().toList(),
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFD4AF37)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      ],
    );
  }

  Widget _buildMembersTab() {
    if (_members.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('Aucun membre pour le moment', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFFD4AF37),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _members.length,
        itemBuilder: (context, index) => _buildMemberTile(_members[index]),
      ),
    );
  }

  Widget _buildMemberTile(Map<String, dynamic> member) {
    final name = member['display_name'] ?? 'Utilisateur';
    final avatar = member['photo_url'];
    final title = member['profession'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: avatar != null && avatar.isNotEmpty ? CachedNetworkImageProvider(avatar) : null,
          child: avatar == null || avatar.isEmpty ? Text(name[0].toUpperCase(), style: const TextStyle(fontSize: 16)) : null,
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: title != null && title.isNotEmpty ? Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)) : null,
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        onTap: () => context.push('/network/profile/${member['id']}'),
      ),
    );
  }

  // OPTIMISATION : L'Optimistic UI était bien pensé ici, on le garde !
  Future<void> _toggleLike(String postId) async {
    try {
      final post = _posts.firstWhere((p) => p.id == postId);
      final newIsLiked = !post.isLiked;
      final newCount = post.likesCount + (newIsLiked ? 1 : -1);

      setState(() {
        final index = _posts.indexWhere((p) => p.id == postId);
        if (index != -1) {
          _posts[index] = post.copyWith(isLiked: newIsLiked, likesCount: newCount);
        }
      });

      if (newIsLiked) {
        await _networkService.likePost(postId);
      } else {
        await _networkService.unlikePost(postId);
      }
    } catch (e) {
      debugPrint('❌ Erreur like: $e');
      await _loadData(); // Rechargement discret si le like a échoué (Rollback)
    }
  }

  void _openComments(String postId) {
    context.push('/network/comments/$postId');
  }

  void _sharePost(String postId) {
    Share.share('Découvrez cette publication sur THIX PRO !');
  }
}
