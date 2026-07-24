// lib/presentation/mon_pays/admin/admin_province_form_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';

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

  late TextEditingController _governorController;
  late TextEditingController _viceGovernorController;
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
      // Met la première lettre en majuscule, le reste en minuscule (ex: "SUD" -> "Sud")
      safeRegion = safeRegion[0].toUpperCase() + safeRegion.substring(1).toLowerCase();
    }
    final validRegions = ['Centre', 'Est', 'Ouest', 'Nord', 'Sud'];
    if (!validRegions.contains(safeRegion)) {
      safeRegion = 'Centre'; // Valeur par défaut si la donnée en DB est corrompue
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
    _viceGovernorController = TextEditingController(text: p?.viceGovernor ?? '');
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
    _viceGovernorController.dispose();
    _languagesController.dispose();
    _resourcesController.dispose();
    _territoriesCountController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage(TextEditingController controller, String folderName) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
      if (result != null && result.files.first.bytes != null) {
        setState(() => _isBusy = true);
        
        // Simulation d'upload
        await Future.delayed(const Duration(seconds: 2));
        final url = 'https://picsum.photos/800/600?random=${DateTime.now().millisecondsSinceEpoch}';

        setState(() { controller.text = url; _isBusy = false; });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image uploadée'), backgroundColor: Colors.green));
      }
    } catch (e) {
      setState(() => _isBusy = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
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
                  
                  // SECTION 2 : GOUVERNANCE
                  _buildSectionCard(
                    title: 'Gouvernance & Administration',
                    icon: Icons.account_balance,
                    children: [
                      _buildTextField(_governorController, 'Gouverneur actuel', Icons.person),
                      const SizedBox(height: 12),
                      _buildTextField(_viceGovernorController, 'Vice-Gouverneur', Icons.person_outline),
                      const SizedBox(height: 12),
                      _buildTextField(_territoriesCountController, 'Nombre de territoires / Villes', Icons.format_list_numbered, isNumber: true),
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
                      _buildUrlWithUploadField(_coverImageUrlController, 'Photo de couverture', Icons.image, 'provinces_covers'),
                      const SizedBox(height: 12),
                      _buildUrlWithUploadField(_coatOfArmsUrlController, 'Blason / Armoiries', Icons.shield, 'provinces_emblems'),
                      const SizedBox(height: 12),
                      _buildUrlWithUploadField(_mapUrlController, 'Carte géographique', Icons.map, 'provinces_maps'),
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
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: navyDeep.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: navyDeep.withOpacity(0.3))), child: const Icon(Icons.upload_file, color: navyDeep, size: 24)),
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
      viceGovernor: _viceGovernorController.text.trim().isEmpty ? null : _viceGovernorController.text.trim(),
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
