import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/models/network_community.dart';

class CommunityDetailPage extends StatefulWidget {
  final String communityId;
  const CommunityDetailPage({super.key, required this.communityId});

  @override
  State<CommunityDetailPage> createState() => _CommunityDetailPageState();
}

class _CommunityDetailPageState extends State<CommunityDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  NetworkCommunity? _community;
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;
  bool _isMember = false;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final supabase = Supabase.instance.client;
      final currentUserId = supabase.auth.currentUser?.id;

      final community = await supabase
          .from('network_communities')
          .select('*')
          .eq('id', widget.communityId)
          .single();

      final members = await supabase
          .from('community_members')
          .select('''
            profiles!user_id (id, display_name, avatar_url, title)
          ''')
          .eq('community_id', widget.communityId)
          .limit(20);

      // ✅ Correction: utiliser network_posts au lieu de community_posts
      final posts = await supabase
          .from('network_posts')
          .select('''
            *,
            profiles!user_id (display_name, avatar_url)
          ''')
          .eq('community_id', widget.communityId)
          .order('created_at', ascending: false)
          .limit(20);

      if (currentUserId != null) {
        final memberCheck = await supabase
            .from('community_members')
            .select('id')
            .eq('community_id', widget.communityId)
            .eq('user_id', currentUserId)
            .maybeSingle();
        _isMember = memberCheck != null;
      }

      setState(() {
        _community = NetworkCommunity.fromJson(community);
        _members = (members as List).map((e) => e['profiles'] as Map<String, dynamic>).toList();
        _posts = (posts as List).cast<Map<String, dynamic>>();
      });
    } catch (e) {
      debugPrint('Error loading community: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleJoin() async {
    if (_isJoining) return;
    setState(() => _isJoining = true);

    try {
      final supabase = Supabase.instance.client;
      final currentUserId = supabase.auth.currentUser!.id;

      if (_isMember) {
        await supabase
            .from('community_members')
            .delete()
            .eq('community_id', widget.communityId)
            .eq('user_id', currentUserId);
        
        // Décrémenter le compteur
        await supabase.rpc('decrement_community_members', params: {'community_id': widget.communityId});
      } else {
        await supabase.from('community_members').insert({
          'community_id': widget.communityId,
          'user_id': currentUserId,
          'joined_at': DateTime.now().toIso8601String(),
        });
        
        // Incrémenter le compteur
        await supabase.rpc('increment_community_members', params: {'community_id': widget.communityId});
      }

      setState(() => _isMember = !_isMember);
      await _loadData(); // Recharger pour mettre à jour le compteur
    } catch (e) {
      debugPrint('Error toggling join: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isJoining = false);
    }
  }

  void _shareCommunity() {
    final link = 'https://thix.app/community/${widget.communityId}';
    Share.share('Rejoins la communauté "${_community?.name ?? 'cette communauté'}" sur THIX Réseau Pro ! $link');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(_community?.name ?? 'Communauté', style: const TextStyle(color: Color(0xFF0B1B3D), fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFF0B1B3D)),
            onPressed: _shareCommunity,
          ),
          if (_community != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton(
                onPressed: _isJoining ? null : _toggleJoin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isMember ? Colors.white : const Color(0xFFD4AF37),
                  foregroundColor: const Color(0xFF0B1B3D),
                  side: _isMember ? BorderSide(color: const Color(0xFFD4AF37)) : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(_isMember ? 'Quitter' : 'Rejoindre'),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFD4AF37),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFD4AF37),
          tabs: const [Tab(text: 'À propos'), Tab(text: 'Membres')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _community == null
              ? const Center(child: Text('Communauté non trouvée'))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAboutTab(),
                    _buildMembersTab(),
                  ],
                ),
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              image: _community?.bannerUrl != null
                  ? DecorationImage(image: NetworkImage(_community!.bannerUrl!), fit: BoxFit.cover)
                  : null,
            ),
            child: _community?.bannerUrl == null
                ? const Center(child: Icon(Icons.groups, size: 50, color: Color(0xFFD4AF37)))
                : null,
          ),
          const SizedBox(height: 16),
          if (_community?.description != null && _community!.description!.isNotEmpty) ...[
            const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(_community!.description!),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              _buildStatItem('${_members.length}', 'membres'),
              const SizedBox(width: 24),
              _buildStatItem('${_posts.length}', 'publications'),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Dernières publications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          if (_posts.isEmpty)
            const Center(child: Text('Aucune publication pour le moment')),
          ..._posts.map((post) => _buildPostTile(post)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildPostTile(Map<String, dynamic> post) {
    final user = post['profiles'];
    return GestureDetector(
      onTap: () => context.push('/network/post/${post['id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
                ),
                const SizedBox(width: 8),
                Text(user['display_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            Text(post['content'], maxLines: 3, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersTab() {
    if (_members.isEmpty) {
      return const Center(child: Text('Aucun membre pour le moment'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _members.length,
      itemBuilder: (context, index) => _buildMemberTile(_members[index]),
    );
  }

  Widget _buildMemberTile(Map<String, dynamic> member) {
    return GestureDetector(
      onTap: () => context.push('/network/profile/${member['id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: member['avatar_url'] != null ? NetworkImage(member['avatar_url']) : null,
              child: member['avatar_url'] == null ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member['display_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (member['title'] != null && member['title'].toString().isNotEmpty)
                    Text(member['title'], style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
