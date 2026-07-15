// lib/presentation/chat/escalation/screens/escalation_history_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/escalation_provider.dart';
import '../models/escalation_step.dart';
import '../widgets/level_badge.dart';
import '../widgets/priority_chip.dart';
import '../widgets/status_indicator.dart';
import '../../chat/chat_screen.dart'; // ✅ chemin correct vers ChatScreen
import '../../../../services/chat/chat_service.dart'; // ✅ chemin correct vers ChatService

class EscalationHistoryPage extends StatelessWidget {
  final String conversationId;

  const EscalationHistoryPage({Key? key, required this.conversationId}) : super(key: key);

  Future<void> _openConversation(BuildContext context, String convId) async {
    try {
      final chatService = ChatService(Supabase.instance.client);
      final conv = await chatService.getConversation(convId);
      if (conv != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: convId,
              conversation: conv,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EscalationProvider>(context, listen: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des escalades'),
        backgroundColor: Colors.purple,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.history.isEmpty
              ? const Center(child: Text('Aucune escalade pour cette conversation'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: provider.history.length,
                  itemBuilder: (context, index) {
                    final step = provider.history[index];
                    return InkWell(
                      onTap: () => _openConversation(context, step.conversationId),
                      borderRadius: BorderRadius.circular(12),
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  LevelBadge(level: step.fromLevel),
                                  const Icon(Icons.arrow_forward, size: 16),
                                  LevelBadge(level: step.toLevel),
                                  const Spacer(),
                                  PriorityChip(priority: step.priority),
                                ],
                              ),
                              const Divider(),
                              Text(
                                step.reason,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              if (step.comment != null)
                                Text(
                                  'Commentaire: ${step.comment}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  StatusIndicator(status: step.status),
                                  const Spacer(),
                                  Text(
                                    step.createdAt.toString().substring(0, 16),
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              if (step.resolvedAt != null)
                                Text(
                                  'Résolu le: ${step.resolvedAt!.toString().substring(0, 16)}',
                                  style: const TextStyle(fontSize: 12, color: Colors.green),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
