import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/models/network_community.dart';
import 'package:thix_id/services/network_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CommunitiesListPage extends StatefulWidget {
  const CommunitiesListPage({super.key});

  @override
  State<CommunitiesListPage> createState() => _CommunitiesListPageState();
}

class _CommunitiesListPageState extends State<CommunitiesListPage> with SingleTickerProviderStateMixin {
  late NetworkService _networkService;
  late TabController _tabController;
  List<NetworkCommunity> _myCommunities = [];
  List<NetworkCommunity> _suggestedCommunities = [];
  List<NetworkCommunity> _allCommunities = [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _networkService = NetworkService(Supabase.instance.client);
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final myCommunities = await _networkService.getMyCommunities();
      final suggested = await _networkService.getSuggestedCommunities();
      final all = await _networkService.getAllCommunities();

      setState(() {
        _myCommunities = myCommunities;
        _suggestedCommunities = suggested;
        _allCommunities = all;
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ Erreur chargement communautés: $e');
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<NetworkCommunity> _getFilteredCommunities(List<NetworkCommunity> list) {
    if (_searchQuery.isEmpty) return list;
    return list.where((c) =>
      c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      (c.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Communautés',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF1A1A2E),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF1A1A2E)),
            onPressed: () => _showSearchDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF1A1A2E)),
            onPressed: () => _navigateToCreateCommunity(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFD4AF37),
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: const Color(0xFFD4AF37),
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Mes communautés'),
            Tab(text: 'Suggestions'),
            Tab(text: 'Toutes'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
              ),
            )
          : _error != null
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCommunityList(_myCommunities, 'Vous n\'avez pas encore rejoint de communauté.'),
                    _buildCommunityList(_suggestedCommunities, 'Aucune suggestion pour le moment.'),
                    _buildCommunityList(_allCommunities, 'Aucune communauté disponible.'),
                  ],
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 56, color: Colors.red.shade400),
          const SizedBox(height: 16),
          const Text(
            'Erreur de chargement',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600), // ✅ correction : sans 'const'
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityList(List<NetworkCommunity> communities, String emptyMessage) {
    final filtered = _getFilteredCommunities(communities);
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600), // ✅ correction : sans 'const'
              textAlign: TextAlign.center,
            ),
            if (_tabController.index == 1) // Suggestions
              const SizedBox(height: 16),
            if (_tabController.index == 1)
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Rafraîchir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFFD4AF37),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        itemBuilder: (context, index) => _buildCommunityCard(filtered[index]),
      ),
    );
  }

  Widget _buildCommunityCard(NetworkCommunity community) {
    final isMember = community.isMember ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: community.logoUrl != null && community.logoUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: community.logoUrl!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    width: 50,
                    height: 50,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.groups, color: Colors.grey),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    width: 50,
                    height: 50,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.groups, color: Colors.grey),
                  ),
                )
              : Container(
                  width: 50,
                  height: 50,
                  color: const Color(0xFFD4AF37).withOpacity(0.1),
                  child: const Icon(Icons.groups, color: Color(0xFFD4AF37)),
                ),
        ),
        title: Text(
          community.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Color(0xFF1A1A2E),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (community.description != null && community.description!.isNotEmpty)
              Text(
                community.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.people, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${community.membersCount ?? 0} membres',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                const SizedBox(width: 12),
                if (isMember)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Membre',
                      style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () => context.push('/network/community/${community.id}'),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Rechercher une communauté'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nom, description...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _navigateToCreateCommunity() {
    context.push('/network/community/create');
  }
}
