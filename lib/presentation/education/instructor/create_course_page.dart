// lib/presentation/education/instructor/create_course_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/presentation/education/models/formation.dart';
import 'package:thix_id/presentation/education/models/module.dart';
import 'package:thix_id/presentation/education/models/lesson.dart';
import 'package:thix_id/presentation/education/providers/education_provider.dart';
import 'package:thix_id/presentation/education/instructor/module_management_page.dart';

class CreateCoursePage extends StatefulWidget {
  final String? courseId;
  const CreateCoursePage({super.key, this.courseId});

  @override
  State<CreateCoursePage> createState() => _CreateCoursePageState();
}

class _CreateCoursePageState extends State<CreateCoursePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructorController = TextEditingController();
  final _priceController = TextEditingController();
  String _level = 'beginner';
  String _categoryId = '';
  bool _isLoading = false;
  List<Module> _modules = [];

  @override
  void initState() {
    super.initState();
    if (widget.courseId != null) {
      _loadCourse();
    }
  }

  Future<void> _loadCourse() async {
    // TODO: charger les données du cours existant
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // ✅ Gestion de null pour les listes de leçons
      final totalDuration = _modules.fold<int>(0, (sum, m) {
        final lessons = m.lessons ?? [];
        return sum + lessons.fold<int>(0, (s, l) => s + l.durationMinutes);
      });

      final formation = Formation(
        id: widget.courseId ?? '',
        title: _titleController.text,
        description: _descriptionController.text,
        categoryId: _categoryId,
        instructorId: userId,
        level: _level,
        duration: totalDuration,
        price: double.tryParse(_priceController.text) ?? 0.0,
        status: 'published',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        instructor: _instructorController.text,
        modules: _modules,
      );

      // Appeler le service pour sauvegarder
      // final provider = context.read<EducationProvider>();
      // if (widget.courseId == null) await provider.createFormation(formation);
      // else await provider.updateFormation(formation);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cours sauvegardé !')),
      );
      context.pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addModule() async {
    final newModule = await Navigator.push<Module>(
      context,
      MaterialPageRoute(builder: (_) => ModuleManagementPage()),
    );
    if (newModule != null) {
      setState(() => _modules.add(newModule));
    }
  }

  void _editModule(Module module) async {
    final updated = await Navigator.push<Module>(
      context,
      MaterialPageRoute(builder: (_) => ModuleManagementPage(module: module)),
    );
    if (updated != null) {
      final index = _modules.indexOf(module);
      if (index != -1) setState(() => _modules[index] = updated);
    }
  }

  void _deleteModule(Module module) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer le module ?'),
        content: Text('Supprimer "${module.title}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              setState(() => _modules.remove(module));
              Navigator.pop(context);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.courseId == null ? 'Créer un cours' : 'Modifier le cours'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded),
            onPressed: _saveCourse,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informations générales
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(labelText: 'Titre du cours*'),
                              validator: (v) => v!.isEmpty ? 'Requis' : null,
                            ),
                            TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(labelText: 'Description'),
                              maxLines: 4,
                            ),
                            TextFormField(
                              controller: _instructorController,
                              decoration: const InputDecoration(labelText: 'Nom du formateur*'),
                              validator: (v) => v!.isEmpty ? 'Requis' : null,
                            ),
                            TextFormField(
                              controller: _priceController,
                              decoration: const InputDecoration(labelText: 'Prix (FC)'),
                              keyboardType: TextInputType.number,
                            ),
                            DropdownButtonFormField<String>(
                              value: _level,
                              items: const [
                                DropdownMenuItem(value: 'beginner', child: Text('Débutant')),
                                DropdownMenuItem(value: 'intermediate', child: Text('Intermédiaire')),
                                DropdownMenuItem(value: 'advanced', child: Text('Avancé')),
                              ],
                              onChanged: (v) => setState(() => _level = v!),
                              decoration: const InputDecoration(labelText: 'Niveau'),
                            ),
                            TextFormField(
                              decoration: const InputDecoration(labelText: 'Catégorie ID'),
                              onChanged: (v) => _categoryId = v,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Modules
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Modules du cours',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addModule,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Ajouter un module'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D6CDF),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_modules.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'Aucun module. Ajoutez-en un.',
                            style: TextStyle(color: Color(0xFF7386A8)),
                          ),
                        ),
                      )
                    else
                      ..._modules.map((module) => Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF2D6CDF),
                                child: Text('${_modules.indexOf(module) + 1}'),
                              ),
                              title: Text(module.title),
                              subtitle: Text('${(module.lessons ?? []).length} leçons'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded),
                                    onPressed: () => _editModule(module),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_rounded, color: Colors.red),
                                    onPressed: () => _deleteModule(module),
                                  ),
                                ],
                              ),
                              onTap: () => _editModule(module),
                            ),
                          )),
                  ],
                ),
              ),
            ),
    );
  }
}
