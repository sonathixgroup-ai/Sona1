import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/escalation_provider.dart';
import '../models/escalation_level.dart';
import '../models/escalation_step.dart';
import '../widgets/level_badge.dart';
import '../widgets/priority_chip.dart';

class EscalationDashboardPage extends StatelessWidget {
  final String agentId;
  final EscalationLevel agentLevel;

  const EscalationDashboardPage({
    Key? key,
    required this.agentId,
    required this.agentLevel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EscalationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Escalades'),
        backgroundColor: Colors.blue.shade800,
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.loadPendingEscalations(agentId, agentLevel),
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Card(
                    margin: const EdgeInsets.all(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statItem(
                            'En attente',
                            provider.pendingEscalations.length.toString(),
                            Colors.orange,
                          ),
                          _statItem(
                            'Acceptées',
                            provider.history.where((e) => e.status.index == 1).length.toString(),
                            Colors.green,
                          ),
                          _statItem(
                            'Résolues',
                            provider.history.where((e) => e.status.index == 4).length.toString(),
                            Colors.blue,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: provider.pendingEscalations.isEmpty
                        ? const Center(child: Text('Aucune escalade en attente'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: provider.pendingEscalations.length,
                            itemBuilder: (context, index) {
                              final step = provider.pendingEscalations[index];
                              return _buildPendingCard(step, context);
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildPendingCard(EscalationStep step, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: step.priority.color,
          child: Text(step.priority.label[0]),
        ),
        title: Text('De: ${step.fromAgentName ?? step.fromAgentId}'),
        subtitle: Text(step.reason),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward, color: Colors.blue),
          onPressed: () {
            context.push('/chat/escalation/handle/${step.id}');
          },
        ),
        isThreeLine: true,
      ),
    );
  }
}
