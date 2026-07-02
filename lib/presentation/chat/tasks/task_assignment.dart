// lib/presentation/chat/tasks/task_assignment.dart
// Sélecteur de membre pour assigner une tâche (liste des participants)

import 'package:flutter/material.dart';

class TaskAssignment extends StatefulWidget {
  final String? selectedUserId;

  const TaskAssignment({Key? key, this.selectedUserId}) : super(key: key);

  @override
  State<TaskAssignment> createState() => _TaskAssignmentState();
}

class _TaskAssignmentState extends State<TaskAssignment> {
  // Dans un vrai projet, ces données viendraient du repository (participants du groupe)
  final List<Contact> _contacts = const [
    Contact(id: '1', name: 'Moi-même'),
    Contact(id: '2', name: 'Aminata Diallo'),
    Contact(id: '3', name: 'Koffi Mensah'),
    Contact(id: '4', name: 'David Alloco'),
  ];

  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedUserId;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Assigner à', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._contacts.map((contact) => RadioListTile<String>(
            title: Text(contact.name),
            value: contact.id,
            groupValue: _selectedId,
            onChanged: (val) => setState(() => _selectedId = val),
          )),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, _selectedId),
                child: const Text('Assigner'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Contact {
  final String id;
  final String name;
  const Contact({required this.id, required this.name});
}
