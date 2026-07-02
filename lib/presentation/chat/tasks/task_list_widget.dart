// lib/presentation/chat/tasks/task_list_widget.dart
// Widget qui affiche la liste des tâches d'une conversation (avec cases à cocher)

import 'package:flutter/material.dart';
import 'task_creator.dart';

class TaskListWidget extends StatefulWidget {
  final List<TaskData> tasks;
  final Function(String taskId, bool completed) onToggleComplete;
  final Function(String taskId) onDelete;
  final Function(TaskData) onAdd;

  const TaskListWidget({
    Key? key,
    required this.tasks,
    required this.onToggleComplete,
    required this.onDelete,
    required this.onAdd,
  }) : super(key: key);

  @override
  State<TaskListWidget> createState() => _TaskListWidgetState();
}

class _TaskListWidgetState extends State<TaskListWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.task_alt, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            const Text('Aucune tâche'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _addTask(),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une tâche'),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tâches', style: TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _addTask,
                tooltip: 'Nouvelle tâche',
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.tasks.length,
          itemBuilder: (context, index) {
            final task = widget.tasks[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: Checkbox(
                  value: task.completed,
                  onChanged: (val) => widget.onToggleComplete(task.id, val ?? false),
                ),
                title: Text(
                  task.title,
                  style: TextStyle(
                    decoration: task.completed ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (task.description != null && task.description!.isNotEmpty)
                      Text(task.description!, style: const TextStyle(fontSize: 12)),
                    if (task.dueDate != null)
                      Text('Échéance: ${_formatDate(task.dueDate!)}', style: const TextStyle(fontSize: 10)),
                    if (task.assignedTo != null)
                      Text('Assignée à: ${task.assignedTo}', style: const TextStyle(fontSize: 10)),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') widget.onDelete(task.id);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'delete', child: Row(
                      children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Supprimer')],
                    )),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _addTask() async {
    final task = await showDialog<TaskData>(
      context: context,
      builder: (context) => TaskCreator(onTaskCreated: (t) => Navigator.pop(context, t)),
    );
    if (task != null) widget.onAdd(task);
  }

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
}
