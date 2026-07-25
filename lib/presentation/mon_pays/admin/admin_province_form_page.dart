// lib/presentation/mon_pays/admin/admin_province_form_page.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/province.dart';
import '../models/city.dart';
import '../models/province_economic.dart';
import '../models/province_tourism.dart';
import '../models/province_emergency.dart';
import '../models/province_administrative.dart';
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

  // Nouveaux champs institutionnels et historiques majeurs
  late TextEditingController _historyController;
  late TextEditingController _climateController;
  late TextEditingController _infrastructureController;
  late TextEditingController _educationController;

  // Identité visuelle
  String? _coverImageUrl;
  String? _coatOfArmsUrl;
  String? _mapUrl;
  late TextEditingController _websiteController;

  // Gouvernance Exécutif
  late TextEditingController _governorController;
  String? _governorPhotoUrl;
  late TextEditingController _viceGovernorController;
  String? _viceGovernorPhotoUrl;
  
  // Listes dynamiques enrichies (avec multi-médias)
  List<Map<String, dynamic>> _ministers = [];
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _economicSectors = [];
  List<Map<String, dynamic>> _tourismSites = [];
  List<Map<String, dynamic>> _emergencyContacts = [];
  List<Map<String, dynamic>> _administrativeDivisions = [];
  List<Map<String, dynamic>> _achievements = [];
  List<Map<String, dynamic>> _tribes = []; // Rubrique Culture & Tribus enrichie
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

    // Initialisation des nouveaux grands champs
    _historyController = TextEditingController(text: p?.history ?? '');
    _climateController = TextEditingController(text: p?.climate ?? '');
    _infrastructureController = TextEditingController(text: p?.infrastructure ?? '');
    _educationController = TextEditingController(text: p?.education ?? '');
    
    _coverImageUrl = p?.coverImageUrl;
    _coatOfArmsUrl = p?.coatOfArmsUrl;
    _mapUrl = p?.mapUrl;
    _websiteController = TextEditingController(text: p?.website ?? '');

    _governorController = TextEditingController(text: p?.governor ?? '');
    _governorPhotoUrl = p?.governorPhotoUrl;
    _viceGovernorController = TextEditingController(text: p?.viceGovernor ?? '');
    _viceGovernorPhotoUrl = p?.viceGovernorPhotoUrl;
    
    _ministers = p?.ministers?.map((m) => {'name': m['name'] ?? '', 'role': m['role'] ?? '', 'photoUrl': m['photoUrl'] ?? ''}).toList() ?? [];
    
    _cities = p?.cities.map((c) => {
      'name': c.name, 'population': c.population?.toString() ?? '', 'isCapital': c.isCapital,
      'mayor': c.mayor ?? '', 'mayorPhotoUrl': c.mayorPhotoUrl ?? '',
      'media': c.media != null ? List<Map<String, dynamic>>.from(c.media!) : (c.imageUrl != null ? [{'url': c.imageUrl, 'type': 'photo'}] : []),
    }).toList() ?? [];

    _economicSectors = p?.economicResources.map((e) => {
      'name': e.name, 'description': e.description ?? '',
      'media': e.media != null ? List<Map<String, dynamic>>.from(e.media!) : (e.imageUrl != null ? [{'url': e.imageUrl, 'type': 'photo'}] : []),
    }).toList() ?? [];

    _tourismSites = p?.tourismSites.map((t) => {
      'name': t.name, 'type': t.type, 'description': t.description ?? '',
      'media': t.media != null ? List<Map<String, dynamic>>.from(t.media!) : (t.imageUrl != null ? [{'url': t.imageUrl, 'type': 'photo'}] : []),
    }).toList() ?? [];

    _emergencyContacts = p?.emergencyContacts.map((e) => {'service': e.service, 'phone': e.phone}).toList() ?? [];
    
    _administrativeDivisions = p?.administrativeDivisions.map((a) => {
      'type': a.type, 'name': a.name, 'capital': a.capital ?? '', 'population': a.population?.toString() ?? '',
      'area': a.area?.toString() ?? '', 'administrator': a.administrator ?? '',
      'media': a.media != null ? List<Map<String, dynamic>>.from(a.media!) : [],
    }).toList() ?? [];

    _achievements = p?.achievements?.map((a) => {
      'title': a['title'] ?? '', 'description': a['description'] ?? '', 'date': a['date'] ?? '', 'location': a['location'] ?? '',
      'media': a['media'] != null ? List<Map<String, dynamic>>.from(a['media']) : (a['imageUrl'] != null ? [{'url': a['imageUrl'], 'type': 'photo'}] : []),
    }).toList() ?? [];

    // Chargement des tribus et peuples
    _tribes = p?.tribes?.map((tr) => {
      'name': tr['name'] ?? '',
      'zone': tr['zone'] ?? '',
      'history': tr['history'] ?? '',
      'media': tr['media'] != null ? List<Map<String, dynamic>>.from(tr['media']) : [],
    }).toList() ?? [];

    _galleryMedia = p?.galleryMedia?.map((m) => Map<String, dynamic>.from(m)).toList() ?? [];

    _languagesController = TextEditingController(text: p?.languages ?? '');
    _resourcesController = TextEditingController(text: p?.resources ?? '');
    _territoriesCountController = TextEditingController(text: p?.territoriesCount?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose(); _codeController.dispose(); _capitalController.dispose();
    _regionController.dispose(); _areaController.dispose(); _populationController.dispose();
    _descriptionController.dispose(); _historyController.dispose(); _climateController.dispose();
    _infrastructureController.dispose(); _educationController.dispose(); _websiteController.dispose();
    _governorController.dispose(); _viceGovernorController.dispose(); _languagesController.dispose();
    _resourcesController.dispose(); _territoriesCountController.dispose();
    super.dispose();
  }

  /// 🚀 UPLOAD MULTI-MÉDIAS (Photos & Vidéos)
  Future<void> _uploadMultiFiles(String folderName, Function(String url, String type) onUploaded) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.media, allowMultiple: true, withData: true);
      if (result != null && result.files.isNotEmpty) {
        setState(() => _isBusy = true);
        for (var file in result.files) {
          if (file.bytes != null) {
            final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
            final path = '$folderName/$fileName';
            final ext = file.extension?.toLowerCase() ?? '';
            final type = (ext == 'mp4' || ext == 'mov' || ext == 'avi') ? 'video' : 'photo';
            await Supabase.instance.client.storage.from('provinces').uploadBinary(path, file.bytes!, fileOptions: const FileOptions(upsert: true));
            final url = Supabase.instance.client.storage.from('provinces').getPublicUrl(path);
            onUploaded(url, type);
          }
        }
        setState(() => _isBusy = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Médias ajoutés avec succès !'), backgroundColor: Colors.green));
      }
    } catch (e) {
      setState(() => _isBusy = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red));
    }
  }

  /// 🚀 UPLOAD FICHIER UNIQUE (ex: Photo profil)
  Future<void> _uploadSingleFile(String folderName, Function(String url) onUploaded) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
      if (result != null && result.files.first.bytes != null) {
        setState(() => _isBusy = true);
        final file = result.files.first;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        final path = '$folderName/$fileName';
        await Supabase.instance.client.storage.from('provinces').uploadBinary(path, file.bytes!, fileOptions: const FileOptions(upsert: true));
        final url = Supabase.instance.client.storage.from('provinces').getPublicUrl(path);
        onUploaded(url);
        setState(() => _isBusy = false);
      }
    } catch (e) {
      setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(title: Text(_isEditing ? 'Modifier la province' : 'Nouvelle province', style: const TextStyle(fontWeight: FontWeight.w700)), backgroundColor: redThix, foregroundColor: Colors.white, elevation: 0),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionCard(title: 'Identité de la province', icon: Icons.badge, children: [
                    _buildTextField(_nameController, 'Nom de la province *', Icons.map_outlined, validator: _requiredValidator),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _buildTextField(_codeController, 'Code (ex: KIN) *', Icons.tag, validator: _requiredValidator, isUppercase: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField(_capitalController, 'Capitale *', Icons.location_city, validator: _requiredValidator)),
                    ]),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _regionController.text.isNotEmpty ? _regionController.text : 'Centre',
                      decoration: _inputDecoration('Région géographique *', Icons.explore),
                      items: const [DropdownMenuItem(value: 'Centre', child: Text('Centre')), DropdownMenuItem(value: 'Est', child: Text('Est')), DropdownMenuItem(value: 'Ouest', child: Text('Ouest')), DropdownMenuItem(value: 'Nord', child: Text('Nord')), DropdownMenuItem(value: 'Sud', child: Text('Sud'))],
                      onChanged: (value) => _regionController.text = value ?? 'Centre',
                      validator: (v) => v == null ? 'Champ requis' : null,
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // 🏛️ NOUVEAUX CHAMPS INSTITUTIONNELS & HISTORIQUES MAJEURS
                  _buildSectionCard(title: 'Histoire, Climat & Infrastructures', icon: Icons.history_edu, children: [
                    _buildTextField(_historyController, 'Historique complet & Origines de la province', Icons.menu_book, maxLines: 4),
                    const SizedBox(height: 12),
                    _buildTextField(_climateController, 'Climat, Relief & Environnement', Icons.wb_sunny, maxLines: 3),
                    const SizedBox(height: 12),
                    _buildTextField(_infrastructureController, 'Infrastructures, Transports & Énergie', Icons.bolt, maxLines: 3),
                    const SizedBox(height: 12),
                    _buildTextField(_educationController, 'Éducation, Recherche & Santé', Icons.school, maxLines: 3),
                  ]),
                  const SizedBox(height: 16),
                  
                  _buildSectionCard(title: 'Gouvernance & Exécutif Provincial', icon: Icons.account_balance, children: [
                    _buildTextField(_governorController, 'Nom du Gouverneur', Icons.person), const SizedBox(height: 8),
                    _buildImagePickerRow('Photo du Gouverneur', _governorPhotoUrl, 'governors', (url) => setState(() => _governorPhotoUrl = url)), const SizedBox(height: 16),
                    _buildTextField(_viceGovernorController, 'Nom du Vice-Gouverneur', Icons.person_outline), const SizedBox(height: 8),
                    _buildImagePickerRow('Photo du Vice-Gouverneur', _viceGovernorPhotoUrl, 'governors', (url) => setState(() => _viceGovernorPhotoUrl = url)), const SizedBox(height: 16),
                    _buildTextField(_territoriesCountController, 'Nombre de territoires / Villes', Icons.format_list_numbered, isNumber: true),
                    const Divider(height: 32),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Ministres', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: navyDeep)),
                      ElevatedButton.icon(onPressed: () => setState(() => _ministers.add({'name': '', 'role': '', 'photoUrl': ''})), icon: const Icon(Icons.add, size: 16), label: const Text('Ajouter'), style: ElevatedButton.styleFrom(backgroundColor: navyDeep, foregroundColor: Colors.white)),
                    ]),
                    const SizedBox(height: 12),
                    ..._ministers.asMap().entries.map((entry) {
                      int index = entry.key; var minister = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                        child: Column(children: [
                          Row(children: [Text('Ministre #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)), const Spacer(), IconButton(icon: const Icon(Icons.delete, color: redThix, size: 20), onPressed: () => setState(() => _ministers.removeAt(index)))]),
                          TextFormField(initialValue: minister['name'], onChanged: (v) => _ministers[index]['name'] = v, decoration: _inputDecoration('Nom complet', Icons.person)), const SizedBox(height: 8),
                          TextFormField(initialValue: minister['role'], onChanged: (v) => _ministers[index]['role'] = v, decoration: _inputDecoration('Portefeuille / Rôle', Icons.work)), const SizedBox(height: 8),
                          _buildImagePickerRow('Photo du Ministre', minister['photoUrl'], 'ministers', (url) => setState(() => _ministers[index]['photoUrl'] = url)),
                        ]),
                      );
                    }),
                  ]),
                  const SizedBox(height: 16),

                  // 🌍 CULTURE & TRIBUS ENRICHIES (Nom, Zone, Histoire, Galerie Photos & Vidéos)
                  _buildSectionCard(title: 'Culture, Langues & Peuples / Tribus', icon: Icons.people, children: [
                    _buildTextField(_languagesController, 'Langues parlées', Icons.chat_bubble_outline), const SizedBox(height: 12),
                    _buildTextField(_resourcesController, 'Ressources principales', Icons.diamond), const SizedBox(height: 12),
                    _buildTextField(_descriptionController, 'Description générale & Traditions', Icons.description, maxLines: 3),
                    const Divider(height: 32),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Peuples & Tribus de la Province', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: navyDeep)),
                      ElevatedButton.icon(
                        onPressed: () => setState(() => _tribes.add({'name': '', 'zone': '', 'history': '', 'media': []})),
                        icon: const Icon(Icons.add, size: 16), label: const Text('Ajouter une tribu'),
                        style: ElevatedButton.styleFrom(backgroundColor: navyDeep, foregroundColor: Colors.white),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    ..._tribes.asMap().entries.map((entry) {
                      int index = entry.key; var tribe = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                        child: Column(children: [
                          Row(children: [Text('Tribu / Peuple #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: navyDeep)), const Spacer(), IconButton(icon: const Icon(Icons.delete, color: redThix, size: 20), onPressed: () => setState(() => _tribes.removeAt(index)))]),
                          const SizedBox(height: 8),
                          TextFormField(initialValue: tribe['name'], onChanged: (v) => _tribes[index]['name'] = v, decoration: _inputDecoration('Nom de la tribu / ethnie', Icons.group)), const SizedBox(height: 8),
                          TextFormField(initialValue: tribe['zone'], onChanged: (v) => _tribes[index]['zone'] = v, decoration: _inputDecoration('Zone géographique / Territoire d\'origine', Icons.place)), const SizedBox(height: 8),
                          TextFormField(initialValue: tribe['history'], onChanged: (v) => _tribes[index]['history'] = v, maxLines: 3, decoration: _inputDecoration('Histoire, origines & coutumes', Icons.menu_book)), const SizedBox(height: 8),
                          _buildMultiMediaGallery('Photos & Vidéos de la tribu', tribe['media'], 'tribes', () => setState((){})),
                        ]),
                      );
                    }),
                  ]),
                  const SizedBox(height: 16),

                  _buildSectionCard(title: 'Villes Principales (avec Galerie)', icon: Icons.location_city, children: [
                    Align(alignment: Alignment.centerRight, child: ElevatedButton.icon(onPressed: () => setState(() => _cities.add({'name': '', 'population': '', 'isCapital': false, 'mayor': '', 'mayorPhotoUrl': '', 'media': []})), icon: const Icon(Icons.add, size: 16), label: const Text('Ajouter une ville'), style: ElevatedButton.styleFrom(backgroundColor: navyDeep, foregroundColor: Colors.white))),
                    const SizedBox(height: 12),
                    ..._cities.asMap().entries.map((entry) {
                      int index = entry.key; var city = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [Text('Ville #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: navyDeep)), const Spacer(), Switch(value: city['isCapital'] ?? false, onChanged: (v) => setState(() => _cities[index]['isCapital'] = v), activeColor: redThix), const Text('Chef-lieu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.delete, color: redThix, size: 20), onPressed: () => setState(() => _cities.removeAt(index)))]),
                          const SizedBox(height: 8),
                          TextFormField(initialValue: city['name'], onChanged: (v) => _cities[index]['name'] = v, decoration: _inputDecoration('Nom de la ville', Icons.location_city)), const SizedBox(height: 8),
                          TextFormField(initialValue: city['population'], onChanged: (v) => _cities[index]['population'] = v, keyboardType: TextInputType.number, decoration: _inputDecoration('Population', Icons.groups)), const SizedBox(height: 8),
                          _buildMultiMediaGallery('Galerie Photos/Vidéos de la ville', city['media'], 'cities', () => setState((){})), const Divider(height: 20),
                          TextFormField(initialValue: city['mayor'], onChanged: (v) => _cities[index]['mayor'] = v, decoration: _inputDecoration('Autorité (Maire / Bourgmestre)', Icons.person)), const SizedBox(height: 8),
                          _buildImagePickerRow('Photo de l\'autorité', city['mayorPhotoUrl'], 'mayors', (url) => setState(() => _cities[index]['mayorPhotoUrl'] = url)),
                        ]),
                      );
                    }),
                  ]),
                  const SizedBox(height: 16),

                  _buildSectionCard(title: 'Économie & Secteurs Clés', icon: Icons.monetization_on, children: [
                    Align(alignment: Alignment.centerRight, child: ElevatedButton.icon(onPressed: () => setState(() => _economicSectors.add({'name': '', 'description': '', 'media': []})), icon: const Icon(Icons.add, size: 16), label: const Text('Ajouter un secteur'), style: ElevatedButton.styleFrom(backgroundColor: navyDeep, foregroundColor: Colors.white))),
                    const SizedBox(height: 12),
                    ..._economicSectors.asMap().entries.map((entry) {
                      int index = entry.key; var sector = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                        child: Column(children: [
                          Row(children: [Text('Secteur #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)), const Spacer(), IconButton(icon: const Icon(Icons.delete, color: redThix, size: 20), onPressed: () => setState(() => _economicSectors.removeAt(index)))]),
                          TextFormField(initialValue: sector['name'], onChanged: (v) => _economicSectors[index]['name'] = v, decoration: _inputDecoration('Nom du secteur', Icons.business)), const SizedBox(height: 8),
                          TextFormField(initialValue: sector['description'], onChanged: (v) => _economicSectors[index]['description'] = v, maxLines: 2, decoration: _inputDecoration('Détails', Icons.notes)), const SizedBox(height: 8),
                          _buildMultiMediaGallery('Photos & Vidéos du secteur', sector['media'], 'economy', () => setState((){})),
                        ]),
                      );
                    }),
                  ]),
                  const SizedBox(height: 16),

                  _buildSectionCard(title: 'Tourisme & Sites Remarquables', icon: Icons.landscape, children: [
                    Align(alignment: Alignment.centerRight, child: ElevatedButton.icon(onPressed: () => setState(() => _tourismSites.add({'name': '', 'type': '', 'description': '', 'media': []})), icon: const Icon(Icons.add, size: 16), label: const Text('Ajouter un site'), style: ElevatedButton.styleFrom(backgroundColor: navyDeep, foregroundColor: Colors.white))),
                    const SizedBox(height: 12),
                    ..._tourismSites.asMap().entries.map((entry) {
                      int index = entry.key; var site = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                        child: Column(children: [
                          Row(children: [Text('Site #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)), const Spacer(), IconButton(icon: const Icon(Icons.delete, color: redThix, size: 20), onPressed: () => setState(() => _tourismSites.removeAt(index)))]),
                          TextFormField(initialValue: site['name'], onChanged: (v) => _tourismSites[index]['name'] = v, decoration: _inputDecoration('Nom du site', Icons.place)), const SizedBox(height: 8),
                          TextFormField(initialValue: site['type'], onChanged: (v) => _tourismSites[index]['type'] = v, decoration: _inputDecoration('Type (ex: Parc, Cascade)', Icons.category)), const SizedBox(height: 8),
                          TextFormField(initialValue: site['description'], onChanged: (v) => _tourismSites[index]['description'] = v, maxLines: 2, decoration: _inputDecoration('Description', Icons.description)), const SizedBox(height: 8),
                          _buildMultiMediaGallery('Galerie du site', site['media'], 'tourism', () => setState((){})),
                        ]),
                      );
                    }),
                  ]),
                  const SizedBox(height: 16),

                  _buildSectionCard(title: 'Découpage Administratif (Détaillé)', icon: Icons.dashboard_customize, children: [
                    Align(alignment: Alignment.centerRight, child: ElevatedButton.icon(onPressed: () => setState(() => _administrativeDivisions.add({'type': 'Territoire', 'name': '', 'capital': '', 'population': '', 'area': '', 'administrator': '', 'media': []})), icon: const Icon(Icons.add, size: 16), label: const Text('Ajouter une division'), style: ElevatedButton.styleFrom(backgroundColor: navyDeep, foregroundColor: Colors.white))),
                    const SizedBox(height: 12),
                    ..._administrativeDivisions.asMap().entries.map((entry) {
                      int index = entry.key; var div = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                        child: Column(children: [
                          Row(children: [Text('Division #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)), const Spacer(), IconButton(icon: const Icon(Icons.delete, color: redThix, size: 20), onPressed: () => setState(() => _administrativeDivisions.removeAt(index)))]),
                          Row(children: [Expanded(child: TextFormField(initialValue: div['type'], onChanged: (v) => _administrativeDivisions[index]['type'] = v, decoration: _inputDecoration('Type (Territoire, Commune)', Icons.category))), const SizedBox(width: 8), Expanded(child: TextFormField(initialValue: div['name'], onChanged: (v) => _administrativeDivisions[index]['name'] = v, decoration: _inputDecoration('Nom', Icons.place)))]), const SizedBox(height: 8),
                          TextFormField(initialValue: div['capital'], onChanged: (v) => _administrativeDivisions[index]['capital'] = v, decoration: _inputDecoration('Chef-lieu', Icons.star)), const SizedBox(height: 8),
                          Row(children: [Expanded(child: TextFormField(initialValue: div['population'], onChanged: (v) => _administrativeDivisions[index]['population'] = v, keyboardType: TextInputType.number, decoration: _inputDecoration('Population', Icons.groups))), const SizedBox(width: 8), Expanded(child: TextFormField(initialValue: div['area'], onChanged: (v) => _administrativeDivisions[index]['area'] = v, keyboardType: TextInputType.number, decoration: _inputDecoration('Superficie (km²)', Icons.map)))]), const SizedBox(height: 8),
                          TextFormField(initialValue: div['administrator'], onChanged: (v) => _administrativeDivisions[index]['administrator'] = v, decoration: _inputDecoration('Nom de l\'Administrateur', Icons.person)), const SizedBox(height: 8),
                          _buildMultiMediaGallery('Photos & Vidéos', div['media'], 'admin_divisions', () => setState((){})),
                        ]),
                      );
                    }),
                  ]),
                  const SizedBox(height: 16),

                  _buildSectionCard(title: 'Réalisations & Projets Majeurs', icon: Icons.emoji_events, children: [
                    Align(alignment: Alignment.centerRight, child: ElevatedButton.icon(onPressed: () => setState(() => _achievements.add({'title': '', 'description': '', 'date': '', 'location': '', 'media': []})), icon: const Icon(Icons.add, size: 16), label: const Text('Ajouter une réalisation'), style: ElevatedButton.styleFrom(backgroundColor: navyDeep, foregroundColor: Colors.white))),
                    const SizedBox(height: 12),
                    ..._achievements.asMap().entries.map((entry) {
                      int index = entry.key; var ach = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                        child: Column(children: [
                          Row(children: [Text('Projet #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)), const Spacer(), IconButton(icon: const Icon(Icons.delete, color: redThix, size: 20), onPressed: () => setState(() => _achievements.removeAt(index)))]),
                          TextFormField(initialValue: ach['title'], onChanged: (v) => _achievements[index]['title'] = v, decoration: _inputDecoration('Titre du projet', Icons.title)), const SizedBox(height: 8),
                          Row(children: [Expanded(child: TextFormField(initialValue: ach['date'], onChanged: (v) => _achievements[index]['date'] = v, decoration: _inputDecoration('Date', Icons.calendar_today))), const SizedBox(width: 8), Expanded(child: TextFormField(initialValue: ach['location'], onChanged: (v) => _achievements[index]['location'] = v, decoration: _inputDecoration('Lieu', Icons.location_on)))]), const SizedBox(height: 8),
                          TextFormField(initialValue: ach['description'], onChanged: (v) => _achievements[index]['description'] = v, maxLines: 2, decoration: _inputDecoration('Description détaillée', Icons.description)), const SizedBox(height: 8),
                          _buildMultiMediaGallery('Galerie du projet', ach['media'], 'achievements', () => setState((){})),
                        ]),
                      );
                    }),
                  ]),
                  const SizedBox(height: 16),

                  _buildSectionCard(title: 'Urgences & Contacts Utiles', icon: Icons.emergency, children: [
                    Align(alignment: Alignment.centerRight, child: ElevatedButton.icon(onPressed: () => setState(() => _emergencyContacts.add({'service': '', 'phone': ''})), icon: const Icon(Icons.add, size: 16), label: const Text('Ajouter'), style: ElevatedButton.styleFrom(backgroundColor: navyDeep, foregroundColor: Colors.white))),
                    const SizedBox(height: 12),
                    ..._emergencyContacts.asMap().entries.map((entry) {
                      int index = entry.key; var emergency = entry.value;
                      return Container(margin: const EdgeInsets.only(bottom: 8), child: Row(children: [
                        Expanded(child: TextFormField(initialValue: emergency['service'], onChanged: (v) => _emergencyContacts[index]['service'] = v, decoration: _inputDecoration('Service', Icons.local_hospital))), const SizedBox(width: 8),
                        Expanded(child: TextFormField(initialValue: emergency['phone'], onChanged: (v) => _emergencyContacts[index]['phone'] = v, decoration: _inputDecoration('Numéro', Icons.phone))),
                        IconButton(icon: const Icon(Icons.delete, color: redThix), onPressed: () => setState(() => _emergencyContacts.removeAt(index))),
                      ]));
                    }),
                  ]),
                  const SizedBox(height: 16),

                  _buildSectionCard(title: 'Galerie Média Globale (Photos & Vidéos)', icon: Icons.perm_media, children: [
                    _buildMultiMediaGallery('Tous les médias de la province', _galleryMedia, 'gallery', () => setState((){})),
                  ]),
                  const SizedBox(height: 16),

                  _buildSectionCard(title: 'Identité Visuelle Officielle', icon: Icons.image, children: [
                    _buildImagePickerRow('Photo de couverture', _coverImageUrl, 'covers', (url) => setState(() => _coverImageUrl = url)), const SizedBox(height: 12),
                    _buildImagePickerRow('Blason / Armoiries', _coatOfArmsUrl, 'emblems', (url) => setState(() => _coatOfArmsUrl = url)), const SizedBox(height: 12),
                    _buildImagePickerRow('Carte géographique', _mapUrl, 'maps', (url) => setState(() => _mapUrl = url)), const SizedBox(height: 12),
                    _buildTextField(_websiteController, 'Site Web officiel', Icons.language),
                  ]),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _isBusy ? null : _save,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: navyDeep, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 2),
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

  /// WIDGET : Galerie Multi-médias (Photos & Vidéos)
  Widget _buildMultiMediaGallery(String label, List<dynamic> mediaList, String folder, VoidCallback onUpdate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: navyDeep)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: [
            ...mediaList.asMap().entries.map((entry) {
              int idx = entry.key; var m = entry.value;
              bool isVideo = m['type'] == 'video';
              return Stack(
                children: [
                  Container(
                    width: 70, height: 70,
                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: isVideo ? const Icon(Icons.videocam, color: Colors.grey, size: 30) : Image.network(m['url'], fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(right: 0, top: 0, child: GestureDetector(onTap: () { mediaList.removeAt(idx); onUpdate(); }, child: Container(decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), padding: const EdgeInsets.all(4), child: const Icon(Icons.close, size: 12, color: Colors.white)))),
                ],
              );
            }),
            InkWell(
              onTap: () => _uploadMultiFiles(folder, (url, type) { mediaList.add({'url': url, 'type': type}); onUpdate(); }),
              child: Container(width: 70, height: 70, decoration: BoxDecoration(color: navyDeep.withOpacity(0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: navyDeep.withOpacity(0.3), style: BorderStyle.solid)), child: const Icon(Icons.add_a_photo, color: navyDeep)),
            ),
          ],
        ),
      ],
    );
  }

  /// WIDGET : Image Picker Simple
  Widget _buildImagePickerRow(String label, String? currentUrl, String folderName, Function(String url) onUpdated) {
    final hasImg = currentUrl != null && currentUrl.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Row(children: [
        Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)), child: hasImg ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(currentUrl, fit: BoxFit.cover)) : const Icon(Icons.image_outlined, color: Colors.grey, size: 24)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: navyDeep)), Text(hasImg ? 'Image chargée' : 'Aucune image', style: TextStyle(fontSize: 11, color: hasImg ? Colors.green.shade700 : Colors.grey))])),
        ElevatedButton.icon(onPressed: () => _uploadSingleFile(folderName, onUpdated), icon: const Icon(Icons.upload, size: 16), label: const Text('Choisir'), style: ElevatedButton.styleFrom(backgroundColor: navyDeep, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8))),
      ]),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: navyDeep, size: 22), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: navyDeep))]), const Divider(height: 24, thickness: 1), ...children]));
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {String? Function(String?)? validator, bool isNumber = false, bool isUppercase = false, int maxLines = 1}) {
    return TextFormField(controller: controller, decoration: _inputDecoration(label, icon), validator: validator, maxLines: maxLines, keyboardType: isNumber ? TextInputType.number : TextInputType.text, inputFormatters: [if (isNumber) FilteringTextInputFormatter.digitsOnly, if (isUppercase) TextInputFormatter.withFunction((oldValue, newValue) => newValue.copyWith(text: newValue.text.toUpperCase()))]);
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(labelText: label, prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20), filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: navyDeep, width: 2)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14));
  }

  String? _requiredValidator(String? value) => (value == null || value.trim().isEmpty) ? 'Requis' : null;
  
  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isBusy = true);

    final mappedCities = _cities.map((c) => {'name': c['name'] ?? '', 'population': c['population']?.toString(), 'isCapital': c['isCapital'] ?? false, 'mayor': c['mayor'], 'mayorPhotoUrl': c['mayorPhotoUrl'], 'media': c['media'] ?? []}).toList();
    final mappedEconomy = _economicSectors.map((e) => {'name': e['name'] ?? '', 'description': e['description'], 'media': e['media'] ?? []}).toList();
    final mappedTourism = _tourismSites.map((t) => {'name': t['name'] ?? '', 'type': t['type'] ?? '', 'description': t['description'], 'media': t['media'] ?? []}).toList();
    final mappedEmergency = _emergencyContacts.map((e) => {'service': e['service'] ?? '', 'phone': e['phone'] ?? ''}).toList();
    final mappedAdmin = _administrativeDivisions.map((a) => {'type': a['type'] ?? '', 'name': a['name'] ?? '', 'capital': a['capital'], 'population': a['population'], 'area': a['area'], 'administrator': a['administrator'], 'media': a['media'] ?? []}).toList();
    
    // Mappage des tribus enrichies
    final mappedTribes = _tribes.map((tr) => {
      'name': tr['name'] ?? '',
      'zone': tr['zone'] ?? '',
      'history': tr['history'] ?? '',
      'media': tr['media'] ?? [],
    }).toList();

    final province = Province(
      id: _provinceId ?? '',
      name: _nameController.text.trim(),
      code: _codeController.text.trim(),
      capital: _capitalController.text.trim(),
      region: _regionController.text.trim(),
      area: int.tryParse(_areaController.text.trim()),
      population: int.tryParse(_populationController.text.trim()),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      
      // Nouveaux champs institutionnels et historiques
      history: _historyController.text.trim().isEmpty ? null : _historyController.text.trim(),
      climate: _climateController.text.trim().isEmpty ? null : _climateController.text.trim(),
      infrastructure: _infrastructureController.text.trim().isEmpty ? null : _infrastructureController.text.trim(),
      education: _educationController.text.trim().isEmpty ? null : _educationController.text.trim(),

      coverImageUrl: _coverImageUrl,
      coatOfArmsUrl: _coatOfArmsUrl,
      mapUrl: _mapUrl,
      website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
      governor: _governorController.text.trim().isEmpty ? null : _governorController.text.trim(),
      governorPhotoUrl: _governorPhotoUrl,
      viceGovernor: _viceGovernorController.text.trim().isEmpty ? null : _viceGovernorController.text.trim(),
      viceGovernorPhotoUrl: _viceGovernorPhotoUrl,
      ministers: _ministers.where((m) => (m['name'] ?? '').trim().isNotEmpty).toList(),
      
      cities: mappedCities.map((c) => City.fromJson(c)).toList(),
      economicResources: mappedEconomy.map((e) => ProvinceEconomicResource.fromJson(e)).toList(),
      tourismSites: mappedTourism.map((t) => ProvinceTourism.fromJson(t)).toList(),
      emergencyContacts: mappedEmergency.map((e) => ProvinceEmergencyContact.fromJson(e)).toList(),
      administrativeDivisions: mappedAdmin.map((a) => ProvinceAdministrativeDivision.fromJson(a)).toList(),
      
      achievements: _achievements.where((a) => (a['title'] ?? '').trim().isNotEmpty).toList(),
      tribes: mappedTribes, // Attribution des tribus enrichies
      galleryMedia: _galleryMedia,

      languages: _languagesController.text.trim().isEmpty ? null : _languagesController.text.trim(),
      resources: _resourcesController.text.trim().isEmpty ? null : _resourcesController.text.trim(),
      territoriesCount: int.tryParse(_territoriesCountController.text.trim()),
    );
    
    try {
      if (_isEditing) {
        await ref.read(adminProvincesProvider.notifier).updateProvince(province);
      } else {
        await ref.read(adminProvincesProvider.notifier).createProvince(province);
      }
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _isBusy = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red));
    }
  }
}
