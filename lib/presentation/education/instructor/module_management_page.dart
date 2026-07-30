// lib/presentation/education/instructor/module_management_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/presentation/education/models/module.dart';
import 'package:thix_id/presentation/education/models/lesson.dart';
import 'package:thix_id/presentation/education/instructor/content/lesson_management_page.dart';

// ============================================================
// CONSTANTES UI
// ============================================================
class _C {
  static const bg = Color(0xFFF8FAFC);
  static const surface = Colors.white;
  static const primary = Color(0xFF2D6CDF);
  static const green = Color(0xFF10B981);
  static const textMain = Color(0xFF1E293B);
  static const textMuted = Color(0xFF7386A8);
  static const border = Color(0xFFE2E8F0);
  static const red = Color(0xFFEF4444);
}

class ModuleManagementPage extends ConsumerStatefulWidget {
  final Module? module;
  final String? courseId; // ID de la formation parente

  const ModuleManagementPage({super.key, this.module, this.courseId});

  @override
  ConsumerState<ModuleManagementPage> createState() => _ModuleManagementPageState();
}

class _ModuleManagementPageState extends ConsumerState<ModuleManagementPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  
  bool _isLoading = false;
  List<Lesson> _lessons = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.module?.title ?? '');
    _descriptionController = TextEditingController(text: widget.module?.description ?? '');
    _lessons = List.from(widget.module?.lessons ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOGIQUE PERSISTANCE SUPABASE
  // ============================================================
  Future<void> _saveModule() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non connecté.');

      final targetFormationId = widget.courseId ?? widget.module?.formationId;
      if (targetFormationId == null || targetFormationId.isEmpty) {
        throw Exception('Formation parente introuvable.');
      }

      final moduleData = {
        'formation_id': targetFormationId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'order': widget.module?.order ?? 0,
        'updated_at': DateTime.now().toIso8601String(),
      };

      String moduleId = widget.module?.id ?? '';

      if (widget.module == null) {
        // Mode Création
        moduleData['created_at'] = DateTime.now().toIso8601String();
        final res = await Supabase.instance.client
            .from('modules')
            .insert(moduleData)
            .select()
            .single();
        moduleId = res['id'];
      } else {
        // Mode Édition
        await Supabase.instance.client
            .from('modules')
            .update(moduleData)
            .eq('id', moduleId);
      }

      final savedModule = Module(
        id: moduleId,
        formationId: targetFormationId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        order: widget.module?.order ?? 0,
        lessons: _lessons,
      );

      if (!mounted) return;
      _showSnackBar('Module sauvegardé avec succès !', isError: false);
      context.pop(savedModule);
    } catch (e) {
      _showSnackBar('Erreur : $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ============================================================
  // GESTION DES LEÇONS LOCALES
  // ============================================================
  void _addLesson() async {
    // 🛡️ VERROUILLAGE : Empêche d'ajouter une leçon si le module n'est pas encore créé
    if (widget.module == null || widget.module!.id.isEmpty) {
      _showSnackBar('Veuillez d\'abord enregistrer le module (en haut à droite) avant d\'ajouter des leçons.', isError: true);
      return;
    }

    final newLesson = await Navigator.push<Lesson>(
      context,
      MaterialPageRoute(
        builder: (_) => LessonManagementPage(moduleId: widget.module!.id),
      ),
    );
    if (newLesson != null) {
      setState(() => _lessons.add(newLesson));
    }
  }

  void _editLesson(Lesson lesson) async {
    final updated = await Navigator.push<Lesson>(
      context,
      MaterialPageRoute(
        builder: (_) => LessonManagementPage(lesson: lesson, moduleId: widget.module?.id),
      ),
    );
    if (updated != null) {
      final index = _lessons.indexOf(lesson);
      if (index != -1) {
        setState(() => _lessons[index] = updated);
      }
    }
  }

  void _deleteLesson(Lesson lesson) {
    setState(() => _lessons.remove(lesson));
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? _C.red : _C.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.module != null;

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Modifier le module' : 'Ajouter un module',
          style: const TextStyle(fontWeight: FontWeight.w800, color: _C.textMain, fontSize: 18),
        ),
        backgroundColor: _C.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _C.textMain),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_rounded, color: _C.primary),
            onPressed: _isLoading ? null : _saveModule,
            tooltip: 'Enregistrer',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _C.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _C.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _C.border),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Informations du module', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _C.textMain)),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _titleController,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            decoration: _inputDecoration('Titre du module*', Icons.title_rounded),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Le titre est requis' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 3,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            decoration: _inputDecoration('Description', Icons.description_outlined),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Leçons (${_lessons.length})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _C.textMain),
                      ),
                      ElevatedButton.icon(
                        onPressed: _addLesson,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Ajouter une leçon', style: TextStyle(fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _C.green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _lessons.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(Icons.menu_book_rounded, size: 48, color: _C.textMuted.withOpacity(0.4)),
                                const SizedBox(height: 12),
                                const Text(
                                  'Aucune leçon pour l\'instant.',
                                  style: TextStyle(color: _C.textMuted, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _lessons.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final lesson = _lessons[index];
                            return Container(
                              decoration: BoxDecoration(
                                color: _C.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _C.border),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                leading: CircleAvatar(
                                  backgroundColor: _C.green.withOpacity(0.12),
                                  child: Text('${index + 1}', style: const TextStyle(color: _C.green, fontWeight: FontWeight.w800)),
                                ),
                                title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.w700, color: _C.textMain)),
                                subtitle: Text('Type : ${lesson.type}', style: const TextStyle(color: _C.textMuted, fontSize: 12)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_rounded, color: _C.primary, size: 20),
                                      onPressed: () => _editLesson(lesson),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_rounded, color: _C.red, size: 20),
                                      onPressed: () => _deleteLesson(lesson),
                                    ),
                                  ],
                                ),
                                onTap: () => _editLesson(lesson),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _C.textMuted, fontWeight: FontWeight.w500),
      prefixIcon: Icon(icon, color: _C.textMuted, size: 20),
      filled: true,
      fillColor: _C.bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.transparent)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _C.primary, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _C.red, width: 1.0)),
    );
  }
}
