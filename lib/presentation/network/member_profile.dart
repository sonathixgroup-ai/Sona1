// lib/presentation/network/member_profile.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/services/network_service.dart';
import 'package:thix_id/models/network_post.dart';

class MemberProfile extends StatefulWidget {
  final String userId;
  const MemberProfile({super.key, required this.userId});

  @override
  State<MemberProfile> createState() => _MemberProfileState();
}

class _MemberProfileState extends State<MemberProfile> {
  late NetworkService _networkService;
  Map<String, dynamic>? _user;
  List<NetworkPost> _posts = [];
  bool _loading = true;
  bool _isConnected = false;
  bool _isConnectionPending = false;

  // Méthode locale pour vérifier le statut de connexion
  Future<String?> _getConnectionStatusDirect(String userId) async {
    try {
      final supabase = Supabase.instance.client;
      final currentUserId = supabase.auth.currentUser!.id;
      
      final connection = await supabase
          .from('connections')
          .select('status')
          .or('user_id.eq.$currentUserId,connection_id.eq.$currentUserId')
          .or('user_id.eq.$userId,connection_id.eq.$userId')
          .eq('status', 'accepted')
          .maybeSingle();
      
      if (connection != null) return 'accepted';
      
      final request = await supabase
          .from('connection_requests')
          .select('status')
          .or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
          .or('sender_id.eq.$userId,receiver_id.eq.$userId')
          .eq('status', 'pending')
          .maybeSingle();
      
      return request != null ? 'pending' : null;
    } catch (e) {
      debugPrint('Error checking connection status: $e');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _networkService = NetworkService(Supabase.instance.client);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final userData = await _networkService.getUserProfile(widget.userId);
      final posts = await _networkService.getUserPosts(widget.userId);
      final connectionStatus = await _getConnectionStatusDirect(widget.userId);
      
      setState(() {
        _user = userData;
        _posts = posts;
        _isConnected = connectionStatus == 'accepted';
        _isConnectionPending = connectionStatus == 'pending';
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _loading = false);
    }
  }

  Future<void> _sendConnectionRequest() async {
    try {
      await _networkService.sendConnectionRequest(widget.userId);
      setState(() => _isConnectionPending = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demande de connexion envoyée'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _sendMessage() {
    context.push('/network/chat/${widget.userId}');
  }

  void _shareProfile() {
    final displayName = _user?['display_name']?.toString() ?? 'Utilisateur';
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Partage bientôt disponible'), backgroundColor: Colors.orange),
    );
  }

  Future<void> _blockUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bloquer l\'utilisateur'),
        content: const Text('Voulez-vous vraiment bloquer cet utilisateur ? Il ne pourra plus vous contacter.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Bloquer')),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        final supabase = Supabase.instance.client;
        final currentUserId = supabase.auth.currentUser!.id;
        
        final existing = await supabase
            .from('blocked_users')
            .select('id')
            .eq('user_id', currentUserId)
            .eq('blocked_user_id', widget.userId)
            .maybeSingle();
        
