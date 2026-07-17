import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/chat/connection_service.dart';

class ConnectionsPage extends StatefulWidget {
  const ConnectionsPage({super.key});

  @override
  State<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<ConnectionsPage> {
  // Couleurs harmonisées THIX ID
  static const Color primaryBlue = Color(0xFF4A8BFF);
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color ivory = Color(0xFFF3F5FA);
  static const Color success = Color(0xFF1FA971);
  static const Color danger = Color(0xFFD64545);
  static const Color mutedText = Color(0xFF6B7690);
  static const Color darkText = Color(0xFF10182B);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final service = context.read<ConnectionService>();
    await service.loadData(user.id);
  }

  // ============================================================
  // GESTION DES DEMANDES
  // ============================================================

  Future<void> _acceptRequest(String requestId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final service = context.read<ConnectionService>();
    final isSuccess = await service.acceptRequest(requestId, user.id);
    if (isSuccess && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        // CORRECTION : Plus de 'const' devant SnackBar
        const SnackBar(content: Text('Connexion acceptée ✅'), backgroundColor: success),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${service.error}'), backgroundColor: danger),
      );
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final service = context.read<ConnectionService>();
    final isSuccess = await service.rejectRequest(requestId, user.id);
    if (isSuccess && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        // CORRECTION : Plus de 'const' devant SnackBar
        const SnackBar(content: Text('Demande refusée'), backgroundColor: Colors.orange),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${service.error}'), backgroundColor: danger),
      );
    }
  }

  // Confirmation avant annulation
  Future<void> _confirmCancelRequest(String requestId) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Annuler la demande ?', style: TextStyle(color: navyDeep, fontWeight: FontWeight.bold)),
        content: const Text('Êtes-vous sûr de vouloir annuler cette invitation ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Non', style: TextStyle(color: mutedText))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Oui, annuler', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _cancelRequest(requestId);
    }
  }

  Future<void> _cancelRequest(String requestId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final service = context.read<ConnectionService>();
    final isSuccess = await service.cancelRequest(requestId, user.id);
    if (isSuccess && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        // CORRECTION : Plus de 'const' devant SnackBar
        const SnackBar(content: Text('Demande annulée'), backgroundColor: danger)
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${service.error}'), backgroundColor: danger),
      );
    }
  }

  // ============================================================
  // INTERFACE UTILISATEUR
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ConnectionService>();

    return Scaffold(
      backgroundColor: ivory,
      appBar: AppBar(
        title: const Text('Connexions', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: navyDeep,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white), 
            onPressed: _loadData
          ),
        ],
      ),
      body: service.isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (service.receivedRequests.isNotEmpty) ...[
                  _buildSectionTitle('Demandes reçues'),
                  ...service.receivedRequests.map((req) => _buildRequestCard(
                    name: req.sender?['display_name'] ?? 'Inconnu',
                    subtitle: req.message ?? 'Souhaite vous contacter',
                    onAccept: () => _acceptRequest(req.id),
                    onReject: () => _rejectRequest(req.id),
                  )),
                ],
                
                if (service.sentRequests.isNotEmpty) ...[
                  _buildSectionTitle('Demandes envoyées'),
                  ...service.sentRequests.map((req) => _buildRequestCard(
                    name: req.receiver?['display_name'] ?? 'Inconnu',
                    subtitle: 'En attente...',
                    onCancel: () => _confirmCancelRequest(req.id),
                  )),
                ],

                _buildSectionTitle('Vos connexions'),
                if (service.connections.isEmpty)
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text('Aucune connexion pour le moment', style: TextStyle(color: mutedText)),
                      ),
                    ),
                  )
                else
                  ...service.connections.map((conn) => Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: primaryBlue.withOpacity(0.1), 
                        child: Text((conn['display_name'] ?? '?')[0].toUpperCase(), style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.bold))
                      ),
                      title: Text(conn['display_name'] ?? 'Inconnu', style: const TextStyle(fontWeight: FontWeight.bold, color: darkText)),
                      subtitle: Text('@${conn['username'] ?? ''}', style: const TextStyle(color: mutedText)),
                      onTap: () {
                        // Ouvrir la conversation
                      },
                    ),
                  )),
              ],
            ),
    );
  }

  // ============================================================
  // WIDGETS REUTILISABLES
  // ============================================================

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title, 
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: navyDeep)
      ),
    );
  }

  Widget _buildRequestCard({
    required String name, 
    required String subtitle, 
    VoidCallback? onAccept, 
    VoidCallback? onReject, 
    VoidCallback? onCancel
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: primaryBlue.withOpacity(0.1),
          child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: darkText)),
        subtitle: Text(subtitle, style: const TextStyle(color: mutedText)),
        trailing: onCancel != null 
          ? IconButton(icon: const Icon(Icons.close, color: danger), onPressed: onCancel)
          : Row(
              mainAxisSize: MainAxisSize.min, 
              children: [
                IconButton(icon: const Icon(Icons.check, color: success), onPressed: onAccept),
                IconButton(icon: const Icon(Icons.close, color: danger), onPressed: onReject),
              ]
            ),
      ),
    );
  }
}
