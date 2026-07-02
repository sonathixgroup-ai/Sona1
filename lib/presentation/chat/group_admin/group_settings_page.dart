// lib/presentation/chat/group_admin/group_settings_page.dart
// Paramètres du groupe (nom, avatar, description, règles, etc.)

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

class GroupSettingsPage extends StatefulWidget {
  final String groupId;
  final String initialName;
  final String? initialAvatarUrl;
  final String? initialDescription;
  final Function(String name, String? description, String? avatarPath) onSave;

  const GroupSettingsPage({
    Key? key,
    required this.groupId,
    required this.initialName,
    this.initialAvatarUrl,
    this.initialDescription,
    required this.onSave,
  }) : super(key: key);

  @override
  State<GroupSettingsPage> createState() => _GroupSettingsPageState();
}

class _GroupSettingsPageState extends State<GroupSettingsPage> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _descController = TextEditingController(text: widget.initialDescription);
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _avatarPath = picked.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres du groupe')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: _avatarPath != null
                      ? FileImage(File(_avatarPath!))
                      : (widget.initialAvatarUrl != null
                          ? CachedNetworkImageProvider(widget.initialAvatarUrl!)
                          : const AssetImage('assets/default_group.png') as ImageProvider),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: _pickAvatar,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nom du groupe'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(labelText: 'Description (optionnel)'),
            maxLines: 3,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              widget.onSave(
                _nameController.text.trim(),
                _descController.text.trim(),
                _avatarPath,
              );
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
