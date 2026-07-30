// lib/presentation/education/instructor/content/module_management_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/presentation/education/models/module.dart';
import 'package:thix_id/presentation/education/models/lesson.dart';
import 'package:thix_id/presentation/education/instructor/content/lesson_management_page.dart';

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
  final String? courseId;

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
  String? _currentModuleId; // Garde l'ID en mémoire après sauvegarde

  @override
  void initState() {
    super.initState();
    _currentModuleId = widget.module?.id;
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

  // Permet de renvoyer le module mis à jour à la page parente quand on quitte
  void _goBack() {
    if (_currentModuleId != null) {
      final savedModule = Module(
        id: _currentModuleId!,
        formationId: widget.courseId ?? widget.module?.formationId ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        order: widget.module?.order ?? 0,
        lessons: _lessons,
      );
      context.pop(savedModule);
    } else {
      context.pop();
    }
  }

  Future<void> _saveModule() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final targetFormationId = widget.courseId ?? widget.module?.formationId;
      if (targetFormationId == null) throw Exception('Formation parente introuvable.');

      final moduleData = {
        'formation_id': targetFormationId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'order': widget.module?.order ?? 0,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (_currentModuleId == null) {
        // Mode Création : on insère et on garde la page ouverte
        moduleData['created_at'] = DateTime.now().toIso8601String();
        final res = await Supabase.instance.client.from('modules').insert(moduleData).select().single();
        
        setState(() {
          _currentModuleId = res['id'];
        });
        _showSnackBar('Module sauvegardé ! Le bouton "Ajouter une leçon" est débloqué.', isError: false);
      } else {
        // Mode Édition
        await Supabase.instance.client.from('modules').update(moduleData).eq('id', _currentModuleId!);
        _showSnackBar('Module mis à jour avec succès !', isError: false);
      }
    } catch (e) {
      _showSnackBar('Erreur : $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addLesson() async {
    if (_currentModuleId == null) return; // Sécurité supplémentaire

    final newLesson = await Navigator.push<Lesson>(
      context,
      MaterialPageRoute(
        builder: (_) => LessonManagementPage(moduleId: _currentModuleId!),
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
        builder: (_) => LessonManagementPage(lesson: lesson, moduleId: _currentModuleId),
      ),
    );
    if (updated != null) {
      final index = _lessons.indexOf(lesson);
      if (index != -1) setState(() => _lessons[index] = updated);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? _C.red : _C.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSaved = _currentModuleId != null;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        backgroundColor: _C.bg,
        appBar: AppBar(
          title: Text(isSaved ? 'Modifier le module' : 'Ajouter un module', style: const TextStyle(fontWeight: FontWeight.w800, color: _C.textMain, fontSize: 18)),
          backgroundColor: _C.surface,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: _C.textMain), onPressed: _goBack),
          actions: [
            IconButton(
              icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_rounded, color: _C.primary),
              onPressed: _isLoading ? null : _saveModule,
              tooltip: 'Enregistrer',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _C.border)),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Informations du module', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _C.textMain)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(labelText: 'Titre du module*', prefixIcon: const Icon(Icons.title_rounded), filled: true, fillColor: _C.bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(labelText: 'Description', prefixIcon: const Icon(Icons.description_outlined), filled: true, fillColor: _C.bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Leçons (${_lessons.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _C.textMain)),
                  
                  ElevatedButton.icon(
                    onPressed: !isSaved 
                        ? () => _showSnackBar('Sauvegardez d\'abord le module (en haut à droite) pour pouvoir y ajouter des leçons.', isError: true) 
                        : _addLesson,
                    icon: Icon(!isSaved ? Icons.lock_rounded : Icons.add_rounded, size: 18),
                    label: Text(!isSaved ? 'Sauvegarder d\'abord' : 'Ajouter une leçon', style: const TextStyle(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !isSaved ? _C.textMuted : _C.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _lessons.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _C.border, style: BorderStyle.solid)),
                      child: Column(
                        children: [
                          Icon(!isSaved ? Icons.lock_outline_rounded : Icons.menu_book_rounded, size: 48, color: _C.textMuted.withOpacity(0.4)),
                          const SizedBox(height: 12),
                          Text(
                            !isSaved ? 'Leçons verrouillées avant sauvegarde.' : 'Aucune leçon pour l\'instant.',
                            style: const TextStyle(color: _C.textMuted, fontWeight: FontWeight.w600),
                          ),
                        ],
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
                          decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.border)),
                          child: ListTile(
                            title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.w700, color: _C.textMain)),
                            subtitle: Text('Type : ${lesson.type}', style: const TextStyle(color: _C.textMuted, fontSize: 12)),
                            trailing: IconButton(icon: const Icon(Icons.edit_rounded, color: _C.primary, size: 20), onPressed: () => _editLesson(lesson)),
                            onTap: () => _editLesson(lesson),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
