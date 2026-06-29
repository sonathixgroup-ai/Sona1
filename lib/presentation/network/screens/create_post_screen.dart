import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../network_view_model.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final List<PlatformFile> _selectedMedia = [];
  bool _isUploading = false;
  String? _postType = 'publication'; // 'publication', 'photo', 'video', 'short', 'sondage'

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final res = await FilePicker.pickFiles(type: FileType.image, allowMultiple: true, withData: true);
    if (res == null || res.files.isEmpty) return;
    setState(() => _selectedMedia.addAll(res.files));
  }

  Future<void> _pickVideo() async {
    final res = await FilePicker.pickFiles(type: FileType.video, allowMultiple: true, withData: true);
    if (res == null || res.files.isEmpty) return;
    setState(() => _selectedMedia.addAll(res.files));
  }

  Future<void> _submitPost() async {
    if (_contentController.text.trim().isEmpty && _selectedMedia.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez écrire du contenu ou ajouter un média.')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non connecté');

      List<String> mediaUrls = [];

      // Upload des médias vers Supabase Storage
      for (final f in _selectedMedia) {
        final bytes = f.bytes;
        if (bytes == null) continue;
        final ext = (f.extension ?? 'bin').toLowerCase();
        final storagePath = 'posts/${userId}_${DateTime.now().millisecondsSinceEpoch}.${ext.isEmpty ? 'bin' : ext}';
        await supabase.storage.from('media').uploadBinary(storagePath, bytes);
        final url = supabase.storage.from('media').getPublicUrl(storagePath);
        mediaUrls.add(url);
      }

      // Insérer le post dans la table posts
      await supabase.from('posts').insert({
        'user_id': userId,
        'content': _contentController.text.trim(),
        'media_urls': mediaUrls.isEmpty ? null : mediaUrls,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Rafraîchir le ViewModel
      final vm = context.read<NetworkViewModel>();
      await vm.loadInitialData();

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publication créée avec succès !')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer une publication', style: TextStyle(fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: _isUploading ? null : _submitPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Publier', style: TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Sélecteur de type de post
            Row(
              children: [
                _typeChip('Publication', Icons.edit, 'publication'),
                _typeChip('Photo', Icons.photo_camera, 'photo'),
                _typeChip('Vidéo', Icons.videocam, 'video'),
                _typeChip('Short', Icons.short_text, 'short'),
                _typeChip('Sondage', Icons.poll, 'sondage'),
              ],
            ),
            const SizedBox(height: 16),
            // Champ de texte
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Quoi de neuf dans votre monde pro ?',
                  hintStyle: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            // Médias sélectionnés
            if (_selectedMedia.isNotEmpty)
              Container(
                height: 100,
                margin: const EdgeInsets.only(top: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedMedia.length,
                  itemBuilder: (context, index) {
                    final file = _selectedMedia[index];
                    final bytes = file.bytes;
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: bytes == null
                                ? null
                                : DecorationImage(
                                    image: MemoryImage(bytes),
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          child: bytes == null ? const Center(child: Icon(Icons.insert_photo_outlined)) : null,
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedMedia.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            // Boutons d'ajout
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo_library_outlined, size: 24),
                  onPressed: _pickMedia,
                ),
                IconButton(
                  icon: const Icon(Icons.video_library_outlined, size: 24),
                  onPressed: _pickVideo,
                ),
                const Spacer(),
                if (_selectedMedia.isNotEmpty)
                  Text(
                    '${_selectedMedia.length} média(s)',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(String label, IconData icon, String type) {
    final isSelected = _postType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey.shade700),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12)),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _postType = selected ? type : 'publication';
          });
        },
        selectedColor: const Color(0xFF1A73E8),
        backgroundColor: Colors.grey.shade200,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey.shade700,
        ),
      ),
    );
  }
}
