import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/media_service.dart';
import '../../models/media_content.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;
  const UserProfilePage({super.key, required this.userId});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  Map<String, dynamic>? _profile;
  Map<String, int> _stats = {'followers': 0, 'following': 0, 'posts': 0};
  bool _isFollowing = false;
  bool _loading = true;
  List<MediaContent> _userPosts = [];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final service = MediaService();
    final profileData = await service.fetchProfile(widget.userId);
    final statsData = await service.fetchUserStats(widget.userId);
    final followingStatus = await service.isFollowing(widget.userId);
    
    // Récupérer les posts de cet utilisateur
    final postsData = await Supabase.instance.client
        .from('media_content')
        .select()
        .eq('user_id', widget.userId)
        .order('created_at', ascending: false);

    if (mounted) {
      setState(() {
        _profile = profileData;
        _stats = statsData;
        _isFollowing = followingStatus;
        _userPosts = (postsData as List).map((e) => MediaContent.fromJson(e)).toList();
        _loading = false;
      });
    }
  }

  Future<void> _handleFollowToggle() async {
    final res = await MediaService().toggleFollow(widget.userId);
    setState(() {
      _isFollowing = res;
      _stats['followers'] = (_stats['followers'] ?? 0) + (res ? 1 : -1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isMe = currentUserId == widget.userId;

    if (_loading) {
      return const Scaffold(backgroundColor: Color(0xFF050507), body: Center(child: CircularProgressIndicator(color: Color(0xFFFF1A1A))));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF050507),
      appBar: AppBar(backgroundColor: Colors.transparent, title: Text(_profile?['username'] ?? 'Profil', style: const TextStyle(color: Colors.white)), iconTheme: const IconThemeData(color: Colors.white)),
      body: Column(
        children: [
          const SizedBox(height: 20),
          CircleAvatar(radius: 40, backgroundImage: _profile?['avatar_url'] != null ? NetworkImage(_profile!['avatar_url']) : null, child: _profile?['avatar_url'] == null ? const Icon(Icons.person, size: 40) : null),
          const SizedBox(height: 12),
          Text(_profile?['username'] ?? 'Utilisateur', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statItem('Publications', '${_stats['posts']}'),
              _statItem('Abonnés', '${_stats['followers']}'),
              _statItem('Abonnements', '${_stats['following']}'),
            ],
          ),
          const SizedBox(height: 20),
          if (!isMe)
            ElevatedButton(
              onPressed: _handleFollowToggle,
              style: ElevatedButton.styleFrom(backgroundColor: _isFollowing ? Colors.grey[800] : const Color(0xFFFF1A1A)),
              child: Text(_isFollowing ? 'Abonné' : "S'abonner", style: const TextStyle(color: Colors.white)),
            ),
          const Divider(color: Colors.white24, height: 40),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
              itemCount: _userPosts.length,
              itemBuilder: (context, index) {
                final post = _userPosts[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(post.coverUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: Colors.grey)),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
