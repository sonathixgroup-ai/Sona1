import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/chat/connection_service.dart';

class ConnectionRequestsPage extends StatefulWidget {
  const ConnectionRequestsPage({super.key});

  @override
  State<ConnectionRequestsPage> createState() => _ConnectionRequestsPageState();
}

class _ConnectionRequestsPageState extends State<ConnectionRequestsPage> {
  // Couleurs harmonisées
  static const Color primaryBlue = Color(0xFF4A8BFF);
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color ivory = Color(0xFFF3F5FA);
  static const Color success = Color(0xFF1FA971);
  static const Color danger = Color(0xFFD64545);
  static const Color mutedText = Color(0xFF6B7690);

  late ConnectionService _connectionService;
  List<ConnectionRequest> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _connectionService = ConnectionService();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    setState(() => _loading = true);
    try {
      final requests = await _connectionService.getPendingRequests(userId);
      setState(() {
        _requests = requests;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  // Confirmation pour refuser (Insister pour le deuxième avis)
  Future<void> _confirmRejectRequest(String requestId) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Refuser la demande ?', style: TextStyle(color: navyDeep, fontWeight: FontWeight.bold)),
        content: const Text('Êtes-vous sûr de vouloir refuser cette invitation ? Prenez un moment pour réfléchir.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Oui, refuser', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _rejectRequest(requestId);
    }
  }

  Future<void> _acceptRequest(String requestId) async {
    try {
      await _connectionService.acceptRequest(requestId);
      _loadRequests();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connexion acceptée '), backgroundColor: success),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: danger),
      );
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    try {
      await _connectionService.rejectRequest(requestId);
      _loadRequests();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande refusée'), backgroundColor: Colors.orange),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ivory,
      appBar: AppBar(
        title: const Text('Demandes reçues', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: navyDeep,
        elevation: 0,
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : _requests.isEmpty
              ? const Center(child: Text('Aucune demande en attente', style: TextStyle(color: mutedText)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    final request = _requests[index];
                    final sender = request.sender;
                    final name = sender?['display_name'] ?? sender?['username'] ?? 'Inconnu';
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: CircleAvatar(
                          backgroundColor: primaryBlue.withOpacity(0.1),
                          child: Text(name[0].toUpperCase(), style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(request.message ?? 'Souhaite vous contacter', style: const TextStyle(color: mutedText)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: success),
                              onPressed: () => _acceptRequest(request.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: danger),
                              onPressed: () => _confirmRejectRequest(request.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
