// lib/presentation/education/instructor/lesson_management_page.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

import 'package:thix_id/presentation/education/models/lesson.dart';
import 'package:thix_id/presentation/education/models/video.dart';
import 'package:thix_id/presentation/education/models/evaluation.dart';
import 'package:thix_id/presentation/education/instructor/evaluations/question_management_page.dart';

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

class LessonManagementPage extends ConsumerStatefulWidget {
  final Lesson? lesson;
  final String? moduleId; 
  final String? formationId; // Optionnel pour charger les modules si moduleId est absent

  const LessonManagementPage({
    super.key,
    this.lesson,
    this.moduleId,
    this.formationId,
  });

  @override
  ConsumerState<LessonManagementPage> createState() => _LessonManagementPageState();
}

class _LessonManagementPageState extends ConsumerState<LessonManagementPage> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _contentController;
  late final TextEditingController _durationController;

  String _type = 'video';
  int _duration = 0;
  Video? _video;
  Evaluation? _evaluation;
  
  String? _selectedModuleId;
  List<Map<String, dynamic>> _availableModules = [];

  bool _isLoading = false;
  bool _isUploading = false;
  bool _isLoadingModules = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.lesson?.title ?? '');
    _descriptionController = TextEditingController(text: widget.lesson?.description ?? '');
    _contentController = TextEditingController(text: widget.lesson?.content ?? '');
    _durationController = TextEditingController(text: widget.lesson?.durationMinutes.toString() ?? '0');
    
    _type = widget.lesson?.type ?? 'video';
    _duration = widget.lesson?.durationMinutes ?? 0;
    _video = widget.lesson?.video;
    _evaluation = widget.lesson?.evaluation;
    
    _selectedModuleId = widget.moduleId ?? widget.lesson?.moduleId;

    if (_selectedModuleId == null) {
      _loadModules();
    }
  }

  Future<void> _loadModules() async {
    setState(() => _isLoadingModules = true);
    try {
      var query = Supabase.instance.client.from('modules').select('id, title, formation_id');
      if (widget.formationId != null) {
        query = query.eq('formation_id', widget.formationId!);
      }
      final res = await query;
      if (mounted) {
        setState(() {
          _availableModules = List<Map<String, dynamic>>.from(res);
          if (_availableModules.isNotEmpty && _selectedModuleId == null) {
            _selectedModuleId = _availableModules.first['id'];
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement modules : $e');
    } finally {
      if (mounted) setState(() => _isLoadingModules = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _uploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: _type == 'video' ? FileType.video : FileType.custom,
        allowedExtensions: _type == 'document' ? ['pdf', 'doc', 'docx', 'ppt', 'pptx'] : null,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      setState(() => _isUploading = true);
      
      final file = result.files.first;
      final bytes = file.bytes ?? (file.path != null ? await File(file.path!).readAsBytes() : null);
      
      if (bytes == null) throw Exception('Impossible de lire le fichier.');

      final bucket = _type == 'video' ? 'videos' : 'documents';
      final ext = file.extension ?? 'bin';
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
      final path = 'lessons/$fileName';

      await Supabase.instance.client.storage.from(bucket).uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(upsert: true, contentType: file.identifier),
      );

      final publicUrl = Supabase.instance.client.storage.from(bucket).getPublicUrl(path);

      setState(() {
        _contentController.text = publicUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fichier téléchargé avec succès !'), backgroundColor: _C.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'upload : $e'), backgroundColor: _C.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _saveLesson() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedModuleId == null || _selectedModuleId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur : Aucun module parent sélectionné.'), backgroundColor: _C.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final parsedDuration = int.tryParse(_durationController.text.trim()) ?? 0;

      final lessonData = {
        'module_id': _selectedModuleId!,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'type': _type,
        'duration_minutes': parsedDuration,
        'content': _contentController.text.trim(),
        'order': widget.lesson?.order ?? 0,
        'updated_at': DateTime.now().toIso8601String(),
      };

      String lessonId = widget.lesson?.id ?? '';

      if (widget.lesson == null) {
        lessonData['created_at'] = DateTime.now().toIso8601String();
        final res = await Supabase.instance.client
            .from('lessons')
            .insert(lessonData)
            .select()
            .single();
        lessonId = res['id'];
      } else {
        await Supabase.instance.client
            .from('lessons')
            .update(lessonData)
            .eq('id', lessonId);
      }

      final resultLesson = Lesson(
        id: lessonId,
        moduleId: _selectedModuleId!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _type,
        durationMinutes: parsedDuration,
        order: widget.lesson?.order ?? 0,
        content: _contentController.text.trim(),
        video: _video,
        evaluation: _evaluation,
      );

      if (!mounted) return;
      context.pop(resultLesson);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: _C.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.lesson != null;

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Modifier la leçon' : 'Ajouter une leçon',
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
            onPressed: _isLoading ? null : _saveLesson,
            tooltip: 'Enregistrer',
          ),
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
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _C.border),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Informations principales', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _C.textMain)),
                    const SizedBox(height: 16),
                    
                    // Sélecteur de module si non fourni par le parent
                    if (widget.moduleId == null && widget.lesson?.moduleId == null) ...[
                      _isLoadingModules
                          ? const Center(child: LinearProgressIndicator(color: _C.primary))
                          : DropdownButtonFormField<String>(
                              value: _selectedModuleId,
                              dropdownColor: _C.surface,
                              style: const TextStyle(color: _C.textMain, fontWeight: FontWeight.w600),
                              items: _availableModules.map((m) {
                                return DropdownMenuItem<String>(
                                  value: m['id'].toString(),
                                  child: Text(m['title']?.toString() ?? 'Module sans titre'),
                                );
                              }).toList(),
                              onChanged: (v) => setState(() => _selectedModuleId = v),
                              decoration: _inputDecoration('Module parent*', Icons.folder_open_rounded),
                              validator: (v) => v == null || v.isEmpty ? 'Veuillez sélectionner un module' : null,
                            ),
                      const SizedBox(height: 16),
                    ],

                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      decoration: _inputDecoration('Titre de la leçon*', Icons.title_rounded),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Le titre est requis' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      decoration: _inputDecoration('Description', Icons.description_outlined),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _type,
                      dropdownColor: _C.surface,
                      style: const TextStyle(color: _C.textMain, fontWeight: FontWeight.w600),
                      items: const [
                        DropdownMenuItem(value: 'video', child: Text('Vidéo')),
                        DropdownMenuItem(value: 'text', child: Text('Texte')),
                        DropdownMenuItem(value: 'quiz', child: Text('Quiz')),
                        DropdownMenuItem(value: 'evaluation', child: Text('Évaluation')),
                        DropdownMenuItem(value: 'document', child: Text('Document (PDF, PPT)')),
                        DropdownMenuItem(value: 'assignment', child: Text('Devoir')),
                      ],
                      onChanged: (v) => setState(() => _type = v!),
                      decoration: _inputDecoration('Type de leçon', Icons.category_outlined),
                    ),
                    const SizedBox(height: 16),

                    if (_type == 'video' || _type == 'document')
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _contentController,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                              decoration: _inputDecoration(
                                _type == 'video' ? 'URL de la vidéo' : 'URL du document',
                                Icons.link_rounded,
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Ce champ est requis' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: _isUploading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.upload_rounded, color: _C.primary),
                            onPressed: _isUploading ? null : _uploadFile,
                            tooltip: 'Télécharger un fichier',
                          ),
                        ],
                      )
                    else if (_type == 'text')
                      TextFormField(
                        controller: _contentController,
                        maxLines: 5,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        decoration: _inputDecoration('Contenu textuel de la leçon', Icons.article_outlined),
                      )
                    else
                      TextFormField(
                        controller: _contentController,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        decoration: _inputDecoration('ID de l\'évaluation ou consignes', Icons.assignment_outlined),
                      ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      decoration: _inputDecoration('Durée (en minutes)', Icons.timer_outlined),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (_type == 'quiz' || _type == 'evaluation')
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: widget.lesson?.id == null
                        ? () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Veuillez d\'abord enregistrer la leçon pour configurer ses questions.')),
                            )
                        : () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QuestionManagementPage(evaluationId: widget.lesson!.id),
                              ),
                            );
                          },
                    icon: const Icon(Icons.quiz_rounded, color: Colors.white),
                    label: const Text('Gérer les questions du Quiz', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
            ],
          ),
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
