// lib/presentation/mon_pays/admin/admin_authority_form_page.dart
// Formulaire complet pour la création/modification d'une autorité
// Avec gestion des études, parcours, réalisations, photos, vidéos, documents, dates de mandat, etc.
// + Assistant IA (Tavily + Astral IA)

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

// Imports corrigés avec des chemins absolus (sûrs à 100%)
import 'package:thix_id/presentation/mon_pays/models/authority.dart';
import 'package:thix_id/presentation/mon_pays/providers/authorities_provider.dart';
import 'package:thix_id/presentation/mon_pays/utils/validators.dart';

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

  // ---- Contrôleur pour la recherche IA ----
  final TextEditingController _aiSearchController = TextEditingController();

  // ---- Listes dynamiques ----
  final List<Education> _educationList = [];
  final List<Career> _careerList = [];
  final List<Achievement> _achievementList = [];
  final List<AuthorityPhoto> _photoList = [];
  final List<AuthorityVideo> _videoList = [];
  final List<AuthorityDocument> _documentList = [];

  bool _isUploadingFile = false;
  bool _isAiLoading = false;

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
    _aiSearchController.dispose();
    super.dispose();
  }

  // ============================================================
  // INTEGRATION IA (Tavily + Astral IA)
  // ============================================================

  Future<void> _fillWithAi() async {
    final query = _aiSearchController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un nom ou un sujet pour l\'IA'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isAiLoading = true);

    try {
      // ⚠️ Ici, vous connecterez votre service Tavily / Astral IA existant
      // Exemple : final aiData = await ref.read(authoritiesServiceProvider).fetchAuthorityDataWithAi(query);
      
      // Simulation d'appel API le temps de brancher vos services réels :
      await Future.delayed(const Duration(seconds: 2));

      // Exemple de remplissage automatique des champs suite au retour de l'IA :
      setState(() {
        _nameController.text = query;
        _biographyController.text = "Biographie générée automatiquement par Thix IA via Tavily pour $query...";
        _titleController.text = "Ministre / Haute Autorité";
        _isAiLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informations pré-remplies avec succès par l\'IA !'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => _isAiLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur IA: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ============================================================
  // UPLOAD FICHIERS
  // ============================================================

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo de profil uploadée avec succès'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => _isUploadingFile = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur upload: ${e.toString()}'), backgroundColor: Colors.red),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo de couverture uploadée avec succès'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => _isUploadingFile = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur upload: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  // ============================================================
  // AJOUT / SUPPRESSION DYNAMIQUES
  // ============================================================

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

  void _removeEducation(int index) => setState(() => _educationList.removeAt(index));
  void _removeCareer(int index) => setState(() => _careerList.removeAt(index));
  void _removeAchievement(int index) => setState(() => _achievementList.removeAt(index));
  void _removePhoto(int index) => setState(() => _photoList.removeAt(index));
  void _removeVideo(int index) => setState(() => _videoList.removeAt(index));
  void _removeDocument(int index) => setState(() => _documentList.removeAt(index));

  // ============================================================
  // BUILD PRINCIPAL
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(adminAuthoritiesProvider).isLoading;
    final isBusy = isSaving || _isUploadingFile || _isAiLoading;
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
                  // 👉 CHAMP ASSISTANT IA (Tavily + Astral IA)
                  if (!isEditing) _buildAiAssistantSection(),
                  if (!isEditing) const Divider(height: 32),

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
          if (isBusy)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 12),
                    Text(
                      _isAiLoading ? 'Thix IA interroge Tavily...' : 'Chargement...',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION ASSISTANT IA
  // ============================================================

  Widget _buildAiAssistantSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1A5276).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFF1A5276)),
              SizedBox(width: 8),
              Text(
                'Assistant Thix IA & Tavily',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A5276)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Entrez le nom complet de la personnalité pour pré-remplir automatiquement le formulaire.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _aiSearchController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de la personnalité',
                    hintText: 'Ex: Félix Tshisekedi',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _isAiLoading ? null : _fillWithAi,
                icon: const Icon(Icons.psychology),
                label: const Text('Rechercher'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A5276),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTIONS GENERALES ET DYNAMIQUES
  // ============================================================

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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A5276),
                foregroundColor: Colors.white,
              ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A5276),
                foregroundColor: Colors.white,
              ),
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

  Widget _buildEducationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Études', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton.icon(onPressed: _addEducation, icon: const Icon(Icons.add), label: const Text('Ajouter')),
          ],
        ),
        if (_educationList.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Aucune étude renseignée', style: TextStyle(color: Colors.grey)),
          ),
        ..._educationList.asMap().entries.map((entry) {
          final i = entry.key;
          final edu = entry.value;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              title: Text(edu.degree),
              subtitle: Text('${edu.institution} (${edu.startYear ?? ''} - ${edu.endYear ?? 'Présent'})'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _removeEducation(i),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCareerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Parcours professionnel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton.icon(onPressed: _addCareer, icon: const Icon(Icons.add), label: const Text('Ajouter')),
          ],
        ),
        if (_careerList.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Aucun parcours renseigné', style: TextStyle(color: Colors.grey)),
          ),
        ..._careerList.asMap().entries.map((entry) {
          final i = entry.key;
          final c = entry.value;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              title: Text(c.title),
              subtitle: Text('${c.organization} (${c.startDate} - ${c.endDate ?? 'Présent'})'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _removeCareer(i),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAchievementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Réalisations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton.icon(onPressed: _addAchievement, icon: const Icon(Icons.add), label: const Text('Ajouter')),
          ],
        ),
        if (_achievementList.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Aucune réalisation renseignée', style: TextStyle(color: Colors.grey)),
          ),
        ..._achievementList.asMap().entries.map((entry) {
          final i = entry.key;
          final a = entry.value;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              title: Text(a.title),
              subtitle: Text('${a.category ?? ''} - ${a.date ?? ''}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _removeAchievement(i),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Galerie photos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton.icon(onPressed: _addPhoto, icon: const Icon(Icons.add), label: const Text('Ajouter')),
          ],
        ),
        if (_photoList.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Aucune photo', style: TextStyle(color: Colors.grey)),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _photoList.asMap().entries.map((entry) {
            final i = entry.key;
            final p = entry.value;
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    p.url,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
                if (p.isCover)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      color: Colors.amber,
                      child: const Text('COUV', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: GestureDetector(
                    onTap: () => _removePhoto(i),
                    child: Container(
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildVideoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Vidéos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton.icon(onPressed: _addVideo, icon: const Icon(Icons.add), label: const Text('Ajouter')),
          ],
        ),
        if (_videoList.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Aucune vidéo', style: TextStyle(color: Colors.grey)),
          ),
        ..._videoList.asMap().entries.map((entry) {
          final i = entry.key;
          final v = entry.value;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.video_library, color: Colors.blue),
              title: Text(v.title),
              subtitle: Text(v.url),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _removeVideo(i),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDocumentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Documents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton.icon(onPressed: _addDocument, icon: const Icon(Icons.add), label: const Text('Ajouter')),
          ],
        ),
        if (_documentList.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Aucun document', style: TextStyle(color: Colors.grey)),
          ),
        ..._documentList.asMap().entries.map((entry) {
          final i = entry.key;
          final d = entry.value;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: Icon(
                d.type == 'PDF' ? Icons.picture_as_pdf :
                d.type == 'DOC' ? Icons.description :
                Icons.insert_drive_file,
                color: Colors.blue,
              ),
              title: Text(d.title),
              subtitle: Text('${d.type} - ${d.url}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _removeDocument(i),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ============================================================
  // SAUVEGARDE
  // ============================================================

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final authority = Authority(
      id: widget.authority?.id ?? '',
      category: _categoryController.text.trim(),
      name: _nameController.text.trim(),
      title: _titleController.text.trim(),
      imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
      coverImageUrl: _coverImageUrlController.text.trim().isEmpty ? null : _coverImageUrlController.text.trim(),
      biography: _biographyController.text.trim(),
      explanation: _explanationController.text.trim().isEmpty ? null : _explanationController.text.trim(),
      mandate: _mandateController.text.trim(),
      mandateStart: _mandateStart,
      mandateEnd: _mandateEnd,
      party: _partyController.text.trim(),
      isActive: _isActive,
      education: _educationList,
      career: _careerList,
      achievements: _achievementList,
      photos: _photoList,
      videos: _videoList,
      documents: _documentList,
      speeches: [],
      publications: [],
      socialNetworks: {},
      agenda: [],
    );

    try {
      if (widget.authority != null) {
        await ref.read(adminAuthoritiesProvider.notifier).updateAuthority(authority);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Autorité modifiée avec succès'), backgroundColor: Colors.green),
        );
      } else {
        await ref.read(adminAuthoritiesProvider.notifier).createAuthority(authority);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Autorité créée avec succès'), backgroundColor: Colors.green),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// ============================================================
// DIALOGUES DYNAMIQUES
// ============================================================

class _EducationFormDialog extends StatefulWidget {
  final void Function(Education) onSave;
  const _EducationFormDialog({required this.onSave});

  @override
  State<_EducationFormDialog> createState() => _EducationFormDialogState();
}

class _EducationFormDialogState extends State<_EducationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _institutionCtrl = TextEditingController();
  final _degreeCtrl = TextEditingController();
  final _fieldCtrl = TextEditingController();
  final _startYearCtrl = TextEditingController();
  final _endYearCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void dispose() {
    _institutionCtrl.dispose();
    _degreeCtrl.dispose();
    _fieldCtrl.dispose();
    _startYearCtrl.dispose();
    _endYearCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter une étude'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _institutionCtrl,
                decoration: const InputDecoration(labelText: 'Institution *'),
                validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _degreeCtrl,
                decoration: const InputDecoration(labelText: 'Diplôme *'),
                validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _fieldCtrl,
                decoration: const InputDecoration(labelText: 'Domaine'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _startYearCtrl,
                decoration: const InputDecoration(labelText: 'Année début'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _endYearCtrl,
                decoration: const InputDecoration(labelText: 'Année fin'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave(
                Education(
                  id: '',
                  institution: _institutionCtrl.text,
                  degree: _degreeCtrl.text,
                  field: _fieldCtrl.text.isNotEmpty ? _fieldCtrl.text : null,
                  startYear: _startYearCtrl.text.isNotEmpty ? _startYearCtrl.text : null,
                  endYear: _endYearCtrl.text.isNotEmpty ? _endYearCtrl.text : null,
                  description: _descCtrl.text.isNotEmpty ? _descCtrl.text : null,
                ),
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}

class _CareerFormDialog extends StatefulWidget {
  final void Function(Career) onSave;
  const _CareerFormDialog({required this.onSave});

  @override
  State<_CareerFormDialog> createState() => _CareerFormDialogState();
}

class _CareerFormDialogState extends State<_CareerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _orgCtrl = TextEditingController();
  final _startCtrl = TextEditingController();
  final _endCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _orgCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un parcours'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Titre *'),
                validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _orgCtrl,
                decoration: const InputDecoration(labelText: 'Organisation *'),
                validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _startCtrl,
                decoration: const InputDecoration(labelText: 'Date début *'),
                validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _endCtrl,
                decoration: const InputDecoration(labelText: 'Date fin (vide = présent)'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave(
                Career(
                  id: '',
                  title: _titleCtrl.text,
                  organization: _orgCtrl.text,
                  startDate: _startCtrl.text,
                  endDate: _endCtrl.text.isNotEmpty ? _endCtrl.text : null,
                  description: _descCtrl.text.isNotEmpty ? _descCtrl.text : null,
                ),
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}

class _AchievementFormDialog extends StatefulWidget {
  final void Function(Achievement) onSave;
  const _AchievementFormDialog({required this.onSave});

  @override
  State<_AchievementFormDialog> createState() => _AchievementFormDialogState();
}

class _AchievementFormDialogState extends State<_AchievementFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _dateCtrl.dispose();
    _categoryCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter une réalisation'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Titre *'),
                validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _dateCtrl,
                decoration: const InputDecoration(labelText: 'Date'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _categoryCtrl.text.isNotEmpty ? _categoryCtrl.text : null,
                decoration: const InputDecoration(labelText: 'Catégorie'),
                items: [
                  'Infrastructure',
                  'Santé',
                  'Éducation',
                  'Agriculture',
                  'Économie',
                  'Tourisme',
                  'Culture',
                  'Sport',
                  'Environnement',
                  'Autre'
                ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => _categoryCtrl.text = v ?? '',
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _imageUrlCtrl,
                decoration: const InputDecoration(labelText: 'URL de l\'image'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave(
                Achievement(
                  id: '',
                  title: _titleCtrl.text,
                  description: _descCtrl.text.isNotEmpty ? _descCtrl.text : null,
                  date: _dateCtrl.text.isNotEmpty ? _dateCtrl.text : null,
                  category: _categoryCtrl.text.isNotEmpty ? _categoryCtrl.text : null,
                  imageUrl: _imageUrlCtrl.text.isNotEmpty ? _imageUrlCtrl.text : null,
                ),
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}

class _PhotoFormDialog extends ConsumerStatefulWidget {
  final void Function(AuthorityPhoto) onSave;
  const _PhotoFormDialog({required this.onSave});

  @override
  ConsumerState<_PhotoFormDialog> createState() => _PhotoFormDialogState();
}

class _PhotoFormDialogState extends ConsumerState<_PhotoFormDialog> {
  final _titleCtrl = TextEditingController();
  String? _uploadedUrl;
  bool _isCover = false;
  bool _isUploading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.first.bytes != null) {
        setState(() => _isUploading = true);
        final bytes = result.files.first.bytes!;
        final name = result.files.first.name;

        final url = await ref.read(authoritiesServiceProvider).uploadMedia(name, bytes, folder: 'gallery');

        setState(() {
          _uploadedUrl = url;
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur upload: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter une photo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_uploadedUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(_uploadedUrl!, height: 120, width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _isUploading ? null : _pickAndUploadPhoto,
                icon: const Icon(Icons.refresh),
                label: const Text('Changer la photo'),
              )
            ] else ...[
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _pickAndUploadPhoto,
                icon: _isUploading 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.upload_file),
                label: Text(_isUploading ? 'Upload en cours...' : 'Parcourir les fichiers...'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A5276),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 45),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Titre de la photo (Optionnel)'),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Photo de couverture'),
              value: _isCover,
              onChanged: (v) => setState(() => _isCover = v),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: _uploadedUrl == null || _isUploading
              ? null
              : () {
                  widget.onSave(
                    AuthorityPhoto(
                      id: '',
                      url: _uploadedUrl!,
                      title: _titleCtrl.text.isNotEmpty ? _titleCtrl.text : null,
                      isCover: _isCover,
                    ),
                  );
                  Navigator.pop(context);
                },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}

class _VideoFormDialog extends ConsumerStatefulWidget {
  final void Function(AuthorityVideo) onSave;
  const _VideoFormDialog({required this.onSave});

  @override
  ConsumerState<_VideoFormDialog> createState() => _VideoFormDialogState();
}

class _VideoFormDialogState extends ConsumerState<_VideoFormDialog> {
  final _titleCtrl = TextEditingController();
  final _thumbCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  
  String? _uploadedUrl;
  bool _isUploading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _thumbCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadVideo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        withData: true,
      );

      if (result != null && result.files.first.bytes != null) {
        setState(() => _isUploading = true);
        final bytes = result.files.first.bytes!;
        final name = result.files.first.name;

        final url = await ref.read(authoritiesServiceProvider).uploadMedia(name, bytes, folder: 'videos');

        setState(() {
          _uploadedUrl = url;
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur upload vidéo: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter une vidéo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Titre *'),
              onChanged: (v) => setState(() {}),
            ),
            const SizedBox(height: 16),
            if (_uploadedUrl != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(child: Text('Vidéo uploadée avec succès', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _isUploading ? null : _pickAndUploadVideo,
                icon: const Icon(Icons.refresh),
                label: const Text('Changer la vidéo'),
              )
            ] else ...[
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _pickAndUploadVideo,
                icon: _isUploading 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.video_call),
                label: Text(_isUploading ? 'Upload en cours...' : 'Uploader la vidéo...'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A5276),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 45),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _thumbCtrl,
              decoration: const InputDecoration(labelText: 'URL miniature (Optionnel)'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description (Optionnel)'),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: _titleCtrl.text.isEmpty || _uploadedUrl == null || _isUploading
              ? null
              : () {
                  widget.onSave(
                    AuthorityVideo(
                      id: '',
                      title: _titleCtrl.text,
                      url: _uploadedUrl!,
                      thumbnailUrl: _thumbCtrl.text.isNotEmpty ? _thumbCtrl.text : null,
                      description: _descCtrl.text.isNotEmpty ? _descCtrl.text : null,
                    ),
                  );
                  Navigator.pop(context);
                },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}

class _DocumentFormDialog extends StatefulWidget {
  final void Function(AuthorityDocument) onSave;
  const _DocumentFormDialog({required this.onSave});

  @override
  State<_DocumentFormDialog> createState() => _DocumentFormDialogState();
}

class _DocumentFormDialogState extends State<_DocumentFormDialog> {
  final _titleCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _typeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _urlCtrl.dispose();
    _typeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un document'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Titre *'),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _urlCtrl,
            decoration: const InputDecoration(labelText: 'URL *'),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _typeCtrl.text.isNotEmpty ? _typeCtrl.text : null,
            decoration: const InputDecoration(labelText: 'Type *'),
            items: ['PDF', 'DOC', 'XLS', 'PPT', 'Autre']
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => _typeCtrl.text = v ?? '',
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descCtrl,
            decoration: const InputDecoration(labelText: 'Description'),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () {
            if (_titleCtrl.text.isNotEmpty && _urlCtrl.text.isNotEmpty && _typeCtrl.text.isNotEmpty) {
              widget.onSave(
                AuthorityDocument(
                  id: '',
                  title: _titleCtrl.text,
                  url: _urlCtrl.text,
                  type: _typeCtrl.text,
                  description: _descCtrl.text.isNotEmpty ? _descCtrl.text : null,
                ),
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}
