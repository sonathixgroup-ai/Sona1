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

  Future<void> _acceptRequest(String requestId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final service = context.read<ConnectionService>();
    final success = await service.acceptRequest(requestId, user.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connexion acceptée '), backgroundColor: Colors.green),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${service.error}'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final service = context.read<ConnectionService>();
    final success = await service.rejectRequest(requestId, user.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande refusée'), backgroundColor: Colors.orange),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${service.error}'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _cancelRequest(String requestId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final service = context.read<ConnectionService>();
    final success = await service.cancelRequest(requestId, user.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande annulée'), backgroundColor: Colors.orange),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${service.error}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ConnectionService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        title: const Text('Connexions', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF3B82F6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: service.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ============================================================
                // SECTION 1 : DEMANDES REÇUES
                // ============================================================
                if (service.receivedRequests.isNotEmpty) ...[
                  const Text(
                    'Demandes reçues',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),
                  ...service.receivedRequests.map((req) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFE9F0FF),
                            child: Text(
                              (req.sender?['display_name'] ?? '?')[0].toUpperCase(),
                              style: const TextStyle(color: Color(0xFF3B82F6)),
                            ),
                          ),
                          title: Text(req.sender?['display_name'] ?? 'Inconnu'),
                          subtitle: Text(req.message ?? 'Souhaite vous contacter'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                onPressed: () => _acceptRequest(req.id),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () => _rejectRequest(req.id),
                              ),
                            ],
                          ),
                        ),
                      )),
                  const SizedBox(height: 16),
                ],

                // ============================================================
                // SECTION 2 : DEMANDES ENVOYÉES
                // ============================================================
                if (service.sentRequests.isNotEmpty) ...[
                  const Text(
                    'Demandes envoyées',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),
                  ...service.sentRequests.map((req) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFE9F0FF),
                            child: Text(
                              (req.receiver?['display_name'] ?? '?')[0].toUpperCase(),
                              style: const TextStyle(color: Color(0xFF3B82F6)),
                            ),
                          ),
                          title: Text(req.receiver?['display_name'] ?? 'Inconnu'),
                          subtitle: const Text('En attente de réponse'),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => _cancelRequest(req.id),
                            tooltip: 'Annuler',
                          ),
                        ),
                      )),
                  const SizedBox(height: 16),
                ],

                // ============================================================
                // SECTION 3 : CONNEXIONS ACTIVES
                // ============================================================
                const Text(
                  'Vos connexions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                if (service.connections.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text('Aucune connexion pour le moment', style: TextStyle(color: Color(0xFF94A3B8))),
                      ),
                    ),
                  )
                else
                  ...service.connections.map((conn) => Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFE9F0FF),
                            child: Text((conn['display_name'] ?? '?')[0].toUpperCase()),
                          ),
                          title: Text(conn['display_name'] ?? 'Inconnu'),
                          subtitle: Text('@${conn['username'] ?? ''}'),
                          onTap: () {
                            // Ouvrir la conversation
                          },
                        ),
                      )),
                const SizedBox(height: 20),
              ],
            ),
    );
  }
}
