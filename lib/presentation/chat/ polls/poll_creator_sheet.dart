// lib/presentation/chat/polls/poll_creator_sheet.dart
// Feuille modale pour créer un sondage (question + options)

import 'package:flutter/material.dart';
import '../core/chat_models.dart';

class PollCreatorSheet extends StatefulWidget {
  final Function(PollData) onPollCreated;

  const PollCreatorSheet({Key? key, required this.onPollCreated}) : super(key: key);

  @override
  State<PollCreatorSheet> createState() => _PollCreatorSheetState();
}

class _PollCreatorSheetState extends State<PollCreatorSheet> {
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [TextEditingController(), TextEditingController()];
  bool _isMultipleChoice = false;
  bool _isAnonymous = false;
  int? _durationHours;

  @override
  void dispose() {
    _questionController.dispose();
    for (var c in _optionControllers) c.dispose();
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Créer un sondage', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _questionController,
            decoration: const InputDecoration(
              hintText: 'Question du sondage',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          const Text('Options', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          ..._optionControllers.asMap().entries.map((entry) {
            final index = entry.key;
            final controller = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: 'Option ${index + 1}',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  if (_optionControllers.length > 2)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => _removeOption(index),
                    ),
                ],
              ),
            );
          }),
          TextButton.icon(
            onPressed: _addOption,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une option'),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            title: const Text('Choix multiple'),
            value: _isMultipleChoice,
            onChanged: (val) => setState(() => _isMultipleChoice = val ?? false),
          ),
          CheckboxListTile(
            title: const Text('Votes anonymes'),
            value: _isAnonymous,
            onChanged: (val) => setState(() => _isAnonymous = val ?? false),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Durée : '),
              DropdownButton<int>(
                value: _durationHours,
                hint: const Text('Illimitée'),
                items: [1, 6, 12, 24, 48, 72].map((h) {
                  return DropdownMenuItem(value: h, child: Text('$h h'));
                }).toList(),
                onChanged: (val) => setState(() => _durationHours = val),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  final options = _optionControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
                  if (_questionController.text.trim().isNotEmpty && options.length >= 2) {
                    final poll = PollData(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      question: _questionController.text.trim(),
                      options: options,
                      isMultipleChoice: _isMultipleChoice,
                      isAnonymous: _isAnonymous,
                      expiresAt: _durationHours != null
                          ? DateTime.now().add(Duration(hours: _durationHours!))
                          : null,
                    );
                    widget.onPollCreated(poll);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Créer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Modèle simple pour le sondage (à étendre dans chat_models.dart si nécessaire)
class PollData {
  final String id;
  final String question;
  final List<String> options;
  final bool isMultipleChoice;
  final bool isAnonymous;
  final DateTime? expiresAt;
  PollData({
    required this.id,
    required this.question,
    required this.options,
    this.isMultipleChoice = false,
    this.isAnonymous = false,
    this.expiresAt,
  });
}
