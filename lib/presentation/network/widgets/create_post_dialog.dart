import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/features/network/data/network_service_provider.dart';
import 'package:thix_id/features/network/presentation/providers/feed_provider.dart';
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

class CreatePostDialog extends ConsumerStatefulWidget {
  final String? communityId;
  final VoidCallback? onPostCreated;
  const CreatePostDialog({super.key, this.communityId, this.onPostCreated});
  @override
  ConsumerState<CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends ConsumerState<CreatePostDialog>
    with SingleTickerProviderStateMixin {
  final _contentController = TextEditingController();
  final _contentFocusNode = FocusNode();
  final _pollOptionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  final _challengeDescController = TextEditingController();
  DateTime? _challengeEndDate;
  int _postTypeMode = 0;
  final List<_MediaItem> _images = [];
  final List<_MediaItem> _videos = [];
  bool _isUploading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _mentionSuggestions = [];
  bool _showMentions = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _animationController.forward();
  }

  @override
  void dispose() {
    _contentController.removeListener(_onContentChanged);
    _contentController.dispose();
    _contentFocusNode.dispose();
    _challengeDescController.dispose();
    for (final c in _pollOptionControllers) c.dispose();
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
    final query = text.substring(lastAtIndex + 1);
    if (query.contains(' ') || query.contains('\n')) {
      setState(() => _showMentions = false);
    } else {
      setState(() => _showMentions = true);
      _searchUsers(query);
    }
  }

  Future<void> _searchUsers(String query) async {
    try {
      final users = await ref.read(networkServiceProvider).searchUsers(query);
      if (mounted) setState(() => _mentionSuggestions = users);
    } catch (e) {
      debugPrint('search error $e');
    }
  }

