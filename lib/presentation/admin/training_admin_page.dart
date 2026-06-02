import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/theme.dart';

class TrainingAdminPage extends StatefulWidget {
  const TrainingAdminPage({super.key});

  @override
  State<TrainingAdminPage> createState() => _TrainingAdminPageState();
}

class _TrainingAdminPageState extends State<TrainingAdminPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<dynamic> _trainings = [];
  bool _loading = true;
  String _searchQuery = '';
  String _filterStatus = 'all';
  String _filterCategory = 'all';
  List<String> _categories = [];

  static const Color _brandPurple = Color(0xFF6366F1);
  static const Color _bgLight = Color(0xFFF8FAFC);
  static const Color _textDark = Color(0xFF1E293B);
  static const Color _textGrey = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _loadTrainings();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final res = await _supabase.from('thix_trainings').select('category');
      if (res is List) {
        final cats = res.map((e) => e['category'] as String).toSet().toList();
        if (mounted) setState(() => _categories = cats);
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  Future<void> _loadTrainings() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      var query = _supabase.from('thix_trainings').select('*');
      
      if (_searchQuery.isNotEmpty) {
        query = query.ilike('title', '%$_searchQuery%');
      }
      
      final res = await query.order('updated_at', ascending: false);
      
      if (!mounted) return;
      setState(() => _trainings = res is List ? res : []);
    } catch (e) {
      debugPrint('Error loading trainings: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<dynamic> get _filteredTrainings {
    var filtered = List.from(_trainings);
    
    if (_filterStatus == 'published') {
      filtered = filtered.where((t) => t['is_published'] == true).toList();
    } else if (_filterStatus == 'draft') {
      filtered = filtered.where((t) => t['is_published'] != true).toList();
    }
    
    if (_filterCategory != 'all') {
      filtered = filtered.where((t) => t['category'] == _filterCategory).toList();
    }
    
    return filtered;
  }

  void _showCreateTrainingDialog() {
    final titleCtrl = TextEditingController();
    final taglineCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    final durationCtrl = TextEditingController();
    final instructorNameCtrl = TextEditingController();
    final instructorTitleCtrl = TextEditingController();
    final requirementsCtrl = TextEditingController();
    bool isFree = false;
    bool certificationIncluded = true;
    bool isFeatured = false;
    String selectedLevel = 'Beginner';
    String selectedLanguage = 'FR';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Créer une formation'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleCtrl, decoration: const InputDecoration(hintText: 'Titre *', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: taglineCtrl, decoration: const InputDecoration(hintText: 'Slogan / Accroche', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: descCtrl, decoration: const InputDecoration(hintText: 'Description', border: OutlineInputBorder()), maxLines: 3),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextField(controller: priceCtrl, decoration: const InputDecoration(hintText: 'Prix', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: DropdownButtonFormField<String>(
                      value: selectedLanguage,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: const [DropdownMenuItem(value: 'FR', child: Text('Français')), DropdownMenuItem(value: 'EN', child: Text('English')), DropdownMenuItem(value: 'SW', child: Text('Swahili'))],
                      onChanged: (v) => setDialogState(() => selectedLanguage = v!),
                    )),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: DropdownButtonFormField<String>(
                      value: selectedLevel,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: const [DropdownMenuItem(value: 'Beginner', child: Text('Débutant')), DropdownMenuItem(value: 'Intermediate', child: Text('Intermédiaire')), DropdownMenuItem(value: 'Advanced', child: Text('Avancé'))],
                      onChanged: (v) => setDialogState(() => selectedLevel = v!),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: durationCtrl, decoration: const InputDecoration(hintText: 'Durée (minutes)', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                  ]),
                  const SizedBox(height: 12),
                  TextField(controller: categoryCtrl, decoration: const InputDecoration(hintText: 'Catégorie', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: instructorNameCtrl, decoration: const InputDecoration(hintText: 'Nom du formateur', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: instructorTitleCtrl, decoration: const InputDecoration(hintText: 'Titre du formateur', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: requirementsCtrl, decoration: const InputDecoration(hintText: 'Prérequis', border: OutlineInputBorder()), maxLines: 2),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: SwitchListTile(title: const Text('Gratuit'), value: isFree, onChanged: (v) => setDialogState(() => isFree = v), dense: true, contentPadding: EdgeInsets.zero)),
                    Expanded(child: SwitchListTile(title: const Text('Certificat'), value: certificationIncluded, onChanged: (v) => setDialogState(() => certificationIncluded = v), dense: true, contentPadding: EdgeInsets.zero)),
                  ]),
                  SwitchListTile(title: const Text('À la une'), value: isFeatured, onChanged: (v) => setDialogState(() => isFeatured = v), dense: true, contentPadding: EdgeInsets.zero),
                  const SizedBox(height: 12),
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.orange.shade50, border: Border.all(color: Colors.orange.shade200), borderRadius: BorderRadius.circular(8)),
                    child: const Text('⚠️ La formation sera créée en BROUILLON et invisible aux utilisateurs jusqu\'à publication.', style: TextStyle(color: Color(0xFF92400e), fontSize: 11, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _supabase.from('thix_trainings').insert({
                      'title': titleCtrl.text,
                      'tagline': taglineCtrl.text.isEmpty ? null : taglineCtrl.text,
                      'description': descCtrl.text.isEmpty ? null : descCtrl.text,
                      'price_amount': isFree ? 0 : double.tryParse(priceCtrl.text),
                      'currency': 'USD',
                      'is_free': isFree,
                      'certification_included': certificationIncluded,
                      'is_featured': isFeatured,
                      'is_published': false,
                      'category': categoryCtrl.text.isEmpty ? 'General' : categoryCtrl.text,
                      'level': selectedLevel,
                      'language': selectedLanguage,
                      'delivery_mode': 'online',
                      'duration_minutes': int.tryParse(durationCtrl.text),
                      'instructor_name': instructorNameCtrl.text.isEmpty ? null : instructorNameCtrl.text,
                      'instructor_title': instructorTitleCtrl.text.isEmpty ? null : instructorTitleCtrl.text,
                      'requirements': requirementsCtrl.text.isEmpty ? null : requirementsCtrl.text,
                    });
                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Formation créée en brouillon!'), backgroundColor: Colors.green));
                    _loadTrainings();
                  } catch (e) {
                    debugPrint('Error creating training: $e');
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: _brandPurple),
                child: const Text('Créer', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditTrainingDialog(dynamic training) {
    final titleCtrl = TextEditingController(text: training['title']);
    final taglineCtrl = TextEditingController(text: training['tagline'] ?? '');
    final descCtrl = TextEditingController(text: training['description'] ?? '');
    final priceCtrl = TextEditingController(text: training['price_amount']?.toString() ?? '');
    final categoryCtrl = TextEditingController(text: training['category'] ?? 'General');
    final durationCtrl = TextEditingController(text: training['duration_minutes']?.toString() ?? '');
    final instructorNameCtrl = TextEditingController(text: training['instructor_name'] ?? '');
    final instructorTitleCtrl = TextEditingController(text: training['instructor_title'] ?? '');
    final requirementsCtrl = TextEditingController(text: training['requirements'] ?? '');
    bool isFree = training['is_free'] ?? false;
    bool certificationIncluded = training['certification_included'] ?? true;
    bool isFeatured = training['is_featured'] ?? false;
    String selectedLevel = training['level'] ?? 'Beginner';
    String selectedLanguage = training['language'] ?? 'FR';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Modifier la formation'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleCtrl, decoration: const InputDecoration(hintText: 'Titre *', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: taglineCtrl, decoration: const InputDecoration(hintText: 'Slogan / Accroche', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: descCtrl, decoration: const InputDecoration(hintText: 'Description', border: OutlineInputBorder()), maxLines: 3),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextField(controller: priceCtrl, decoration: const InputDecoration(hintText: 'Prix', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: DropdownButtonFormField<String>(
                      value: selectedLanguage,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: const [DropdownMenuItem(value: 'FR', child: Text('Français')), DropdownMenuItem(value: 'EN', child: Text('English')), DropdownMenuItem(value: 'SW', child: Text('Swahili'))],
                      onChanged: (v) => setDialogState(() => selectedLanguage = v!),
                    )),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: DropdownButtonFormField<String>(
                      value: selectedLevel,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: const [DropdownMenuItem(value: 'Beginner', child: Text('Débutant')), DropdownMenuItem(value: 'Intermediate', child: Text('Intermédiaire')), DropdownMenuItem(value: 'Advanced', child: Text('Avancé'))],
                      onChanged: (v) => setDialogState(() => selectedLevel = v!),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: durationCtrl, decoration: const InputDecoration(hintText: 'Durée (minutes)', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                  ]),
                  const SizedBox(height: 12),
                  TextField(controller: categoryCtrl, decoration: const InputDecoration(hintText: 'Catégorie', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: instructorNameCtrl, decoration: const InputDecoration(hintText: 'Nom du formateur', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: instructorTitleCtrl, decoration: const InputDecoration(hintText: 'Titre du formateur', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: requirementsCtrl, decoration: const InputDecoration(hintText: 'Prérequis', border: OutlineInputBorder()), maxLines: 2),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: SwitchListTile(title: const Text('Gratuit'), value: isFree, onChanged: (v) => setDialogState(() => isFree = v), dense: true, contentPadding: EdgeInsets.zero)),
                    Expanded(child: SwitchListTile(title: const Text('Certificat'), value: certificationIncluded, onChanged: (v) => setDialogState(() => certificationIncluded = v), dense: true, contentPadding: EdgeInsets.zero)),
                  ]),
                  SwitchListTile(title: const Text('À la une'), value: isFeatured, onChanged: (v) => setDialogState(() => isFeatured = v), dense: true, contentPadding: EdgeInsets.zero),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _supabase.from('thix_trainings').update({
                      'title': titleCtrl.text,
                      'tagline': taglineCtrl.text.isEmpty ? null : taglineCtrl.text,
                      'description': descCtrl.text.isEmpty ? null : descCtrl.text,
                      'price_amount': isFree ? 0 : double.tryParse(priceCtrl.text),
                      'is_free': isFree,
                      'certification_included': certificationIncluded,
                      'is_featured': isFeatured,
                      'category': categoryCtrl.text.isEmpty ? 'General' : categoryCtrl.text,
                      'level': selectedLevel,
                      'language': selectedLanguage,
                      'duration_minutes': int.tryParse(durationCtrl.text),
                      'instructor_name': instructorNameCtrl.text.isEmpty ? null : instructorNameCtrl.text,
                      'instructor_title': instructorTitleCtrl.text.isEmpty ? null : instructorTitleCtrl.text,
                      'requirements': requirementsCtrl.text.isEmpty ? null : requirementsCtrl.text,
                      'updated_at': DateTime.now().toUtc().toIso8601String(),
                    }).eq('id', training['id']);
                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Formation modifiée!'), backgroundColor: Colors.green));
                    _loadTrainings();
                  } catch (e) {
                    debugPrint('Error updating training: $e');
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: _brandPurple),
                child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _uploadCoverImage(dynamic training) async {
    final String? trainingId = training['id']?.toString();
    if (trainingId == null || trainingId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID de formation invalide')),
      );
      return;
    }

    try {
      // Correction : utiliser FilePicker.pickFiles (méthode statique) au lieu de FilePicker.platform.pickFiles
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      
      if (result == null || result.files.isEmpty) return;
      
      final PlatformFile file = result.files.first;
      
      Uint8List bytes;
      if (kIsWeb) {
        if (file.bytes == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible de lire le fichier sur Web')),
          );
          return;
        }
        bytes = file.bytes!;
      } else {
        if (file.path == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chemin du fichier invalide')),
          );
          return;
        }
        bytes = await File(file.path!).readAsBytes();
      }
      
      const int maxSize = 10 * 1024 * 1024;
      if (bytes.length > maxSize) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fichier trop volumineux (max 10 MB)')),
        );
        return;
      }
      
      if (!mounted) return;
      setState(() => _loading = true);
      
      final String storagePath = 'covers/$trainingId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await _supabase.storage.from('thix-trainings').uploadBinary(
        storagePath,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );
      
      final String publicUrl = _supabase.storage.from('thix-trainings').getPublicUrl(storagePath);
      
      await _supabase.from('thix_trainings').update({
        'cover_image_path': storagePath,
        'cover_image_url': publicUrl,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', trainingId);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Image de couverture ajoutée !'),
          backgroundColor: Colors.green,
        ),
      );
      _loadTrainings();
      
    } catch (e) {
      debugPrint('Error uploading cover: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _publishTraining(dynamic training) async {
    final String? trainingId = training['id']?.toString();
    final String trainingTitle = training['title']?.toString() ?? 'Formation';
    
    if (trainingId == null || trainingId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID de formation invalide')),
      );
      return;
    }
    
    try {
      if (!mounted) return;
      setState(() => _loading = true);
      
      await _supabase
          .from('thix_trainings')
          .update({'is_published': true})
          .eq('id', trainingId);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ "$trainingTitle" publiée !'),
          backgroundColor: Colors.green,
        ),
      );
      _loadTrainings();
      
    } catch (e) {
      debugPrint('Error publishing: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _unpublishTraining(dynamic training) async {
    final String? trainingId = training['id']?.toString();
    final String trainingTitle = training['title']?.toString() ?? 'Formation';
    
    if (trainingId == null || trainingId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID de formation invalide')),
      );
      return;
    }
    
    try {
      if (!mounted) return;
      setState(() => _loading = true);
      
      await _supabase
          .from('thix_trainings')
          .update({'is_published': false})
          .eq('id', trainingId);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⏸️ "$trainingTitle" dépubliée'),
          backgroundColor: Colors.orange,
        ),
      );
      _loadTrainings();
      
    } catch (e) {
      debugPrint('Error unpublishing: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteTraining(dynamic training) async {
    final String? trainingId = training['id']?.toString();
    final String trainingTitle = training['title']?.toString() ?? 'cette formation';
    
    if (trainingId == null || trainingId.isEmpty) return;
    
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette formation ?'),
        content: Text('Êtes-vous sûr de vouloir supprimer "$trainingTitle" ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Supprimer', style: TextStyle(color: Colors.white))),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (!mounted) return;
      setState(() => _loading = true);
      
      await _supabase
          .from('thix_trainings')
          .delete()
          .eq('id', trainingId);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Formation supprimée'),
          backgroundColor: Colors.red,
        ),
      );
      _loadTrainings();
      
    } catch (e) {
      debugPrint('Delete error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTrainings = _filteredTrainings;
    final publishedCount = _trainings.where((t) => t['is_published'] == true).length;
    final draftCount = _trainings.where((t) => t['is_published'] != true).length;
    
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Gestion des Formations',
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadTrainings,
            icon: const Icon(Icons.refresh_rounded, color: _brandPurple),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche et filtres
          Container(
            padding: const EdgeInsets.all(14),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    _loadTrainings();
                  },
                  decoration: InputDecoration(
                    hintText: 'Rechercher une formation...',
                    prefixIcon: const Icon(Icons.search_rounded, color: _brandPurple),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: _bgLight,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'all', label: Text('Toutes')),
                          ButtonSegment(value: 'published', label: Text('Publiées')),
                          ButtonSegment(value: 'draft', label: Text('Brouillons')),
                        ],
                        selected: {_filterStatus},
                        onSelectionChanged: (selection) {
                          setState(() => _filterStatus = selection.first);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filterCategory,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(value: 'all', child: Text('Toutes catégories')),
                          ..._categories.map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(cat),
                          )),
                        ],
                        onChanged: (v) => setState(() => _filterCategory = v!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Cartes statistiques
          Container(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _buildStatCard('Total', _trainings.length.toString()),
                const SizedBox(width: 12),
                _buildStatCard('Publiées', publishedCount.toString()),
                const SizedBox(width: 12),
                _buildStatCard('Brouillons', draftCount.toString()),
              ],
            ),
          ),
          
          // Bannière d'information
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                border: Border.all(color: _brandPurple.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_rounded, color: _brandPurple, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '📋 Brouillon = Invisible aux utilisateurs',
                          style: TextStyle(
                            color: _textDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Cliquez "Publier" pour rendre visible dans THIX FORMATION',
                          style: TextStyle(
                            color: _textGrey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 14),
          
          // Liste des formations
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: _brandPurple),
                  )
                : filteredTrainings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.school_outlined, size: 64, color: _textGrey),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty 
                                  ? 'Aucune formation trouvée pour "$_searchQuery"'
                                  : 'Aucune formation disponible',
                              style: const TextStyle(color: _textGrey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: filteredTrainings.length,
                        itemBuilder: (context, index) {
                          final t = filteredTrainings[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: (t['is_published'] ?? false)
                                    ? Colors.green.shade300
                                    : const Color(0xFFE2E8F0),
                                width: (t['is_published'] ?? false) ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (t['cover_image_url'] != null) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      t['cover_image_url'],
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        t['title'] ?? 'Sans titre',
                                        style: const TextStyle(
                                          color: _textDark,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: (t['is_published'] ?? false)
                                            ? Colors.green.shade100
                                            : Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        (t['is_published'] ?? false)
                                            ? '✅ Publiée'
                                            : '📋 Brouillon',
                                        style: TextStyle(
                                          color: (t['is_published'] ?? false)
                                              ? Colors.green
                                              : Colors.orange,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (t['category'] != null)
                                  Text(
                                    '📁 ${t['category']} • ${t['level'] ?? 'Débutant'}',
                                    style: const TextStyle(
                                      color: _textGrey,
                                      fontSize: 11,
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      '💰 ${t['is_free'] == true ? 'Gratuit' : '${t['price_amount'] ?? 0} ${t['currency'] ?? 'USD'}'}',
                                      style: const TextStyle(
                                        color: _brandPurple,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      onPressed: () => _uploadCoverImage(t),
                                      icon: const Icon(
                                        Icons.image_rounded,
                                        color: Colors.green,
                                        size: 18,
                                      ),
                                      tooltip: 'Ajouter une image de couverture',
                                    ),
                                    if (t['is_published'] == true)
                                      IconButton(
                                        onPressed: () => _unpublishTraining(t),
                                        icon: const Icon(
                                          Icons.visibility_off_rounded,
                                          color: Colors.orange,
                                          size: 18,
                                        ),
                                        tooltip: 'Dépublier',
                                      )
                                    else
                                      IconButton(
                                        onPressed: () => _publishTraining(t),
                                        icon: const Icon(
                                          Icons.visibility_rounded,
                                          color: _brandPurple,
                                          size: 18,
                                        ),
                                        tooltip: 'Publier',
                                      ),
                                    IconButton(
                                      onPressed: () => _showEditTrainingDialog(t),
                                      icon: const Icon(
                                        Icons.edit_rounded,
                                        color: _brandPurple,
                                        size: 18,
                                      ),
                                      tooltip: 'Éditer',
                                    ),
                                    IconButton(
                                      onPressed: () => _deleteTraining(t),
                                      icon: const Icon(
                                        Icons.delete_rounded,
                                        color: Colors.red,
                                        size: 18,
                                      ),
                                      tooltip: 'Supprimer',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _brandPurple,
        onPressed: _showCreateTrainingDialog,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: _textGrey,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: _brandPurple,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
