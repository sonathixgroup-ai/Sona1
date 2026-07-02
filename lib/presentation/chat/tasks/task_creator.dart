// lib/presentation/chat/tasks/task_creator.dart
// Dialog ou feuille modale pour créer une tâche (titre, description, assignation, échéance)

import 'package:flutter/material.dart';
import 'task_assignment.dart';

class TaskCreator extends StatefulWidget {
  final Function(TaskData) onTaskCreated;

  const TaskCreator({Key? key, required this.onTaskCreated}) : super(key: key);

  @override
  State<TaskCreator> createState() => _TaskCreatorState();
}

class _TaskCreatorState extends State<TaskCreator> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _dueDate;
  String? _assignedTo;
  int _priority = 1; // 0-low, 1-medium, 2-high

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Créer une tâche'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'Titre *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(hintText: 'Description (optionnel)', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            ListTile(
              title: Text(_dueDate != null ? _formatDate(_dueDate!) : 'Date d\'échéance'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) setState(() => _dueDate = date);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              title: const Text('Assigner à'),
              trailing: const Icon(Icons.person),
              onTap: () async {
                final selected = await showModalBottomSheet<String>(
                  context: context,
                  builder: (_) => TaskAssignment(selectedUserId: _assignedTo),
                );
                if (selected != null) setState(() => _assignedTo = selected);
              },
              subtitle: _assignedTo != null ? Text('Utilisateur $_assignedTo') : null,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Priorité : '),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Basse')),
                    ButtonSegment(value: 1, label: Text('Moyenne')),
                    ButtonSegment(value: 2, label: Text('Haute')),
                  ],
                  selected: {_priority},
                  onSelectionChanged: (set) => setState(() => _priority = set.first),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.trim().isNotEmpty) {
              final task = TaskData(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: _titleController.text.trim(),
                description: _descController.text.trim(),
                dueDate: _dueDate,
                assignedTo: _assignedTo,
                priority: _priority,
                completed: false,
                createdAt: DateTime.now(),
              );
              widget.onTaskCreated(task);
              Navigator.pop(context);
            }
          },
          child: const Text('Créer'),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
}

class TaskData {
  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final String? assignedTo;
  final int priority;
  final bool completed;
  final DateTime createdAt;

  TaskData({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.assignedTo,
    required this.priority,
    required this.completed,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'due_date': dueDate?.toIso8601String(),
    'assigned_to': assignedTo,
    'priority': priority,
    'completed': completed,
    'created_at': createdAt.toIso8601String(),
  };

  factory TaskData.fromJson(Map<String, dynamic> json) => TaskData(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
    assignedTo: json['assigned_to'],
    priority: json['priority'],
    completed: json['completed'] ?? false,
    createdAt: DateTime.parse(json['created_at']),
  );
}
