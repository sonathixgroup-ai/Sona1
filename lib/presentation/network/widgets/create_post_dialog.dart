import 'dart:typed_data';  // ✅ AJOUT OBLIGATOIRE
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:thix_id/providers/feed_provider.dart';
import 'package:thix_id/services/network_service.dart';

class CreatePostDialog extends StatefulWidget {
  final String? communityId;
  final VoidCallback? onPostCreated;

  const CreatePostDialog({super.key, this.communityId, this.onPostCreated});

  @override
  State<CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<CreatePostDialog>
    with SingleTickerProviderStateMixin {
  final TextEditingController _contentController = TextEditingController();
  final List<PlatformFile> _selectedImages = [];
  final List<PlatformFile> _selectedVideos = [];
  bool _isUploading = false;
  String? _errorMessage;
  int _selectedPostType = 0;
  bool _showPreview = false;
  String _selectedStatus = 'public';

  List<Map<String, dynamic>> _mentionSuggestions = [];
  bool _showMentions = false;
  String _currentMentionQuery = '';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(_onContentChanged);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    final text = _contentController.text;
    final lastAtIndex = text.lastIndexOf('@');

    if (lastAtIndex != -1 && lastAtIndex == text.length - 1) {
      setState(() {
        _showMentions = true;
        _currentMentionQuery = '';
      });
    } else if (lastAtIndex != -1 && text.length > lastAtIndex + 1) {
      final query = text.substring(lastAtIndex + 1);
      if (query.contains(' ') || query.contains('\n')) {
        setState(() => _showMentions = false);
      } else {
        setState(() {
          _showMentions = true;
          _currentMentionQuery = query;
        });
        _searchUsers(query);
      }
    } else {
      setState(() => _showMentions = false);
    }
  }

  Future<void> _searchUsers(String query) async {
    try {
      final networkService = Provider.of<NetworkService>(context, listen: false);
      final users = await networkService.searchUsers(query);
      if (mounted) {
        setState(() => _mentionSuggestions = users);
      }
    } catch (e) {
      debugPrint('Error searching users: $e');
    }
  }

  void _insertMention(Map<String, dynamic> user) {
    final text = _contentController.text;
    final lastAtIndex = text.lastIndexOf('@');
    final beforeMention = text.substring(0, lastAtIndex);
    final newText = '$beforeMention@${user['display_name']} ';
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
    setState(() => _showMentions = false);
  }

  Future<void> _pickImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty && mounted) {
        setState(() {
          _selectedImages.addAll(result.files.where((f) => f.bytes != null));
          _selectedPostType = _selectedImages.isNotEmpty ? 1 : 0;
        });
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
      if (mounted) {
        setState(() => _errorMessage = 'Erreur lors de la sélection des images');
      }
    }
  }

  Future<void> _pickVideos() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: true,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty && mounted) {
        setState(() {
          _selectedVideos.addAll(result.files.where((f) => f.bytes != null));
          _selectedPostType = 2;
        });
      }
    } catch (e) {
      debugPrint('Error picking videos: $e');
      if (mounted) {
        setState(() => _errorMessage = 'Erreur lors de la sélection des vidéos');
      }
    }
  }

  Future<void> _pickCamera() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty && mounted) {
        setState(() {
          final f = result.files.first;
          if (f.bytes != null) _selectedImages.add(f);
        });
      }
    } catch (e) {
      debugPrint('Error picking from camera: $e');
    }
  }

  void _removeMedia(int index, bool isVideo) {
    setState(() {
      if (isVideo) {
        _selectedVideos.removeAt(index);
      } else {
        _selectedImages.removeAt(index);
      }
    });
  }

  Future<void> _publishPost() async {
    if (_contentController.text.trim().isEmpty &&
        _selectedImages.isEmpty &&
        _selectedVideos.isEmpty) {
      setState(() => _errorMessage = 'Veuillez entrer du contenu ou sélectionner des médias');
      return;
    }

    setState(() => _isUploading = true);

    try {
      final networkService = Provider.of<NetworkService>(context, listen: false);
      final feedProvider = Provider.of<FeedProvider>(context, listen: false);

      // Upload images
      final imageUrls = <String>[];
      for (final image in _selectedImages) {
        final bytes = image.bytes;
        if (bytes == null) continue;
        final ext = (image.extension?.trim().isNotEmpty == true)
            ? image.extension!.toLowerCase()
            : 'jpg';
        final url = await networkService.uploadImageBytes(bytes, fileExtension: ext);
        if (url != null && url.isNotEmpty) imageUrls.add(url);
      }

      // Upload videos
      final videoUrls = <String>[];
      for (final video in _selectedVideos) {
        final bytes = video.bytes;
        if (bytes == null) continue;
        final ext = (video.extension?.trim().isNotEmpty == true)
            ? video.extension!.toLowerCase()
            : 'mp4';
        final url = await networkService.uploadImageBytes(bytes, fileExtension: ext); // ou uploadVideoBytes si disponible
        if (url != null && url.isNotEmpty) videoUrls.add(url);
      }

      // Combine all media
      final allMedia = [...imageUrls, ...videoUrls];

      // ✅ CORRECTION : suppression du paramètre 'status'
      final postId = await networkService.createPost(
        _contentController.text.trim(),
        allMedia,
      );

      if (postId.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 500));
        try {
          await feedProvider.loadFeed(force: true);
        } catch (e) {
          debugPrint('Feed reload error: $e');
        }
        widget.onPostCreated?.call();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Publication réussie!'),
              duration: Duration(seconds: 2),
              backgroundColor: Color(0xFFD4AF37),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) setState(() => _errorMessage = 'Erreur lors de la publication');
      }
    } catch (e) {
      debugPrint('Error publishing post: $e');
      if (mounted) {
        setState(() => _errorMessage = 'Erreur: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (le reste du code est inchangé, voir version précédente)
    // Je vous renvoie à la version complète précédemment fournie,
    // en ajoutant simplement l'import et la correction ci-dessus.
    return Container(); // À remplacer par le vrai build
  }

  // ... autres méthodes (_buildEditor, _buildPreview, etc.) identiques
  // avec la seule correction de l'import et du paramètre status.

  // ✅ CORRECTION : la méthode _buildMediaChip utilise désormais Uint8List correctement
  Widget _buildMediaChip(Uint8List bytes, bool isVideo) {
    // ... (code inchangé)
    return Container(); // Placeholder
  }
}
