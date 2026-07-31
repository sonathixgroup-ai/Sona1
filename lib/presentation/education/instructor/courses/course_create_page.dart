// lib/presentation/education/instructor/content/module_management_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/presentation/education/models/module.dart';
import 'package:thix_id/presentation/education/models/lesson.dart';

class _C {
  static const bg = Color(0xFFF8FAFC);
  static const surface = Colors.white;
  static const border = Color(0xFFE2E8F0);
  static const primary = Color(0xFF2D6CDF);
  static const textMain = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);
  static const red = Color(0xFFEF4444);
  static const green = Color(0xFF10B981);
  static const orange = Color(0xFFF59E0B);
  static const purple = Color(0xFF8B5CF6);
}

class ModuleManagementPage extends StatefulWidget {
  final String? courseId;
  final Module? module;

  const ModuleManagementPage({super.key, this.courseId, this.module});

  @override
  State<ModuleManagementPage> createState() => _ModuleManagementPageState();
}

class _ModuleManagementPageState extends State<ModuleManagementPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  List<Lesson> _lessons = [];
  bool _isLoading = false;

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

  void _openLessonDialog({Lesson? lesson, int? index}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _LessonFormSheet(
          lesson: lesson,
          onSave: (newLesson) {
            setState(() {
              if (index != null) {
                _lessons[index] = newLesson;
              } else {
                _lessons.add(newLesson);
              }
            });
          },
        ),
      ),
    );
  }

  void _deleteLesson(int index) {
    setState(() {
      _lessons.removeAt(index);
    });
  }

  Future<void> _saveModule() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final moduleData = {
        if (widget.courseId != null) 'formation_id': widget.courseId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'order_index': widget.module?.orderIndex ?? 0,
      };

      String moduleId = widget.module?.id ?? '';

      if (widget.courseId != null && moduleId.isEmpty) {
        final res = await Supabase.instance.client
            .from('modules')
            .insert(moduleData)
            .select('id')
            .single();
        moduleId = res['id'];
      }

      final savedModule = Module(
        id: moduleId.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : moduleId,
        formationId: widget.courseId ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        orderIndex: widget.module?.orderIndex ?? 0,
        lessons: _lessons,
      );

      if (mounted) {
        Navigator.pop(context, savedModule);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'enregistrement du module : $e'), backgroundColor: _C.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDeco(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _C.textMuted),
      filled: true,
      fillColor: _C.bg,
      prefixIcon: icon != null ? Icon(icon, color: _C.textMuted, size: 20) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _C.primary, width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.module != null;

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier le module' : 'Nouveau module', style: const TextStyle(fontWeight: FontWeight.w800, color: _C.textMain, fontSize: 18)),
        backgroundColor: _C.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.close_rounded, color: _C.textMain), onPressed: () => context.pop()),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveModule,
              icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check_rounded, size: 18),
              label: Text(_isLoading ? 'Validation...' : 'Valider', style: const TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: _C.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _C.border)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Détails du Module', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _C.textMain)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: _inputDeco('Titre du module *', icon: Icons.view_module_rounded),
                      validator: (v) => v == null || v.isEmpty ? 'Le titre est requis' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: _inputDeco('Description (optionnelle)', icon: Icons.description_rounded),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.between,
                children: [
                  const Text('Leçons du module', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _C.textMain)),
                  ElevatedButton.icon(
                    onPressed: () => _openLessonDialog(),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Ajouter une leçon'),
                    style: ElevatedButton.styleFrom(backgroundColor: _C.textMain, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_lessons.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _C.border)),
                  child: const Column(
                    children: [
                      Icon(Icons.menu_book_rounded, size: 40, color: _C.border),
                      SizedBox(height: 8),
                      Text('Aucune leçon dans ce module pour l\'instant.', style: TextStyle(color: _C.textMuted, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )
              else
                ..._lessons.asMap().entries.map((entry) {
                  final index = entry.key;
                  final lesson = entry.value;
                  
                  Color typeColor = _C.primary;
                  IconData typeIcon = Icons.article_rounded;
                  if (lesson.type == 'video') { typeColor = _C.green; typeIcon = Icons.play_arrow_rounded; }
                  else if (lesson.type == 'quiz') { typeColor = _C.orange; typeIcon = Icons.quiz_rounded; }
                  else if (lesson.type == 'assignment') { typeColor = _C.purple; typeIcon = Icons.assignment_rounded; }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.border)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: typeColor.withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(typeIcon, color: typeColor, size: 20),
                      ),
                      title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.w700, color: _C.textMain)),
                      subtitle: Text('Type : ${lesson.type.toUpperCase()} · ${lesson.durationMinutes} min', style: const TextStyle(fontSize: 12, color: _C.textMuted)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit_rounded, color: _C.textMuted, size: 20), onPressed: () => _openLessonDialog(lesson: lesson, index: index)),
                          IconButton(icon: const Icon(Icons.delete_outline_rounded, color: _C.red, size: 20), onPressed: () => _deleteLesson(index)),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// WIDGET MODAL : FORMULAIRE DE CRÉATION/ÉDITION D'UNE LEÇON
// ============================================================================
class _LessonFormSheet extends StatefulWidget {
  final Lesson? lesson;
  final Function(Lesson) onSave;

  const _LessonFormSheet({this.lesson, required this.onSave});

  @override
  State<_LessonFormSheet> createState() => _LessonFormSheetState();
}

