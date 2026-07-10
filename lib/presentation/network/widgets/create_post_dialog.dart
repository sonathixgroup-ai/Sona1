import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:thix_id/providers/feed_provider.dart';
import 'package:thix_id/services/network_service.dart';

// ─── COULEURS THIX PRO — identiques à NetworkProHome pour cohérence ───
class _DialogColors {
  static const Color background = Color(0xFFF6F9FF);
  static const Color white = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF2D6CDF);
  static const Color primaryDeep = Color(0xFF123B7A);
  static const Color softBlue = Color(0xFFEAF1FF);
  static const Color gold = Color(0xFFD9A63C);
  static const Color textDark = Color(0xFF10192E);
  static const Color textSecondary = Color(0xFF7386A8);
  static const Color border = Color(0xFFE7EEFC);
  static const Color shadow = Color(0x142D6CDF);
}

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
  final FocusNode _contentFocusNode = FocusNode();
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

  // ✅ Petite palette de couleurs pour le texte (insertion via marqueurs {c:#HEX}...{c})
  final List<Color> _textColors = const [
    _DialogColors.textDark,
    _DialogColors.primary,
    _DialogColors.gold,
    Color(0xFFE5484D),
    Color(0xFF059669),
  ];

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
    _contentFocusNode.dispose();
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

  // ✅ Insère un marqueur de formatage autour de la sélection actuelle
  // (ou aux positions du curseur si rien n'est sélectionné)
  void _wrapSelection(String prefix, String suffix) {
    final text = _contentController.text;
    final selection = _contentController.selection;

    if (!selection.isValid) {
      final cursor = text.length;
      final newText = '$text$prefix$suffix';
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: cursor + prefix.length),
      );
      _contentFocusNode.requestFocus();
      return;
    }

    final start = selection.start;
    final end = selection.end;
    final selectedText = text.substring(start, end);
    final newText = text.replaceRange(start, end, '$prefix$selectedText$suffix');

    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: start + prefix.length + selectedText.length + suffix.length,
      ),
    );
    _contentFocusNode.requestFocus();
  }

  void _applyBold() => _wrapSelection('**', '**');
  void _applyItalic() => _wrapSelection('*', '*');
  void _applyColor(Color color) {
    final hex = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
    _wrapSelection('{c:$hex}', '{c}');
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
        final url = await networkService.uploadImageBytes(bytes, fileExtension: ext);
        if (url != null && url.isNotEmpty) videoUrls.add(url);
      }

      // Combine all media
      final allMedia = [...imageUrls, ...videoUrls];

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
              backgroundColor: _DialogColors.primary,
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

  // ========== BUILD COMPLET ==========
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: _DialogColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.94,
          constraints: const BoxConstraints(maxHeight: 720),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [_DialogColors.primaryDeep, _DialogColors.primary],
                    ).createShader(bounds),
                    child: const Text(
                      'Créer une publication',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: _DialogColors.softBlue, shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, size: 18, color: _DialogColors.textDark),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEAEA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFE5484D)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_errorMessage!, style: const TextStyle(fontSize: 12, color: Color(0xFFE5484D))),
                      ),
                    ],
                  ),
                ),

              // ── Corps scrollable ──
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Barre de formatage : Gras / Italique / Couleur ──
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _DialogColors.softBlue,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            _formatButton(
                              child: const Text('B', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                              onTap: _applyBold,
                              tooltip: 'Gras',
                            ),
                            const SizedBox(width: 6),
                            _formatButton(
                              child: const Text('I', style: TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.w800, fontSize: 14)),
                              onTap: _applyItalic,
                              tooltip: 'Italique',
                            ),
                            Container(width: 1, height: 20, color: _DialogColors.border, margin: const EdgeInsets.symmetric(horizontal: 8)),
                            ..._textColors.map((color) => Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: GestureDetector(
                                    onTap: () => _applyColor(color),
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                        boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 5, offset: const Offset(0, 2))],
                                      ),
                                    ),
                                  ),
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ── Champ de texte — GRANDE zone d'écriture ──
                      Container(
                        decoration: BoxDecoration(
                          color: _DialogColors.background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _DialogColors.border),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: TextField(
                          controller: _contentController,
                          focusNode: _contentFocusNode,
                          minLines: 8,
                          maxLines: 14,
                          style: const TextStyle(fontSize: 15, color: _DialogColors.textDark, height: 1.4),
                          decoration: const InputDecoration(
                            hintText: 'Quoi de neuf dans votre monde pro ?\n\nUtilisez la barre ci-dessus pour mettre en gras, italique ou en couleur.',
                            hintStyle: TextStyle(color: _DialogColors.textSecondary, fontSize: 13.5, height: 1.4),
                            border: InputBorder.none,
                            isCollapsed: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Mentions ──
                      if (_showMentions && _mentionSuggestions.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _DialogColors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _DialogColors.border),
                            boxShadow: [BoxShadow(color: _DialogColors.shadow, blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            children: _mentionSuggestions.map((user) {
                              return ListTile(
                                dense: true,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                leading: CircleAvatar(
                                  radius: 14,
                                  backgroundColor: _DialogColors.softBlue,
                                  backgroundImage: user['avatar'] != null ? NetworkImage(user['avatar']) : null,
                                  child: user['avatar'] == null
                                      ? Text(user['display_name'][0].toUpperCase(), style: const TextStyle(fontSize: 11, color: _DialogColors.primaryDeep))
                                      : null,
                                ),
                                title: Text(user['display_name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                onTap: () => _insertMention(user),
                              );
                            }).toList(),
                          ),
                        ),

                      // ── Images sélectionnées ──
                      if (_selectedImages.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedImages.map((img) {
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.memory(
                                    img.bytes!,
                                    width: 84,
                                    height: 84,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeMedia(_selectedImages.indexOf(img), false),
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close_rounded, size: 13, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),

                      // ── Vidéos sélectionnées ──
                      if (_selectedVideos.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _selectedVideos.map((vid) {
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.memory(
                                      vid.bytes!,
                                      width: 84,
                                      height: 84,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeMedia(_selectedVideos.indexOf(vid), true),
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close_rounded, size: 13, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: Colors.black45,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ── Footer ──
              const SizedBox(height: 12),
              Row(
                children: [
                  _mediaIconButton(Icons.photo_rounded, _pickImages, const Color(0xFF059669)),
                  _mediaIconButton(Icons.videocam_rounded, _pickVideos, const Color(0xFFE5484D)),
                  _mediaIconButton(Icons.photo_camera_rounded, _pickCamera, _DialogColors.primary),
                  const Spacer(),
                  if (_selectedImages.isNotEmpty || _selectedVideos.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: _DialogColors.softBlue, borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        '${_selectedImages.length + _selectedVideos.length} média(s)',
                        style: const TextStyle(fontSize: 11, color: _DialogColors.primaryDeep, fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Bouton Publier ──
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_DialogColors.gold, Color(0xFFEFC777)]),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: _DialogColors.gold.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 6))],
                ),
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _publishPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: _DialogColors.primaryDeep,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: _DialogColors.primaryDeep),
                        )
                      : const Text('PUBLIER', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.4)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formatButton({required Widget child, required VoidCallback onTap, required String tooltip}) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _DialogColors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: _DialogColors.shadow, blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _mediaIconButton(IconData icon, VoidCallback onTap, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _DialogColors.softBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
