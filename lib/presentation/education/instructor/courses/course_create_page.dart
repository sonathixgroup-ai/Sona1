// lib/presentation/education/instructor/content/lesson_management_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/presentation/education/models/lesson.dart';

class _C {
  static const bg = Color(0xFFF8FAFC);
  static const surface = Colors.white;
  static const primary = Color(0xFF2D6CDF);
  static const textMain = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const green = Color(0xFF10B981);
  static const red = Color(0xFFEF4444);
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
  
  String _selectedType = 'text';

  // --- Outils pour le constructeur de QUIZ ---
  List<Map<String, dynamic>> _quizQuestions = [];
  final TextEditingController _quizQuestionController = TextEditingController();
  final TextEditingController _quizOptionsController = TextEditingController();
  final TextEditingController _quizAnswerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.lesson?.title ?? '');
    _descController = TextEditingController(text: widget.lesson?.description ?? '');
    _durationController = TextEditingController(text: (widget.lesson?.durationMinutes ?? 0).toString());
    _contentController = TextEditingController(text: widget.lesson?.content ?? '');
    
    // S'assurer que le type est valide (par défaut : texte)
    _selectedType = widget.lesson?.type ?? 'text';
    if (!['text', 'video', 'quiz', 'assignment'].contains(_selectedType)) {
      _selectedType = 'text';
    }

    // Charger les questions existantes si c'est un quiz
    if (_selectedType == 'quiz' && widget.lesson?.content != null) {
      try {
        final parsed = jsonDecode(widget.lesson!.content!);
        if (parsed is List) {
          _quizQuestions = List<Map<String, dynamic>>.from(parsed);
        }
      } catch (e) {
        debugPrint('Contenu du quiz non-JSON ou format texte brut.');
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _durationController.dispose();
    _contentController.dispose();
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
    setState(() => _quizQuestions.removeAt(index));
  }

  void _saveLesson() {
    if (!_formKey.currentState!.validate()) return;

    String finalContent = _contentController.text.trim();

    // Gestion spécifique du Quiz
    if (_selectedType == 'quiz') {
      if (_quizQuestions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez ajouter au moins une question au quiz.'), backgroundColor: _C.red)
        );
        return;
      }
      finalContent = jsonEncode(_quizQuestions);
    }

    final newLesson = Lesson(
      id: widget.lesson?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      moduleId: widget.moduleId ?? widget.lesson?.moduleId ?? '',
      title: _titleController.text.trim(),
      description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
      type: _selectedType,
      durationMinutes: int.tryParse(_durationController.text) ?? 0,
      order: widget.lesson?.order ?? 0,
      content: finalContent.isNotEmpty ? finalContent : null,
    );

    Navigator.pop(context, newLesson);
  }

  InputDecoration _inputDeco(String label, {IconData? icon, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: _C.textMuted, fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      prefixIcon: icon != null ? Icon(icon, color: _C.textMuted, size: 20) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _C.primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.lesson != null;

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier la leçon' : 'Ajouter une leçon', style: const TextStyle(fontWeight: FontWeight.w800, color: _C.textMain, fontSize: 18)),
        backgroundColor: _C.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _C.textMain),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded, color: _C.primary),
            onPressed: _saveLesson,
            tooltip: 'Enregistrer',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _C.border),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Informations principales', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _C.textMain)),
                const SizedBox(height: 16),
                
                // Badge de succès
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: _C.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: _C.green, size: 20),
                      const SizedBox(width: 10),
                      const Text('Leçon correctement liée au module', style: TextStyle(color: _C.green, fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Champs de base
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

                // Le Sélecteur de type avec setState ACTIF
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  dropdownColor: Colors.white,
                  icon: const Icon(Icons.arrow_drop_down_rounded, color: _C.textMuted),
                  items: const [
                    DropdownMenuItem(value: 'text', child: Text('📖 Article / Texte')),
                    DropdownMenuItem(value: 'video', child: Text('🎥 Vidéo')),
                    DropdownMenuItem(value: 'quiz', child: Text('❓ Quiz')),
                    DropdownMenuItem(value: 'assignment', child: Text('📝 Devoir')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _selectedType = v; // Cela force la mise à jour des champs en dessous
                      });
                    }
                  },
                  decoration: _inputDeco('Type de leçon', icon: Icons.category_outlined),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _durationController,
                  decoration: _inputDeco('Durée (en minutes)', icon: Icons.timer_outlined),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),

                const Divider(height: 1, color: _C.border),
                const SizedBox(height: 24),

                // ----------------------------------------------------
                // ZONE DYNAMIQUE (Change selon le Dropdown)
                // ----------------------------------------------------
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  child: _buildDynamicFields(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Cette fonction renvoie l'interface appropriée selon _selectedType
  Widget _buildDynamicFields() {
    if (_selectedType == 'video') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Configuration Vidéo', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _C.textMain)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _contentController,
            decoration: _inputDeco('Lien de la vidéo (URL MP4, YouTube...)', icon: Icons.link_rounded),
            validator: (v) => _selectedType == 'video' && (v == null || v.isEmpty) ? 'Le lien de la vidéo est requis' : null,
          ),
        ],
      );
    } 
    
    if (_selectedType == 'quiz') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Générateur de Quiz', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _C.textMain)),
          const SizedBox(height: 12),
          
          // Formulaire d'ajout de question
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.border)),
            child: Column(
              children: [
                TextFormField(
                  controller: _quizQuestionController,
                  decoration: _inputDeco('Intitulé de la question', icon: Icons.help_outline_rounded),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _quizOptionsController,
                  decoration: _inputDeco('Options (séparées par des virgules)', icon: Icons.list_alt_rounded, hint: 'Ex: Paris, Lyon, Marseille'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _quizAnswerController,
                  decoration: _inputDeco('Bonne réponse exacte', icon: Icons.check_circle_outline_rounded),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: _C.textMain, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: _addQuizQuestion,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Ajouter la question', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
          
          // Liste des questions ajoutées
          if (_quizQuestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Questions validées :', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: _C.textMain)),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _quizQuestions.length,
              itemBuilder: (context, i) {
                final q = _quizQuestions[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: _C.green.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: _C.green.withOpacity(0.2))),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: _C.green, shape: BoxShape.circle),
                        child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(q['question'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _C.textMain)),
                            const SizedBox(height: 4),
                            Text('Choix : ${(q['options'] as List).join(', ')}', style: const TextStyle(fontSize: 12, color: _C.textMuted)),
                            Text('Rép : ${q['answer']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _C.green)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: _C.red, size: 20),
                        onPressed: () => _removeQuizQuestion(i),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      );
    } 
    
    if (_selectedType == 'assignment') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Configuration du Devoir', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _C.textMain)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _contentController,
            maxLines: 4,
            decoration: _inputDeco('Consignes détaillées du devoir', icon: Icons.assignment_outlined),
            validator: (v) => _selectedType == 'assignment' && (v == null || v.isEmpty) ? 'Les consignes sont requises' : null,
          ),
        ],
      );
    }

    // Par défaut (Texte)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Contenu de l\'article', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _C.textMain)),
        const SizedBox(height: 12),
        TextFormField(
          controller: _contentController,
          maxLines: 6,
          decoration: _inputDeco('Rédigez le texte de la leçon ici...', icon: Icons.article_outlined),
          validator: (v) => _selectedType == 'text' && (v == null || v.isEmpty) ? 'Le contenu est requis' : null,
        ),
      ],
    );
  }
}
