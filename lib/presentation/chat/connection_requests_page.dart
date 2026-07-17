// lib/presentation/chat/connection_requests_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/chat/connection_service.dart';

class ConnectionRequestsPage extends StatefulWidget {
  const ConnectionRequestsPage({super.key});

  @override
  State<ConnectionRequestsPage> createState() => _ConnectionRequestsPageState();
}

class _ConnectionRequestsPageState extends State<ConnectionRequestsPage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demandes de connexion'),
        backgroundColor: Colors.blue,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(child: Text('Aucune demande en attente'))
              : ListView.builder(
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    final request = _requests[index];
                    final sender = request.sender;
                    final name = sender?['display_name'] ?? sender?['username'] ?? 'Inconnu';
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Text(name[0].toUpperCase()),
                        ),
                        title: Text(name),
                        subtitle: Text(request.message ?? 'Souhaite vous contacter'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () => _acceptRequest(request.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => _rejectRequest(request.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _acceptRequest(String requestId) async {
    try {
      await _connectionService.acceptRequest(requestId);
      _loadRequests();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connexion acceptée ✅'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
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
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
      );
    }
  }
}