        if (existing == null) {
          await supabase.from('blocked_users').insert({
            'user_id': currentUserId,
            'blocked_user_id': widget.userId,
            'blocked_at': DateTime.now().toIso8601String(),
          });
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Utilisateur bloqué'), backgroundColor: Colors.red),
          );
          context.pop();
        }
      } catch (e) {
        debugPrint('Error blocking user: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _reportUser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Signaler cet utilisateur'),
        content: const Text('Voulez-vous signaler ce profil pour comportement inapproprié ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Signalement envoyé'), backgroundColor: Colors.orange),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Signaler'),
          ),
        ],
      ),
    );
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.red),
              title: const Text('Signaler', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _reportUser();
              },
            ),
            if (_isConnected)
              ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: const Text('Bloquer', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _blockUser();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return 'il y a ${diff.inDays}j';
    if (diff.inHours > 0) return 'il y a ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'il y a ${diff.inMinutes}min';
    return 'à l\'instant';
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _user?['display_name'] ?? 'Profil',
          style: const TextStyle(color: Color(0xFF0B1B3D), fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0B1B3D)),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF0B1B3D)),
            onPressed: _showOptions,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildStats(),
                    _buildActionButtons(),
                    const SizedBox(height: 16),
                    _buildPosts(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final avatarUrl = _user?['photo_url']?.toString();
    final displayName = _user?['display_name']?.toString() ?? 'Utilisateur';
    final title = _user?['profession']?.toString() ?? 'Membre THIX';
    final bio = _user?['bio']?.toString();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty 
                ? NetworkImage(avatarUrl) 
                : null,
            child: avatarUrl == null || avatarUrl.isEmpty
                ? Icon(Icons.person, size: 50, color: Colors.grey.shade400)
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            displayName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          if (bio != null && bio.isNotEmpty)
            Text(
              bio,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final postsCount = _user?['posts_count'] as int? ?? 0;
    final followersCount = _user?['followers_count'] as int? ?? 0;
    final followingCount = _user?['following_count'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(postsCount, 'Publications'),
          _buildStatItem(followersCount, 'Abonnés'),
          _buildStatItem(followingCount, 'Abonnements'),
        ],
      ),
    );
  }

  Widget _buildStatItem(int value, String label) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _isConnected
                ? OutlinedButton.icon(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.message),
                    label: const Text('Message'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: _isConnectionPending ? null : _sendConnectionRequest,
                    icon: Icon(_isConnectionPending ? Icons.hourglass_empty : Icons.person_add),
                    label: Text(_isConnectionPending ? 'En attente' : 'Se connecter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: const Color(0xFF0B1B3D),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _shareProfile,
              icon: const Icon(Icons.share),
              label: const Text('Partager'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPosts() {
    if (_posts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text('Aucune publication pour le moment'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _posts.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildPostCard(_posts[index]),
      ),
    );
  }

  // ⭐ CORRIGÉ - Utilisation sécurisée des propriétés
  Widget _buildPostCard(NetworkPost post) {
    // Vérification sécurisée pour mediaUrl
    final dynamicPost = post as dynamic;
    final mediaUrl = dynamicPost.mediaUrl;
    final hasImage = mediaUrl != null && mediaUrl.toString().isNotEmpty;
    final hasContent = post.content != null && post.content!.isNotEmpty;
    
    // Vérification sécurisée pour sharesCount
    final sharesCount = dynamicPost.sharesCount ?? 0;

    return GestureDetector(
      onTap: () => context.push('/network/post/${post.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
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
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: post.authorAvatar != null && post.authorAvatar!.isNotEmpty
                      ? NetworkImage(post.authorAvatar!)
                      : null,
                  child: post.authorAvatar == null || post.authorAvatar!.isEmpty
                      ? const Icon(Icons.person, size: 16)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    post.authorName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                Text(
                  _formatTime(post.createdAt),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
            if (hasContent) ...[
              const SizedBox(height: 8),
              Text(post.content!, style: const TextStyle(fontSize: 13)),
            ],
            // ⭐ CORRIGÉ - Image avec vérification sécurisée
            if (hasImage) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  mediaUrl.toString(),
                  width: double.infinity,
                  height: 150,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 150,
                      color: Colors.grey.shade200,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    color: Colors.grey.shade200,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 40, color: Colors.grey),
                        SizedBox(height: 4),
                        Text('Image non disponible', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                _buildActionButton(Icons.favorite_border, _formatCount(post.likesCount)),
                const SizedBox(width: 16),
                _buildActionButton(Icons.comment_outlined, _formatCount(post.commentsCount)),
                const SizedBox(width: 16),
                // ⭐ CORRIGÉ - sharesCount avec vérification
                _buildActionButton(Icons.share_outlined, _formatCount(sharesCount)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}
