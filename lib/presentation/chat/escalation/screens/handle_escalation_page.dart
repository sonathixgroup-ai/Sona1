// ============================================================
// lib/presentation/chat/escalation/screens/handle_escalation_page.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart'; // LA LIGNE MAGIQUE QUI MANQUAIT !
import '../models/escalation_level.dart';
import '../models/escalation_step.dart';
import '../models/escalation_status.dart';
import '../providers/escalation_provider.dart';
import '../widgets/level_badge.dart';
import '../widgets/priority_chip.dart';
import '../widgets/status_indicator.dart';


class HandleEscalationPage extends StatefulWidget {
  final String escalationId;
  final String agentId;

  const HandleEscalationPage({
    Key? key,
    required this.escalationId,
    required this.agentId,
  }) : super(key: key);

  @override
  State<HandleEscalationPage> createState() => _HandleEscalationPageState();
}

class _HandleEscalationPageState extends State<HandleEscalationPage> {
  final _rejectReasonController = TextEditingController();
  bool _showRejectReason = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Charger les détails de l'escalade via le provider
    // On suppose que le provider a une méthode pour obtenir une escalade par ID
    // Pour l'exemple, on recharge la liste
    final provider = context.read<EscalationProvider>();
    await provider.loadPendingEscalations(widget.agentId, EscalationLevel.senior);
  }

  @override
  void dispose() {
    _rejectReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EscalationProvider>();
    final escalation = provider.pendingEscalations.firstWhere(
      (e) => e.id == widget.escalationId,
      orElse: () => throw Exception('Escalade non trouvée'),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gérer l\'escalade'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec niveau et priorité
            Row(
              children: [
                LevelBadge(level: escalation.toLevel),
                const SizedBox(width: 12),
                PriorityChip(priority: escalation.priority),
                const Spacer(),
                StatusIndicator(status: escalation.status),
              ],
            ),
            const Divider(height: 24),

            // Informations
            _infoRow('De', escalation.fromAgentName ?? escalation.fromAgentId),
            _infoRow('À', escalation.toAgentName ?? escalation.toAgentId),
            _infoRow('Raison', escalation.reason),
            if (escalation.comment != null) _infoRow('Commentaire', escalation.comment!),
            _infoRow('Date', escalation.createdAt.toString().substring(0, 16)),

            const Divider(height: 24),

            // Actions
            if (escalation.status == EscalationStatus.pending) ...[
              const Text(
                'Actions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: provider.isLoading ? null : _accept,
                      icon: provider.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check),
                      label: const Text('Accepter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: provider.isLoading ? null : () {
                        setState(() {
                          _showRejectReason = !_showRejectReason;
                        });
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Refuser'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
              if (_showRejectReason) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _rejectReasonController,
                  decoration: const InputDecoration(
                    hintText: 'Motif du refus',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: provider.isLoading ? null : _reject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Confirmer le refus'),
                ),
              ],
            ],

            if (escalation.status == EscalationStatus.accepted) ...[
              const Text(
                '✅ Escalade acceptée. Vous pouvez maintenant traiter la conversation.',
                style: TextStyle(color: Colors.green),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: provider.isLoading ? null : _resolve,
                icon: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.done_all),
                label: const Text('Marquer comme résolu'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],

            if (escalation.status == EscalationStatus.resolved) ...[
              const Text(
                '✅ Cette escalade est résolue.',
                style: TextStyle(color: Colors.green),
              ),
            ],

            if (escalation.status == EscalationStatus.rejected) ...[
              const Text(
                '❌ Cette escalade a été refusée.',
                style: TextStyle(color: Colors.red),
              ),
            ],

            const SizedBox(height: 24),
            if (provider.error != null)
              Text(
                'Erreur: ${provider.error}',
                style: const TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _accept() async {
    final provider = context.read<EscalationProvider>();
    final success = await provider.acceptEscalation(widget.escalationId, widget.agentId);
    if (success != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escalade acceptée'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${provider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _reject() async {
    if (_rejectReasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez indiquer un motif de refus')),
      );
      return;
    }
    final provider = context.read<EscalationProvider>();
    final success = await provider.rejectEscalation(
      widget.escalationId,
      _rejectReasonController.text,
    );
    if (success != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escalade refusée'),
          backgroundColor: Colors.orange,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${provider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resolve() async {
    final provider = context.read<EscalationProvider>();
    final success = await provider.resolveEscalation(widget.escalationId);
    if (success != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escalade résolue'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${provider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
