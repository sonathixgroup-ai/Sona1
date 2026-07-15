// lib/presentation/chat/escalation/screens/received_escalations_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../models/escalation_step.dart';
import '../models/escalation_status.dart';
import '../providers/escalation_provider.dart';
import '../../chat_screen.dart';
import '../../../../services/chat/chat_service.dart';

class ReceivedEscalationsPage extends StatefulWidget {
  const ReceivedEscalationsPage({super.key});

  @override
  State<ReceivedEscalationsPage> createState() => _ReceivedEscalationsPageState();
}

class _ReceivedEscalationsPageState extends State<ReceivedEscalationsPage> {
  List<EscalationStep> _escalations = [];
  bool _loading = true;
  String? _error;
  late ChatService _chatService;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(Supabase.instance.client);
    _loadEscalations();
  }

  Future<void> _loadEscalations() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() { _loading = false; });
      return;
    }
    try {
      final response = await Supabase.instance.client
          .from('escalation_steps')
          .select('*, from_agent_name, to_agent_name, reason, status, created_at, conversation_id')
          .eq('to_agent_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _escalations = response.map((json) => EscalationStep.fromJson(json)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ✅ Gestion de l'ouverture : si conversation introuvable, message SnackBar
  Future<void> _openConversation(EscalationStep step) async {
    final conversationId = step.conversationId;
    try {
      final conv = await _chatService.getConversation(conversationId);
      if (conv != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: conversationId,
              conversation: conv,
            ),
          ),
        );
        return;
      }

      // Conversation introuvable
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conversation introuvable. Elle a peut-être été supprimée.'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _accept(String escalationId) async {
    final provider = context.read<EscalationProvider>();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final success = await provider.acceptEscalation(escalationId, user.id);
    if (success != null) {
      _loadEscalations();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escalade acceptée'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${provider.error}'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _reject(String escalationId) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Refuser l\'escalade'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: 'Motif du refus'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final provider = context.read<EscalationProvider>();
    final success = await provider.rejectEscalation(escalationId, reasonController.text);
    if (success != null) {
      _loadEscalations();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escalade refusée'), backgroundColor: Colors.orange),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${provider.error}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escalades reçues'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEscalations,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Erreur : $_error'))
              : _escalations.isEmpty
                  ? const Center(child: Text('Aucune escalade reçue'))
                  : ListView.builder(
                      itemCount: _escalations.length,
                      itemBuilder: (context, index) {
                        final step = _escalations[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _openConversation(step),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.person, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        step.fromAgentName ?? 'Inconnu',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const Spacer(),
                                      _buildStatusChip(step.status),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Raison : ${step.reason}'),
                                  if (step.comment != null) Text('Commentaire : ${step.comment}'),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Demandé le ${step.createdAt.toString().substring(0, 16)}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  if (step.status == EscalationStatus.pending) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () => _accept(step.id),
                                          icon: const Icon(Icons.check, size: 16),
                                          label: const Text('Accepter'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton.icon(
                                          onPressed: () => _reject(step.id),
                                          icon: const Icon(Icons.close, size: 16),
                                          label: const Text('Refuser'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _buildStatusChip(EscalationStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: status.color, fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }
}
