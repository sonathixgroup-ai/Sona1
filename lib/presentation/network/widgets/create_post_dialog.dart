// lib/presentation/network/create_post_dialog.dart
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/providers/feed_provider.dart';
import 'package:thix_id/services/network_service.dart';
import 'package:thix_id/services/ai/ai_service.dart'; // 🛡️ Import de ton service IA

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

Future<Uint8List> compressImageBytes(Uint8List bytes) async {
  return FlutterImageCompress.compressWithList(
    bytes,
    minHeight: 1080,
    minWidth: 1080,
    quality: 85,
    rotate: 0,
  );
}

class _MediaItem {
  final Uint8List bytes;
  final String name;
  final bool isVideo;
  const _MediaItem(this.bytes, this.name, {this.isVideo = false});
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

  final List<_MediaItem> _images = [];
  final List<_MediaItem> _videos = [];
  bool _isUploading = false;
  String? _errorMessage;
  int _selectedPostType = 0;

  List<Map<String, dynamic>> _mentionSuggestions = [];
  bool _showMentions = false;
  String _currentMentionQuery = '';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Color> _textColors = const [
    _DialogColors.textDark, _DialogColors.primary, _DialogColors.gold,
    Color(0xFFE5484D), Color(0xFF059669),
  ];

  @override
  void initState() {
    super.initState();
    _contentController.addListener(_onContentChanged);
    _animationController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _animationController.forward();
  }

  @override
  void dispose() {
    _contentController.removeListener(_onContentChanged);
    _contentController.dispose();
    _contentFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    final text = _contentController.text;
    final lastAtIndex = text.lastIndexOf('@');
    if (lastAtIndex == -1) {
      if (_showMentions) setState(() => _showMentions = false);
      return;
    }
    if (lastAtIndex == text.length - 1) {
      setState(() { _showMentions = true; _currentMentionQuery = ''; });
    } else {
      final query = text.substring(lastAtIndex + 1);
      if (query.contains(' ') || query.contains('\n')) {
        setState(() => _showMentions = false);
      } else {
        setState(() { _showMentions = true; _currentMentionQuery = query; });
        _searchUsers(query);
      }
    }
  }

  Future<void> _searchUsers(String query) async {
    try {
      final ns = Provider.of<NetworkService>(context, listen: false);
      final users = await ns.searchUsers(query);
      if (mounted) setState(() => _mentionSuggestions = users);
    } catch (e) {
      debugPrint('Error searching users: $e');
    }
  }

  void _insertMention(Map<String, dynamic> user) {
    final text = _contentController.text;
    final lastAtIndex = text.lastIndexOf('@');
    final before = text.substring(0, lastAtIndex);
    final newText = '$before@${user['display_name']} ';
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
    setState(() => _showMentions = false);
  }

