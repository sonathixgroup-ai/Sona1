// ============================================================
// FICHIER 25 : admin/admin_tourism_form_page.dart
// ============================================================
// lib/presentation/mon_pays/admin/admin_tourism_form_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/province_tourism.dart';
import '../providers/provinces_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier le site touristique' : 'Ajouter un site touristique'),
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
                DropdownButtonFormField<String>(
                  value: _typeController.text.isNotEmpty ? _typeController.text : null,
                  decoration: const InputDecoration(labelText: 'Type *'),
                  items: const [
                    DropdownMenuItem(value: 'parc_national', child: Text('Parc national')),
                    DropdownMenuItem(value: 'site_historique', child: Text('Site historique')),
                    DropdownMenuItem(value: 'monument', child: Text('Monument')),
                    DropdownMenuItem(value: 'musee', child: Text('Musée')),
                    DropdownMenuItem(value: 'evenement', child: Text('Événement')),
                  ],
                  onChanged: (value) => _typeController.text = value!,
                  validator: (v) => v == null ? 'Champ requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nom *'),
                  validator: (v) => v?.isEmpty ?? true ? 'Champ requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Localisation'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(labelText: 'URL de l\'image'),
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
                  child: Text(_isEditing ? 'Modifier' : 'Ajouter'),
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
          const SnackBar(content: Text('Site touristique enregistré'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
