import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/media_service.dart';
import '../../models/media_content.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subtitleController = TextEditingController();
  PlatformFile? _selectedVideo;
  PlatformFile? _selectedCover;
  bool _isUploading = false;
  double _progress = 0.0;

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video, withData: kIsWeb);
    if (result != null) setState(() => _selectedVideo = result.files.first);
  }

  Future<void> _pickCover() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: kIsWeb);
    if (result != null) setState(() => _selectedCover = result.files.first);
  }

  Future<void> _publishPost() async {
    if (_titleController.text.trim().isEmpty || _selectedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez ajouter un titre et une vidéo.')));
      return;
    }

    setState(() { _isUploading = true; _progress = 0.0; });

    try {
      final newContent = MediaContent(
        id: '',
        title: _titleController.text.trim(),
        subtitle: _subtitleController.text.trim().isEmpty ? null : _subtitleController.text.trim(),
        videoUrl: '',
        coverUrl: '',
        type: 'Fil', // Destination exclusive : Le Fil
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await MediaService().insertWithFiles(
        newContent,
        videoFile: _selectedVideo,
        coverFile: _selectedCover,
        onProgress: (p) => setState(() => _progress = p),
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Publication réussie dans le Fil !')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050507),
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('Publier dans le Fil', style: TextStyle(color: Colors.white)), iconTheme: const IconThemeData(color: Colors.white)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _titleController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Titre', labelStyle: TextStyle(color: Colors.grey))),
            const SizedBox(height: 20),
            TextField(controller: _subtitleController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Description', labelStyle: TextStyle(color: Colors.grey))),
            const SizedBox(height: 30),
            ElevatedButton.icon(onPressed: _pickCover, icon: const Icon(Icons.image), label: Text(_selectedCover == null ? 'Choisir une couverture' : 'Couverture OK')),
            const SizedBox(height: 15),
            ElevatedButton.icon(onPressed: _pickVideo, icon: const Icon(Icons.video_call), label: Text(_selectedVideo == null ? 'Choisir une vidéo' : 'Vidéo : ${_selectedVideo!.name}')),
            const SizedBox(height: 40),
            if (_isUploading) ...[
              LinearProgressIndicator(value: _progress, color: const Color(0xFFFF1A1A)),
              const SizedBox(height: 10),
              Text('${(_progress * 100).toStringAsFixed(0)}% en cours...', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            ] else
              ElevatedButton(onPressed: _publishPost, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF1A1A)), child: const Text('Publier', style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
  }
}
