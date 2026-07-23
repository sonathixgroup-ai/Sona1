// ============================================================
// FICHIER CORRIGÉ : admin_authority_form_page.dart
// ============================================================

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
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

  // ---- Champs principaux ----
  late TextEditingController _categoryController;
  late TextEditingController _nameController;
  late TextEditingController _titleController;
  late TextEditingController _biographyController;
  late TextEditingController _explanationController;
  late TextEditingController _mandateController;
  late TextEditingController _partyController;
  late TextEditingController _imageUrlController;
  late TextEditingController _coverImageUrlController;
  DateTime? _mandateStart;
  DateTime? _mandateEnd;
  bool _isActive = true;

  // ---- Listes dynamiques ----
  final List<Education> _educationList = [];
  final List<Career> _careerList = [];
  final List<Achievement> _achievementList = [];
  final List<AuthorityPhoto> _photoList = [];
  final List<AuthorityVideo> _videoList = [];
  final List<AuthorityDocument> _documentList = [];

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
    _coverImageUrlController = TextEditingController(text: a?.coverImageUrl ?? '');
    _mandateStart = a?.mandateStart;
    _mandateEnd = a?.mandateEnd;
    _isActive = a?.isActive ?? true;

    if (a != null) {
      _educationList.addAll(a.education);
      _careerList.addAll(a.career);
      _achievementList.addAll(a.achievements);
      _photoList.addAll(a.photos);
      _videoList.addAll(a.videos);
      _documentList.addAll(a.documents);
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
    _coverImageUrlController.dispose();
    super.dispose();
  }

  // ---- Upload ----
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
        final url = await ref.read(authoritiesServiceProvider).uploadMedia(name, bytes);
        setState(() {
          _imageUrlController.text = url;
          _isUploadingFile = false;
        });
      }
    } catch (_) {
      setState(() => _isUploadingFile = false);
    }
  }

  Future<void> _pickAndUploadCover() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.first.bytes != null) {
        setState(() => _isUploadingFile = true);
        final bytes = result.files.first.bytes!;
        final name = result.files.first.name;
        final url = await ref.read(authoritiesServiceProvider).uploadMedia(name, bytes, folder: 'covers');
        setState(() {
          _coverImageUrlController.text = url;
          _isUploadingFile = false;
        });
      }
    } catch (_) {
      setState(() => _isUploadingFile = false);
    }
  }

  // ---- Ajout / suppression dynamiques ----
  void _addEducation() {
    showDialog(
      context: context,
      builder: (ctx) => _EducationFormDialog(
        onSave: (edu) => setState(() => _educationList.add(edu)),
      ),
    );
  }

  void _addCareer() {
    showDialog(
      context: context,
      builder: (ctx) => _CareerFormDialog(
        onSave: (career) => setState(() => _careerList.add(career)),
      ),
    );
  }

  void _addAchievement() {
    showDialog(
      context: context,
      builder: (ctx) => _AchievementFormDialog(
        onSave: (ach) => setState(() => _achievementList.add(ach)),
      ),
    );
  }

  void _addPhoto() {
    showDialog(
      context: context,
      builder: (ctx) => _PhotoFormDialog(
        onSave: (photo) => setState(() => _photoList.add(photo)),
      ),
    );
  }

  void _addVideo() {
    showDialog(
      context: context,
      builder: (ctx) => _VideoFormDialog(
        onSave: (video) => setState(() => _videoList.add(video)),
      ),
    );
  }

  void _addDocument() {
    showDialog(
      context: context,
      builder: (ctx) => _DocumentFormDialog(
        onSave: (doc) => setState(() => _documentList.add(doc)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(adminAuthoritiesProvider).isLoading;
    final isBusy = isSaving || _isUploadingFile;

    final isEditing = widget.authority != null;

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
                  _buildGeneralSection(isBusy),
                  const Divider(height: 32),
                  _buildEducationSection(),
                  const Divider(height: 32),
                  _buildCareerSection(),
                  const Divider(height: 32),
                  _buildAchievementSection(),
                  const Divider(height: 32),
                  _buildPhotoSection(),
                  const Divider(height: 32),
                  _buildVideoSection(),
                  const Divider(height: 32),
                  _buildDocumentSection(),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isBusy ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      isEditing ? 'Modifier' : 'Créer',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
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

  // ---- Sections (avec paramètre isBusy) ----
  Widget _buildGeneralSection(bool isBusy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Informations générales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _categoryController.text.isNotEmpty ? _categoryController.text : null,
          decoration: const InputDecoration(labelText: 'Catégorie *', border: OutlineInputBorder()),
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
          decoration: const InputDecoration(labelText: 'Nom complet *', border: OutlineInputBorder()),
          validator: (v) => v?.isEmpty ?? true ? 'Champ requis' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(labelText: 'Titre / Fonction *', border: OutlineInputBorder()),
          validator: (v) => v?.isEmpty ?? true ? 'Champ requis' : null,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'Photo de profil (URL)', border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: isBusy ? null : _pickAndUploadImage,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A5276), foregroundColor: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _coverImageUrlController,
                decoration: const InputDecoration(labelText: 'Photo de couverture (URL)', border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: isBusy ? null : _pickAndUploadCover,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A5276), foregroundColor: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _partyController,
          decoration: const InputDecoration(labelText: 'Parti politique', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _mandateController,
          decoration: const InputDecoration(labelText: 'Mandat (ex: 2019 - 2028)', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _mandateStart ?? DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) setState(() => _mandateStart = date);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Début du mandat', border: OutlineInputBorder()),
                  child: Text(_mandateStart != null ? DateFormat('dd/MM/yyyy').format(_mandateStart!) : 'Sélectionner une date'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _mandateEnd ?? DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) setState(() => _mandateEnd = date);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Fin du mandat', border: OutlineInputBorder()),
                  child: Text(_mandateEnd != null ? DateFormat('dd/MM/yyyy').format(_mandateEnd!) : 'Sélectionner une date'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Actif (mandat en cours)'),
          value: _isActive,
          onChanged: (v) => setState(() => _isActive = v),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _biographyController,
          decoration: const InputDecoration(labelText: 'Biographie', border: OutlineInputBorder()),
          maxLines: 5,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _explanationController,
          decoration: const InputDecoration(labelText: 'Rôle & Explication (Optionnel)', border: OutlineInputBorder()),
          maxLines: 4,
        ),
      ],
    );
  }

  // ... Les autres sections (Education, Career, Achievements, Photos, Videos, Documents) restent inchangées ...
  // Elles sont déjà définies dans le code précédent et ne nécessitent pas de paramètre isBusy.
  // Je les ai omises ici pour la concision, mais elles doivent être présentes dans votre fichier final.
  // Vous pouvez copier les mêmes que dans la version précédente.
}
