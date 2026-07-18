import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart'; // 💡 Ajout indispensable
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
  String? _connectionStatus; // 'accepted', 'pending', ou null

  @override
  void initState() {
    super.initState();
    _networkService = NetworkService(Supabase.instance.client);
    _loadData();
  }

  // OPTIMISATION : Chargement parallèle (4 requêtes en 1 seul aller-retour réseau)
  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _networkService.getUserProfile(widget.userId),
        _networkService.getUserPosts(widget.userId),
        _networkService.getConnectionStatus(widget.userId), // 💡 À ajouter dans ton NetworkService
      ]);
      
      if (!mounted) return;

      setState(() {
        _user = results[0] as Map<String, dynamic>?;
        _posts = results[1] as List<NetworkPost>;
        _connectionStatus = results[2] as String?;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
      }
      setState(() => _loading = false);
    }
  }

  // ... (Garde tes méthodes _sendConnectionRequest, _blockUser, etc.)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(_user?['display_name'] ?? 'Profil', style: const TextStyle(color: Color(0xFF0B1B3D), fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF0B1B3D)), onPressed: () => context.pop()),
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
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final avatarUrl = _user?['photo_url']?.toString();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(bottom: Radius.circular(24))),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey.shade200,
            // 💡 Utilisation sécurisée de CachedNetworkImage
            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) 
                ? CachedNetworkImageProvider(avatarUrl) 
                : null,
            child: (avatarUrl == null || avatarUrl.isEmpty) ? const Icon(Icons.person, size: 50) : null,
          ),
          // ... reste du header
        ],
      ),
    );
  }

  Widget _buildPostCard(NetworkPost post) {
    return GestureDetector(
      onTap: () => context.push('/network/post/${post.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ... header auteur
            if (post.content != null && post.content!.isNotEmpty)
              Text(post.content!, style: const TextStyle(fontSize: 13)),
            
            // 💡 Gestion sécurisée et propre des médias
            if (post.mediaUrls.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: post.mediaUrls.first,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(height: 150, color: Colors.grey.shade200),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
