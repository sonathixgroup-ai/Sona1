// ============================================================
// lib/presentation/chat/escalation/widgets/agent_selector.dart
// ============================================================

import 'package:flutter/material.dart';
import '../models/escalation_level.dart';

class AgentSelector extends StatefulWidget {
  final EscalationLevel level;
  final Function(String?) onSelected;

  const AgentSelector({
    Key? key,
    required this.level,
    required this.onSelected,
  }) : super(key: key);

  @override
  State<AgentSelector> createState() => _AgentSelectorState();
}

class _AgentSelectorState extends State<AgentSelector> {
  String? _selectedAgentId;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: _selectedAgentId,
      decoration: const InputDecoration(
        labelText: 'Choisir un agent',
        border: OutlineInputBorder(),
      ),
      items: [
        // Dans une vraie implémentation, on chargerait la liste des agents du niveau concerné
        const DropdownMenuItem(value: 'agent1', child: Text('Agent Senior 1')),
        const DropdownMenuItem(value: 'agent2', child: Text('Agent Senior 2')),
        const DropdownMenuItem(value: 'agent3', child: Text('Agent Senior 3')),
      ],
      onChanged: (value) {
        setState(() {
          _selectedAgentId = value;
        });
        widget.onSelected(value);
      },
      validator: (value) {
        if (value == null) return 'Veuillez sélectionner un agent';
        return null;
      },
    );
  }
}
