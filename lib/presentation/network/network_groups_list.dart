import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:thix_id/models/network_community.dart';
import 'package:thix_id/services/network_service.dart';

class NetworkGroupsList extends StatefulWidget {
  const NetworkGroupsList({super.key});

  @override
  State<NetworkGroupsList> createState() => _NetworkGroupsListState();
}

class _NetworkGroupsListState extends State<NetworkGroupsList> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late NetworkService _networkService;

  List<NetworkCommunity> _myGroups = [];
  List<NetworkCommunity> _suggestedGroups = [];
  bool _loading = true;

  // Couleurs de la charte THIX PRO
  final Color _thixPrimaryBlue = const Color(0xFF2B5CFF);
  final Color _thixDarkText = const Color(0xFF1A1A2E);
  final Color _thixGold = const Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _networkService = Provider.of<NetworkService>(context, listen: false);
    _loadGroups();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // OPTIMISATION #1 : Chargement parallèle via le Service Réseau
  Future<void> _loadGroups() async {
    setState(() => _loading = true);

    try {
      final results = await Future.wait([
        _networkService.getMyCommunities(),
        _networkService.getSuggestedCommunities(limit: 20),
      ]);

      if (!mounted) return;

      final myGroups = results[0];
      final suggestedGroups = results[1];
      
      // Filtrer les suggestions pour retirer les groupes déjà rejoints
      final myGroupIds = myGroups.map((g) => g.id).toSet();
      final filteredSuggestions = suggestedGroups.where((g) => !myGroupIds.contains(g.id)).toList();

      setState(() {
        _myGroups = myGroups;
        _suggestedGroups = filteredSuggestions;
      });
    } catch (e) {
      debugPrint('Error loading groups: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // OPTIMISATION #2 : Optimistic UI (Mise à jour instantanée sans rechargement complet)
  Future<void> _toggleJoin(NetworkCommunity group, bool isCurrentMember) async {
    // 1. Mise à jour immédiate de l'interface (Optimistic UI)
    setState(() {
      if (isCurrentMember) {
        _myGroups.removeWhere((g) => g.id == group.id);
        _suggestedGroups.insert(0, group); // Le remet dans les suggestions
      } else {
        _suggestedGroups.removeWhere((g) => g.id == group.id);
        _myGroups.insert(0, group); // L'ajoute à mes groupes
      }
    });

    try {
      // 2. Appel réseau en arrière-plan via le service
      if (isCurrentMember) {
        await _networkService.leaveCommunity(group.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Groupe quitté'), backgroundColor: Colors.orange),
          );
        }
      } else {
        await _networkService.joinCommunity(group.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Groupe rejoint !'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      // 3. Rollback en cas d'erreur réseau
      if (mounted) {
        setState(() {
          if (isCurrentMember) {
            _suggestedGroups.removeWhere((g) => g.id == group.id);
            _myGroups.insert(0, group);
          } else {
            _myGroups.removeWhere((g) => g.id == group.id);
            _suggestedGroups.insert(0, group);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // OPTIMISATION #3 : Création déléguée au service
  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    bool isCreating = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Créer un groupe', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Nom du groupe',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Description (optionnelle)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
              ],
            ),
            actions: [
              if (!isCreating)
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
                ),
              ElevatedButton(
                onPressed: isCreating ? null : () async {
                  if (nameController.text.trim().isEmpty) return;
                  
                  setStateDialog(() => isCreating = true);
                  
                  try {
                    final newCommunity = await _networkService.createCommunity(
                      name: nameController.text.trim(),
                      description: descController.text.trim(),
                    );
                    
                    if (mounted) {
                      Navigator.pop(dialogContext);
                      // Optimistic ajout
                      setState(() {
                        _myGroups.insert(0, newCommunity);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Groupe créé !'), backgroundColor: Colors.green),
                      );
                    }
                  } catch (e) {
                    setStateDialog(() => isCreating = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _thixGold,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: isCreating 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Créer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Groupes', style: TextStyle(color: _thixDarkText, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _thixDarkText),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: _thixDarkText),
            onPressed: _showCreateGroupDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: _thixPrimaryBlue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _thixPrimaryBlue,
          tabs: const [
            Tab(text: 'Mes groupes'),
            Tab(text: 'Suggestions'),
          ],
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: _thixPrimaryBlue))
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
            Icon(isMyGroups ? Icons.groups : Icons.explore, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              isMyGroups ? 'Aucun groupe rejoint' : 'Aucune suggestion',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
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

  // OPTIMISATION #4 : Utilisation de CachedNetworkImage pour protéger la RAM
  Widget _buildGroupCard(NetworkCommunity group, {required bool isMyGroups}) {
    final hasBanner = group.bannerUrl != null && group.bannerUrl!.isNotEmpty;
    final isMember = isMyGroups;

    return GestureDetector(
      onTap: () => context.push('/network/community/${group.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _thixPrimaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                image: hasBanner
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(group.bannerUrl!), 
                        fit: BoxFit.cover
                      )
                    : null,
              ),
              child: !hasBanner
                  ? Icon(Icons.groups, size: 30, color: _thixPrimaryBlue)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _thixDarkText)),
                  const SizedBox(height: 4),
                  Text('${group.membersCount} membres', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () => _toggleJoin(group, isMember),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: isMember ? Colors.red.shade300 : _thixPrimaryBlue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                isMember ? 'Quitter' : 'Rejoindre',
                style: TextStyle(
                  color: isMember ? Colors.red : _thixPrimaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 12
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
