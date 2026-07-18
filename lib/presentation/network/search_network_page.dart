import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:thix_id/models/network_community.dart';
import 'package:thix_id/services/network_service.dart';

class SearchNetworkPage extends StatefulWidget {
  const SearchNetworkPage({super.key});

  @override
  State<SearchNetworkPage> createState() => _SearchNetworkPageState();
}

class _SearchNetworkPageState extends State<SearchNetworkPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _query = '';
  bool _loading = false;
  late NetworkService _networkService;

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _posts = [];
  List<NetworkCommunity> _communities = [];

  // Gestion des états de connexion (Optimistic UI)
  Set<String> _pendingRequests = {};
  Set<String> _connectedUsers = {};

  // Couleurs de la charte THIX PRO
  final Color _thixPrimaryBlue = const Color(0xFF2B5CFF);
  final Color _thixDarkText = const Color(0xFF1A1A2E);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _networkService = Provider.of<NetworkService>(context, listen: false);
    _loadUserConnections(); // Charge les états existants au démarrage
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserConnections() async {
    try {
      final supabase = Supabase.instance.client;
      final uid = _networkService.currentUserId;

      final pendingRes = await supabase
          .from('connection_requests')
          .select('receiver_id')
          .eq('sender_id', uid)
          .eq('status', 'pending');

      final connRes = await supabase
          .from('connections')
          .select('connection_id')
          .eq('user_id', uid)
          .eq('status', 'accepted');

      if (mounted) {
        setState(() {
          _pendingRequests = (pendingRes as List).map((e) => e['receiver_id'] as String).toSet();
          _connectedUsers = (connRes as List).map((e) => e['connection_id'] as String).toSet();
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement connexions: $e');
    }
  }

  void _onSearchChanged(String value) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _search();
    });
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    
    // Si la recherche est vide, on réinitialise l'écran immédiatement
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _query = '';
          _users = [];
          _posts = [];
          _communities = [];
          _loading = false;
        });
      }
      return;
    }

    setState(() {
      _query = query;
      _loading = true;
    });

    try {
      // Chargement en parallèle
      final results = await Future.wait([
        _networkService.searchUsers(query),
        _networkService.searchPosts(query),
        _networkService.searchCommunities(query),
      ]);

      if (!mounted) return;

      // Bouclier Anti Race Condition : on ignore si l'utilisateur a continué de taper
      if (_searchController.text.trim() != query) {
        debugPrint('Race condition évitée: résultats pour "$query" ignorés.');
        return; 
      }

      setState(() {
        _users = results[0] as List<Map<String, dynamic>>;
        _posts = results[1] as List<Map<String, dynamic>>;
        _communities = results[2] as List<NetworkCommunity>;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Search error: $e');
      if (!mounted) return;
      
      if (_searchController.text.trim() == query) {
        setState(() {
          _users = [];
          _posts = [];
          _communities = [];
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur de recherche'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _sendConnectionRequest(String userId, String userName) async {
    // Optimistic UI : On change l'état immédiatement
    setState(() {
      _pendingRequests.add(userId);
    });

    try {
      await _networkService.sendConnectionRequest(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Demande envoyée à $userName'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      // Rollback en cas d'échec
      if (mounted) {
        setState(() {
          _pendingRequests.remove(userId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _joinCommunity(NetworkCommunity community) async {
    try {
      await _networkService.joinCommunity(community.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action effectuée pour ${community.name}'), backgroundColor: Colors.green),
        );
        _search(); // Rafraîchissement léger
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Recherche', style: TextStyle(color: _thixDarkText, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: _thixDarkText),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _thixPrimaryBlue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _thixPrimaryBlue,
          tabs: const [
            Tab(text: 'Personnes'),
            Tab(text: 'Publications'),
            Tab(text: 'Communautés'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: _thixPrimaryBlue))
                : _query.isEmpty
                    ? Center(child: Text('Recherchez des personnes, publications...', style: TextStyle(color: Colors.grey.shade600)))
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildUsersTab(),
                          _buildPostsTab(),
                          _buildCommunitiesTab(),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        onSubmitted: (_) => _search(),
        decoration: InputDecoration(
          hintText: 'Rechercher...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
          filled: true,
          fillColor: const Color(0xFFF5F8FA),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    if (_users.isEmpty) return const Center(child: Text('Aucun utilisateur trouvé'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (context, index) => _buildUserTile(_users[index]),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final avatarUrl = user['avatar_url']?.toString();
    final displayName = user['display_name']?.toString() ?? 'Utilisateur';
    final title = user['profession']?.toString() ?? user['title']?.toString();
    final userId = user['id']?.toString() ?? '';
    
    final isCurrentUser = userId == _networkService.currentUserId;
    final isPending = _pendingRequests.contains(userId);
    final isConnected = _connectedUsers.contains(userId);

    return GestureDetector(
      onTap: () => context.push('/network/profile/$userId'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) 
                  ? CachedNetworkImageProvider(avatarUrl) 
                  : null,
              child: (avatarUrl == null || avatarUrl.isEmpty) 
                  ? Icon(Icons.person, color: Colors.grey.shade400) 
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName, style: TextStyle(fontWeight: FontWeight.bold, color: _thixDarkText)),
                  if (title != null && title.isNotEmpty)
                    Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            if (!isCurrentUser)
              _buildConnectionButton(userId, displayName, isPending, isConnected)
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionButton(String userId, String userName, bool isPending, bool isConnected) {
    if (isConnected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(Icons.check, size: 14, color: _thixDarkText),
            const SizedBox(width: 4),
            Text('Connecté', style: TextStyle(fontSize: 11, color: _thixDarkText, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    if (isPending) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Text('En attente', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
      );
    }

    return OutlinedButton(
      onPressed: () => _sendConnectionRequest(userId, userName),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: _thixPrimaryBlue),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        foregroundColor: _thixPrimaryBlue,
      ),
      child: const Text('Se connecter', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPostsTab() {
    if (_posts.isEmpty) return const Center(child: Text('Aucune publication trouvée'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _posts.length,
      itemBuilder: (context, index) => _buildPostTile(_posts[index]),
    );
  }

  Widget _buildPostTile(Map<String, dynamic> post) {
    final userName = post['author_name']?.toString() ?? 'Utilisateur';
    final userAvatar = post['author_avatar']?.toString();
    final postId = post['id']?.toString() ?? '';
    final content = post['content']?.toString() ?? '';

    return GestureDetector(
      onTap: () => context.push('/network/post/$postId'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: (userAvatar != null && userAvatar.isNotEmpty) 
                      ? CachedNetworkImageProvider(userAvatar) 
                      : null,
                ),
                const SizedBox(width: 8),
                Text(userName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _thixDarkText)),
              ],
            ),
            const SizedBox(height: 12),
            Text(content, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(color: _thixDarkText.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunitiesTab() {
    if (_communities.isEmpty) return const Center(child: Text('Aucune communauté trouvée'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _communities.length,
      itemBuilder: (context, index) => _buildCommunityTile(_communities[index]),
    );
  }

  Widget _buildCommunityTile(NetworkCommunity community) {
    return GestureDetector(
      onTap: () => context.push('/network/community/${community.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _thixPrimaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.groups, color: _thixPrimaryBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(community.name, style: TextStyle(fontWeight: FontWeight.bold, color: _thixDarkText)),
                  Text('${community.membersCount} membres', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () => _joinCommunity(community),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _thixPrimaryBlue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                foregroundColor: _thixPrimaryBlue,
              ),
              child: const Text('Rejoindre', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
