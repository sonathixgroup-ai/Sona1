// lib/presentation/chat/chat_status_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thix_id/providers/chat_provider.dart';
import 'package:thix_id/presentation/chat/core/chat_models.dart'; // ← CORRIGÉ
import 'chat_status_update.dart';

class ChatStatusPage extends StatefulWidget {
  const ChatStatusPage({super.key});

  @override
  State<ChatStatusPage> createState() => _ChatStatusPageState();
}

class _ChatStatusPageState extends State<ChatStatusPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadContactsStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final contacts = chatProvider.contactsStatus;
    final isLoading = chatProvider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statut'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatStatusUpdatePage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildMyStatus(),
          const Divider(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : contacts.isEmpty
                    ? const Center(child: Text('Aucun contact en ligne'))
                    : ListView.builder(
                        itemCount: contacts.length,
                        itemBuilder: (context, index) {
                          final contact = contacts[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: contact.avatarUrl != null // ← CORRIGÉ
                                  ? NetworkImage(contact.avatarUrl!) // ← CORRIGÉ
                                  : null,
                              child: contact.avatarUrl == null // ← CORRIGÉ
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(contact.displayName),
                            subtitle: Text(
                              _getStatusLabel(contact.status),
                              style: TextStyle(
                                color: _getStatusColor(contact.status),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _getStatusColor(contact.status),
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyStatus() {
    return FutureBuilder(
      future: _getMyStatus(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final status = snapshot.data as Map<String, dynamic>;
        final statusLabel = status['label'] ?? 'En ligne';
        final statusColor = status['color'] ?? Colors.green;
        final customMessage = status['custom'] ?? '';

        return Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[50],
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mon statut : $statusLabel',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (customMessage.isNotEmpty)
                      Text(
                        customMessage,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChatStatusUpdatePage()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getMyStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final status = prefs.getString('user_status') ?? 'online';
    final custom = prefs.getString('custom_status') ?? '';
    return {
      'label': _getStatusLabel(status),
      'color': _getStatusColor(status),
      'custom': custom,
    };
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'online':
        return 'En ligne';
      case 'away':
        return 'Absent';
      case 'busy':
        return 'Occupé';
      case 'offline':
        return 'Hors ligne';
      default:
        return 'En ligne';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'online':
        return Colors.green;
      case 'away':
        return Colors.orange;
      case 'busy':
        return Colors.red;
      case 'offline':
        return Colors.grey;
      default:
        return Colors.green;
    }
  }
}
