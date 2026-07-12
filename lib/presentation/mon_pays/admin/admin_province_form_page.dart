// lib/presentation/mon_pays/admin/admin_province_form_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  
  // Contrôleurs de base
  late TextEditingController _nameCtrl, _codeCtrl, _capitalCtrl, _descCtrl, _popCtrl, _areaCtrl, _coverCtrl, _blasonCtrl;
  
  // Listes dynamiques (Ministres, Villes, Contacts)
  List<Map<String, TextEditingController>> _ministers = [];
  List<Map<String, TextEditingController>> _cities = [];

  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.province;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _codeCtrl = TextEditingController(text: p?.code ?? '');
    _capitalCtrl = TextEditingController(text: p?.capital ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _popCtrl = TextEditingController(text: p?.population ?? '');
    _areaCtrl = TextEditingController(text: p?.surfaceArea ?? '');
    _coverCtrl = TextEditingController(text: p?.coverUrl ?? '');
    _blasonCtrl = TextEditingController(text: p?.coatOfArmsUrl ?? '');

    // Initialisation des listes dynamiques depuis le modèle
    _ministers = p?.provincialMinisters.map((m) => {
      'name': TextEditingController(text: m['name']),
      'role': TextEditingController(text: m['role'])
    }).toList() ?? [];
  }

  // --- LOGIQUE D'UPLOAD ---
  Future<void> _uploadImage(bool isCover) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result != null && result.files.first.bytes != null) {
      setState(() => _isUploading = true);
      final url = await ref.read(provincesServiceProvider).uploadProvinceMedia(
        result.files.first.name, result.files.first.bytes!, isCover ? 'covers' : 'blasons'
      );
      setState(() {
        if (isCover) _coverCtrl.text = url; else _blasonCtrl.text = url;
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.province == null ? 'Nouvelle Province' : 'Modifier')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('Identité'),
            TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nom de la province')),
            TextFormField(controller: _codeCtrl, decoration: const InputDecoration(labelText: 'Code (ex: KN)')),
            TextFormField(controller: _capitalCtrl, decoration: const InputDecoration(labelText: 'Capitale')),
            
            _buildSectionTitle('Gouvernement Provincial'),
            ..._ministers.asMap().entries.map((e) => Row(children: [
              Expanded(child: TextFormField(controller: e.value['name'], decoration: const InputDecoration(labelText: 'Nom du Ministre'))),
              Expanded(child: TextFormField(controller: e.value['role'], decoration: const InputDecoration(labelText: 'Portefeuille'))),
              IconButton(icon: const Icon(Icons.delete), onPressed: () => setState(() => _ministers.removeAt(e.key)))
            ])),
            TextButton.icon(
              onPressed: () => setState(() => _ministers.add({'name': TextEditingController(), 'role': TextEditingController()})),
              icon: const Icon(Icons.add), label: const Text('Ajouter un ministre')
            ),

            const SizedBox(height: 30),
            ElevatedButton(onPressed: _save, child: const Text('Enregistrer la Province'))
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    final province = Province(
      id: widget.province?.id ?? '',
      name: _nameCtrl.text,
      code: _codeCtrl.text,
      capital: _capitalCtrl.text,
      description: _descCtrl.text,
      coverUrl: _coverCtrl.text,
      coatOfArmsUrl: _blasonCtrl.text,
      provincialMinisters: _ministers.map((m) => {
        'name': m['name']!.text,
        'role': m['role']!.text
      }).toList(),
    );

    await ref.read(provincesServiceProvider).saveProvince(province);
    if (mounted) Navigator.pop(context);
  }
}
