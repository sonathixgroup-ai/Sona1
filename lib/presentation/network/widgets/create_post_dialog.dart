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
import 'package:thix_id/services/ai/ai_service.dart';

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

  // Contrôleurs spécifiques Sondages et Challenges
  final List<TextEditingController> _pollOptionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  final TextEditingController _challengeDescController = TextEditingController();
  DateTime? _challengeEndDate;

  // 0 = Standard, 1 = Sondage, 2 = Challenge
  int _postTypeMode = 0;

  final List<_MediaItem> _images = [];
  final List<_MediaItem> _videos = [];
  bool _isUploading = false;
  String? _errorMessage;

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
    _challengeDescController.dispose();
    for (var c in _pollOptionControllers) {
      c.dispose();
    }
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

  // ─── PUBLICATION AVEC FACT-CHECKING ET GESTION DES MODES FORCÉS ───
  Future<void> _publishPost() async {
    final textContent = _contentController.text.trim();
    
    // Validations selon le mode
    if (_postTypeMode == 0 && textContent.isEmpty && _images.isEmpty && _videos.isEmpty) {
      setState(() => _errorMessage = 'Veuillez entrer du contenu ou sélectionner des médias');
      return;
    }
    if (_postTypeMode == 1 && textContent.isEmpty) {
      setState(() => _errorMessage = 'Veuillez saisir la question du sondage');
      return;
    }
    if (_postTypeMode == 2 && (textContent.isEmpty || _challengeEndDate == null)) {
      setState(() => _errorMessage = 'Veuillez remplir le titre et la date de fin du challenge');
      return;
    }

    setState(() => _isUploading = true);

    try {
      final networkService = Provider.of<NetworkService>(context, listen: false);
      final feedProvider = Provider.of<FeedProvider>(context, listen: false);

      bool isMisinformation = false;
      String? factCheckMessage;
      String? factCheckSeverity;

      // Fact-Checking uniquement sur le texte principal si présent
      if (textContent.isNotEmpty) {
        try {
          List<String> webSources = [];
          try {
            final response = await Supabase.instance.client.rpc(
              'search_tavily',
              params: {'search_query': textContent},
            );

            if (response != null && response['results'] != null) {
              final results = response['results'] as List;
              for (var r in results) {
                webSources.add("- ${r['title']}: ${r['content']}");
              }
            }
          } catch (searchError) {
            debugPrint('Erreur recherche web Supabase (non bloquante) : $searchError');
          }

          final contextSources = webSources.isNotEmpty 
              ? "SOURCES WEB TROUVÉES EN TEMPS RÉEL :\n${webSources.join('\n')}" 
              : "Aucune source web spécifique trouvée.";

          final aiService = AiService(Supabase.instance.client);
          final today = DateTime.now();
          final currentDateString = "${today.day}/${today.month}/${today.year}";

          final prompt = """
Date actuelle : $currentDateString

$contextSources

Tu es un moteur de FACT-CHECKING professionnel.
Ta mission est d'analyser UNIQUEMENT la véracité des affirmations factuelles présentes dans la publication suivante.

PUBLICATION :
"$textContent"

====================================================
RÈGLES ABSOLUES
====================================================
Analyse uniquement le FOND.
Ignore totalement : fautes, style, emojis, opinions, satire, présentations personnelles.
Réponds SAFE par défaut si non prouvé faux.
Format de réponse :
SAFE
ou
FAKE: [raison]
""";

          final aiResponse = await aiService.askAi(
            prompt: prompt,
            provider: AiProvider.mistral,
            systemPrompt: "Tu es THIX Fact-Check AI. Réponds uniquement par SAFE ou FAKE: raison.",
          );

          final responseText = aiResponse.trim().toUpperCase();
          if (responseText.startsWith("FAKE:")) {
            isMisinformation = true;
            factCheckSeverity = "fake";
            factCheckMessage = aiResponse.substring(aiResponse.toUpperCase().indexOf("FAKE:") + 5).trim();
          }
        } catch (aiError) {
          debugPrint('Erreur Fact-Check IA (non bloquante) : $aiError');
        }
      }

      // Upload des images
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

      // Upload des vidéos
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
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("Utilisateur non authentifié");

      // ── ENREGISTREMENT STRICT SELON LE MODE ──
      if (_postTypeMode == 1) {
        // 📊 SONDAGE
        final options = _pollOptionControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
        if (options.length < 2) {
          setState(() {
            _errorMessage = 'Un sondage doit contenir au moins 2 options valides.';
            _isUploading = false;
          });
          return;
        }

        final formattedOptions = options.map((opt) => {'text': opt, 'votes': <String>[]}).toList();

        await Supabase.instance.client.from('posts').insert({
          'user_id': user.id,
          'content': textContent,
          'media_urls': allMedia,
          'community_id': widget.communityId,
          'post_type': 'poll', // Forcé à 'poll'
          'poll_data': {'options': formattedOptions},
          'is_fact_checked': true,
          'is_misinformation': isMisinformation,
          'fact_check_message': factCheckMessage,
          'fact_check_severity': factCheckSeverity,
        });

      } else if (_postTypeMode == 2) {
        // 🏆 CHALLENGE
        await Supabase.instance.client.from('posts').insert({
          'user_id': user.id,
          'content': textContent,
          'media_urls': allMedia,
          'community_id': widget.communityId,
          'post_type': 'challenge', // Forcé à 'challenge'
          'challenge_data': {
            'description': _challengeDescController.text.trim(),
            'end_date': _challengeEndDate?.toIso8601String(),
            'participants_count': 0,
          },
          'is_fact_checked': true,
          'is_misinformation': isMisinformation,
          'fact_check_message': factCheckMessage,
          'fact_check_severity': factCheckSeverity,
        });

      } else {
        // 📄 STANDARD
        await Supabase.instance.client.from('posts').insert({
          'user_id': user.id,
          'content': textContent,
          'media_urls': allMedia,
          'community_id': widget.communityId,
          'post_type': 'standard',
          'is_fact_checked': true,
          'is_misinformation': isMisinformation,
          'fact_check_message': factCheckMessage,
          'fact_check_severity': factCheckSeverity,
        });
      }

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
          constraints: const BoxConstraints(maxHeight: 750),
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
              const SizedBox(height: 10),

              // Onglets de choix (Publication / Sondage / Challenge)
              Row(
                children: [
                  _buildTypeTab('Publication', 0, Icons.article_rounded),
                  const SizedBox(width: 6),
                  _buildTypeTab('Sondage', 1, Icons.poll_rounded),
                  const SizedBox(width: 6),
                  _buildTypeTab('Challenge', 2, Icons.emoji_events_rounded),
                ],
              ),
              const SizedBox(height: 12),

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
                    if (_postTypeMode == 0) ...[
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
                    ],

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
                        minLines: _postTypeMode == 2 ? 1 : 6,
                        maxLines: 10,
                        style: const TextStyle(fontSize: 15, color: _DialogColors.textDark, height: 1.4),
                        decoration: InputDecoration(
                          hintText: _postTypeMode == 1
                              ? 'Posez votre question de sondage...'
                              : _postTypeMode == 2
                                  ? 'Titre du challenge...'
                                  : 'Quoi de neuf dans votre monde pro ?\n\nL\'IA de Fact-Checking THIX analysera automatiquement votre publication.',
                          hintStyle: const TextStyle(color: _DialogColors.textSecondary, fontSize: 13.5, height: 1.4),
                          border: InputBorder.none,
                          isCollapsed: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Spécifique SONDAGE
                    if (_postTypeMode == 1) ...[
                      const Text('Options du sondage :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _DialogColors.textDark)),
                      const SizedBox(height: 6),
                      ..._pollOptionControllers.asMap().entries.map((entry) {
                        int index = entry.key;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TextField(
                            controller: entry.value,
                            decoration: InputDecoration(
                              hintText: 'Option ${index + 1}',
                              isDense: true,
                              filled: true,
                              fillColor: _DialogColors.background,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                        );
                      }),
                      if (_pollOptionControllers.length < 4)
                        TextButton.icon(
                          onPressed: () => setState(() => _pollOptionControllers.add(TextEditingController())),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Ajouter une option'),
                        ),
                      const SizedBox(height: 12),
                    ],

                    // Spécifique CHALLENGE
                    if (_postTypeMode == 2) ...[
                      const Text('Description et Règles :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _DialogColors.textDark)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _challengeDescController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Décrivez les règles du challenge...',
                          filled: true,
                          fillColor: _DialogColors.background,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Date de fin : ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          TextButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now().add(const Duration(days: 7)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) setState(() => _challengeEndDate = picked);
                            },
                            icon: const Icon(Icons.calendar_today_rounded, size: 16),
                            label: Text(_challengeEndDate == null ? 'Choisir une date' : '${_challengeEndDate!.day}/${_challengeEndDate!.month}/${_challengeEndDate!.year}'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

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

  Widget _buildTypeTab(String label, int modeIndex, IconData icon) {
    final isSelected = _postTypeMode == modeIndex;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _postTypeMode = modeIndex),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? _DialogColors.primary : _DialogColors.softBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : _DialogColors.primaryDeep),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : _DialogColors.textDark)),
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
