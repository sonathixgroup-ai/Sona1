// lib/presentation/feed/create_post_dialog.dart
import 'dart:typed_data'; 
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
        final url = await networkService.uploadVideoBytes(bytes, fileExtension: ext);
        if (url != null && url.isNotEmpty) videoUrls.add(url);
      }

      // Combine all media
      final allMedia = [...imageUrls, ...videoUrls];

      final postId = await networkService.createPost(
        _contentController.text.trim(),
        allMedia,
        status: _selectedStatus,
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header (élégant)
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade100, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Créer une publication',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 20, color: Color(0xFF1A1A2E)),
                      ),
                    ),
                  ],
                ),
              ),
              // Body
              Expanded(
                child: _showPreview ? _buildPreview() : _buildEditor(),
              ),
              // Footer (actions)
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade100, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    // Bouton Aperçu / Modifier
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isUploading
                            ? null
                            : () => setState(() => _showPreview = !_showPreview),
                        icon: Icon(
                          _showPreview ? Icons.edit : Icons.preview,
                          size: 18,
                          color: const Color(0xFF1A1A2E),
                        ),
                        label: Text(
                          _showPreview ? 'Modifier' : 'Aperçu',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Bouton Publier
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isUploading ? null : _publishPost,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: _isUploading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Text(
                                'Publier',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: Colors.white,
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
      ),
    );
  }

  Widget _buildEditor() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status selector (élégant)
          const Text(
            'Visibilité',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              _buildStatusChip('public', '🌐 Public', Colors.blue),
              _buildStatusChip('private', '🔒 Privé', Colors.red),
              _buildStatusChip('connections', '👥 Connexions', Colors.green),
            ],
          ),
          const SizedBox(height: 20),

          // Type selector (segmented)
          const Text(
            'Type de publication',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<int>(
            style: SegmentedButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              selectedBackgroundColor: const Color(0xFFD4AF37).withOpacity(0.2),
              selectedForegroundColor: const Color(0xFFD4AF37),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            segments: const [
              ButtonSegment(label: Text('Texte'), value: 0),
              ButtonSegment(label: Text('Photo'), value: 1),
              ButtonSegment(label: Text('Vidéo'), value: 2),
            ],
            selected: <int>{_selectedPostType},
            onSelectionChanged: (Set<int> newSelection) {
              setState(() => _selectedPostType = newSelection.first);
            },
          ),
          const SizedBox(height: 20),

          // Text input (élégant)
          TextField(
            controller: _contentController,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: 'Quoi de neuf?',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),

          // Mention suggestions
          if (_showMentions && _mentionSuggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _mentionSuggestions.length,
                itemBuilder: (context, index) {
                  final user = _mentionSuggestions[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: user['avatar'] != null
                          ? NetworkImage(user['avatar'])
                          : null,
                      child: user['avatar'] == null
                          ? Text(user['display_name'][0].toUpperCase())
                          : null,
                      radius: 18,
                    ),
                    title: Text(user['display_name']),
                    subtitle: Text('@${user['username']}'),
                    onTap: () => _insertMention(user),
                  );
                },
              ),
            ),

          // Media pickers (élégants)
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isUploading ? null : _pickImages,
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: const Text('Galerie'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isUploading ? null : _pickVideos,
                  icon: const Icon(Icons.video_library_outlined, size: 18),
                  label: const Text('Vidéo'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isUploading ? null : _pickCamera,
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text('Caméra'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Selected images preview (élégant)
          if (_selectedImages.isNotEmpty || _selectedVideos.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._selectedImages.map((img) => _buildMediaChip(img.bytes!, false)),
                ..._selectedVideos.map((vid) => _buildMediaChip(vid.bytes!, true)),
              ],
            ),
          ],

          // Error message
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade400),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMediaChip(Uint8List bytes, bool isVideo) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            bytes,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
        if (isVideo)
          Positioned.fill(
            child: Container(
              color: Colors.black26,
              child: const Center(
                child: Icon(Icons.play_circle_filled, size: 30, color: Colors.white),
              ),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeMedia(
              _selectedImages.indexWhere((e) => e.bytes == bytes),
              isVideo,
            ),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String value, String label, Color color) {
    final isSelected = _selectedStatus == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label, style: const TextStyle(fontSize: 13)),
      onSelected: (_) => setState(() => _selectedStatus = value),
      backgroundColor: isSelected ? color.withOpacity(0.15) : Colors.grey.shade100,
      side: isSelected
          ? BorderSide(color: color, width: 2)
          : BorderSide(color: Colors.grey.shade300),
      selectedColor: color.withOpacity(0.15),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    );
  }

  Widget _buildPreview() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Status badge
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                _getStatusLabel(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            Text(
              'Aperçu',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Card preview
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _contentController.text.trim().isNotEmpty
                    ? _contentController.text
                    : '(Pas de texte)',
                style: TextStyle(
                  fontSize: 16,
                  color: _contentController.text.trim().isNotEmpty
                      ? Colors.black87
                      : Colors.grey.shade400,
                  height: 1.5,
                ),
              ),
              if (_selectedImages.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedImages.map((img) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        img.bytes!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    );
                  }).toList(),
                ),
              ],
              if (_selectedVideos.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedVideos.map((vid) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            vid.bytes!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned.fill(
                          child: Container(
                            color: Colors.black26,
                            child: const Center(
                              child: Icon(Icons.play_circle_filled, size: 30, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (_selectedStatus) {
      case 'public':
        return Colors.blue.shade600;
      case 'private':
        return Colors.red.shade600;
      case 'connections':
        return Colors.green.shade600;
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
