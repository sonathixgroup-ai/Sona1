// lib/presentation/chat/group_admin/waiting_room.dart
// Salle d'attente pour les demandes d'adhésion (groupes privés ou à approbation)

import 'package:flutter/material.dart';

class WaitingRoom extends StatefulWidget {
  final List<JoinRequest> pendingRequests;
  final Function(String requestId, bool approve) onProcessRequest;

  const WaitingRoom({
    Key? key,
    required this.pendingRequests,
    required this.onProcessRequest,
  }) : super(key: key);

  @override
  State<WaitingRoom> createState() => _WaitingRoomState();
}

class _WaitingRoomState extends State<WaitingRoom> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Salle d\'attente')),
      body: widget.pendingRequests.isEmpty
          ? const Center(child: Text('Aucune demande en attente'))
          : ListView.builder(
              itemCount: widget.pendingRequests.length,
              itemBuilder: (context, index) {
                final req = widget.pendingRequests[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(req.userDisplayName[0])),
                    title: Text(req.userDisplayName),
                    subtitle: Text('Demande le ${_formatDate(req.requestedAt)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => widget.onProcessRequest(req.id, true),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => widget.onProcessRequest(req.id, false),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class JoinRequest {
  final String id;
  final String userId;
  final String userDisplayName;
  final DateTime requestedAt;
  JoinRequest({required this.id, required this.userId, required this.userDisplayName, required this.requestedAt});
}
