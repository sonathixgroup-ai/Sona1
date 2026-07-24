// ============================================================
// FICHIER 25 : admin/admin_tourism_form_page.dart
// ============================================================
// lib/presentation/mon_pays/admin/admin_tourism_form_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';

import '../models/province_tourism.dart';
import '../providers/provinces_provider.dart';
import '../providers/authorities_provider.dart'; // Pour utiliser le service d'upload de médias

class AdminTourismFormPage extends ConsumerStatefulWidget {
  final String provinceId;
  final ProvinceTourism? site;
  
  const AdminTourismFormPage({required this.provinceId, this.site, super.key});

  @override
  ConsumerState<AdminTourismFormPage> createState() => _AdminTourismFormPageState();
}

class _AdminTourismFormPageState extends ConsumerState<AdminTourismFormPage> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _typeController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _imageUrlController;
  late TextEditingController _websiteController;
  
  bool _isEditing = false;
  String? _siteId;
  bool _isBusy = false; // Gère le chargement global (upload ou sauvegarde)

  // Couleurs de la charte
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color redThix = Color(0xFFD32F2F);
  static const Color lightBg = Color(0xFFF6F7FB);

  @override
  void initState() {
    super.initState();
    final s = widget.site;
    _isEditing = s != null;
    _siteId = s?.id;
    
    _nameController = TextEditingController(text: s?.name ?? '');
    _typeController = TextEditingController(text: s?.type ?? '');
    _descriptionController = TextEditingController(text: s?.description ?? '');
    _locationController = TextEditingController(text: s?.location ?? '');
    _imageUrlController = TextEditingController(text: s?.imageUrl ?? '');
    _websiteController = TextEditingController(text: s?.website ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _imageUrlController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  // ============================================================
  // UPLOAD D'IMAGE
  // ============================================================
  Future<void> _pickAndUploadImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.first.bytes != null) {
        setState(() => _isBusy = true);
        
        final bytes = result.files.first.bytes!;
        final name = result.files.first.name;
        
        // Appel au service pour uploader le fichier
        final url = await ref.read(authoritiesServiceProvider).uploadMedia(name, bytes, folder: 'tourism');

        setState(() {
          _imageUrlController.text = url;
          _isBusy = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image uploadée avec succès'), backgroundColor: Colors.green));
        }
      }
    } catch (e) {
      setState(() => _isBusy = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur d\'upload : $e'), backgroundColor: Colors.red));
      }
    }
  }

  // ============================================================
  // BUILD PRINCIPAL
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier le site touristique' : 'Ajouter un site', style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: redThix,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  
                  // SECTION 1 : INFORMATIONS GÉNÉRALES
                  _buildSectionCard(
                    title: 'Informations Générales',
                    icon: Icons.info_outline,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _typeController.text.isNotEmpty ? _typeController.text : null,
                        decoration: _inputDecoration('Type de site *', Icons.category),
                        items: const [
                          DropdownMenuItem(value: 'parc_national', child: Text('Parc national')),
                          DropdownMenuItem(value: 'site_historique', child: Text('Site historique')),
                          DropdownMenuItem(value: 'monument', child: Text('Monument')),
                          DropdownMenuItem(value: 'musee', child: Text('Musée')),
                          DropdownMenuItem(value: 'evenement', child: Text('Événement')),
                        ],
                        onChanged: (value) => _typeController.text = value ?? '',
                        validator: (v) => v == null ? 'Champ requis' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(_nameController, 'Nom du site *', Icons.landscape, validator: _requiredValidator),
                      const SizedBox(height: 12),
                      _buildTextField(_locationController, 'Localisation (Ville, Territoire...)', Icons.place),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // SECTION 2 : DÉTAILS & MÉDIAS
                  _buildSectionCard(
                    title: 'Détails & Médias',
                    icon: Icons.description_outlined,
                    children: [
                      _buildTextField(_descriptionController, 'Description du site', Icons.article_outlined, maxLines: 4),
                      const SizedBox(height: 12),
                      _buildUrlWithUploadField(_imageUrlController, 'Photo du site', Icons.image),
                      const SizedBox(height: 12),
                      _buildTextField(_websiteController, 'Site Web officiel ou lien externe', Icons.language),
                    ],
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _isBusy ? null : _save,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: navyDeep,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: Text(
                      _isEditing ? 'Enregistrer les modifications' : 'Ajouter le site',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          
          if (_isBusy)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // WIDGETS REUTILISABLES
  // ============================================================

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: navyDeep, size: 22),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: navyDeep)),
            ],
          ),
          const Divider(height: 24, thickness: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, 
    String label, 
    IconData icon, {
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(label, icon),
      validator: validator,
      maxLines: maxLines,
    );
  }

  Widget _buildUrlWithUploadField(TextEditingController controller, String label, IconData icon) {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(controller, label, icon),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => _pickAndUploadImage(),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: navyDeep.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: navyDeep.withOpacity(0.3)),
            ),
            child: const Icon(Icons.upload_file, color: navyDeep, size: 24),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: navyDeep, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ce champ est requis';
    }
    return null;
  }

  // ============================================================
  // LOGIQUE DE SAUVEGARDE
  // ============================================================

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isBusy = true);
    
    final site = ProvinceTourism(
      id: _siteId ?? '',
      provinceId: widget.provinceId,
      type: _typeController.text.trim(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
      website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
    );
    
    final service = ref.read(provincesServiceProvider);
    
    try {
      if (_isEditing) {
        await service.updateTourismSite(site);
      } else {
        await service.addTourismSite(site);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Site touristique enregistré avec succès'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      setState(() => _isBusy = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