class _LessonFormSheetState extends State<_LessonFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _contentController;
  late final TextEditingController _durationController;
  
  String _selectedType = 'text';

  List<Map<String, dynamic>> _quizQuestions = [];
  final TextEditingController _quizQuestionController = TextEditingController();
  final TextEditingController _quizOptionsController = TextEditingController();
  final TextEditingController _quizAnswerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.lesson?.title ?? '');
    _descController = TextEditingController(text: widget.lesson?.description ?? '');
    _contentController = TextEditingController(text: widget.lesson?.content ?? '');
    _durationController = TextEditingController(text: (widget.lesson?.durationMinutes ?? 10).toString());
    _selectedType = widget.lesson?.type ?? 'text';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _contentController.dispose();
    _durationController.dispose();
    _quizQuestionController.dispose();
    _quizOptionsController.dispose();
    _quizAnswerController.dispose();
    super.dispose();
  }

  void _addQuizQuestion() {
    if (_quizQuestionController.text.trim().isEmpty) return;
    setState(() {
      _quizQuestions.add({
        'question': _quizQuestionController.text.trim(),
        'options': _quizOptionsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'answer': _quizAnswerController.text.trim(),
      });
      _quizQuestionController.clear();
      _quizOptionsController.clear();
      _quizAnswerController.clear();
    });
  }

  void _removeQuizQuestion(int index) {
    setState(() {
      _quizQuestions.removeAt(index);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    String finalContent = _contentController.text.trim();

    if (_selectedType == 'quiz' && _quizQuestions.isNotEmpty) {
      finalContent = _quizQuestions.map((q) => 'Q: ${q['question']} | Options: ${q['options'].join(', ')} | Rép: ${q['answer']}').join('\n---\n');
    }

    final newLesson = Lesson(
      id: widget.lesson?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      moduleId: widget.lesson?.moduleId ?? '',
      title: _titleController.text.trim(),
      description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
      type: _selectedType,
      durationMinutes: int.tryParse(_durationController.text) ?? 10,
      order: widget.lesson?.order ?? 0,
      content: finalContent.isNotEmpty ? finalContent : null,
    );

    widget.onSave(newLesson);
    Navigator.pop(context);
  }

  InputDecoration _inputDeco(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF64748B)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF64748B), size: 20) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2D6CDF), width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.between,
                children: [
                  Text(widget.lesson == null ? 'Ajouter une leçon' : 'Modifier la leçon', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: const [
                  DropdownMenuItem(value: 'text', child: Text('📖 Article / Texte')),
                  DropdownMenuItem(value: 'video', child: Text('🎥 Vidéo avec explications')),
                  DropdownMenuItem(value: 'quiz', child: Text('❓ Quiz à choix multiples & réponses')),
                  DropdownMenuItem(value: 'assignment', child: Text('📝 Devoir / Travail pratique')),
                ],
                onChanged: (v) => setState(() => _selectedType = v!),
                decoration: _inputDeco('Type de contenu', icon: Icons.category_rounded),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _titleController,
                decoration: _inputDeco('Titre de la leçon *', icon: Icons.title_rounded),
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _descController,
                decoration: _inputDeco('Courte description', icon: Icons.subject_rounded),
                maxLines: 2,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _durationController,
                decoration: _inputDeco('Durée estimée (en minutes)', icon: Icons.timer_rounded),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),

              if (_selectedType == 'video') ...[
                TextFormField(
                  controller: _contentController,
                  decoration: _inputDeco('Lien de la vidéo (URL MP4 ou Storage) *', icon: Icons.link_rounded),
                  validator: (v) => v == null || v.isEmpty ? 'Lien vidéo requis' : null,
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                  child: const Text('💡 Astuce : Utilisez la description ci-dessus pour rédiger les explications textuelles détaillées qui s\'afficheront sous la vidéo.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ),
              ] else if (_selectedType == 'quiz') ...[
                const Divider(height: 30),
                const Text('Configuration des Questions du Quiz', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A))),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _quizQuestionController,
                  decoration: _inputDeco('Intitulé de la question', icon: Icons.help_outline_rounded),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _quizOptionsController,
                  decoration: _inputDeco('Options de réponse (séparées par des virgules)', icon: Icons.list_rounded),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _quizAnswerController,
                  decoration: _inputDeco('Bonne réponse exacte (ou réponse à saisir)', icon: Icons.check_circle_outline_rounded),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D6CDF), foregroundColor: Colors.white, elevation: 0),
                    onPressed: _addQuizQuestion,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Ajouter cette question'),
                  ),
                ),
                const SizedBox(height: 10),
                if (_quizQuestions.isNotEmpty) ...[
                  const Text('Questions ajoutées :', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _quizQuestions.length,
                    itemBuilder: (context, i) {
                      final q = _quizQuestions[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${i + 1}. ${q['question']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                  Text('Choix : ${(q['options'] as List).join(', ')} | Rép : ${q['answer']}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 18),
                              onPressed: () => _removeQuizQuestion(i),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ] else ...[
                TextFormField(
                  controller: _contentController,
                  decoration: _inputDeco(
                    _selectedType == 'assignment' ? 'Consignes détaillées du devoir / travail pratique' : 'Contenu texte de l\'article ou de la leçon',
                    icon: Icons.text_snippet_rounded,
                  ),
                  maxLines: 5,
                  validator: (v) => v == null || v.isEmpty ? 'Le contenu est requis' : null,
                ),
              ],

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D6CDF), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                  onPressed: _submit,
                  child: const Text('Enregistrer la leçon', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