  void _insertMention(Map<String, dynamic> user) {
    final text = _contentController.text;
    final lastAtIndex = text.lastIndexOf('@');
    final before = text.substring(0, lastAtIndex);
    final newText = '$before@${user['display_name']} ';
    _contentController.value = TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: newText.length));
    setState(() => _showMentions = false);
  }

  void _wrapSelection(String prefix, String suffix) {
    final text = _contentController.text;
    final sel = _contentController.selection;
    if (!sel.isValid) {
      final newText = '$text$prefix$suffix';
      _contentController.value = TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: newText.length - suffix.length));
    } else {
      final start = sel.start;
      final end = sel.end;
      final selected = text.substring(start, end);
      final newText = text.replaceRange(start, end, '$prefix$selected$suffix');
      _contentController.value = TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: start + prefix.length + selected.length + suffix.length));
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
    final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: true, withData: true);
    if (result!= null && mounted) {
      setState(() {
        for (final f in result.files) {
          if (f.bytes!= null) _images.add(_MediaItem(f.bytes!, f.name));
        }
      });
    }
  }

  Future<void> _pickVideos() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video, allowMultiple: true, withData: true);
    if (result!= null && mounted) {
      setState(() {
        for (final f in result.files) {
          if (f.bytes!= null) _videos.add(_MediaItem(f.bytes!, f.name, isVideo: true));
        }
      });
    }
  }

  Future<void> _pickCamera() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false, withData: true);
    if (result!= null && result.files.isNotEmpty && mounted) {
      final f = result.files.first;
      if (f.bytes!= null) setState(() => _images.add(_MediaItem(f.bytes!, f.name)));
    }
  }

  void _removeMedia(int index, bool isVideo) {
    setState(() {
      if (isVideo) _videos.removeAt(index);
      else _images.removeAt(index);
    });
  }

  Future<void> _publishPost() async {
    final textContent = _contentController.text.trim();
    if (_postTypeMode == 0 && textContent.isEmpty && _images.isEmpty && _videos.isEmpty) {
      setState(() => _errorMessage = 'Veuillez entrer du contenu');
      return;
    }
    setState(() => _isUploading = true);
    try {
      final ns = ref.read(networkServiceProvider);
      bool isMisinformation = false;
      String? factCheckMessage;
      String? factCheckSeverity;

      if (textContent.isNotEmpty) {
        try {
          final aiService = AiService(Supabase.instance.client);
          final prompt = 'PUBLICATION: "$textContent" Réponds SAFE ou FAKE: raison';
          final aiResponse = await aiService.askAi(prompt: prompt, provider: AiProvider.mistral, systemPrompt: 'Tu es THIX Fact-Check AI.');
          if (aiResponse.trim().toUpperCase().startsWith('FAKE:')) {
            isMisinformation = true;
            factCheckSeverity = 'fake';
            factCheckMessage = aiResponse.substring(5).trim();
          }
        } catch (_) {}
      }

      final List<String> imageUrls = [];
      for (final item in _images) {
        try {
          final compressed = await compute(compressImageBytes, item.bytes);
          final ext = item.name.split('.').last;
          final url = await ns.uploadImageBytes(compressed, fileExtension: ext);
          if (url!= null && url.isNotEmpty) imageUrls.add(url);
        } catch (_) {}
      }

      final List<String> videoUrls = [];
      for (final item in _videos) {
        try {
          final ext = item.name.split('.').last;
          final url = await ns.uploadImageBytes(item.bytes, fileExtension: ext);
          if (url!= null && url.isNotEmpty) videoUrls.add(url);
        } catch (_) {}
      }

      final List<String> allMedia = [];
      allMedia.addAll(imageUrls);
      allMedia.addAll(videoUrls);

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Non authentifié');

      final Map<String, dynamic> payload = {};
      payload['user_id'] = user.id;
      payload['content'] = textContent;
      payload['media_urls'] = allMedia;
      payload['community_id'] = widget.communityId;
      payload['is_fact_checked'] = true;
      payload['is_misinformation'] = isMisinformation;
      payload['fact_check_message'] = factCheckMessage;
      payload['fact_check_severity'] = factCheckSeverity;

      if (_postTypeMode == 1) {
        final options = _pollOptionControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
        if (options.length < 2) throw Exception('2 options minimum');
        payload['post_type'] = 'poll';
        payload['poll_data'] = {'options': options.map((o) => {'text': o, 'votes': []}).toList()};
      } else if (_postTypeMode == 2) {
        payload['post_type'] = 'challenge';
        payload['challenge_data'] = {'description': _challengeDescController.text.trim(), 'end_date': _challengeEndDate?.toIso8601String(), 'participants_count': 0};
      } else {
        payload['post_type'] = 'standard';
      }

      await Supabase.instance.client.from('posts').insert(payload);
      ref.invalidate(feedProvider);
      widget.onPostCreated?.call();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Widget _buildTypeTab(String label, int modeIndex, IconData icon) {
    final isSelected = _postTypeMode == modeIndex;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _postTypeMode = modeIndex),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: isSelected? _DialogColors.primary : _DialogColors.softBlue, borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 16, color: isSelected? Colors.white : _DialogColors.primaryDeep),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected? Colors.white : _DialogColors.textDark)),
          ]),
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
          decoration: BoxDecoration(color: _DialogColors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: _DialogColors.shadow, blurRadius: 4, offset: const Offset(0, 2))]),
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
        child: Container(width: 38, height: 38, decoration: BoxDecoration(color: _DialogColors.softBlue, borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 18, color: color)),
      ),
    );
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
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(colors: [_DialogColors.primaryDeep, _DialogColors.primary]).createShader(b),
                child: const Text('Créer une publication', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
              InkWell(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: _DialogColors.softBlue, shape: BoxShape.circle), child: const Icon(Icons.close_rounded, size: 18))),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _buildTypeTab('Publication', 0, Icons.article_rounded),
              const SizedBox(width: 6),
              _buildTypeTab('Sondage', 1, Icons.poll_rounded),
              const SizedBox(width: 6),
              _buildTypeTab('Challenge', 2, Icons.emoji_events_rounded),
            ]),
            const SizedBox(height: 12),
            if (_errorMessage!= null)
              Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFFFEAEA), borderRadius: BorderRadius.circular(14)), child: Text(_errorMessage!, style: const TextStyle(fontSize: 12, color: Color(0xFFE5484D)))),
            Expanded(
              child: SingleChildScrollView(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: _DialogColors.softBlue, borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      _formatBtn(child: const Text('B', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)), onTap: _applyBold, tooltip: 'Gras'),
                      const SizedBox(width: 6),
                      _formatBtn(child: const Text('I', style: TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.w800, fontSize: 14)), onTap: _applyItalic, tooltip: 'Italique'),
                      Container(width: 1, height: 20, color: _DialogColors.border, margin: const EdgeInsets.symmetric(horizontal: 8)),
                      for (final color in _textColors)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () => _applyColor(color),
                            child: Container(width: 20, height: 20, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))),
                          ),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(color: _DialogColors.background, borderRadius: BorderRadius.circular(20), border: Border.all(color: _DialogColors.border)),
                    padding: const EdgeInsets.all(14),
                    child: TextField(
                      controller: _contentController,
                      focusNode: _contentFocusNode,
                      minLines: 6,
                      maxLines: 10,
                      decoration: InputDecoration(
                        hintText: _postTypeMode == 1? 'Question sondage...' : _postTypeMode == 2? 'Titre challenge...' : 'Quoi de neuf?',
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                    ),
                  ),
                  if (_postTypeMode == 1)...[
                    const SizedBox(height: 12),
                    const Text('Options:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    for (int i = 0; i < _pollOptionControllers.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TextField(
                          controller: _pollOptionControllers[i],
                          decoration: InputDecoration(hintText: 'Option ${i + 1}', filled: true, fillColor: _DialogColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                        ),
                      ),
                  ],
                  if (_postTypeMode == 2)...[
                    const SizedBox(height: 12),
                    TextField(controller: _challengeDescController, minLines: 3, maxLines: 5, decoration: InputDecoration(hintText: 'Règles...', filled: true, fillColor: _DialogColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
                  ],
                  if (_showMentions && _mentionSuggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      decoration: BoxDecoration(color: _DialogColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _DialogColors.border)),
                      child: Column(children: _mentionSuggestions.map((u) => ListTile(dense: true, title: Text(u['display_name']?? '', style: const TextStyle(fontSize: 13)), onTap: () => _insertMention(u))).toList()),
                    ),
                  if (_images.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Wrap(spacing: 8, runSpacing: 8, children: [
                        for (int i = 0; i < _images.length; i++)
                          Stack(children: [
                            ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.memory(_images[i].bytes, width: 84, height: 84, fit: BoxFit.cover)),
                            Positioned(top: 4, right: 4, child: GestureDetector(onTap: () => _removeMedia(i, false), child: Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, size: 13, color: Colors.white)))),
                          ]),
                      ]),
                    ),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [_mediaBtn(Icons.photo_rounded, _pickImages, const Color(0xFF059669)), _mediaBtn(Icons.videocam_rounded, _pickVideos, const Color(0xFFE5484D)), _mediaBtn(Icons.photo_camera_rounded, _pickCamera, _DialogColors.primary)]),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _isUploading? null : _publishPost, style: ElevatedButton.styleFrom(backgroundColor: _DialogColors.gold, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: _isUploading? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('PUBLIER', style: TextStyle(fontWeight: FontWeight.w800)))),
          ]),
        ),
      ),
    );
  }
}
