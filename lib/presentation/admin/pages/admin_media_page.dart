import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '../../../models/media_content.dart';
import '../../../services/media_service.dart';

class AdminMediaPage extends StatefulWidget {
  const AdminMediaPage({super.key});

  @override
  State<AdminMediaPage> createState() => _AdminMediaPageState();
}

class _AdminMediaPageState extends State<AdminMediaPage> {
  late MediaService _mediaService;
  List<MediaContent> _media = [];
  bool _isLoading = true;
  String? _error;

  bool _isEditing = false;
  MediaContent? _editingItem;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _typeController = TextEditingController();
  final _yearController = TextEditingController();
  final _coverUrlController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _viewCountController = TextEditingController();
  final _rankPositionController = TextEditingController();
  bool _isTrending = false;
  bool _isNewRelease = false;
  bool _isRecommended = false;
  bool _isPublished = true;

  File? _selectedCoverFile;
  File? _selectedVideoFile;

  @override
  void initState() {
    super.initState();
    _mediaService = MediaService(Supabase.instance.client);
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    setState(() => _isLoading = true);
    try {
      final all = await _mediaService.fetchAllMedia();
      setState(() {
        _media = all;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _pickCoverFile() async {
    final result = await FilePicker.pickFiles(type: FileType.image); // ✅ corrigé
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedCoverFile = File(result.files.single.path!);
        _coverUrlController.text = _selectedCoverFile!.path;
      });
    }
  }

  Future<void> _pickVideoFile() async {
    final result = await FilePicker.pickFiles(type: FileType.video); // ✅ corrigé
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedVideoFile = File(result.files.single.path!);
        _videoUrlController.text = _selectedVideoFile!.path;
      });
    }
  }

  Future<void> _saveMedia() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      if (_isEditing && _editingItem != null) {
        await _mediaService.updateWithFiles(
          _editingItem!,
          newCoverFile: _selectedCoverFile,
          newVideoFile: _selectedVideoFile,
        );
      } else {
        final newItem = MediaContent(
          id: '',
          title: _titleController.text,
          subtitle: _subtitleController.text,
          type: _typeController.text,
          year: _yearController.text,
          coverUrl: _coverUrlController.text,
          videoUrl: _videoUrlController.text,
          viewCount: int.tryParse(_viewCountController.text) ?? 0,
          rankPosition: _rankPositionController.text.isNotEmpty ? int.parse(_rankPositionController.text) : null,
          isTrending: _isTrending,
          isNewRelease: _isNewRelease,
          isRecommended: _isRecommended,
          isPublished: _isPublished,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _mediaService.insertWithFiles(newItem,
            coverFile: _selectedCoverFile, videoFile: _selectedVideoFile);
      }
      _resetForm();
      await _loadMedia();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Média sauvegardé !')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  Future<void> _deleteMedia(MediaContent item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text('Voulez-vous vraiment supprimer "${item.title}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Non')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Oui')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _mediaService.deleteMedia(item);
      await _loadMedia();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Supprimé !')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur suppression : $e')),
        );
      }
    }
  }

  void _editMedia(MediaContent item) {
    _isEditing = true;
    _editingItem = item;
    _titleController.text = item.title;
    _subtitleController.text = item.subtitle ?? '';
    _typeController.text = item.type;
    _yearController.text = item.year ?? '';
    _coverUrlController.text = item.coverUrl;
    _videoUrlController.text = item.videoUrl;
    _viewCountController.text = item.viewCount.toString();
    _rankPositionController.text = item.rankPosition?.toString() ?? '';
    _isTrending = item.isTrending;
    _isNewRelease = item.isNewRelease;
    _isRecommended = item.isRecommended;
    _isPublished = item.isPublished;
    _selectedCoverFile = null;
    _selectedVideoFile = null;
    _showForm();
  }

  void _resetForm() {
    _isEditing = false;
    _editingItem = null;
    _titleController.clear();
    _subtitleController.clear();
    _typeController.clear();
    _yearController.clear();
    _coverUrlController.clear();
    _videoUrlController.clear();
    _viewCountController.clear();
    _rankPositionController.clear();
    _isTrending = false;
    _isNewRelease = false;
    _isRecommended = false;
    _isPublished = true;
    _selectedCoverFile = null;
    _selectedVideoFile = null;
  }

  void _showForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_isEditing ? 'Modifier le média' : 'Ajouter un média',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Titre *'),
                    validator: (v) => v == null || v.isEmpty ? 'Requis' : null),
                TextFormField(controller: _subtitleController, decoration: const InputDecoration(labelText: 'Sous-titre')),
                TextFormField(controller: _typeController, decoration: const InputDecoration(labelText: 'Type (Musique, Film...) *'),
                    validator: (v) => v == null || v.isEmpty ? 'Requis' : null),
                TextFormField(controller: _yearController, decoration: const InputDecoration(labelText: 'Année')),
                ListTile(
                  leading: const Icon(Icons.image),
                  title: Text(_selectedCoverFile == null ? 'Aucun fichier image' : _selectedCoverFile!.path.split('/').last),
                  trailing: ElevatedButton(
                    onPressed: _pickCoverFile,
                    child: const Text('Choisir image'),
                  ),
                ),
                TextFormField(controller: _coverUrlController, decoration: const InputDecoration(labelText: 'URL de couverture (si pas de fichier)')),
                ListTile(
                  leading: const Icon(Icons.video_file),
                  title: Text(_selectedVideoFile == null ? 'Aucun fichier vidéo' : _selectedVideoFile!.path.split('/').last),
                  trailing: ElevatedButton(
                    onPressed: _pickVideoFile,
                    child: const Text('Choisir vidéo'),
                  ),
                ),
                TextFormField(controller: _videoUrlController, decoration: const InputDecoration(labelText: 'URL vidéo (si pas de fichier)'),
                    validator: (v) => (v == null || v.isEmpty) && _selectedVideoFile == null ? 'Fichier ou URL requis' : null),
                TextFormField(controller: _viewCountController, decoration: const InputDecoration(labelText: 'Nombre de vues'),
                    keyboardType: TextInputType.number),
                TextFormField(controller: _rankPositionController, decoration: const InputDecoration(labelText: 'Position dans tendances (1,2,3...)'),
                    keyboardType: TextInputType.number),
                SwitchListTile(title: const Text('Tendance'), value: _isTrending, onChanged: (v) => setState(() => _isTrending = v)),
                SwitchListTile(title: const Text('Nouveauté'), value: _isNewRelease, onChanged: (v) => setState(() => _isNewRelease = v)),
                SwitchListTile(title: const Text('Recommandé'), value: _isRecommended, onChanged: (v) => setState(() => _isRecommended = v)),
                SwitchListTile(title: const Text('Publié'), value: _isPublished, onChanged: (v) => setState(() => _isPublished = v)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _saveMedia,
                  child: Text(_isEditing ? 'Mettre à jour' : 'Ajouter'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(body: Center(child: Text('Erreur : $_error')));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration THIX MEDIA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _resetForm();
              _showForm();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMedia,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _media.length,
        itemBuilder: (context, index) {
          final item = _media[index];
          return ListTile(
            leading: Image.network(item.coverUrl, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
            title: Text(item.title),
            subtitle: Text('${item.type} • ${item.year ?? ''} • ${item.isPublished ? 'Publié' : 'Brouillon'}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(onPressed: () => _editMedia(item), icon: const Icon(Icons.edit)),
                IconButton(onPressed: () => _deleteMedia(item), icon: const Icon(Icons.delete)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          _resetForm();
          _showForm();
        },
      ),
    );
  }
}