  void _wrapSelection(String prefix, String suffix) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    if (!selection.isValid) {
      final newText = '$text$prefix$suffix';
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length - suffix.length),
      );
    } else {
      final start = selection.start, end = selection.end;
      final selected = text.substring(start, end);
      final newText = text.replaceRange(start, end, '$prefix$selected$suffix');
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start + prefix.length + selected.length + suffix.length),
      );
    }
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
          for (final f in result.files) {
            if (f.bytes != null) {
              _images.add(_MediaItem(f.bytes!, f.name));
            }
          }
          _selectedPostType = _images.isNotEmpty ? 1 : 0;
        });
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
      if (mounted) setState(() => _errorMessage = 'Erreur lors de la sélection des images');
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
          for (final f in result.files) {
            if (f.bytes != null) {
              _videos.add(_MediaItem(f.bytes!, f.name, isVideo: true));
            }
          }
          _selectedPostType = 2;
        });
      }
    } catch (e) {
      debugPrint('Error picking videos: $e');
      if (mounted) setState(() => _errorMessage = 'Erreur lors de la sélection des vidéos');
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
        final f = result.files.first;
        if (f.bytes != null) {
          _images.add(_MediaItem(f.bytes!, f.name));
        }
      }
    } catch (e) {
      debugPrint('Error picking from camera: $e');
    }
  }

  void _removeMedia(int index, bool isVideo) {
    setState(() {
      if (isVideo) {
        _videos.removeAt(index);
      } else {
        _images.removeAt(index);
      }
    });
  }

  // ─── PUBLICATION AVEC FACT-CHECKING AUTOMATIQUE PAR L'IA ───
  Future<void> _publishPost() async {
    final textContent = _contentController.text.trim();
    if (textContent.isEmpty && _images.isEmpty && _videos.isEmpty) {
      setState(() => _errorMessage = 'Veuillez entrer du contenu ou sélectionner des médias');
      return;
    }

    setState(() => _isUploading = true);

    try {
      final networkService = Provider.of<NetworkService>(context, listen: false);
      final feedProvider = Provider.of<FeedProvider>(context, listen: false);

      // 🛡️ 1. ANALYSE FACT-CHECKING AUTOMATIQUE AVANT L'ENVOI
      bool isMisinformation = false;
      String? factCheckMessage;
      String? factCheckSeverity;

      if (textContent.isNotEmpty) {
        try {
          final aiService = AiService(Supabase.instance.client);
          
          final today = DateTime.now();
          final currentDateString = "${today.day}/${today.month}/${today.year}";

          // 🚨 NOUVEAU PROMPT STRICT QUI IGNORE LES FAUTES ET VALIDE TES TITRES
          final prompt = """
Date actuelle : $currentDateString

Analyse cette publication pour un réseau social professionnel :
"$textContent"

RÈGLES DE MODÉRATION INTRANSIGEANTES :
1. IGNORE L'ORTHOGRAPHE ET LA GRAMMAIRE : Une faute de frappe, de grammaire ou un problème de majuscule/minuscule (ex: "sONATHIX", "fire" au lieu de "fier") N'EST JAMAIS une désinformation.
2. VALIDATION AUTOMATIQUE DES TITRES ET ENTREPRISES : Si l'auteur parle de son poste (CEO, fondateur, etc.), de son entreprise, de ses projets professionnels ou institutionnels, tu DOIS répondre SAFE. Ne remets jamais en question l'identité professionnelle de l'auteur.
3. CIBLE UNIQUEMENT LE DANGER PUBLIC : Signale UNIQUEMENT les rumeurs graves, absurdes ou dangereuses pour la société (ex: fausse annonce de décès d'une personnalité politique, fausse alerte sécuritaire nationale).
4. En cas de moindre doute, ou si le texte est inoffensif, réponds SAFE.

Réponds STRICTEMENT sous forme de texte brut avec l'un des deux formats :
- SAFE
- FAKE: [Explique très brièvement pourquoi c'est une rumeur publique grave]
""";

          final aiResponse = await aiService.askAi(
            prompt: prompt,
            provider: AiProvider.mistral,
            systemPrompt: "Tu es un outil technique silencieux. Tu ne corriges pas les fautes. Tu ne vérifies que les Fake News extrêmement graves à l'échelle nationale ou mondiale.",
          );

          if (aiResponse.toUpperCase().contains("FAKE:")) {
            isMisinformation = true;
            factCheckMessage = aiResponse.replaceAll(RegExp(r'FAKE:\s*', caseSensitive: false), '').trim();
            factCheckSeverity = "fake";
          }
        } catch (aiError) {
          debugPrint('Erreur Fact-Check IA (non bloquante) : $aiError');
        }
      }

      // 2. Upload des images
      final imageUrls = <String>[];
      for (final item in _images) {
        try {
          final compressed = await compute(compressImageBytes, item.bytes);
          final ext = item.name.split('.').last;
          final url = await networkService.uploadImageBytes(compressed, fileExtension: ext);
          if (url != null && url.isNotEmpty) imageUrls.add(url);
        } catch (e) {
          debugPrint('Image upload error: $e');
        }
      }

      // 3. Upload des vidéos
      final videoUrls = <String>[];
      for (final item in _videos) {
        try {
          final ext = item.name.split('.').last;
          final url = await networkService.uploadImageBytes(item.bytes, fileExtension: ext);
          if (url != null && url.isNotEmpty) videoUrls.add(url);
        } catch (e) {
          debugPrint('Video upload error: $e');
        }
      }

      final allMedia = [...imageUrls, ...videoUrls];
      
      // 4. Insertion dans Supabase avec les données de Fact-Checking
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("Utilisateur non authentifié");

      final responseMap = await Supabase.instance.client.from('posts').insert({
        'user_id': user.id,
        'content': textContent,
        'media_urls': allMedia,
        'community_id': widget.communityId,
        'is_fact_checked': true,
        'is_misinformation': isMisinformation,
        'fact_check_message': factCheckMessage,
        'fact_check_severity': factCheckSeverity,
      }).select('id').maybeSingle();

      final postId = responseMap?['id']?.toString() ?? '';

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
            SnackBar(
              content: Text(isMisinformation ? 'Publication publiée avec avertissement Fact-Check.' : 'Publication réussie !'),
              backgroundColor: isMisinformation ? Colors.orange : _DialogColors.primary,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) setState(() => _errorMessage = 'Erreur lors de la publication');
      }
    } catch (e) {
      debugPrint('Error publishing post: $e');
      if (mounted) setState(() => _errorMessage = 'Erreur: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

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
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
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
                    decoration: const BoxDecoration(
                      color: _DialogColors.softBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 18, color: _DialogColors.textDark),
                  ),
                ),
              ]),
              const SizedBox(height: 14),

              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEAEA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFE5484D)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorMessage!, style: const TextStyle(fontSize: 12, color: Color(0xFFE5484D)))),
                  ]),
                ),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _DialogColors.softBlue,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(children: [
                        _formatBtn(
                          child: const Text('B', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                          onTap: _applyBold,
                          tooltip: 'Gras',
                        ),
                        const SizedBox(width: 6),
                        _formatBtn(
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
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.35),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )),
                      ]),
                    ),
                    const SizedBox(height: 10),

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
                          hintText: 'Quoi de neuf dans votre monde pro ?\n\nL\'IA de Fact-Checking THIX analysera automatiquement votre publication.',
                          hintStyle: TextStyle(color: _DialogColors.textSecondary, fontSize: 13.5, height: 1.4),
                          border: InputBorder.none,
                          isCollapsed: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_showMentions && _mentionSuggestions.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _DialogColors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _DialogColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: _DialogColors.shadow,
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
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
                                    ? Text(
                                        user['display_name'][0].toUpperCase(),
                                        style: const TextStyle(fontSize: 11, color: _DialogColors.primaryDeep),
                                      )
                                    : null,
                              ),
                              title: Text(user['display_name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              onTap: () => _insertMention(user),
                            );
                          }).toList(),
                        ),
                      ),

                    if (_images.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _images.map((item) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.memory(
                                  item.bytes,
                                  width: 84,
                                  height: 84,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: _DialogColors.softBlue,
                                    child: const Icon(Icons.broken_image),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeMedia(_images.indexOf(item), false),
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

                    if (_videos.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _videos.map((item) {
                            return Stack(
                              children: [
                                Container(
                                  width: 84,
                                  height: 84,
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeMedia(_videos.indexOf(item), true),
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
                      ),
                  ]),
                ),
              ),

              const SizedBox(height: 12),
              Row(children: [
                _mediaBtn(Icons.photo_rounded, _pickImages, const Color(0xFF059669)),
                _mediaBtn(Icons.videocam_rounded, _pickVideos, const Color(0xFFE5484D)),
                _mediaBtn(Icons.photo_camera_rounded, _pickCamera, _DialogColors.primary),
                const Spacer(),
                if (_images.isNotEmpty || _videos.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _DialogColors.softBlue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_images.length + _videos.length} média(s)',
                      style: const TextStyle(fontSize: 11, color: _DialogColors.primaryDeep, fontWeight: FontWeight.w700),
                    ),
                  ),
              ]),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_DialogColors.gold, Color(0xFFEFC777)]),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: _DialogColors.gold.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
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

  Widget _formatBtn({required Widget child, required VoidCallback onTap, required String tooltip}) {
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
            boxShadow: [
              BoxShadow(
                color: _DialogColors.shadow,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _mediaBtn(IconData icon, VoidCallback onTap, Color color) {
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
