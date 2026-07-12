// lib/presentation/mon_pays/admin/admin_authority_form_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../models/authority.dart';
import '../providers/authorities_provider.dart';
import '../utils/validators.dart';

class AdminAuthorityFormPage extends ConsumerStatefulWidget {
  final Authority? authority;

  const AdminAuthorityFormPage({super.key, this.authority});

  @override
  ConsumerState<AdminAuthorityFormPage> createState() => _AdminAuthorityFormPageState();
}

class _AdminAuthorityFormPageState extends ConsumerState<AdminAuthorityFormPage> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _categoryController;
  late TextEditingController _nameController;
  late TextEditingController _titleController;
  late TextEditingController _biographyController;
  late TextEditingController _explanationController;
  late TextEditingController _mandateController;
  late TextEditingController _partyController;
  late TextEditingController _imageUrlController;
  
  final List<TextEditingController> _speechControllers = [];
  final List<TextEditingController> _videoControllers = [];
  final List<TextEditingController> _publicationControllers = [];
  final Map<String, TextEditingController> _socialControllers = {};

  bool _isUploadingFile = false;

  @override
  void initState() {
    super.initState();
    final a = widget.authority;
    _categoryController = TextEditingController(text: a?.category ?? 'Gouvernement');
    _nameController = TextEditingController(text: a?.name ?? '');
    _titleController = TextEditingController(text: a?.title ?? '');
    _biographyController = TextEditingController(text: a?.biography ?? '');
    _explanationController = TextEditingController(text: a?.explanation ?? '');
    _mandateController = TextEditingController(text: a?.mandate ?? '');
    _partyController = TextEditingController(text: a?.party ?? '');
    _imageUrlController = TextEditingController(text: a?.imageUrl ?? '');

    if (a != null) {
      for (var speech in a.speeches) {
        _speechControllers.add(TextEditingController(text: speech));
      }
      for (var video in a.videos) {
        _videoControllers.add(TextEditingController(text: video));
      }
      for (var pub in a.publications) {
        _publicationControllers.add(TextEditingController(text: pub));
      }
      for (var entry in a.socialNetworks.entries) {
        _socialControllers[entry.key] = TextEditingController(text: entry.value);
      }
    }
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _nameController.dispose();
    _titleController.dispose();
    _biographyController.dispose();
    _explanationController.dispose();
    _mandateController.dispose();
    _partyController.dispose();
    _imageUrlController.dispose();
    for (var c in _speechControllers) c.dispose();
    for (var c in _videoControllers) c.dispose();
    for (var c in _publicationControllers) c.dispose();
    for (var c in _socialControllers.values) c.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.first.bytes != null) {
        setState(() => _isUploadingFile = true);
        final bytes = result.files.first.bytes!;
        final name = result.files.first.name;
        final url = await ref.read(authoritiesServiceProvider).uploadMedia(name, bytes, isVideo: false);
        
        setState(() {
          _imageUrlController.text = url;
          _isUploadingFile = false;
        });
      }
    } catch (e) {
      setState(() => _isUploadingFile = false);
    }
  }

  Future<void> _pickAndUploadVideo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        withData: true,
      );

      if (result != null && result.files.first.bytes != null) {
        setState(() => _isUploadingFile = true);
        final bytes = result.files.first.bytes!;
        final name = result.files.first.name;
        final url = await ref.read(authoritiesServiceProvider).uploadMedia(name, bytes, isVideo: true);
        
        setState(() {
          _videoControllers.add(TextEditingController(text: url));
          _isUploadingFile = false;
        });
      }
    } catch (e) {
      setState(() => _isUploadingFile = false);
    }
  }

  void _addSpeechField() => setState(() => _speechControllers.add(TextEditingController()));
  void _addVideoField() => setState(() => _videoControllers.add(TextEditingController()));
  void _addPublicationField() => setState(() => _publicationControllers.add(TextEditingController()));
  void _addSocialNetwork() => setState(() => _socialControllers['Nouveau réseau'] = TextEditingController());

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.authority != null;
    final isSaving = ref.watch(adminAuthoritiesProvider).isLoading;
    final isBusy = isSaving || _isUploadingFile;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier l\'autorité' : 'Nouvelle autorité'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Informations générales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  
                  // Menu déroulant pour la catégorie
                  DropdownButtonFormField<String>(
                    value: _categoryController.text.isNotEmpty ? _categoryController.text : null,
                    decoration: const InputDecoration(labelText: 'Catégorie *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.category)),
                    items: [
                      'Président de la République',
                      'Présidence',
                      'Gouvernement',
                      'Assemblée Nationale',
                      'Sénat',
                      'Cours et Tribunaux',
                      'Entreprises Publiques',
                      'Gouverneurs',
                      'Figures Historiques',
                      'Autres'
                    ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setState(() => _categoryController.text = val ?? ''),
                  ),
                  const SizedBox(height: 12),
                  
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nom complet *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                    validator: MonPaysValidators.validateName,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Titre / Fonction *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.work)),
                    validator: MonPaysValidators.validateTitle,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _imageUrlController,
                          decoration: const InputDecoration(labelText: 'URL de la photo', border: OutlineInputBorder(), prefixIcon: Icon(Icons.image)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: isBusy ? null : _pickAndUploadImage,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Uploader'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A5276), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _partyController,
                    decoration: const InputDecoration(labelText: 'Parti politique', border: OutlineInputBorder(), prefixIcon: Icon(Icons.people)),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _mandateController,
                    decoration: const InputDecoration(labelText: 'Mandat (ex: 2019 - 2028)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today)),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _biographyController,
                    decoration: const InputDecoration(labelText: 'Biographie', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description)),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _explanationController,
                    decoration: const InputDecoration(labelText: 'Rôle & Explication (Optionnel)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lightbulb_outline)),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),

                  // Discours
                  const Text('Discours', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ..._speechControllers.asMap().entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Expanded(child: TextFormField(controller: entry.value, decoration: InputDecoration(labelText: 'Discours ${entry.key + 1}', border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.mic)))),
                        IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => setState(() => _speechControllers.removeAt(entry.key))),
                      ],
                    ),
                  )),
                  TextButton.icon(onPressed: _addSpeechField, icon: const Icon(Icons.add), label: const Text('Ajouter un discours')),
                  const SizedBox(height: 24),

                  // Vidéos
                  const Text('Vidéos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ..._videoControllers.asMap().entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Expanded(child: TextFormField(controller: entry.value, decoration: InputDecoration(labelText: 'Lien vidéo ${entry.key + 1}', border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.video_library)))),
                        IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => setState(() => _videoControllers.removeAt(entry.key))),
                      ],
                    ),
                  )),
                  Row(
                    children: [
                      TextButton.icon(onPressed: _addVideoField, icon: const Icon(Icons.add_link), label: const Text('Ajouter URL')),
                      const Spacer(),
                      ElevatedButton.icon(onPressed: isBusy ? null : _pickAndUploadVideo, icon: const Icon(Icons.upload), label: const Text('Uploader Vidéo'), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: isBusy ? null : _save,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text(isEditing ? 'Modifier' : 'Créer', style: const TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
          if (isBusy) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final socialNetworks = <String, String>{};
    for (var entry in _socialControllers.entries) {
      if (entry.value.text.trim().isNotEmpty) socialNetworks[entry.key] = entry.value.text.trim();
    }

    final authority = Authority(
      id: widget.authority?.id ?? '',
      category: _categoryController.text.trim(),
      name: _nameController.text.trim(),
      title: _titleController.text.trim(),
      imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
      biography: _biographyController.text.trim(),
      explanation: _explanationController.text.trim().isEmpty ? null : _explanationController.text.trim(),
      mandate: _mandateController.text.trim(),
      party: _partyController.text.trim(),
      speeches: _speechControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList(),
      videos: _videoControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList(),
      publications: _publicationControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList(),
      socialNetworks: socialNetworks,
      agenda: [],
    );

    try {
      if (widget.authority != null) {
        await ref.read(adminAuthoritiesProvider.notifier).updateAuthority(authority);
      } else {
        await ref.read(adminAuthoritiesProvider.notifier).createAuthority(authority);
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {}
  }
}
