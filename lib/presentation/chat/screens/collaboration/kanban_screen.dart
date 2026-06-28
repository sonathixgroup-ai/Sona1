import 'package:flutter/material.dart';

class KanbanScreen extends StatefulWidget {
  final String conversationId;
  final String conversationName;

  const KanbanScreen({
    Key? key,
    required this.conversationId,
    required this.conversationName,
  }) : super(key: key);

  @override
  State<KanbanScreen> createState() => _KanbanScreenState();
}

class _KanbanScreenState extends State<KanbanScreen> {
  final Map<String, List<KanbanCard>> _columns = {
    'À faire': [
      KanbanCard(id: '1', title: 'Tâche 1', description: 'Description 1'),
      KanbanCard(id: '2', title: 'Tâche 2', description: 'Description 2'),
    ],
    'En cours': [
      KanbanCard(id: '3', title: 'Tâche 3', description: 'Description 3'),
    ],
    'Terminé': [
      KanbanCard(id: '4', title: 'Tâche 4', description: 'Description 4'),
    ],
  };

  void _addCard(String columnName) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle tâche'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Titre de la tâche',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _columns[columnName]!.add(
                  KanbanCard(
                    id: DateTime.now().toString(),
                    title: controller.text,
                    description: '',
                  ),
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Kanban - ${widget.conversationName}',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _columns.entries.map((entry) {
            return Container(
              width: 300,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5A67D8),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _addCard(entry.key),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(8),
                      children: entry.value
                          .map(
                            (card) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    card.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (card.description.isNotEmpty) ...[const SizedBox(height: 4), Text(card.description, style: const TextStyle(fontSize: 12, color: Colors.grey))],
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class KanbanCard {
  final String id;
  final String title;
  final String description;

  KanbanCard({
    required this.id,
    required this.title,
    required this.description,
  });
}
