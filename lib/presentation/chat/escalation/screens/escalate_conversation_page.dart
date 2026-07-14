// ============================================================
// lib/presentation/chat/escalation/screens/escalate_conversation_page.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/escalation_level.dart';
import '../models/escalation_priority.dart';
import '../providers/escalation_provider.dart';
import 'package:provider/provider.dart';
class EscalateConversationPage extends StatefulWidget {
  final String conversationId;
  final String fromAgentId;
  final String? fromAgentName;

  const EscalateConversationPage({
    Key? key,
    required this.conversationId,
    required this.fromAgentId,
    this.fromAgentName,
  }) : super(key: key);

  @override
  State<EscalateConversationPage> createState() => _EscalateConversationPageState();
}

class _EscalateConversationPageState extends State<EscalateConversationPage> {
  final _formKey = GlobalKey<FormState>();
  EscalationLevel? _selectedLevel;
  EscalationPriority _selectedPriority = EscalationPriority.medium;
  final _reasonController = TextEditingController();
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EscalationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Escalader la conversation'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info conversation
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.chat, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Conversation #${widget.conversationId.substring(0, 8)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Sélection du niveau cible
              const Text(
                'Niveau cible',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: EscalationLevel.values
                    .where((level) => level != EscalationLevel.agent) // On ne peut pas escalader vers agent
                    .map((level) => ChoiceChip(
                          label: Text(level.shortLabel),
                          selected: _selectedLevel == level,
                          onSelected: (selected) {
                            setState(() {
                              _selectedLevel = selected ? level : null;
                            });
                          },
                          selectedColor: level.color,
                          backgroundColor: level.color.withOpacity(0.1),
                        ))
                    .toList(),
              ),
              if (_selectedLevel != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Description: ${_selectedLevel!.label}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
              const SizedBox(height: 16),

              // Priorité
              const Text(
                'Priorité',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: EscalationPriority.values.map((priority) {
                  return ChoiceChip(
                    label: Text(priority.label),
                    selected: _selectedPriority == priority,
                    onSelected: (selected) {
                      setState(() {
                        _selectedPriority = selected ? priority : EscalationPriority.medium;
                      });
                    },
                    selectedColor: priority.color,
                    backgroundColor: priority.color.withOpacity(0.1),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Raison
              const Text(
                'Raison de l\'escalade *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  hintText: 'Expliquez pourquoi vous escaladez',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une raison';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Commentaire optionnel
              const Text(
                'Commentaire (optionnel)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: 'Ajoutez un commentaire pour l\'agent cible',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Boutons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: provider.isLoading ? null : _submit,
                      icon: provider.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send),
                      label: const Text('Escalader'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Annuler'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),

              if (provider.error != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Erreur: ${provider.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un niveau cible')),
      );
      return;
    }

    final provider = context.read<EscalationProvider>();
    final success = await provider.createEscalation(
      conversationId: widget.conversationId,
      fromAgentId: widget.fromAgentId,
      toLevel: _selectedLevel!,
      reason: _reasonController.text,
      priority: _selectedPriority,
      comment: _commentController.text.isNotEmpty ? _commentController.text : null,
      fromAgentName: widget.fromAgentName,
    );

    if (success != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escalade envoyée avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop(true);
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
