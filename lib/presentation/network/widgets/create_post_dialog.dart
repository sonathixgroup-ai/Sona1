// lib/presentation/network/widgets/create_post_dialog.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../../services/network_service.dart';
import '../../../providers/feed_provider.dart';

class CreatePostDialog extends StatefulWidget {
  final String? communityId;
  final VoidCallback? onPostCreated;
  
  const CreatePostDialog({super.key, this.communityId, this.onPostCreated});

  @override
  State<CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<CreatePostDialog> {
  final TextEditingController _contentController = TextEditingController();
  final List<File> _selectedImages = [];
  final List<File> _selectedVideos = [];
  final List<String> _uploadingFiles = [];
  bool _isUploading = false;
  String? _errorMessage;
  int _selectedPostType = 0;
  bool _showPreview = false;
  String _selectedStatus = 'public';
  
  List<Map<String, dynamic>> _mentionSuggestions = [];
  bool _showMentions = false;
  String _currentMentionQuery = '';

  @override
  void initState() {
    super.initState();
    _contentController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _contentController.dispose();
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

  // ⭐ CORRIGÉ - Utilisation de FilePicker au lieu de ImagePicker
  Future<void> _pickImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );
      
      if (result != null && result.files.isNotEmpty && mounted) {
        setState(() {
          for (final file in result.files) {
            if (file.path != null) {
              _selectedImages.add(File(file.path!));
            }
          }
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

  // ⭐ CORRIGÉ - Utilisation de FilePicker pour la caméra (fallback)
  Future<void> _pickCamera() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty && result.files.first.path != null && mounted) {
        setState(() {
          _selectedImages.add(File(result.files.first.path!));
        });
      }
    } catch (e) {
      debugPrint('Error picking from camera: $e');
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  Future<void> _publishPost() async {
    if (_contentController.text.trim().isEmpty && _selectedImages.isEmpty) {
      setState(() => _errorMessage = 'Veuillez entrer du contenu ou sélectionner des images');
      return;
    }

    setState(() => _isUploading = true);

    try {
      final networkService = Provider.of<NetworkService>(context, listen: false);
      final feedProvider = Provider.of<FeedProvider>(context, listen: false);

      // Upload images and get URLs
      final imageUrls = <String>[];
      for (var image in _selectedImages) {
        final url = await networkService.uploadImage(image.path);
        if (url != null && url.isNotEmpty) {
          imageUrls.add(url);
        }
      }

      // Create post
      final postId = await networkService.createPost(
        _contentController.text.trim(),
        imageUrls,
      );

      if (postId.isNotEmpty) {
        debugPrint('✅ Post published successfully: $postId');
        
        // Reload feed
        await feedProvider.loadFeed();
        
        // Call callback if provided
        widget.onPostCreated?.call();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Publication réussie!'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          setState(() => _errorMessage = 'Erreur lors de la publication');
        }
      }
    } catch (e) {
      debugPrint('Error publishing post: $e');
      if (mounted) {
        setState(() => _errorMessage = 'Erreur: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Créer une publication',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: _showPreview ? _buildPreview() : _buildEditor(),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  if (!_showPreview)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isUploading ? null : () => setState(() => _showPreview = true),
                        icon: const Icon(Icons.preview),
                        label: const Text('Aperçu'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isUploading ? null : () => setState(() => _showPreview = false),
                        icon: const Icon(Icons.edit),
                        label: const Text('Modifier'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _publishPost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                      ),
                      child: _isUploading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text(
                              'Publier',
                              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditor() {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status selector
              const Text('Visibilité:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildStatusChip('public', '🌐 Public'),
                    const SizedBox(width: 8),
                    _buildStatusChip('private', '🔒 Privé'),
                    const SizedBox(width: 8),
                    _buildStatusChip('connections', '👥 Connexions'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Post type
              const Text('Type de publication:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(label: Text('Texte'), value: 0),
                        ButtonSegment(label: Text('Photo'), value: 1),
                      ],
                      selected: <int>{_selectedPostType},
                      onSelectionChanged: (Set<int> newSelection) {
                        setState(() => _selectedPostType = newSelection.first);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Text input
              TextField(
                controller: _contentController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: 'Quoi de neuf?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
            ],
          ),
        ),
        // Image selector
        if (_selectedPostType == 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Photos:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isUploading ? null : _pickImages,
                        icon: const Icon(Icons.image),
                        label: const Text('Galerie'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isUploading ? null : _pickCamera,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Caméra'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        // Selected images preview
        if (_selectedImages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Images sélectionnées:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImages[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        // Error message
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red[700]),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPreview() {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusLabel(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Content preview
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Aperçu de votre publication',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _contentController.text.trim().isNotEmpty
                            ? _contentController.text
                            : '(Pas de texte)',
                        style: TextStyle(
                          fontSize: 16,
                          color: _contentController.text.trim().isNotEmpty
                              ? Colors.black
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_selectedImages.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Images:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) => ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImages[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String value, String label) {
    final isSelected = _selectedStatus == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) => setState(() => _selectedStatus = value),
      backgroundColor: isSelected ? const Color(0xFFD4AF37).withOpacity(0.2) : Colors.grey[200],
      side: isSelected
          ? const BorderSide(color: Color(0xFFD4AF37), width: 2)
          : BorderSide(color: Colors.grey[300]!),
    );
  }

  Color _getStatusColor() {
    switch (_selectedStatus) {
      case 'public':
        return Colors.blue;
      case 'private':
        return Colors.red;
      case 'connections':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel() {
    switch (_selectedStatus) {
      case 'public':
        return '🌐 Public';
      case 'private':
        return '🔒 Privé';
      case 'connections':
        return '👥 Connexions';
      default:
        return 'Public';
    }
  }
}
