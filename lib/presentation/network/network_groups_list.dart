import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/models/network_community.dart';

class NetworkGroupsList extends StatefulWidget {
  const NetworkGroupsList({super.key});

  @override
  State<NetworkGroupsList> createState() => _NetworkGroupsListState();
}

class _NetworkGroupsListState extends State<NetworkGroupsList>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<NetworkCommunity> _myGroups = [];
  List<NetworkCommunity> _suggestedGroups = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadGroups();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    setState(() => _loading = true);

    try {
      final supabase = Supabase.instance.client;
      final currentUserId = supabase.auth.currentUser?.id;

      if (currentUserId == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      // Mes groupes
      final myGroupsData = await supabase
          .from('community_members')
          .select('communities!community_id(*)')
          .eq('user_id', currentUserId);

      final myGroups = (myGroupsData as List)
          .map((e) => NetworkCommunity.fromJson(e['communities'] as Map<String, dynamic>))
          .toList();

      final myGroupIds = myGroups.map((g) => g.id).toList();

      // Suggestions (exclure mes groupes)
      final suggestedData = await supabase
          .from('network_communities')
          .select('*')
          .order('members_count', ascending: false)
          .limit(20);

      final suggestedGroups = (suggestedData as List)
          .map((e) => NetworkCommunity.fromJson(e as Map<String, dynamic>))
          .where((g) => !myGroupIds.contains(g.id))
          .toList();

      if (!mounted) return;

      setState(() {
        _myGroups = myGroups;
        _suggestedGroups = suggestedGroups;
      });
    } catch (e) {
      debugPrint('Error loading groups: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleJoin(NetworkCommunity group, bool isCurrentMember) async {
    try {
      final supabase = Supabase.instance.client;
      final currentUserId = supabase.auth.currentUser!.id;

      if (isCurrentMember) {
        // Quitter
        await supabase
            .from('community_members')
            .delete()
            .eq('community_id', group.id)
            .eq('user_id', currentUserId);
        
        await supabase.rpc('decrement_community_members', params: {'community_id': group.id});
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Groupe quitté'), backgroundColor: Colors.orange),
          );
        }
      } else {
        // Rejoindre
        await supabase.from('community_members').insert({
          'community_id': group.id,
          'user_id': currentUserId,
          'joined_at': DateTime.now().toIso8601String(),
        });
        
        await supabase.rpc('increment_community_members', params: {'community_id': group.id});
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Groupe rejoint !'), backgroundColor: Colors.green),
          );
        }
      }
      
      await _loadGroups();
    } catch (e) {
      debugPrint('Error toggling group: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Créer un groupe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                hintText: 'Nom du groupe',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Description (optionnelle)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              
              Navigator.pop(context);
              
              try {
                final supabase = Supabase.instance.client;
                final currentUserId = supabase.auth.currentUser!.id;
                
                final response = await supabase
                    .from('network_communities')
                    .insert({
                      'name': nameController.text.trim(),
                      'description': descController.text.trim(),
                      'created_by': currentUserId,
                      'created_at': DateTime.now().toIso8601String(),
                      'members_count': 1,
                      'posts_count': 0,
                    })
                    .select()
                    .single();
                
                await supabase.from('community_members').insert({
                  'community_id': response['id'],
                  'user_id': currentUserId,
                  'role': 'admin',
                  'joined_at': DateTime.now().toIso8601String(),
                });
                
                await _loadGroups();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Groupe créé !'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                debugPrint('Error creating group: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Groupes',
          style: TextStyle(color: Color(0xFF0B1B3D), fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0B1B3D)),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF0B1B3D)),
            onPressed: _showCreateGroupDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFD4AF37),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFD4AF37),
          tabs: const [
            Tab(text: 'Mes groupes'),
            Tab(text: 'Suggestions'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGroupsList(_myGroups, isMyGroups: true),
                _buildGroupsList(_suggestedGroups, isMyGroups: false),
              ],
            ),
    );
  }

  Widget _buildGroupsList(List<NetworkCommunity> groups, {required bool isMyGroups}) {
    if (groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isMyGroups ? Icons.groups : Icons.explore, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(isMyGroups ? 'Aucun groupe rejoint' : 'Aucune suggestion'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        return _buildGroupCard(groups[index], isMyGroups: isMyGroups);
      },
    );
  }

  Widget _buildGroupCard(NetworkCommunity group, {required bool isMyGroups}) {
    final hasBanner = group.bannerUrl != null && group.bannerUrl!.isNotEmpty;
    final isMember = isMyGroups;

    return GestureDetector(
      onTap: () => context.go('/network/community/${group.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                image: hasBanner
                    ? DecorationImage(image: NetworkImage(group.bannerUrl!), fit: BoxFit.cover)
                    : null,
              ),
              child: !hasBanner
                  ? const Icon(Icons.groups, size: 30, color: Color(0xFFD4AF37))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('${group.membersCount} membres', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () => _toggleJoin(group, isMember),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: isMember ? Colors.red : const Color(0xFFD4AF37)),
              ),
              child: Text(
                isMember ? 'Quitter' : 'Rejoindre',
                style: TextStyle(color: isMember ? Colors.red : const Color(0xFFD4AF37)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
