// lib/presentation/mon_pays/admin/admin_province_form_page.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/province.dart';
import '../providers/provinces_provider.dart';

class AdminProvinceFormPage extends ConsumerStatefulWidget {
  final Province? province;

  const AdminProvinceFormPage({super.key, this.province});

  @override
  ConsumerState<AdminProvinceFormPage> createState() => _AdminProvinceFormPageState();
}

class _AdminProvinceFormPageState extends ConsumerState<AdminProvinceFormPage> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _capitalController;
  late TextEditingController _regionController;
  late TextEditingController _areaController;
  late TextEditingController _populationController;
  late TextEditingController _descriptionController;
  late TextEditingController _coverImageUrlController;
  late TextEditingController _coatOfArmsUrlController;
  late TextEditingController _mapUrlController;
  late TextEditingController _websiteController;

  // Gouvernance
  late TextEditingController _governorController;
  late TextEditingController _governorPhotoController;
  late TextEditingController _viceGovernorController;
  late TextEditingController _viceGovernorPhotoController;
  
  // Listes dynamiques enrichies
  List<Map<String, String>> _ministers = [];
  List<Map<String, dynamic>> _tourismSites = [];
  List<Map<String, dynamic>> _achievements = [];
  List<Map<String, dynamic>> _emergencyContacts = [];
  List<Map<String, dynamic>> _galleryMedia = [];

  late TextEditingController _languagesController;
  late TextEditingController _resourcesController;
  late TextEditingController _territoriesCountController;
  
  bool _isEditing = false;
  String? _provinceId;
  bool _isBusy = false; 

  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color redThix = Color(0xFFD32F2F);
  static const Color lightBg = Color(0xFFF6F7FB);

  @override
  void initState() {
    super.initState();
    final p = widget.province;
    _isEditing = p != null;
    _provinceId = p?.id;
    
    _nameController = TextEditingController(text: p?.name ?? '');
    _codeController = TextEditingController(text: p?.code ?? '');
    _capitalController = TextEditingController(text: p?.capital ?? '');
    
    String safeRegion = (p?.region ?? 'Centre').trim();
    if (safeRegion.isNotEmpty) {
      safeRegion = safeRegion[0].toUpperCase() + safeRegion.substring(1).toLowerCase();
    }
    final validRegions = ['Centre', 'Est', 'Ouest', 'Nord', 'Sud'];
    if (!validRegions.contains(safeRegion)) safeRegion = 'Centre';
    _regionController = TextEditingController(text: safeRegion);

    _areaController = TextEditingController(text: p?.area?.toString() ?? '');
    _populationController = TextEditingController(text: p?.population?.toString() ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _coverImageUrlController = TextEditingController(text: p?.coverImageUrl ?? '');
    _coatOfArmsUrlController = TextEditingController(text: p?.coatOfArmsUrl ?? '');
    _mapUrlController = TextEditingController(text: p?.mapUrl ?? '');
    _websiteController = TextEditingController(text: p?.website ?? '');

    _governorController = TextEditingController(text: p?.governor ?? '');
    _governorPhotoController = TextEditingController(text: p?.governorPhotoUrl ?? '');
    _viceGovernorController = TextEditingController(text: p?.viceGovernor ?? '');
    _viceGovernorPhotoController = TextEditingController(text: p?.viceGovernorPhotoUrl ?? '');
    
    _ministers = p?.ministers?.map((m) => {
          'name': m['name']?.toString() ?? '',
          'role': m['role']?.toString() ?? '',
          'photoUrl': m['photoUrl']?.toString() ?? '',
        }).toList() ?? [];

    _tourismSites = p?.tourismSites.map((t) => {'name': t.name, 'type': t.type, 'description': t.description ?? '', 'imageUrl': t.imageUrl ?? ''}).toList() ?? [];
    _emergencyContacts = p?.emergencyContacts.map((e) => {'service': e.service, 'phone': e.phone}).toList() ?? [];

    _languagesController = TextEditingController(text: p?.languages ?? '');
    _resourcesController = TextEditingController(text: p?.resources ?? '');
    _territoriesCountController = TextEditingController(text: p?.territoriesCount?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _capitalController.dispose();
    _regionController.dispose();
    _areaController.dispose();
    _populationController.dispose();
    _descriptionController.dispose();
    _coverImageUrlController.dispose();
    _coatOfArmsUrlController.dispose();
    _mapUrlController.dispose();
    _websiteController.dispose();
    _governorController.dispose();
    _governorPhotoController.dispose();
    _viceGovernorController.dispose();
    _viceGovernorPhotoController.dispose();
    _languagesController.dispose();
    _resourcesController.dispose();
    _territoriesCountController.dispose();
    super.dispose();
  }

  /// 🚀 UPLOAD MULTI-FICHIERS OU FICHIER UNIQUE VERS SUPABASE STORAGE
  Future<void> _pickAndUploadImage(TextEditingController controller, String folderName, {bool multi = false}) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any, 
        allowMultiple: multi,
        withData: true
      );
      
      if (result != null && result.files.isNotEmpty) {
        setState(() => _isBusy = true);
        
        if (multi) {
          // Mode multi-upload (ex: Galerie Média)
          for (var file in result.files) {
            if (file.bytes != null) {
              final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
              final path = '$folderName/$fileName';
              await Supabase.instance.client.storage.from('provinces').uploadBinary(path, file.bytes!, fileOptions: const FileOptions(upsert: true));
              final url = Supabase.instance.client.storage.from('provinces').getPublicUrl(path);
              _galleryMedia.add({'url': url, 'type': file.extension == 'mp4' ? 'video' : 'photo', 'title': file.name});
            }
          }
        } else {
          // Mode fichier unique (ex: Cover, Gouverneur, etc.)
          final file = result.files.first;
          if (file.bytes != null) {
            final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
            final path = '$folderName/$fileName';
            await Supabase.instance.client.storage.from('provinces').uploadBinary(path, file.bytes!, fileOptions: const FileOptions(upsert: true));
            final url = Supabase.instance.client.storage.from('provinces').getPublicUrl(path);
            controller.text = url;
          }
        }

        setState(() => _isBusy = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fichiers uploadés avec succès !'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      setState(() => _isBusy = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'upload : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier la province' : 'Nouvelle province', style: const TextStyle(fontWeight: FontWeight.w700)),
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
                  
                  // SECTION 1 : IDENTITÉ
                  _buildSectionCard(
                    title: 'Identité de la province',
                    icon: Icons.badge,
                    children: [
                      _buildTextField(_nameController, 'Nom de la province *', Icons.map_outlined, validator: _requiredValidator),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_codeController, 'Code (ex: KIN) *', Icons.tag, validator: _requiredValidator, isUppercase: true)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField(_capitalController, 'Capitale *', Icons.location_city, validator: _requiredValidator)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _regionController.text.isNotEmpty ? _regionController.text : 'Centre',
                        decoration: _inputDecoration('Région géographique *', Icons.explore),
                        items: const [
                          DropdownMenuItem(value: 'Centre', child: Text('Centre')),
                          DropdownMenuItem(value: 'Est', child: Text('Est')),
                          DropdownMenuItem(value: 'Ouest', child: Text('Ouest')),
                          DropdownMenuItem(value: 'Nord', child: Text('Nord')),
                          DropdownMenuItem(value: 'Sud', child: Text('Sud')),
                        ],
                        onChanged: (value) => _regionController.text = value ?? 'Centre',
                        validator: (v) => v == null ? 'Champ requis' : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // SECTION 2 : GOUVERNANCE & EXÉCUTIF
                  _buildSectionCard(
                    title: 'Gouvernance & Exécutif Provincial',
                    icon: Icons.account_balance,
                    children: [
                      _buildTextField(_governorController, 'Nom du Gouverneur', Icons.person),
                      const SizedBox(height: 8),
                      _buildUrlWithUploadField(_governorPhotoController, 'Photo du Gouverneur', Icons.image, 'governors'),
                      const SizedBox(height: 16),
                      
                      _buildTextField(_viceGovernorController, 'Nom du Vice-Gouverneur', Icons.person_outline),
                      const SizedBox(height: 8),
                      _buildUrlWithUploadField(_viceGovernorPhotoController, 'Photo du Vice-Gouverneur', Icons.image, 'governors'),
                      const SizedBox(height: 16),

                      _buildTextField(_territoriesCountController, 'Nombre de territoires / Villes', Icons.format_list_numbered, isNumber: true),
                      
                      const Divider(height: 32),
                      
                      // Gestion des Ministres
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Ministres / Membres du gouvernement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: navyDeep)),
                          ElevatedButton.icon(
                            onPressed: () => setState(() => _ministers.add({'name': '', 'role': '', 'photoUrl': ''})),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Ajouter un ministre'),
                            style: ElevatedButton.styleFrom(backgroundColor: navyDeep, foregroundColor: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._ministers.asMap().entries.map((entry) {
                        int index = entry.key;
                        var minister = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Text('Ministre #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: navyDeep)),
                                  const Spacer(),
                                  IconButton(icon: const Icon(Icons.delete, color: redThix, size: 20), onPressed: () => setState(() => _ministers.removeAt(index))),
                                ],
                              ),
                              TextFormField(initialValue: minister['name'], onChanged: (v) => _ministers[index]['name'] = v, decoration: _inputDecoration('Nom complet', Icons.person)),
                              const SizedBox(height: 8),
                              TextFormField(initialValue: minister['role'], onChanged: (v) => _ministers[index]['role'] = v, decoration: _inputDecoration('Portefeuille / Rôle', Icons.work)),
                              const SizedBox(height: 8),
                              TextFormField(initialValue: minister['photoUrl'], onChanged: (v) => _ministers[index]['photoUrl'] = v, decoration: _inputDecoration('URL Photo', Icons.image)),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // SECTION 3 : TOURISME & SITES (Multi-ajout)
                  _buildSectionCard(
                    title: 'Tourisme & Sites Remarquables',
                    icon: Icons.landscape,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Sites touristiques', style: TextStyle(fontWeight: FontWeight.bold, color: navyDeep)),
                          ElevatedButton.icon(
                            onPressed: () => setState(() => _tourismSites.add({'name': '', 'type': '', 'description': '', 'imageUrl': ''})),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Ajouter un site'),
                            style: ElevatedButton.styleFrom(backgroundColor: navyDeep, foregroundColor: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._tourismSites.asMap().entries.map((entry) {
                        int index = entry.key;
                        var site = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                          child: Column(
                            children: [
                              Row(children: [Text('Site #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)), const Spacer(), IconButton(icon: const Icon(Icons.delete, color: redThix, size: 20), onPressed: () => setState(() => _tourismSites.removeAt(index)))]),
                              TextFormField(initialValue: site['name'], onChanged: (v) => _tourismSites[index]['name'] = v, decoration: _inputDecoration('Nom du site', Icons.place)),
                              const SizedBox(height: 8),
                              TextFormField(initialValue: site['type'], onChanged: (v) => _tourismSites[index]['type'] = v, decoration: _inputDecoration('Type (ex: Parc, Cascade)', Icons.category)),
                              const SizedBox(height: 8),
                              TextFormField(initialValue: site['imageUrl'], onChanged: (v) => _tourismSites[index]['imageUrl'] = v, decoration: _inputDecoration('URL Image du site', Icons.image)),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // SECTION 4 : MÉDIAS & GALERIE (Multi-Upload Photos & Vidéos)
                  _buildSectionCard(
                    title: 'Galerie Média (Photos & Vidéos)',
                    icon: Icons.perm_media,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _pickAndUploadImage(TextEditingController(), 'gallery', multi: true),
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Uploader plusieurs photos/vidéos'),
                        style: ElevatedButton.styleFrom(backgroundColor: navyDeep, foregroundColor: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _galleryMedia.asMap().entries.map((entry) {
                          int index = entry.key;
                          var media = entry.value;
                          return Stack(
                            children: [
                              Container(
                                width: 80, height: 80,
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey)),
                                child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(media['url'], fit: BoxFit.cover)),
                              ),
                              Positioned(
                                right: 0, top: 0,
                                child: GestureDetector(
                                  onTap: () => setState(() => _galleryMedia.removeAt(index)),
                                  child: Container(color: Colors.red, child: const Icon(Icons.close, size: 16, color: Colors.white)),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // SECTION 5 : GÉOGRAPHIE & ÉCONOMIE
                  _buildSectionCard(
                    title: 'Géographie, Culture & Économie',
                    icon: Icons.public,
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_areaController, 'Superficie (km²)', Icons.square_foot, isNumber: true)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField(_populationController, 'Population', Icons.groups, isNumber: true)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(_languagesController, 'Langues parlées', Icons.chat_bubble_outline),
                      const SizedBox(height: 12),
                      _buildTextField(_resourcesController, 'Ressources principales', Icons.diamond),
                      const SizedBox(height: 12),
                      _buildTextField(_descriptionController, 'Description détaillée', Icons.description, maxLines: 4),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // SECTION 6 : COUVERTURE & BLASON
                  _buildSectionCard(
                    title: 'Identité Visuelle Officielle',
                    icon: Icons.image,
                    children: [
                      _buildUrlWithUploadField(_coverImageUrlController, 'Photo de couverture', Icons.image, 'covers'),
                      const SizedBox(height: 12),
                      _buildUrlWithUploadField(_coatOfArmsUrlController, 'Blason / Armoiries', Icons.shield, 'emblems'),
                      const SizedBox(height: 12),
                      _buildUrlWithUploadField(_mapUrlController, 'Carte géographique', Icons.map, 'maps'),
                      const SizedBox(height: 12),
                      _buildTextField(_websiteController, 'Site Web officiel', Icons.language),
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
                    child: Text(_isEditing ? 'Enregistrer les modifications' : 'Créer la province', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          if (_isBusy) Container(color: Colors.black.withOpacity(0.4), child: const Center(child: CircularProgressIndicator(color: Colors.white))),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: navyDeep, size: 22), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: navyDeep))]),
          const Divider(height: 24, thickness: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {String? Function(String?)? validator, bool isNumber = false, bool isUppercase = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller, decoration: _inputDecoration(label, icon), validator: validator, maxLines: maxLines, keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: [
        if (isNumber) FilteringTextInputFormatter.digitsOnly,
        if (isUppercase) TextInputFormatter.withFunction((oldValue, newValue) => newValue.copyWith(text: newValue.text.toUpperCase())),
      ],
    );
  }

  Widget _buildUrlWithUploadField(TextEditingController controller, String label, IconData icon, String folderName) {
    return Row(
      children: [
        Expanded(child: _buildTextField(controller, label, icon)),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => _pickAndUploadImage(controller, folderName),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), 
            decoration: BoxDecoration(color: navyDeep.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: navyDeep.withOpacity(0.3))), 
            child: const Icon(Icons.upload_file, color: navyDeep, size: 24)
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label, prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20), filled: true, fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: navyDeep, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  String? _requiredValidator(String? value) => (value == null || value.trim().isEmpty) ? 'Ce champ est requis' : null;
  
  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isBusy = true);

    final province = Province(
      id: _provinceId ?? '',
      name: _nameController.text.trim(),
      code: _codeController.text.trim(),
      capital: _capitalController.text.trim(),
      region: _regionController.text.trim(),
      area: int.tryParse(_areaController.text.trim()),
      population: int.tryParse(_populationController.text.trim()),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      coverImageUrl: _coverImageUrlController.text.trim().isEmpty ? null : _coverImageUrlController.text.trim(),
      coatOfArmsUrl: _coatOfArmsUrlController.text.trim().isEmpty ? null : _coatOfArmsUrlController.text.trim(),
      mapUrl: _mapUrlController.text.trim().isEmpty ? null : _mapUrlController.text.trim(),
      website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
      governor: _governorController.text.trim().isEmpty ? null : _governorController.text.trim(),
      governorPhotoUrl: _governorPhotoController.text.trim().isEmpty ? null : _governorPhotoController.text.trim(),
      viceGovernor: _viceGovernorController.text.trim().isEmpty ? null : _viceGovernorController.text.trim(),
      viceGovernorPhotoUrl: _viceGovernorPhotoController.text.trim().isEmpty ? null : _viceGovernorPhotoController.text.trim(),
      ministers: _ministers.where((m) => (m['name'] ?? '').trim().isNotEmpty).toList(),
      languages: _languagesController.text.trim().isEmpty ? null : _languagesController.text.trim(),
      resources: _resourcesController.text.trim().isEmpty ? null : _resourcesController.text.trim(),
      territoriesCount: int.tryParse(_territoriesCountController.text.trim()),
    );
    
    final notifier = ref.read(adminProvincesProvider.notifier);
    
    try {
      if (_isEditing) {
        await notifier.updateProvince(province);
      } else {
        await notifier.createProvince(province);
      }
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _isBusy = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red));
    }
  }
}
