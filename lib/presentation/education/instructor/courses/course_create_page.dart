// lib/presentation/education/instructor/courses/course_create_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/presentation/education/models/formation.dart';
import 'package:thix_id/presentation/education/models/module.dart';
import 'package:thix_id/presentation/education/providers/education_provider.dart';
import 'package:thix_id/presentation/education/instructor/content/module_management_page.dart';
import 'package:file_picker/file_picker.dart';

class CourseCreatePage extends StatefulWidget {
  final String? courseId;
  const CourseCreatePage({super.key, this.courseId});

  @override
  State<CourseCreatePage> createState() => _CourseCreatePageState();
}

class _CourseCreatePageState extends State<CourseCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructorController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _tagsController = TextEditingController();
  String _level = 'beginner';
  String _categoryId = '';
  String _currency = 'USD';
  bool _isFree = false;
  bool _isCertifying = false;
  bool _isLoading = false;
  List<Module> _modules = [];

  // Prérequis (liste de texte)
  final List<String> _prerequisites = [];
  final TextEditingController _prereqController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.courseId != null) {
      _loadCourse();
    }
  }

  Future<void> _loadCourse() async {
    // TODO: charger le cours existant
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty) {
      // Ici, vous devriez uploader l'image vers Supabase Storage
      // et récupérer l'URL publique.
      // Pour l'exemple, on simule avec un chemin local.
      setState(() {
        _imageUrlController.text = result.files.first.path ?? '';
      });
    }
  }

  void _addPrerequisite() {
    final text = _prereqController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _prerequisites.add(text);
        _prereqController.clear();
      });
    }
  }

  void _removePrerequisite(int index) {
    setState(() {
      _prerequisites.removeAt(index);
    });
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

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
        currency: _currency,
        imageUrl: _imageUrlController.text.trim(),
        tags: _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        isFree: _isFree,
        isCertifying: _isCertifying,
        status: 'draft',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        instructor: _instructorController.text,
        modules: _modules,
      );

      // Sauvegarde
      // final provider = context.read<EducationProvider>();
      // await provider.createFormation(formation);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cours sauvegardé avec succès !')),
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
                            // Prix et devise
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: _priceController,
                                    decoration: const InputDecoration(labelText: 'Prix'),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: DropdownButtonFormField<String>(
                                    value: _currency,
                                    items: const [
                                      DropdownMenuItem(value: 'USD', child: Text('USD $')),
                                      DropdownMenuItem(value: 'FC', child: Text('FC')),
                                    ],
                                    onChanged: (v) => setState(() => _currency = v!),
                                    decoration: const InputDecoration(labelText: 'Devise'),
                                  ),
                                ),
                              ],
                            ),
                            // Niveau
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
                            // Catégorie
                            TextFormField(
                              decoration: const InputDecoration(labelText: 'Catégorie ID'),
                              onChanged: (v) => _categoryId = v,
                            ),
                            // Image de couverture
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _imageUrlController,
                                    decoration: const InputDecoration(labelText: 'URL de la couverture'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.upload_rounded),
                                  onPressed: _pickImage,
                                  tooltip: 'Choisir une image',
                                ),
                              ],
                            ),
                            // Tags
                            TextFormField(
                              controller: _tagsController,
                              decoration: const InputDecoration(
                                labelText: 'Mots-clés (séparés par des virgules)',
                              ),
                            ),
                            // Options
                            Row(
                              children: [
                                Expanded(
                                  child: CheckboxListTile(
                                    title: const Text('Gratuit'),
                                    value: _isFree,
                                    onChanged: (v) => setState(() => _isFree = v!),
                                    contentPadding: EdgeInsets.zero,
                                    controlAffinity: ListTileControlAffinity.leading,
                                  ),
                                ),
                                Expanded(
                                  child: CheckboxListTile(
                                    title: const Text('Certifiant'),
                                    value: _isCertifying,
                                    onChanged: (v) => setState(() => _isCertifying = v!),
                                    contentPadding: EdgeInsets.zero,
                                    controlAffinity: ListTileControlAffinity.leading,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Prérequis
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Prérequis', style: TextStyle(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _prereqController,
                                    decoration: const InputDecoration(
                                      hintText: 'Ajouter un prérequis',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    onFieldSubmitted: (_) => _addPrerequisite(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.add_rounded, color: Color(0xFF2D6CDF)),
                                  onPressed: _addPrerequisite,
                                ),
                              ],
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _prerequisites.asMap().entries.map((entry) {
                                final index = entry.key;
                                final text = entry.value;
                                return Chip(
                                  label: Text(text),
                                  deleteIcon: const Icon(Icons.close, size: 16),
                                  onDeleted: () => _removePrerequisite(index),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

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
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}
