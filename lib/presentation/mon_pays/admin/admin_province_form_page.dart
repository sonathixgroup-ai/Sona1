// lib/presentation/mon_pays/admin/admin_province_form_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  bool _isEditing = false;
  String? _provinceId;

  @override
  void initState() {
    super.initState();
    final p = widget.province;
    _isEditing = p != null;
    _provinceId = p?.id;
    _nameController = TextEditingController(text: p?.name ?? '');
    _codeController = TextEditingController(text: p?.code ?? '');
    _capitalController = TextEditingController(text: p?.capital ?? '');
    _regionController = TextEditingController(text: p?.region ?? '');
    _areaController = TextEditingController(text: p?.area?.toString() ?? '');
    _populationController = TextEditingController(text: p?.population?.toString() ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _coverImageUrlController = TextEditingController(text: p?.coverImageUrl ?? '');
    _coatOfArmsUrlController = TextEditingController(text: p?.coatOfArmsUrl ?? '');
    _mapUrlController = TextEditingController(text: p?.mapUrl ?? '');
    _websiteController = TextEditingController(text: p?.website ?? '');
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier la province' : 'Nouvelle province'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nom *'),
                  validator: (v) => v?.isEmpty ?? true ? 'Champ requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(labelText: 'Code (ex: KIN) *'),
                  validator: (v) => v?.isEmpty ?? true ? 'Champ requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _capitalController,
                  decoration: const InputDecoration(labelText: 'Capitale *'),
                  validator: (v) => v?.isEmpty ?? true ? 'Champ requis' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _regionController.text.isNotEmpty ? _regionController.text : null,
                  decoration: const InputDecoration(labelText: 'Région *'),
                  items: const [
                    DropdownMenuItem(value: 'Centre', child: Text('Centre')),
                    DropdownMenuItem(value: 'Est', child: Text('Est')),
                    DropdownMenuItem(value: 'Ouest', child: Text('Ouest')),
                    DropdownMenuItem(value: 'Nord', child: Text('Nord')),
                    DropdownMenuItem(value: 'Sud', child: Text('Sud')),
                  ],
                  onChanged: (value) => _regionController.text = value!,
                  validator: (v) => v == null ? 'Champ requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _areaController,
                  decoration: const InputDecoration(labelText: 'Superficie (km²)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _populationController,
                  decoration: const InputDecoration(labelText: 'Population'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _coverImageUrlController,
                  decoration: const InputDecoration(labelText: 'URL de la couverture'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _coatOfArmsUrlController,
                  decoration: const InputDecoration(labelText: 'URL du blason'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _mapUrlController,
                  decoration: const InputDecoration(labelText: 'URL de la carte'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _websiteController,
                  decoration: const InputDecoration(labelText: 'Site web'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_isEditing ? 'Modifier' : 'Créer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    final province = Province(
      id: _provinceId ?? '',
      name: _nameController.text.trim(),
      code: _codeController.text.trim().toUpperCase(),
      capital: _capitalController.text.trim(),
      region: _regionController.text.trim(),
      area: int.tryParse(_areaController.text.trim()),
      population: int.tryParse(_populationController.text.trim()),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      coverImageUrl: _coverImageUrlController.text.trim().isEmpty ? null : _coverImageUrlController.text.trim(),
      coatOfArmsUrl: _coatOfArmsUrlController.text.trim().isEmpty ? null : _coatOfArmsUrlController.text.trim(),
      mapUrl: _mapUrlController.text.trim().isEmpty ? null : _mapUrlController.text.trim(),
      website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
