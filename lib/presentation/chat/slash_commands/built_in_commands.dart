// lib/presentation/chat/slash_commands/built_in_commands.dart
// Implémentation des commandes slash (poll, remind, todo, etc.)

import 'package:flutter/material.dart';

class BuiltInCommands {
  // Commande /poll : créer un sondage
  static Future<Map<String, dynamic>?> showPollCreator(BuildContext context) async {
    final questionController = TextEditingController();
    final optionControllers = [TextEditingController(), TextEditingController()];
    bool isMultipleChoice = false;
    bool isAnonymous = false;
    int? durationHours;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Créer un sondage (/poll)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: questionController,
                  decoration: const InputDecoration(hintText: 'Question'),
                ),
                const SizedBox(height: 8),
                ...optionControllers.asMap().entries.map((entry) {
                  return Row(
                    children: [
                      Expanded(child: TextField(controller: entry.value, decoration: InputDecoration(hintText: 'Option ${entry.key + 1}'))),
                      if (optionControllers.length > 2)
                        IconButton(icon: const Icon(Icons.remove), onPressed: () => setState(() => optionControllers.removeAt(entry.key))),
                    ],
                  );
                }),
                TextButton(onPressed: () => setState(() => optionControllers.add(TextEditingController())), child: const Text('+ Ajouter option')),
                CheckboxListTile(title: const Text('Choix multiple'), value: isMultipleChoice, onChanged: (v) => setState(() => isMultipleChoice = v ?? false)),
                CheckboxListTile(title: const Text('Votes anonymes'), value: isAnonymous, onChanged: (v) => setState(() => isAnonymous = v ?? false)),
                DropdownButtonFormField<int>(
                  value: durationHours,
                  hint: const Text('Durée (heures)'),
                  items: [1, 6, 12, 24, 48, 72].map((h) => DropdownMenuItem(value: h, child: Text('$h h'))).toList(),
                  onChanged: (v) => setState(() => durationHours = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () {
                final options = optionControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
                if (questionController.text.trim().isNotEmpty && options.length >= 2) {
                  Navigator.pop(context, {
                    'type': 'poll',
                    'question': questionController.text.trim(),
                    'options': options,
                    'multiple_choice': isMultipleChoice,
                    'anonymous': isAnonymous,
                    'duration_hours': durationHours,
                  });
                }
              },
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }

  // Commande /remind : programmer un rappel
  static Future<Map<String, dynamic>?> showReminderCreator(BuildContext context) async {
    DateTime? reminderTime;
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rappel (/remind)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(hintText: 'Message du rappel'),
              controller: TextEditingController(),
            ),
            const SizedBox(height: 8),
            ListTile(
              title: Text(reminderTime != null ? _formatDateTime(reminderTime!) : 'Choisir une date/heure'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                if (date != null) {
                  final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (time != null) {
                    reminderTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (reminderTime != null) {
                Navigator.pop(context, {'type': 'remind', 'scheduled_at': reminderTime!.toIso8601String()});
              }
            },
            child: const Text('Programmer'),
          ),
        ],
      ),
    );
  }

  // Commande /todo : créer une tâche
  static Future<Map<String, dynamic>?> showTodoCreator(BuildContext context) async {
    final titleController = TextEditingController();
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tâche (/todo)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(hintText: 'Titre de la tâche')),
            const SizedBox(height: 8),
            const TextField(decoration: InputDecoration(hintText: 'Description (optionnel)'), maxLines: 2),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                Navigator.pop(context, {'type': 'todo', 'title': titleController.text.trim()});
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  static String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
