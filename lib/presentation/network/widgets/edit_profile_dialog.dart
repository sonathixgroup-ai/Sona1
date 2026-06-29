import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/services/upload_service.dart';

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
  File? _selectedAvatar;
  bool _isSaving = false;
  bool _isUploading = false;
  late UploadService _uploadService;

  @override
  void initState() {
    super.initState();
    _uploadService = UploadService();
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
        const SnackBar(content: Text('Vous ne pouvez pas ajouter plus de 10 compétences')),
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
      _selectedAvatar = null;
    });
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    
    if (result != null && result.files.isNotEmpty) {
      final file = File(result.files.first.path!);
      final size = await file.length();
      
      if (size > 5 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('L\'image ne doit pas dépasser 5MB')),
        );
        return;
      }
      
      setState(() {
        _selectedAvatar = file;
      });
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer votre nom')),
      );
      return;
    }

    final skills = _skillControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (skills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez au moins une compétence')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? avatarUrl = widget.currentAvatarUrl;
      
      if (_selectedAvatar != null) {
        setState(() => _isUploading = true);
        avatarUrl = await _uploadService.uploadAvatar(_selectedAvatar!, widget.userId);
        setState(() => _isUploading = false);
      } else if (widget.currentAvatarUrl != null && _selectedAvatar == null) {
        // Avatar non modifié
      }

      await Supabase.instance.client
          .from('profiles')
          .update({
            'display_name': name,
            'title': _titleController.text.trim(),
            'bio': _bioController.text.trim(),
            'skills': skills,
            if (avatarUrl != null) 'avatar_url': avatarUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.userId);

      if (mounted) {
        Navigator.pop(context, {
          'name': name,
          'title': _titleController.text.trim(),
          'bio': _bioController.text.trim(),
          'skills': skills,
          'avatar_url': avatarUrl,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour !'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildAvatarPreview() {
    if (_selectedAvatar != null) {
      return ClipOval(
        child: Image.file(
          _selectedAvatar!,
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
    final hasAvatar = widget.currentAvatarUrl != null || _selectedAvatar != null;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Modifier mon profil',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                              border: Border.all(color: const Color(0xFFD4AF37), width: 2),
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
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.camera_alt, size: 18, color: Color(0xFF0B1B3D)),
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
                                  child: const Icon(Icons.delete, size: 14, color: Colors.white),
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
                        labelText: 'Nom complet',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Titre
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Titre professionnel',
                        hintText: 'Ex: CEO @ PayPal Solutions',
                        border: OutlineInputBorder(),
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
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () => _removeSkillField(index),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
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
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('ENREGISTRER'),
            ),
          ],
        ),
      ),
    );
  }
}
