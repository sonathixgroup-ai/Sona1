// lib/presentation/network/widgets/create_post_dialog.dart
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/features/network/data/network_service_provider.dart';
import 'package:thix_id/providers/feed_provider.dart';
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
  return FlutterImageCompress.compressWithList(bytes, minHeight: 1080, minWidth: 1080, quality: 85);
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

class _CreatePostDialogState extends ConsumerState<CreatePostDialog> with SingleTickerProviderStateMixin {
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _contentFocusNode = FocusNode();
  final List<TextEditingController> _pollOptionControllers = [TextEditingController(), TextEditingController()];
  final TextEditingController _challengeDescController = TextEditingController();
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

  final List<Color> _textColors = const [_DialogColors.textDark, _DialogColors.primary, _DialogColors.gold, Color(0xFFE5484D), Color(0xFF059669)];

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
    for (var c in _pollOptionControllers) c.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    final text = _contentController.text;
    final lastAtIndex = text.lastIndexOf('@');
    if (lastAtIndex == -1) { if (_showMentions) setState(()=> _showMentions = false); return; }
    final query = text.substring(lastAtIndex + 1);
    if (query.contains(' ') || query.contains('\n')) { setState(()=> _showMentions = false); }
    else { setState(()=> _showMentions = true); _searchUsers(query); }
  }

  Future<void> _searchUsers(String query) async {
    try {
      final users = await ref.read(networkServiceProvider).searchUsers(query);
      if (mounted) setState(()=> _mentionSuggestions = users);
    } catch (e) { debugPrint('search error $e'); }
  }

  void _insertMention(Map<String, dynamic> user) {
    final text = _contentController.text;
    final lastAt = text.lastIndexOf('@');
    final newText = '${text.substring(0, lastAt)}@${user['display_name']} ';
    _contentController.value = TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: newText.length));
    setState(()=> _showMentions = false);
  }

  void _wrapSelection(String pre, String suf) {
    final text = _contentController.text;
    final sel = _contentController.selection;
    if (!sel.isValid || sel.isCollapsed) {
      final newText = '$text$pre$suf';
      _contentController.value = TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: newText.length - suf.length));
    } else {
      final selected = text.substring(sel.start, sel.end);
      final newText = text.replaceRange(sel.start, sel.end, '$pre$selected$suf');
      _contentController.value = TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: sel.start + pre.length + selected.length + suf.length));
    }
    _contentFocusNode.requestFocus();
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: true, withData: true);
    if (result != null && mounted) setState(()=> _images.addAll(result.files.where((f)=> f.bytes != null).map((f)=> _MediaItem(f.bytes!, f.name))));
  }

  Future<void> _pickVideos() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video, allowMultiple: true, withData: true);
    if (result != null && mounted) setState(()=> _videos.addAll(result.files.where((f)=> f.bytes != null).map((f)=> _MediaItem(f.bytes!, f.name, isVideo: true))));
  }

  Future<void> _pickCamera() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false, withData: true);
    if (result != null && result.files.isNotEmpty && mounted) setState(()=> _images.add(_MediaItem(result.files.first.bytes!, result.files.first.name)));
  }

  Future<void> _publishPost() async {
    final textContent = _contentController.text.trim();
    if (_postTypeMode == 0 && textContent.isEmpty && _images.isEmpty && _videos.isEmpty) { setState(()=> _errorMessage = 'Contenu vide'); return; }
    if (_postTypeMode == 1 && textContent.isEmpty) { setState(()=> _errorMessage = 'Question sondage requise'); return; }
    if (_postTypeMode == 2 && _challengeEndDate == null) { setState(()=> _errorMessage = 'Date de fin requise'); return; }

    setState(()=> _isUploading = true);
    try {
      final ns = ref.read(networkServiceProvider);
      bool isMisinformation = false;
      String? factCheckMessage;
      String? factCheckSeverity;

      if (textContent.isNotEmpty) {
        try {
          final aiService = AiService(Supabase.instance.client);
          final prompt = "Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}\nPUBLICATION: \"$textContent\"\nRéponds SAFE ou FAKE: raison";
          final aiRes = await aiService.askAi(prompt: prompt, provider: AiProvider.mistral, systemPrompt: "Tu es THIX Fact-Check AI. SAFE ou FAKE: raison.");
          if (aiRes.trim().toUpperCase().startsWith("FAKE:")) { isMisinformation = true; factCheckSeverity = "fake"; factCheckMessage = aiRes.substring(5).trim(); }
        } catch (_) {}
      }

      // Upload scalable en parallèle
      final imageUrls = await Future.wait(_images.map((item) async {
        try { final comp = await compute(compressImageBytes, item.bytes); return await ns.uploadImageBytes(comp, fileExtension: item.name.split('.').last) ?? ''; } catch (_) { return ''; }
      }));
      final videoUrls = await Future.wait(_videos.map((item) async {
        try { return await ns.uploadImageBytes(item.bytes, fileExtension: item.name.split('.').last) ?? ''; } catch (_) { return ''; }
      }));

      final allMedia = [...imageUrls, ...videoUrls].where((u)=> u.isNotEmpty).toList();
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("Non auth");

      final basePayload = {
        'user_id': user.id, 'content': textContent, 'media_urls': allMedia, 'community_id': widget.communityId,
        'is_fact_checked': true, 'is_misinformation': isMisinformation, 'fact_check_message': factCheckMessage, 'fact_check_severity': factCheckSeverity,
      };

      if (_postTypeMode == 1) {
        final options = _pollOptionControllers.map((c)=> c.text.trim()).where((t)=> t.isNotEmpty).toList();
        if (options.length < 2) throw Exception('2 options minimum');
        await Supabase.instance.client.from('posts').insert({...basePayload, 'post_type': 'poll', 'poll_data': {'options': options.map((o)=> {'text': o, 'votes': []}).toList()}});
      } else if (_postTypeMode == 2) {
        await Supabase.instance.client.from('posts').insert({...basePayload, 'post_type': 'challenge', 'challenge_data': {'description': _challengeDescController.text.trim(), 'end_date': _challengeEndDate?.toIso8601String(), 'participants_count': 0}});
      } else {
        await Supabase.instance.client.from('posts').insert({...basePayload, 'post_type': 'standard'});
      }

      ref.invalidate(feedProvider);
      widget.onPostCreated?.call();
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isMisinformation ? 'Publié avec avertissement' : 'Publié !'), backgroundColor: isMisinformation ? Colors.orange : _DialogColors.primary)); Navigator.pop(context, true); }
    } catch (e) { if (mounted) setState(()=> _errorMessage = 'Erreur: $e'); }
    finally { if (mounted) setState(()=> _isUploading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: _DialogColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: FadeTransition(opacity: _fadeAnimation, child: Container(width: MediaQuery.of(context).size.width * 0.94, constraints: const BoxConstraints(maxHeight: 750), padding: const EdgeInsets.fromLTRB(18,18,18,14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Créer une publication', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), InkWell(onTap: ()=> Navigator.pop(context), child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: _DialogColors.softBlue, shape: BoxShape.circle), child: const Icon(Icons.close_rounded, size: 18)))]),
          const SizedBox(height: 10),
          Row(children: [_buildTypeTab('Publication',0,Icons.article_rounded), const SizedBox(width:6), _buildTypeTab('Sondage',1,Icons.poll_rounded), const SizedBox(width:6), _buildTypeTab('Challenge',2,Icons.emoji_events_rounded)]),
          const SizedBox(height: 12),
          if (_errorMessage != null) Container(margin: const EdgeInsets.only(bottom:10), padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFFFEAEA), borderRadius: BorderRadius.circular(14)), child: Text(_errorMessage!, style: const TextStyle(fontSize:12,color:Color(0xFFE5484D)))),
          Expanded(child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(decoration: BoxDecoration(color: _DialogColors.background, borderRadius: BorderRadius.circular(20), border: Border.all(color: _DialogColors.border)), padding: const EdgeInsets.all(14),
              child: TextField(controller: _contentController, focusNode: _contentFocusNode, minLines: 4, maxLines: 10, style: const TextStyle(fontSize: 15), decoration: InputDecoration(hintText: _postTypeMode==1 ? 'Question sondage...' : _postTypeMode==2 ? 'Titre challenge...' : 'Quoi de neuf ?', border: InputBorder.none, isCollapsed: true))),
            if (_postTypeMode==1) ...[const SizedBox(height:12), const Text('Options:', style: TextStyle(fontWeight: FontWeight.bold, fontSize:13)), ..._pollOptionControllers.asMap().entries.map((e)=> Padding(padding: const EdgeInsets.only(top:8), child: TextField(controller: e.value, decoration: InputDecoration(hintText: 'Option ${e.key+1}', filled:true, fillColor: _DialogColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))))), if(_pollOptionControllers.length<4) TextButton.icon(onPressed: ()=> setState(()=> _pollOptionControllers.add(TextEditingController())), icon: const Icon(Icons.add,size:16), label: const Text('Ajouter'))],
            if (_postTypeMode==2) ...[const SizedBox(height:12), TextField(controller: _challengeDescController, minLines:3, maxLines:5, decoration: InputDecoration(hintText:'Règles...', filled:true, fillColor: _DialogColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))), const SizedBox(height:8), TextButton.icon(onPressed: () async { final p = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days:7)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days:365))); if(p!=null) setState(()=> _challengeEndDate=p); }, icon: const Icon(Icons.calendar_today,size:16), label: Text(_challengeEndDate==null?'Date fin':'${_challengeEndDate!.day}/${_challengeEndDate!.month}'))],
            if (_images.isNotEmpty) Padding(padding: const EdgeInsets.only(top:10), child: Wrap(spacing:8, runSpacing:8, children: _images.map((it)=> Stack(children:[ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.memory(it.bytes,width:84,height:84,fit:BoxFit.cover)), Positioned(top:4,right:4, child: GestureDetector(onTap: ()=> setState(()=> _images.remove(it)), child: Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close,size:13,color:Colors.white))))])).toList())),
            if (_videos.isNotEmpty) Padding(padding: const EdgeInsets.only(top:8), child: Wrap(spacing:8, children: _videos.map((it)=> Stack(children:[Container(width:84,height:84,decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.play_arrow,color:Colors.white)), Positioned(top:4,right:4, child: GestureDetector(onTap: ()=> setState(()=> _videos.remove(it)), child: Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close,size:13,color:Colors.white))))])).toList())),
          ]))),
          const SizedBox(height:12),
          Row(children: [_mediaBtn(Icons.photo_rounded, _pickImages, const Color(0xFF059669)), _mediaBtn(Icons.videocam_rounded, _pickVideos, const Color(0xFFE5484D)), _mediaBtn(Icons.photo_camera_rounded, _pickCamera, _DialogColors.primary), const Spacer(), if(_images.isNotEmpty || _videos.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal:10,vertical:5), decoration: BoxDecoration(color: _DialogColors.softBlue, borderRadius: BorderRadius.circular(20)), child: Text('${_images.length+_videos.length} média(s)', style: const TextStyle(fontSize:11,fontWeight:FontWeight.w700)))]),
          const SizedBox(height:12),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _isUploading ? null : _publishPost, style: ElevatedButton.styleFrom(backgroundColor: _DialogColors.gold, foregroundColor: _DialogColors.primaryDeep, padding: const EdgeInsets.symmetric(vertical:14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: _isUploading ? const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2)) : const Text('PUBLIER', style: TextStyle(fontWeight: FontWeight.w800))))),
        ]),
      )),
    );
  }

  Widget _buildTypeTab(String label, int mode, IconData icon) {
    final sel = _postTypeMode==mode;
    return Expanded(child: InkWell(onTap: ()=> setState(()=> _postTypeMode=mode), borderRadius: BorderRadius.circular(12), child: Container(padding: const EdgeInsets.symmetric(vertical:8), decoration: BoxDecoration(color: sel ? _DialogColors.primary : _DialogColors.softBlue, borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children:[Icon(icon,size:16,color: sel? Colors.white : _DialogColors.primaryDeep), const SizedBox(width:4), Text(label, style: TextStyle(fontSize:12,fontWeight: FontWeight.bold, color: sel? Colors.white : _DialogColors.textDark))]))));
  }
  Widget _mediaBtn(IconData icon, VoidCallback tap, Color color) => Padding(padding: const EdgeInsets.only(right:8), child: InkWell(onTap: tap, borderRadius: BorderRadius.circular(12), child: Container(width:38,height:38, decoration: BoxDecoration(color: _DialogColors.softBlue, borderRadius: BorderRadius.circular(12)), child: Icon(icon,size:18,color: color))));
}
