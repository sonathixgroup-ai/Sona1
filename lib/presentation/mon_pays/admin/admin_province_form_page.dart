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

  // Gouvernance avancée & Ministres
  late TextEditingController _governorController;
  late TextEditingController _governorPhotoController;
  late TextEditingController _viceGovernorController;
  late TextEditingController _viceGovernorPhotoController;
  
  // Liste des ministres provinciaux (Nom, Rôle/Portefeuille, PhotoUrl)
  List<Map<String, String>> _ministers = [];

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
    
    // 🛡️ SÉCURISATION DU DROPDOWN DE LA RÉGION (Anti-crash)
    String safeRegion = (p?.region ?? 'Centre').trim();
    if (safeRegion.isNotEmpty) {
      safeRegion = safeRegion[0].toUpperCase() + safeRegion.substring(1).toLowerCase();
    }
    final validRegions = ['Centre', 'Est', 'Ouest', 'Nord', 'Sud'];
    if (!validRegions.contains(safeRegion)) {
      safeRegion = 'Centre';
    }
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
    
    // Charger les ministres si existants dans le modèle (ou liste vide)
    _ministers = p?.ministers?.map((m) => {
          'name': m['name']?.toString() ?? '',
          'role': m['role']?.toString() ?? '',
          'photoUrl': m['photoUrl']?.toString() ?? '',
        }).toList() ?? [];

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

  /// 🚀 UPLOAD RÉEL VERS SUPABASE STORAGE (Au lieu du mock-up)
  Future<void> _pickAndUploadImage(TextEditingController controller, String folderName) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image, 
        withData: true
      );
      
      if (result != null && result.files.first.bytes != null) {
        setState(() => _isBusy = true);
        
        final fileBytes = result.files.first.bytes!;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${result.files.first.name}';
        final path = '$folderName/$fileName';

        // Upload réel vers le bucket Supabase Storage nommé "provinces" (adaptez le nom du bucket si besoin)
        await Supabase.instance.client.storage
            .from('provinces')
            .uploadBinary(path, fileBytes, fileOptions: const FileOptions(upsert: true));

        // Récupération de l'URL publique
        final imageUrl = Supabase.instance.client.storage
            .from('provinces')
            .getPublicUrl(path);

        setState(() { 
          controller.text = imageUrl; 
          _isBusy = false; 
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image uploadée avec succès !'), backgroundColor: Colors.green),
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

  void _addMinister() {
    setState(() {
      _ministers.add({'name': '', 'role': '', 'photoUrl': ''});
    });
  }

  void _removeMinister(int index) {
    setState(() {
      _ministers.removeAt(index);
    });
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
                  
                  // SECTION 2 : GOUVERNANCE & EXécutif (Gouverneur, Vice-Gouverneur & Ministres)
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
                      
                      // Liste des ministres provinciaux
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Ministres / Membres du gouvernement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: navyDeep)),
                          ElevatedButton.icon(
                            onPressed: _addMinister,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Ajouter un ministre'),
                            style: ElevatedButton.styleFrom(backgroundColor: navyDeep, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_ministers.isEmpty)
                        const Text('Aucun ministre ajouté pour le moment.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                      
                      ..._ministers.asMap().entries.map((entry) {
                        int index = entry.key;
                        var minister = entry.value;
                        
                        // Contrôleurs locaux pour la gestion de la liste
                        final nameCtrl = TextEditingController(text: minister['name']);
                        final roleCtrl = TextEditingController(text: minister['role']);
                        final photoCtrl = TextEditingController(text: minister['photoUrl']);

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
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: redThix, size: 20),
                                    onPressed: () => _removeMinister(index),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: nameCtrl,
                                onChanged: (v) => _ministers[index]['name'] = v,
                                decoration: _inputDecoration('Nom complet du ministre', Icons.person),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: roleCtrl,
                                onChanged: (v) => _ministers[index]['role'] = v,
                                decoration: _inputDecoration('Portefeuille / Ministère (ex: Ministre de l\'Intérieur)', Icons.work),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: photoCtrl,
                                      onChanged: (v) => _ministers[index]['photoUrl'] = v,
                                      decoration: _inputDecoration('URL Photo du ministre', Icons.image),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.upload_file, color: navyDeep),
                                    onPressed: () async {
                                      // Upload direct pour le ministre
                                      try {
                                        FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
                                        if (result != null && result.files.first.bytes != null) {
                                          setState(() => _isBusy = true);
                                          final bytes = result.files.first.bytes!;
                                          final name = 'minister_${DateTime.now().millisecondsSinceEpoch}.jpg';
                                          const path = 'ministers';
                                          await Supabase.instance.client.storage.from('provinces').uploadBinary('$path/$name', bytes);
                                          final url = Supabase.instance.client.storage.from('provinces').getPublicUrl('$path/$name');
                                          setState(() {
                                            _ministers[index]['photoUrl'] = url;
                                            _isBusy = false;
                                          });
                                        }
                                      } catch (e) {
                                        setState(() => _isBusy = false);
                                      }
                                    },
                                  )
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // SECTION 3 : GÉOGRAPHIE & DÉMOGRAPHIE
                  _buildSectionCard(
                    title: 'Géographie & Culture',
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
                      _buildTextField(_languagesController, 'Langues parlées (ex: Lingala, Swahili)', Icons.chat_bubble_outline),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // SECTION 4 : ÉCONOMIE & PRÉSENTATION
                  _buildSectionCard(
                    title: 'Économie & Présentation',
                    icon: Icons.monetization_on,
                    children: [
                      _buildTextField(_resourcesController, 'Ressources principales (ex: Cuivre, Café)', Icons.diamond),
                      const SizedBox(height: 12),
                      _buildTextField(_descriptionController, 'Description détaillée de la province', Icons.description, maxLines: 4),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // SECTION 5 : MÉDIAS
                  _buildSectionCard(
                    title: 'Médias & Liens',
                    icon: Icons.perm_media,
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
      if (mounted) context.go('/... '); // Laissez votre logique de navigation ou context.pop()
    } catch (e) {
      setState(() => _isBusy = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red));
    }
  }
}
