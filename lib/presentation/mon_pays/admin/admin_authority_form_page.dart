// lib/presentation/mon_pays/admin/admin_authority_form_page.dart
// Formulaire d'ajout/modification d'une autorité

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  late TextEditingController _nameController;
  late TextEditingController _titleController;
  late TextEditingController _biographyController;
  late TextEditingController _mandateController;
  late TextEditingController _partyController;
  late TextEditingController _imageUrlController;
  final List<TextEditingController> _speechControllers = [];
  final List<TextEditingController> _videoControllers = [];
  final List<TextEditingController> _publicationControllers = [];
  final Map<String, TextEditingController> _socialControllers = {};

  @override
  void initState() {
    super.initState();
    final a = widget.authority;
    _nameController = TextEditingController(text: a?.name ?? '');
    _titleController = TextEditingController(text: a?.title ?? '');
    _biographyController = TextEditingController(text: a?.biography ?? '');
    _mandateController = TextEditingController(text: a?.mandate ?? '');
    _partyController = TextEditingController(text: a?.party ?? '');
    _imageUrlController = TextEditingController(text: a?.imageUrl ?? '');

    if (a != null) {
      for (var speech in a.speeches) {
        _speechControllers.add(TextEditingController(text: speech));
      }
      for (var video in a.videos) {
        _videoControllers.add(TextEditingController(text: video));
      }
      for (var pub in a.publications) {
        _publicationControllers.add(TextEditingController(text: pub));
      }
      for (var entry in a.socialNetworks.entries) {
        _socialControllers[entry.key] = TextEditingController(text: entry.value);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _biographyController.dispose();
    _mandateController.dispose();
    _partyController.dispose();
    _imageUrlController.dispose();
    for (var c in _speechControllers) c.dispose();
    for (var c in _videoControllers) c.dispose();
    for (var c in _publicationControllers) c.dispose();
    for (var c in _socialControllers.values) c.dispose();
    super.dispose();
  }

  void _addSpeechField() {
    setState(() {
      _speechControllers.add(TextEditingController());
    });
  }

  void _addVideoField() {
    setState(() {
      _videoControllers.add(TextEditingController());
    });
  }

  void _addPublicationField() {
    setState(() {
      _publicationControllers.add(TextEditingController());
    });
  }

  void _addSocialNetwork() {
    setState(() {
      _socialControllers['Nouveau réseau'] = TextEditingController();
    });
  }

  void _removeSpeechField(int index) {
    setState(() {
      _speechControllers[index].dispose();
      _speechControllers.removeAt(index);
    });
  }

  void _removeVideoField(int index) {
    setState(() {
      _videoControllers[index].dispose();
      _videoControllers.removeAt(index);
    });
  }

  void _removePublicationField(int index) {
    setState(() {
      _publicationControllers[index].dispose();
      _publicationControllers.removeAt(index);
    });
  }

  void _removeSocialNetwork(String key) {
    setState(() {
      _socialControllers[key]?.dispose();
      _socialControllers.remove(key);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.authority != null;
    final isLoading = ref.watch(adminAuthoritiesProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier l\'autorité' : 'Nouvelle autorité'),
        backgroundColor: Colors.red.shade700,
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
                  // === INFORMATIONS DE BASE ===
                  const Text(
                    'Informations générales',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom complet *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: MonPaysValidators.validateName,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Titre / Fonction *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.work),
                    ),
                    validator: MonPaysValidators.validateTitle,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _partyController,
                    decoration: const InputDecoration(
                      labelText: 'Parti politique',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.people),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _mandateController,
                    decoration: const InputDecoration(
                      labelText: 'Mandat (ex: 2019 - 2028)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _imageUrlController,
                    decoration: const InputDecoration(
                      labelText: 'URL de la photo',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.image),
                    ),
                    validator: MonPaysValidators.validateUrl,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _biographyController,
                    decoration: const InputDecoration(
                      labelText: 'Biographie',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 24),

                  // === DISCOURS ===
                  const Text(
                    'Discours',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._speechControllers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final controller = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: controller,
                              decoration: InputDecoration(
                                labelText: 'Discours ${index + 1}',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.mic),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => _removeSpeechField(index),
                          ),
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: _addSpeechField,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter un discours'),
                  ),
                  const SizedBox(height: 24),

                  // === VIDÉOS ===
                  const Text(
                    'Vidéos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._videoControllers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final controller = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: controller,
                              decoration: InputDecoration(
                                labelText: 'Vidéo ${index + 1}',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.video_library),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => _removeVideoField(index),
                          ),
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: _addVideoField,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter une vidéo'),
                  ),
                  const SizedBox(height: 24),

                  // === PUBLICATIONS ===
                  const Text(
                    'Publications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._publicationControllers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final controller = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: controller,
                              decoration: InputDecoration(
                                labelText: 'Publication ${index + 1}',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.article),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => _removePublicationField(index),
                          ),
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: _addPublicationField,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter une publication'),
                  ),
                  const SizedBox(height: 24),

                  // === RÉSEAUX SOCIAUX ===
                  const Text(
                    'Réseaux sociaux',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._socialControllers.entries.map((entry) {
                    final key = entry.key;
                    final controller = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: controller,
                              decoration: InputDecoration(
                                labelText: 'URL $key',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.link),
                              ),
                              validator: MonPaysValidators.validateUrl,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => _removeSocialNetwork(key),
                          ),
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: _addSocialNetwork,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter un réseau social'),
                  ),
                  const SizedBox(height: 32),

                  // === BOUTON DE SAUVEGARDE ===
                  ElevatedButton(
                    onPressed: isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isEditing ? 'Modifier' : 'Créer',
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Récupérer les réseaux sociaux
    final socialNetworks = <String, String>{};
    for (var entry in _socialControllers.entries) {
      if (entry.value.text.trim().isNotEmpty) {
        socialNetworks[entry.key] = entry.value.text.trim();
      }
    }

    // Récupérer l'agenda (vide pour l'instant)
    final agenda = <Map<String, String>>[];

    final authority = Authority(
      id: widget.authority?.id ?? '',
      name: _nameController.text.trim(),
      title: _titleController.text.trim(),
      imageUrl: _imageUrlController.text.trim().isEmpty
          ? null
          : _imageUrlController.text.trim(),
      biography: _biographyController.text.trim(),
      mandate: _mandateController.text.trim(),
      party: _partyController.text.trim(),
      speeches: _speechControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
      videos: _videoControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
      publications: _publicationControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
      socialNetworks: socialNetworks,
      agenda: agenda,
    );

    final notifier = ref.read(adminAuthoritiesProvider.notifier);
    try {
      if (widget.authority != null) {
        await notifier.updateAuthority(authority);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Autorité modifiée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await notifier.createAuthority(authority);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Autorité créée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
