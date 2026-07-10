// lib/presentation/education/instructor/module_management_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/presentation/education/models/module.dart';
import 'package:thix_id/presentation/education/models/lesson.dart';
import 'package:thix_id/presentation/education/instructor/lesson_management_page.dart';

class ModuleManagementPage extends StatefulWidget {
  final Module? module;
  const ModuleManagementPage({super.key, this.module});

  @override
  State<ModuleManagementPage> createState() => _ModuleManagementPageState();
}

class _ModuleManagementPageState extends State<ModuleManagementPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<Lesson> _lessons = [];

  @override
  void initState() {
    super.initState();
    if (widget.module != null) {
      _titleController.text = widget.module!.title;
      _descriptionController.text = widget.module!.description ?? '';
      // ✅ Gestion de la nullabilité de `lessons`
      _lessons = List.from(widget.module!.lessons ?? []);
    }
  }

  void _addLesson() async {
    final newLesson = await Navigator.push<Lesson>(
      context,
      MaterialPageRoute(builder: (_) => LessonManagementPage()),
    );
    if (newLesson != null) setState(() => _lessons.add(newLesson));
  }

  void _editLesson(Lesson lesson) async {
    final updated = await Navigator.push<Lesson>(
      context,
      MaterialPageRoute(builder: (_) => LessonManagementPage(lesson: lesson)),
    );
    if (updated != null) {
      final index = _lessons.indexOf(lesson);
      if (index != -1) setState(() => _lessons[index] = updated);
    }
  }

  void _deleteLesson(Lesson lesson) {
    setState(() => _lessons.remove(lesson));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.module == null ? 'Ajouter un module' : 'Modifier le module'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                final module = Module(
                  id: widget.module?.id ?? '',
                  formationId: '',
                  title: _titleController.text,
                  description: _descriptionController.text,
                  order: 0,
                  lessons: _lessons,
                );
                Navigator.pop(context, module);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Titre du module*'),
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Leçons',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addLesson,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Ajouter une leçon'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _lessons.isEmpty
                    ? const Center(child: Text('Aucune leçon. Ajoutez-en une.'))
                    : ListView.builder(
                        itemCount: _lessons.length,
                        itemBuilder: (context, index) {
                          final lesson = _lessons[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF10B981),
                                child: Text('${index + 1}'),
                              ),
                              title: Text(lesson.title),
                              subtitle: Text('Type : ${lesson.type}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded),
                                    onPressed: () => _editLesson(lesson),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_rounded, color: Colors.red),
                                    onPressed: () => _deleteLesson(lesson),
                                  ),
                                ],
                              ),
                              onTap: () => _editLesson(lesson),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
