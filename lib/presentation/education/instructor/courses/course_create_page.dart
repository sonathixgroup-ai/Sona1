// lib/presentation/education/instructor/courses/course_create_page.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

import 'package:thix_id/presentation/education/providers/education_provider.dart';
import 'package:thix_id/presentation/education/models/formation.dart';
import 'package:thix_id/presentation/education/models/module.dart';
import 'package:thix_id/presentation/education/models/lesson.dart';
import 'package:thix_id/presentation/education/instructor/content/module_management_page.dart';

class _C {
  static const bg = Color(0xFFF8FAFC);
  static const surface = Colors.white;
  static const border = Color(0xFFE2E8F0);
  static const primary = Color(0xFF2D6CDF);
  static const textMain = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);
  static const red = Color(0xFFEF4444);
}

class CourseCreatePage extends ConsumerStatefulWidget {
  final String? courseId;
  const CourseCreatePage({super.key, this.courseId});

  @override
  ConsumerState<CourseCreatePage> createState() => _CourseCreatePageState();
}

class _CourseCreatePageState extends ConsumerState<CourseCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructorController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController(); 
  final _tagsController = TextEditingController();
  
  String _level = 'beginner';
  String? _categoryId;
  String _currency = 'USD';
  bool _isFree = false;
  bool _isCertifying = false;
  bool _isLoading = false;
  bool _isInitLoading = false;
  List<Module> _modules = [];

  final List<String> _prerequisites = [];
  final TextEditingController _prereqController = TextEditingController();

  Uint8List? _coverImageBytes;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    if (widget.courseId != null) {
      _loadCourse();
    } else {
      // Pré-remplir le nom du formateur si possible
      final userName = Supabase.instance.client.auth.currentUser?.userMetadata?['name'];
      if (userName != null) {
        _instructorController.text = userName;
      }
    }
  }

  Future<void> _loadCourse() async {
    setState(() => _isInitLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('formations')
          .select('*, modules(*, lessons(*))')
          .eq('id', widget.courseId!)
          .single();

      if (mounted) {
        setState(() {
          _titleController.text = data['title'] ?? '';
          _descriptionController.text = data['description'] ?? '';
          _instructorController.text = data['instructor_name'] ?? '';
          _priceController.text = (data['price'] ?? 0).toString();
          _categoryId = data['category_id'];
          _level = data['level'] ?? 'beginner';
          _currency = data['currency'] ?? 'USD';
          _imageUrlController.text = data['image_url'] ?? '';
          _isFree = data['is_free'] ?? false;
          _isCertifying = data['is_certifying'] ?? false;
          
          if (data['tags'] != null && data['tags'] is List) {
            _tagsController.text = (data['tags'] as List).join(', ');
          }

          if (data['modules'] != null) {
            _modules = (data['modules'] as List).map((mJson) {
              final module = Module.fromJson(mJson);
              if (mJson['lessons'] != null) {
                module.lessons = (mJson['lessons'] as List).map((lJson) => Lesson.fromJson(lJson)).toList();
                module.lessons!.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
              }
              return module;
            }).toList();
            _modules.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur de chargement pour édition : $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Impossible de charger le cours: $e'), backgroundColor: _C.red));
      }
    } finally {
      if (mounted) setState(() => _isInitLoading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image, 
        allowMultiple: false,
        withData: true, 
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes;
        
        if (bytes == null) return;

        setState(() {
          _coverImageBytes = bytes; 
          _isUploadingImage = true;
        });

        final ext = file.extension ?? 'jpg';
        final fileName = 'cover_${DateTime.now().millisecondsSinceEpoch}.$ext';
        final filePath = 'courses/covers/$fileName';

        await Supabase.instance.client.storage
            .from('course-media')
            .uploadBinary(filePath, bytes);

        final publicUrl = Supabase.instance.client.storage
            .from('course-media')
            .getPublicUrl(filePath);

        setState(() {
          _imageUrlController.text = publicUrl; 
          _isUploadingImage = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image uploadée avec succès !'), backgroundColor: Color(0xFF10B981)),
          );
        }
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'upload : $e'), backgroundColor: _C.red),
        );
      }
    }
  }

  void _addPrerequisite() {
    final text = _prereqController.text.trim();
    if (text.isNotEmpty) {
      setState(() { _prerequisites.add(text); _prereqController.clear(); });
    }
  }

  void _removePrerequisite(int index) {
    setState(() { _prerequisites.removeAt(index); });
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_isUploadingImage) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez patienter, l\'image est en cours d\'upload.')));
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non connecté.');

      final totalDuration = _modules.fold<int>(0, (sum, m) {
        final lessons = m.lessons ?? [];
        return sum + lessons.fold<int>(0, (s, l) => s + l.durationMinutes);
      });

      final formationData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'category_id': (_categoryId != null && _categoryId!.isNotEmpty) ? _categoryId : null,
        
        // ✅ CORRECTION VITALE : On inclut 'user_id' pour satisfaire la contrainte SQL
        'user_id': userId, 
        'instructor_id': userId,
        
        'instructor_name': _instructorController.text,
        'level': _level,
        'duration': totalDuration,
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'currency': _currency,
        'image_url': _imageUrlController.text.trim(),
        'tags': _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'is_free': _isFree,
        'is_certifying': _isCertifying,
        'status': 'draft',
      };

      if (widget.courseId == null) {
        final res = await Supabase.instance.client.from('formations').insert(formationData).select('id').single();
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cours sauvegardé ! Vous pouvez maintenant ajouter des modules.', style: TextStyle(color: Colors.white)), backgroundColor: Color(0xFF10B981)),
        );
        
        context.pushReplacement('/instructor/courses/edit/${res['id']}');
      } else {
        await Supabase.instance.client.from('formations').update(formationData).eq('id', widget.courseId!);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cours mis à jour avec succès !', style: TextStyle(color: Colors.white)), backgroundColor: Color(0xFF10B981)),
        );
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e', style: const TextStyle(color: Colors.white)), backgroundColor: _C.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addModule() async {
    final newModule = await Navigator.push<Module>(context, MaterialPageRoute(builder: (_) => ModuleManagementPage(courseId: widget.courseId)));
    if (newModule != null) setState(() => _modules.add(newModule));
  }

  void _editModule(Module module) async {
    final updated = await Navigator.push<Module>(context, MaterialPageRoute(builder: (_) => ModuleManagementPage(module: module, courseId: widget.courseId)));
    if (updated != null) {
      final index = _modules.indexOf(module);
      if (index != -1) setState(() => _modules[index] = updated);
    }
  }

  void _deleteModule(Module module) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _C.surface,
        title: const Text('Supprimer le module ?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Voulez-vous vraiment supprimer "${module.title}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler', style: TextStyle(color: _C.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _C.red),
            onPressed: () { setState(() => _modules.remove(module)); Navigator.pop(context); }, 
            child: const Text('Supprimer', style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    );
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
    final categoriesAsync = ref.watch(categoriesProvider);
    final isNewCourse = widget.courseId == null;

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        title: Text(isNewCourse ? 'Créer un cours' : 'Modifier le cours', style: const TextStyle(fontWeight: FontWeight.w800, color: _C.textMain, fontSize: 18)),
        backgroundColor: _C.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.close_rounded, color: _C.textMain), onPressed: () => context.pop()),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: _isLoading || _isInitLoading ? null : _saveCourse,
              icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save_rounded, size: 18),
              label: Text(_isLoading ? 'Sauvegarde...' : 'Enregistrer', style: const TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: _C.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            ),
          )
        ],
      ),
      body: _isInitLoading 
        ? const Center(child: CircularProgressIndicator(color: _C.primary))
        : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // INFO GÉNÉRALES
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _C.border)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Informations Générales', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _C.textMain)),
                    const SizedBox(height: 16),
                    TextFormField(controller: _titleController, decoration: _inputDeco('Titre du cours *'), validator: (v) => v!.isEmpty ? 'Requis' : null),
                    const SizedBox(height: 12),
                    TextFormField(controller: _descriptionController, decoration: _inputDeco('Description globale'), maxLines: 4),
                    const SizedBox(height: 12),
                    TextFormField(controller: _instructorController, decoration: _inputDeco('Nom affiché du formateur *', icon: Icons.person_rounded), validator: (v) => v!.isEmpty ? 'Requis' : null),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // DÉTAILS & PRIX
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _C.border)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Détails & Tarification', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _C.textMain)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(flex: 3, child: TextFormField(controller: _priceController, decoration: _inputDeco('Prix', icon: Icons.sell_rounded), keyboardType: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(flex: 2, child: DropdownButtonFormField<String>(
                          value: _currency, 
                          items: const [DropdownMenuItem(value: 'USD', child: Text('USD \$')), DropdownMenuItem(value: 'FC', child: Text('FC'))], 
                          onChanged: (v) => setState(() => _currency = v!), 
                          decoration: _inputDeco('Devise')
                        )),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _level, 
                            items: const [DropdownMenuItem(value: 'beginner', child: Text('Débutant')), DropdownMenuItem(value: 'intermediate', child: Text('Intermédiaire')), DropdownMenuItem(value: 'advanced', child: Text('Avancé'))], 
                            onChanged: (v) => setState(() => _level = v!), 
                            decoration: _inputDeco('Niveau')
                          )
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: categoriesAsync.when(
                            data: (cats) {
                              final catExists = cats.any((c) => c.id == _categoryId);
                              return DropdownButtonFormField<String>(
                                value: catExists ? _categoryId : null,
                                items: cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis))).toList(),
                                onChanged: (v) => setState(() => _categoryId = v),
                                decoration: _inputDeco('Catégorie'),
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (e, _) => const Text('Erreur DB', style: TextStyle(color: _C.red)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // ZONE DE PRÉVISUALISATION ET D'UPLOAD DE L'IMAGE
                    const Text('Image de couverture', style: TextStyle(fontWeight: FontWeight.w600, color: _C.textMuted)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _isUploadingImage ? null : _pickAndUploadImage,
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _C.bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _C.border, width: 2, style: BorderStyle.solid),
                          image: _coverImageBytes != null
                              ? DecorationImage(image: MemoryImage(_coverImageBytes!), fit: BoxFit.cover)
                              : (_imageUrlController.text.isNotEmpty
                                  ? DecorationImage(image: NetworkImage(_imageUrlController.text), fit: BoxFit.cover)
                                  : null),
                        ),
                        child: _isUploadingImage
                            ? const Center(child: CircularProgressIndicator(color: _C.primary))
                            : (_coverImageBytes == null && _imageUrlController.text.isEmpty
                                ? const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate_rounded, size: 48, color: _C.textMuted),
                                      SizedBox(height: 8),
                                      Text('Appuyez pour uploader une image', style: TextStyle(color: _C.textMuted, fontWeight: FontWeight.w500)),
                                    ],
                                  )
                                : const Align(
                                    alignment: Alignment.topRight,
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: CircleAvatar(backgroundColor: Colors.black54, child: Icon(Icons.edit, color: Colors.white, size: 18)),
                                    ),
                                  )),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(controller: _tagsController, decoration: _inputDeco('Mots-clés (séparés par des virgules)', icon: Icons.tag_rounded)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: SwitchListTile(title: const Text('Gratuit', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)), value: _isFree, activeColor: _C.primary, onChanged: (v) => setState(() => _isFree = v), contentPadding: EdgeInsets.zero)), 
                        Expanded(child: SwitchListTile(title: const Text('Certifiant', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)), value: _isCertifying, activeColor: _C.primary, onChanged: (v) => setState(() => _isCertifying = v), contentPadding: EdgeInsets.zero)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // MODULES (Masqués si le cours n'est pas encore créé)
              if (isNewCourse)
                 Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24), 
                  decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _C.border, style: BorderStyle.solid)),
                  child: const Column(
                    children: [
                      Icon(Icons.lock_rounded, size: 40, color: _C.textMuted),
                      SizedBox(height: 12),
                      Text('Sauvegardez d\'abord le cours pour pouvoir y ajouter des modules.', textAlign: TextAlign.center, style: TextStyle(color: _C.textMain, fontWeight: FontWeight.w600)),
                    ],
                  )
                )
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                  children: [
                    const Text('Modules du cours', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _C.textMain)), 
                    ElevatedButton.icon(
                      onPressed: _addModule, 
                      icon: const Icon(Icons.add_rounded, size: 18), 
                      label: const Text('Ajouter'), 
                      style: ElevatedButton.styleFrom(backgroundColor: _C.textMain, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))
                    )
                  ]
                ),
                const SizedBox(height: 12),
                
                if (_modules.isEmpty) 
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40), 
                    decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _C.border, style: BorderStyle.solid)),
                    child: const Column(
                      children: [
                        Icon(Icons.view_module_rounded, size: 40, color: _C.border),
                        SizedBox(height: 8),
                        Text('Aucun module. Ajoutez-en un pour commencer.', style: TextStyle(color: _C.textMuted, fontWeight: FontWeight.w500)),
                      ],
                    )
                  ) 
                else 
                  ..._modules.asMap().entries.map((entry) {
                    final index = entry.key;
                    final module = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12), 
                      decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.border)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(backgroundColor: _C.primary.withOpacity(0.1), child: Text('${index + 1}', style: const TextStyle(color: _C.primary, fontWeight: FontWeight.bold))), 
                        title: Text(module.title, style: const TextStyle(fontWeight: FontWeight.bold, color: _C.textMain)), 
                        subtitle: Text('${(module.lessons ?? []).length} leçon(s)', style: const TextStyle(color: _C.textMuted)), 
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min, 
                          children: [
                            IconButton(icon: const Icon(Icons.edit_rounded, color: _C.textMuted), onPressed: () => _editModule(module)), 
                            IconButton(icon: const Icon(Icons.delete_outline_rounded, color: _C.red), onPressed: () => _deleteModule(module))
                          ]
                        ), 
                        onTap: () => _editModule(module)
                      )
                    );
                  }),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
