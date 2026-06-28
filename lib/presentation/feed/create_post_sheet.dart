// lib/presentation/feed/create_post_sheet.dart
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thix_id/services/post_service.dart';
import 'package:thix_id/services/media_service.dart';

class CreatePostSheet extends StatefulWidget {
  final String profileId;

  const CreatePostSheet({Key? key, required this.profileId}) : super(key: key);

  static Future<void> show(BuildContext context, {required String profileId}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: CreatePostSheet(profileId: profileId),
      ),
    );
  }

  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  final _controller = TextEditingController();
  List<PlatformFile> _picked = [];
  bool _loading = false;

  Future<void> _pickFiles() async {
    final res = await FilePicker().pickFiles(allowMultiple: true, type: FileType.image, withData: true);
    if (res == null) return;
    setState(() => _picked = res.files);
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    if (content.isEmpty && _picked.isEmpty) return;
    setState(() => _loading = true);
    try {
      final postService = context.read<PostService>();
      await postService.createPost(profileId: widget.profileId, content: content, mediaFiles: _picked);
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de la publication: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Créer une publication', style: Theme.of(context).textTheme.titleLarge)),
              IconButton(onPressed: () => Navigator.of(context).pop(), icon: Icon(Icons.close))
            ],
          ),
          TextField(controller: _controller, maxLines: null, decoration: InputDecoration(hintText: 'Que voulez-vous partager ?')),
          const SizedBox(height: 12),
          if (_picked.isNotEmpty)
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _picked.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final p = _picked[i];
                  return Stack(
                    children: [
                      Container(width: 96, height: 96, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey[200]), child: p.bytes != null ? Image.memory(p.bytes!, fit: BoxFit.cover) : Image.file(File(p.path!), fit: BoxFit.cover)),
                      Positioned(top: 4, right: 4, child: GestureDetector(onTap: () => setState(() => _picked.removeAt(i)), child: CircleAvatar(radius: 12, child: Icon(Icons.close, size: 14))))
                    ],
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(onPressed: _pickFiles, icon: Icon(Icons.photo_library), label: Text('Photos')),
              const Spacer(),
              ElevatedButton(onPressed: _loading ? null : _submit, child: _loading ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text('Publier'))
            ],
          )
        ],
      ),
    );
  }
}
