// lib/presentation/education/instructor/content/lesson_management_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'lib/presentation/education/models/lesson.dart';
import 'lib/presentation/education/instructor/evaluations/question_management_page.dart';

class _C {
  static const bg = Color(0xFFF8FAFC);
  static const surface = Colors.white;
  static const primary = Color(0xFF2D6CDF);
  static const textMain = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const green = Color(0xFF10B981);
  static const orange = Color(0xFFF59E0B);
}

class LessonManagementPage extends StatefulWidget {
  final String? moduleId;
  final Lesson? lesson;

  const LessonManagementPage({super.key, this.moduleId, this.lesson});

  @override
  State<LessonManagementPage> createState() => _LessonManagementPageState();
}

class _LessonManagementPageState extends State<LessonManagementPage> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _durationController;
  late final TextEditingController _contentController;
  
  String _selectedType = 'Texte';
  bool _isLoadingEval = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.lesson?.title ?? '');
    _descController = TextEditingController(text: widget.lesson?.description ?? '');
    _durationController = TextEditingController(text: (widget.lesson?.durationMinutes ?? 0).toString());
    _contentController = TextEditingController(text: widget.lesson?.content ?? '');
    _selectedType = widget.lesson?.type ?? 'Texte';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _durationController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // Ouvre le gestionnaire de questions en créant l'évaluation si nécessaire
  Future<void> _openQuestionManager() async {
    if (widget.lesson == null || widget.lesson!.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez d\'abord enregistrer la leçon avant d\'ajouter des questions.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoadingEval = true);
    try {
      // 1. Chercher si une évaluation existe déjà pour cette leçon
      final existingEval = await Supabase.instance.client
          .from('evaluations')
          .select('id')
          .eq('lesson_id', widget.lesson!.id)
          .maybeSingle();

      String evaluationId;

      if (existingEval != null && existingEval.isNotEmpty) {
        evaluationId = existingEval['id'];
      } else {
        // 2. Créer l'évaluation si elle n'existe pas
        final newEval = await Supabase.instance.client
            .from('evaluations')
            .insert({
              'lesson_id': widget.lesson!.id,
              'title': _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : 'Évaluation',
              'type': _selectedType.toLowerCase(),
            })
            .select('id')
            .single();
        evaluationId = newEval['id'];
      }

      if (!mounted) return;

      // 3. Ouvrir la page de gestion des questions
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuestionManagementPage(evaluationId: evaluationId),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoadingEval = false);
    }
  }

  void _saveLesson() {
    if (!_formKey.currentState!.validate()) return;

    final newLesson = Lesson(
      id: widget.lesson?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      moduleId: widget.moduleId ?? widget.lesson?.moduleId ?? '',
      title: _titleController.text.trim(),
      description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
      type: _selectedType,
      durationMinutes: int.tryParse(_durationController.text) ?? 0,
      order: widget.lesson?.order ?? 0,
      content: _contentController.text.trim().isNotEmpty ? _contentController.text.trim() : null,
    );

    Navigator.pop(context, newLesson);
  }

  InputDecoration _inputDeco(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _C.textMuted, fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      prefixIcon: icon != null ? Icon(icon, color: _C.textMuted, size: 20) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _C.primary, width: 1.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.lesson != null;
    final isQuizOrEval = _selectedType.toLowerCase().contains('quiz') || _selectedType.toLowerCase().contains('évaluation');

    return Scaffold(
      backgroundColor: _C.surface,
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier la leçon' : 'Ajouter une leçon', style: const TextStyle(fontWeight: FontWeight.w800, color: _C.textMain, fontSize: 18)),
        backgroundColor: _C.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: _C.textMain), onPressed: () => context.pop()),
        actions: [
          IconButton(icon: const Icon(Icons.save_rounded, color: _C.primary), onPressed: _saveLesson, tooltip: 'Enregistrer'),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _C.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Informations principales', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _C.textMain)),
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: _C.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: _C.green, size: 20),
                      SizedBox(width: 10),
                      Text('Leçon correctement liée au module', style: TextStyle(color: _C.green, fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _titleController,
                  decoration: _inputDeco('Titre de la leçon*', icon: Icons.title_rounded),
                  validator: (v) => v == null || v.isEmpty ? 'Le titre est requis' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _descController,
                  decoration: _inputDeco('Description', icon: Icons.description_outlined),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedType,
                  dropdownColor: Colors.white,
                  items: const [
                    DropdownMenuItem(value: 'Vidéo', child: Text('🎥 Vidéo')),
                    DropdownMenuItem(value: 'Texte', child: Text('📖 Texte')),
                    DropdownMenuItem(value: 'Quiz', child: Text('❓ Quiz')),
                    DropdownMenuItem(value: 'Évaluation', child: Text('📝 Évaluation')),
                    DropdownMenuItem(value: 'Document (PDF, PPT)', child: Text('📁 Document (PDF, PPT)')),
                    DropdownMenuItem(value: 'Devoir', child: Text('📋 Devoir')),
                  ],
                  onChanged: (v) => setState(() => _selectedType = v!),
                  decoration: _inputDeco('Type de leçon', icon: Icons.category_outlined),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _durationController,
                  decoration: _inputDeco('Durée (en minutes)', icon: Icons.timer_outlined),
                  keyboardType: TextInputType.number,
                ),
                
                // BOUTON D'ACCÈS AU GESTIONNAIRE DE QUESTIONS (Visible si Quiz ou Évaluation)
                if (isQuizOrEval) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _C.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.orange.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Évaluation interactive', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFB45309), fontSize: 14)),
                        const SizedBox(height: 4),
                        const Text('Configurez les questions et les choix de réponses pour cette évaluation.', style: TextStyle(color: _C.textMuted, fontSize: 12)),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _C.orange,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBoard(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _isLoadingEval ? null : _openQuestionManager,
                            icon: _isLoadingEval 
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.quiz_rounded, size: 18),
                            label: const Text('Gérer les questions', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
