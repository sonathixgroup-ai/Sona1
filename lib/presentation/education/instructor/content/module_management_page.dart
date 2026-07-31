// lib/presentation/education/instructor/content/module_management_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:thix_id/presentation/education/models/module.dart';
import 'package:thix_id/presentation/education/models/lesson.dart';
import 'package:thix_id/presentation/education/instructor/content/question_management_page.dart';

class ModuleManagementPage extends StatefulWidget {
  final Module? module;
  final String? courseId;
  const ModuleManagementPage({super.key, this.module, this.courseId});

  @override
  State<ModuleManagementPage> createState() => _ModuleManagementPageState();
}

class _ModuleManagementPageState extends State<ModuleManagementPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  List<Lesson> _lessons = [];

  @override
  void initState() {
    super.initState();
    if (widget.module != null) {
      _titleController.text = widget.module!.title;
      _descriptionController.text = widget.module!.description ?? '';
      _lessons = List.from(widget.module!.lessons ?? []);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Enregistrement du module (comme avant)
  Future<void> _saveModule() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final module = Module(
        id: widget.module?.id ?? '',
        formationId: widget.courseId ?? widget.module?.formationId ?? '',
        title: _titleController.text,
        description: _descriptionController.text,
        order: widget.module?.order ?? 0,
        lessons: _lessons,
      );

      // TODO: Sauvegarder le module via Supabase
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Module sauvegardé !')),
      );
      Navigator.pop(context, module);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Ajouter une leçon (comme avant)
  void _addLesson() async {
    // Ici vous pourriez utiliser un sélecteur de type, ou directement créer une leçon
    // Simplification : on ouvre une page de création de leçon (non fournie)
    // Pour l'exemple, on crée directement une leçon quiz avec un evaluation_id temporaire
    final newLesson = Lesson(
      id: '', // généré plus tard
      moduleId: widget.module?.id ?? '',
      title: 'Nouvelle leçon quiz',
      type: 'quiz',
      durationMinutes: 15,
      order: _lessons.length,
      // evaluationId sera assigné après la création dans la table evaluations
    );
    setState(() => _lessons.add(newLesson));
    // Normalement vous pousseriez LessonManagementPage ici
  }

  // Éditer une leçon : si type == 'quiz', on va directement aux questions
  void _editLesson(Lesson lesson) async {
    if (lesson.type == 'quiz') {
      // Récupérer l'evaluation_id associé à cette leçon
      // Il faut d'abord le récupérer depuis la base de données (ou le modèle)
      final evaluationId = lesson.evaluationId; // supposons que le modèle a ce champ
      if (evaluationId == null || evaluationId.isEmpty) {
        // Créer une évaluation dans la base et récupérer son id
        final evalRes = await Supabase.instance.client
            .from('evaluations')
            .insert({
              'lesson_id': lesson.id,
              'title': 'Quiz - ${lesson.title}',
              'type': 'quiz',
            })
            .select('id')
            .single();
        lesson.evaluationId = evalRes['id'];
        evaluationId = evalRes['id'];
      }
      // Ouvrir QuestionManagementPage
      final questions = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuestionManagementPage(evaluationId: evaluationId!),
        ),
      );
      if (questions != null && mounted) {
        // Facultatif : mettre à jour quelque chose
      }
    } else {
      // Pour les autres types (video, texte), ouvrir LessonManagementPage
      // (non implémenté ici, mais vous pouvez l'ajouter)
      // await Navigator.push(context, MaterialPageRoute(builder: (_) => LessonManagementPage(lesson: lesson)));
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
            onPressed: _saveModule,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
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
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Leçons',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
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
                        ? const Center(
                            child: Text(
                              'Aucune leçon. Ajoutez-en une.',
                              style: TextStyle(color: Color(0xFF7386A8)),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _lessons.length,
                            itemBuilder: (context, index) {
                              final lesson = _lessons[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: lesson.type == 'quiz'
                                        ? Colors.orange
                                        : const Color(0xFF10B981),
                                    child: Icon(
                                      lesson.type == 'quiz' ? Icons.quiz : Icons.play_arrow,
                                      color: Colors.white,
                                    ),
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
    );
  }
}
