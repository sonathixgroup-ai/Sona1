// lib/presentation/education/instructor/content/lesson_management_page.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:thix_id/presentation/education/models/lesson.dart';
import 'package:thix_id/presentation/education/models/video.dart';
import 'package:thix_id/presentation/education/models/evaluation.dart';
import 'package:thix_id/presentation/education/instructor/evaluations/question_management_page.dart';

class LessonManagementPage extends StatefulWidget {
  final Lesson? lesson;
  final String? moduleId; // ✅ Ajout du paramètre moduleId

  const LessonManagementPage({
    super.key,
    this.lesson,
    this.moduleId,
  });

  @override
  State<LessonManagementPage> createState() => _LessonManagementPageState();
}

class _LessonManagementPageState extends State<LessonManagementPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();
  String _type = 'video';
  int _duration = 0;
  Video? _video;
  Evaluation? _evaluation;

  @override
  void initState() {
    super.initState();
    if (widget.lesson != null) {
      _titleController.text = widget.lesson!.title;
      _descriptionController.text = widget.lesson!.description ?? '';
      _type = widget.lesson!.type;
      _duration = widget.lesson!.durationMinutes;
      _contentController.text = widget.lesson!.content ?? '';
      _video = widget.lesson!.video;
      _evaluation = widget.lesson!.evaluation;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _uploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: _type == 'video' ? FileType.video : FileType.custom,
      allowedExtensions: _type == 'document' ? ['pdf', 'doc', 'docx', 'ppt', 'pptx'] : null,
    );
    if (result != null && result.files.isNotEmpty) {
      // Simuler l'upload (à remplacer par un vrai upload vers Supabase Storage)
      setState(() {
        _contentController.text = 'uploaded_file_${DateTime.now().millisecondsSinceEpoch}.${result.files.first.extension}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fichier sélectionné ! (upload à implémenter)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.lesson == null ? 'Ajouter une leçon' : 'Modifier la leçon'),
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
                final lesson = Lesson(
                  id: widget.lesson?.id ?? '',
                  moduleId: widget.moduleId ?? '',
                  title: _titleController.text,
                  description: _descriptionController.text,
                  type: _type,
                  durationMinutes: _duration,
                  order: 0,
                  content: _contentController.text,
                  video: _video,
                  evaluation: _evaluation,
                );
                Navigator.pop(context, lesson);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Titre de la leçon*'),
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              DropdownButtonFormField<String>(
                value: _type,
                items: const [
                  DropdownMenuItem(value: 'video', child: Text('Vidéo')),
                  DropdownMenuItem(value: 'text', child: Text('Texte')),
                  DropdownMenuItem(value: 'quiz', child: Text('Quiz')),
                  DropdownMenuItem(value: 'evaluation', child: Text('Évaluation')),
                  DropdownMenuItem(value: 'document', child: Text('Document (PDF, PPT, etc.)')),
                  DropdownMenuItem(value: 'assignment', child: Text('Devoir')),
                ],
                onChanged: (v) => setState(() => _type = v!),
                decoration: const InputDecoration(labelText: 'Type de leçon'),
              ),
              if (_type == 'video' || _type == 'document')
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _contentController,
                        decoration: InputDecoration(
                          labelText: _type == 'video' ? 'URL de la vidéo' : 'URL du document',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.upload_rounded, color: Color(0xFF2D6CDF)),
                      onPressed: _uploadFile,
                      tooltip: 'Télécharger un fichier',
                    ),
                  ],
                )
              else if (_type == 'text')
                TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(labelText: 'Contenu textuel'),
                  maxLines: 5,
                )
              else
                TextFormField(
                  controller: _contentController,
                  decoration: InputDecoration(
                    labelText: _type == 'quiz' || _type == 'evaluation' ? 'ID de l\'évaluation' : 'Consignes',
                  ),
                ),
              TextFormField(
                initialValue: _duration.toString(),
                decoration: const InputDecoration(labelText: 'Durée (minutes)'),
                keyboardType: TextInputType.number,
                onChanged: (v) => _duration = int.tryParse(v) ?? 0,
              ),
              const SizedBox(height: 16),
              if (_type == 'quiz' || _type == 'evaluation')
                ElevatedButton(
                  onPressed: () async {
                    final questions = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuestionManagementPage(evaluationId: widget.lesson?.id ?? ''),
                      ),
                    );
                    if (questions != null) {
                      // Créer une évaluation avec les questions (à implémenter)
                    }
                  },
                  child: const Text('Gérer les questions'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
