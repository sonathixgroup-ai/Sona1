import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/services/network_service.dart';

class EditProfileDialog extends StatefulWidget {
  final String userId;
  final String currentName;
  final String? currentTitle;
  final String? currentBio;
  final String? currentAvatarUrl;
  final List<String> currentSkills;

  const EditProfileDialog({
    super.key,
    required this.userId,
    required this.currentName,
    this.currentTitle,
    this.currentBio,
    this.currentAvatarUrl,
    this.currentSkills = const [],
  });

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late TextEditingController _nameController;
  late TextEditingController _titleController;
  late TextEditingController _bioController;
  final List<TextEditingController> _skillControllers = [];
  Uint8List? _selectedAvatarBytes;
  String? _selectedAvatarExtension;
  bool _isSaving = false;
  bool _isUploading = false;
  late NetworkService _networkService;

  @override
  void initState() {
    super.initState();
    _networkService = NetworkService(Supabase.instance.client);
    _nameController = TextEditingController(text: widget.currentName);
    _titleController = TextEditingController(text: widget.currentTitle ?? '');
    _bioController = TextEditingController(text: widget.currentBio ?? '');
    
    for (var skill in widget.currentSkills) {
      final controller = TextEditingController(text: skill);
      _skillControllers.add(controller);
    }
    if (_skillControllers.isEmpty) {
      _addSkillField();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _bioController.dispose();
    for (var c in _skillControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addSkillField() {
    if (_skillControllers.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous ne pouvez pas ajouter plus de 10 compétences'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() {
      _skillControllers.add(TextEditingController());
    });
  }

  void _removeSkillField(int index) {
    setState(() {
      _skillControllers[index].dispose();
      _skillControllers.removeAt(index);
    });
  }

  void _removeAvatar() {
    setState(() {
      _selectedAvatarBytes = null;
      _selectedAvatarExtension = null;
    });
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final size = file.bytes?.length ?? file.size;
      
      if (size > 5 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('L\'image ne doit pas dépasser 5MB'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      setState(() {
        _selectedAvatarBytes = file.bytes;
        _selectedAvatarExtension = file.extension ?? 'jpg';
      });
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer votre nom'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final skills = _skillControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (skills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajoutez au moins une compétence'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? avatarUrl = widget.currentAvatarUrl;
      
      // Upload du nouvel avatar si sélectionné
      if (_selectedAvatarBytes != null) {
        setState(() => _isUploading = true);
        avatarUrl = await _networkService.uploadImageBytes(
          _selectedAvatarBytes!,
          fileExtension: _selectedAvatarExtension!,
          bucket: 'avatars',
        );
        setState(() => _isUploading = false);
      }

      // Mise à jour du profil (table 'users' ou 'profiles')
      final updateData = {
        'display_name': name,
        'profession': _titleController.text.trim(),
        'bio': _bioController.text.trim(),
        'skills': skills,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (avatarUrl != null) {
        updateData['photo_url'] = avatarUrl;  // ou 'avatar_url' selon votre schéma
      }

      await Supabase.instance.client
          .from('users')  // ou 'profiles' selon votre table
          .update(updateData)
          .eq('id', widget.userId);

      if (mounted) {
        // Retourner les données mises à jour au parent
        Navigator.pop(context, {
          'name': name,
          'title': _titleController.text.trim(),
          'bio': _bioController.text.trim(),
          'skills': skills,
          'avatar_url': avatarUrl,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde profil: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildAvatarPreview() {
    if (_selectedAvatarBytes != null) {
      return ClipOval(
        child: Image.memory(
          _selectedAvatarBytes!,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
        ),
      );
    }
    if (widget.currentAvatarUrl != null && widget.currentAvatarUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          widget.currentAvatarUrl!,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey.shade200,
            child: const Icon(Icons.person, size: 50, color: Colors.grey),
          ),
        ),
      );
    }
    return Container(
      color: Colors.grey.shade200,
      child: const Icon(Icons.person, size: 50, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAvatar = widget.currentAvatarUrl != null || _selectedAvatarBytes != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 650),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Modifier mon profil',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Body (scrollable)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Avatar
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFD4AF37),
                                width: 2,
                              ),
                            ),
                            child: _buildAvatarPreview(),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _isUploading ? null : _pickAvatar,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFD4AF37),
                                  shape: BoxShape.circle,
                                ),
                                child: _isUploading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.camera_alt,
                                        size: 18,
                                        color: Color(0xFF0B1B3D),
                                      ),
                              ),
                            ),
                          ),
                          if (hasAvatar && !_isUploading)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              child: GestureDetector(
                                onTap: _removeAvatar,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.delete,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Nom
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom complet *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Titre professionnel
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Titre professionnel',
                        hintText: 'Ex: CEO @ PayPal Solutions',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.work_outline),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Bio
                    TextField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        hintText: 'Parlez de vous...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Compétences
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Compétences',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: _addSkillField,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Ajouter'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFD4AF37),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(_skillControllers.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _skillControllers[index],
                                decoration: const InputDecoration(
                                  hintText: 'Ex: Flutter, Firebase...',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                              onPressed: () => _removeSkillField(index),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // Footer
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: const Color(0xFF0B1B3D),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 2,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0B1B3D)),
                      ),
                    )
                  : const Text(
                      'ENREGISTRER',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
