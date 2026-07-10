import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/services/network_service.dart';
import 'package:thix_id/presentation/network/widgets/connection_card.dart';

class ConnectionsListPage extends StatefulWidget {
  const ConnectionsListPage({super.key});

  @override
  State<ConnectionsListPage> createState() => _ConnectionsListPageState();
}

class _ConnectionsListPageState extends State<ConnectionsListPage> {
  late NetworkService _networkService;
  List<Map<String, dynamic>> _connections = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _networkService = NetworkService(Supabase.instance.client);
    _loadConnections();
  }

  Future<void> _loadConnections() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = _networkService.currentUserId;
      if (userId.isEmpty) {
        setState(() {
          _error = 'Utilisateur non connecté';
          _isLoading = false;
        });
        return;
      }

      final response = await Supabase.instance.client
          .from('connections')
          .select('''
            id,
            connection_id,
            created_at,
            users:connection_id!inner (
              id,
              display_name,
              photo_url,
              profession,
              bio
            )
          ''')
          .eq('user_id', userId)
          .eq('status', 'accepted')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> connections = [];
      for (var conn in response as List) {
        final userData = conn['users'] as Map<String, dynamic>?;
        if (userData != null) {
          connections.add({
            'id': conn['id'],
            'user_id': userData['id'],
            'display_name': userData['display_name'] ?? 'Utilisateur',
            'photo_url': userData['photo_url'],
            'profession': userData['profession'] ?? 'Membre THIX',
            'bio': userData['bio'],
            'connected_at': conn['created_at'],
          });
        }
      }

      setState(() {
        _connections = connections;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur chargement connexions: $e');
      setState(() {
        _error = 'Impossible de charger vos connexions';
        _isLoading = false;
      });
    }
  }

  Future<void> _removeConnection(String connectionId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la connexion'),
        content: Text('Voulez-vous vraiment retirer $userName de vos connexions ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await Supabase.instance.client
          .from('connections')
          .delete()
          .eq('id', connectionId);

      setState(() {
        _connections.removeWhere((c) => c['id'] == connectionId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$userName a été retiré de vos connexions'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(
          children: [
            const Text(
              'Mes connexions',
              style: TextStyle(
                color: Color(0xFF1A1A2E),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_connections.length}',
                style: const TextStyle(
                  color: Color(0xFFD4AF37),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A1A2E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF1A1A2E), size: 22),
            onPressed: () {
              // TODO: Rechercher dans les connexions
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
              ),
            )
          : _error != null
              ? _buildErrorWidget()
              : _connections.isEmpty
                  ? _buildEmptyWidget()
                  : RefreshIndicator(
                      onRefresh: _loadConnections,
                      color: const Color(0xFFD4AF37),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _connections.length,
                        itemBuilder: (context, index) {
                          final conn = _connections[index];
                          return ConnectionCard(
                            userId: conn['user_id'],
                            displayName: conn['display_name'],
                            photoUrl: conn['photo_url'],
                            profession: conn['profession'],
                            bio: conn['bio'],
                            connectedAt: conn['connected_at'],
                            onTap: () {
                              context.push('/network/profile/${conn['user_id']}');
                            },
                            onMessageTap: () {
                              context.push('/network/chat/${conn['user_id']}');
                            },
                            onRemoveTap: () => _removeConnection(conn['id'], conn['display_name']),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadConnections,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline,
              size: 64,
              color: const Color(0xFFD4AF37).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucune connexion',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez à vous connecter avec\ndes professionnels de votre secteur.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.push('/network/discover');
            },
            icon: const Icon(Icons.explore),
            label: const Text('Découvrir des personnes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
