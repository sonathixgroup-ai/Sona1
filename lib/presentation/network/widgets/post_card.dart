import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:thix_id/models/network_post.dart';
import 'package:thix_id/features/network/data/network_service_provider.dart';
import 'package:thix_id/presentation/network/post_detail_page.dart';
import 'package:go_router/go_router.dart';

class _PostColors {
  static const background = Color(0xFFF6F9FF);
  static const white = Color(0xFFFFFFFF);
  static const primary = Color(0xFF2D6CDF);
  static const primaryDeep = Color(0xFF123B7A);
  static const softBlue = Color(0xFFEAF1FF);
  static const gold = Color(0xFFD9A63C);
  static const textDark = Color(0xFF10192E);
  static const textSecondary = Color(0xFF7386A8);
  static const border = Color(0xFFE7EEFC);
  static const red = Color(0xFFE5484D);
  static const green = Color(0xFF059669);
  static const shadow = Color(0x142D6CDF);
}

final postItemProvider = StateNotifierProvider<PostItemNotifier, NetworkPost>(
  (ref) => throw UnimplementedError('must override'),
);

class PostItemNotifier extends StateNotifier<NetworkPost> {
  PostItemNotifier(super.post, this.ref);
  final Ref ref;
  Future<void> toggleLike() async {
    final wasLiked = state.isLiked;
    final oldCount = state.likesCount;
    state = state.copyWith(isLiked:!wasLiked, likesCount: wasLiked? oldCount - 1 : oldCount + 1);
    try {
      if (wasLiked) { await ref.read(networkServiceProvider).unlikePost(state.id); }
      else { await ref.read(networkServiceProvider).likePost(state.id); }
    } catch (_) { state = state.copyWith(isLiked: wasLiked, likesCount: oldCount); }
  }
  Future<void> toggleSave() async {
    final was = state.isSaved;
    state = state.copyWith(isSaved:!was);
    try {
      if (was) { await ref.read(networkServiceProvider).unsavePost(state.id); }
      else { await ref.read(networkServiceProvider).savePost(state.id); }
    } catch (_) { state = state.copyWith(isSaved: was); }
  }
  void updateContent(String c) => state = state.copyWith(content: c);
  void incRepost() => state = state.copyWith(repostsCount: state.repostsCount + 1, isReposted: true);
}

class PostCard extends ConsumerStatefulWidget {
  final NetworkPost post;
  final String currentProfileId;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onTap;
  final VoidCallback? onShare;
  final VoidCallback? onRefresh;
  final VoidCallback? onPin;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onSave;
  const PostCard({super.key, required this.post, required this.currentProfileId, this.onLike, this.onComment, this.onTap, this.onShare, this.onRefresh, this.onPin, this.onEdit, this.onDelete, this.onSave});
  @override ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;
  bool _isPressed = false;
  bool _isReposting = false;
  bool _isLikedAnimating = false;
  bool _isExpanded = false;
  final _quoteController = TextEditingController();
  static const _maxContentChars = 250;
  static const _cardHorizontalPadding = 14.0;
  static final _richContentRegex = RegExp(r'\{c:(#[0-9A-Fa-f]{6,8})\}([\s\S]*?)\{c\}|' r'\*\*([\s\S]+?)\*\*|' r'\*([\s\S]+?)\*|' r'@(\w+)|' r'#(\w+)',);
  List<InlineSpan>? _cachedFullSpans;
  List<InlineSpan>? _cachedTruncatedSpans;
  bool _isTruncatable = false;
  final List<GestureRecognizer> _recognizers = [];

  @override void initState() { super.initState(); _cacheParsedContent(); }
  @override void dispose() { _disposeRecognizers(); _quoteController.dispose(); super.dispose(); }
  void _disposeRecognizers() { for (final r in _recognizers) r.dispose(); _recognizers.clear(); }
  void _cacheParsedContent() {
    final content = widget.post.content;
    const baseStyle = TextStyle(fontSize: 14, height: 1.45, color: _PostColors.textDark);
    _cachedFullSpans = _parseContent(content, baseStyle);
    _isTruncatable = content.length > _maxContentChars;
    if (_isTruncatable) {
      String truncated = content.substring(0, _maxContentChars);
      final lastSpace = truncated.lastIndexOf(' ');
      if (lastSpace > 0) truncated = truncated.substring(0, lastSpace);
      _cachedTruncatedSpans = _parseContent('$truncated…', baseStyle);
    } else { _cachedTruncatedSpans = _cachedFullSpans; }
  }
  List<InlineSpan> _parseContent(String content, TextStyle baseStyle) {
    final spans = <InlineSpan>[]; int lastIndex = 0;
    for (final match in _richContentRegex.allMatches(content)) {
      if (match.start > lastIndex) spans.add(TextSpan(text: content.substring(lastIndex, match.start), style: baseStyle));
      if (match.group(1)!= null) {
        final hex = match.group(1)!.replaceFirst('#', ''); final inner = match.group(2)?? '';
        Color color; try { final argb = hex.length == 8? hex : 'FF$hex'; color = Color(int.parse(argb, radix: 16)); } catch (_) { color = baseStyle.color?? _PostColors.textDark; }
        spans.add(TextSpan(children: _parseContent(inner, baseStyle.copyWith(color: color))));
      } else if (match.group(3)!= null) { spans.add(TextSpan(children: _parseContent(match.group(3)!, baseStyle.copyWith(fontWeight: FontWeight.w800)))); }
      else if (match.group(4)!= null) { spans.add(TextSpan(children: _parseContent(match.group(4)!, baseStyle.copyWith(fontStyle: FontStyle.italic)))); }
      else if (match.group(5)!= null) {
        final value = match.group(5)!; final recognizer = TapGestureRecognizer()..onTap = () => context.push('/profile/$value'); _recognizers.add(recognizer);
        spans.add(TextSpan(text: '@$value', style: baseStyle.merge(const TextStyle(color: _PostColors.primary, fontWeight: FontWeight.w700)), recognizer: recognizer));
      } else if (match.group(6)!= null) {
        final value = match.group(6)!; final recognizer = TapGestureRecognizer()..onTap = () => context.push('/hashtag/$value'); _recognizers.add(recognizer);
        spans.add(TextSpan(text: '#$value', style: baseStyle.merge(const TextStyle(color: _PostColors.gold, fontWeight: FontWeight.w700)), recognizer: recognizer));
      }
      lastIndex = match.end;
    }
    if (lastIndex < content.length) spans.add(TextSpan(text: content.substring(lastIndex), style: baseStyle));
    return spans;
  }

  String _getTimeAgo(DateTime dt) => timeago.format(dt, locale: 'fr');
  String _formatCount(int count) => count >= 1000000? '${(count / 1000000).toStringAsFixed(1)}M' : count >= 1000? '${(count / 1000).toStringAsFixed(1)}k' : '$count';
  void _openPostDetails(String postId) => context.push('/network/comments/$postId').then((_) => widget.onRefresh?.call());
  void _openGallery(int initialIndex, List<String> urls, String postId) {
    Navigator.push(context, PageRouteBuilder(opaque: false, barrierColor: Colors.black, transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, anim, __) => FadeTransition(opacity: anim, child: _FullScreenGallery(imageUrls: urls, initialIndex: initialIndex, postId: postId))));
  }
  Widget _buildNetworkImage(String url, {double? width, double height = 200, BoxFit fit = BoxFit.cover, Alignment alignment = Alignment.center}) {
    return CachedNetworkImage(imageUrl: url, width: width, height: height, fit: fit, alignment: alignment,
      placeholder: (_, __) => Container(height: height, width: width, color: _PostColors.softBlue, child: const Center(child: CircularProgressIndicator(color: _PostColors.primary, strokeWidth: 2))),
      errorWidget: (_, __, ___) => Container(height: height, width: width, color: _PostColors.softBlue, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.broken_image_rounded, size: 36, color: _PostColors.primary.withOpacity(0.4)), const SizedBox(height: 6), const Text('Image non disponible', style: TextStyle(color: _PostColors.textSecondary, fontSize: 11))])) );
  }
  Widget _tappableImage(String url, int index, List<String> allUrls, String postId, {required double height}) {
    return GestureDetector(onTap: () => _openGallery(index, allUrls, postId), child: Hero(tag: 'post_${postId}_image_$index', child: _buildNetworkImage(url, width: double.infinity, height: height, alignment: Alignment.topCenter)));
  }
  Widget _buildImageGrid(List<String> urls, String postId) {
    if (urls.isEmpty) return const SizedBox.shrink(); const spacing = 4.0; final radius = BorderRadius.circular(12);
    if (urls.length == 1) return ClipRRect(borderRadius: BorderRadius.circular(18), child: GestureDetector(onTap: () => _openGallery(0, urls, postId), child: Hero(tag: 'post_${postId}_image_0', child: _AdaptiveSingleImage(imageUrl: urls[0]))));
    if (urls.length == 2) return Row(children: [Expanded(child: ClipRRect(borderRadius: radius, child: GestureDetector(onTap: () => _openGallery(0, urls, postId), child: Hero(tag: 'post_${postId}_image_0', child: _AdaptivePairImage(imageUrl: urls[0], groupKey: urls))))), const SizedBox(width: spacing), Expanded(child: ClipRRect(borderRadius: radius, child: GestureDetector(onTap: () => _openGallery(1, urls, postId), child: Hero(tag: 'post_${postId}_image_1', child: _AdaptivePairImage(imageUrl: urls[1], groupKey: urls))))),]);
    if (urls.length == 3) return SizedBox(height: 240, child: Row(children: [Expanded(flex: 3, child: ClipRRect(borderRadius: radius, child: _tappableImage(urls[0], 0, urls, postId, height: 240))), const SizedBox(width: spacing), Expanded(flex: 2, child: Column(children: [Expanded(child: ClipRRect(borderRadius: radius, child: _tappableImage(urls[1], 1, urls, postId, height: 118))), const SizedBox(height: spacing), Expanded(child: ClipRRect(borderRadius: radius, child: _tappableImage(urls[2], 2, urls, postId, height: 118)))]))]));
    if (urls.length == 4) return SizedBox(height: 320, child: Column(children: [Expanded(child: Row(children: [Expanded(child: ClipRRect(borderRadius: radius, child: _tappableImage(urls[0], 0, urls, postId, height: 158))), const SizedBox(width: spacing), Expanded(child: ClipRRect(borderRadius: radius, child: _tappableImage(urls[1], 1, urls, postId, height: 158)))])), const SizedBox(height: spacing), Expanded(child: Row(children: [Expanded(child: ClipRRect(borderRadius: radius, child: _tappableImage(urls[2], 2, urls, postId, height: 158))), const SizedBox(width: spacing), Expanded(child: ClipRRect(borderRadius: radius, child: _tappableImage(urls[3], 3, urls, postId, height: 158)))]))]));
    final remaining = urls.length - 5;
    return SizedBox(height: 320, child: Column(children: [Expanded(flex: 3, child: Row(children: [Expanded(child: ClipRRect(borderRadius: radius, child: _tappableImage(urls[0], 0, urls, postId, height: 190))), const SizedBox(width: spacing), Expanded(child: ClipRRect(borderRadius: radius, child: _tappableImage(urls[1], 1, urls, postId, height: 190)))])), const SizedBox(height: spacing), Expanded(flex: 2, child: Row(children: [Expanded(child: ClipRRect(borderRadius: radius, child: _tappableImage(urls[2], 2, urls, postId, height: 126))), const SizedBox(width: spacing), Expanded(child: ClipRRect(borderRadius: radius, child: _tappableImage(urls[3], 3, urls, postId, height: 126))), const SizedBox(width: spacing), Expanded(child: ClipRRect(borderRadius: radius, child: GestureDetector(onTap: () => _openGallery(4, urls, postId), child: Stack(alignment: Alignment.center, children: [Hero(tag: 'post_${postId}_image_4', child: _buildNetworkImage(urls[4], width: double.infinity, height: 126, alignment: Alignment.topCenter)), if (remaining > 0) Container(color: Colors.black54, child: Center(child: Text('+$remaining', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))))]))))]))]));
  }
  Widget _buildPollWidget(NetworkPost post, WidgetRef ref) {
    final pollData = post.pollData?? {}; final options = (pollData['options'] as List?)?? [];
    if (options.isEmpty) return const SizedBox.shrink(); int totalVotes = 0; for (var opt in options) totalVotes += ((opt['votes'] as List?)?.length?? 0);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: options.asMap().entries.map((entry) {
      final index = entry.key; final opt = entry.value; final text = opt['text']?? ''; final voters = (opt['votes'] as List?)?? []; final double percentage = totalVotes > 0? voters.length / totalVotes : 0.0;
      return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: InkWell(onTap: () async { try { await ref.read(networkServiceProvider).votePoll(post.id, index); widget.onRefresh?.call(); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur vote: $e'), backgroundColor: _PostColors.red)); } }, borderRadius: BorderRadius.circular(12), child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _PostColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: _PostColors.border)), child: Stack(children: [Positioned.fill(child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: percentage, child: Container(decoration: BoxDecoration(color: _PostColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(8))))), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(text, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: _PostColors.textDark))), Text('${(percentage * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _PostColors.primary))])]))));
    }).toList());
  }
  Widget _buildChallengeWidget(NetworkPost post) {
    final challengeData = post.challengeData?? {}; final description = challengeData['description']?? ''; final participantsCount = challengeData['participants_count']?? 0;
    return Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: _PostColors.softBlue, borderRadius: BorderRadius.circular(16), border: Border.all(color: _PostColors.border)), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [if (description.isNotEmpty)...[Text(description, style: const TextStyle(fontSize: 13.5, height: 1.4, color: _PostColors.textDark)), const SizedBox(height: 12)], Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Row(children: [Icon(Icons.emoji_events_rounded, color: _PostColors.gold, size: 20), SizedBox(width: 6), Text('Challenge Actif', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: _PostColors.textDark))]), Row(children: [const Icon(Icons.people_alt_rounded, color: _PostColors.primary, size: 18), const SizedBox(width: 6), Text('$participantsCount participants', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: _PostColors.textSecondary))])]), const SizedBox(height: 12), ElevatedButton.icon(onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Participation enregistrée!'), backgroundColor: _PostColors.green)); }, style: ElevatedButton.styleFrom(backgroundColor: _PostColors.primaryDeep, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), icon: const Icon(Icons.check_circle_outline_rounded, size: 18), label: const Text('RELEVER LE DÉFI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))]));
  }
  Widget _buildFactCheckBanner(bool isMisinformation, String? message) {
    if (!isMisinformation || message == null || message.isEmpty) return const SizedBox.shrink();
    return Container(margin: const EdgeInsets.symmetric(vertical: 8).copyWith(left: -_cardHorizontalPadding, right: -_cardHorizontalPadding), padding: const EdgeInsets.symmetric(horizontal: _cardHorizontalPadding, vertical: 9), decoration: BoxDecoration(color: Colors.red.shade50, border: Border(top: BorderSide(color: Colors.red.shade200), bottom: BorderSide(color: Colors.red.shade200))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Alerte Fact-Check THIX : Désinformation potentielle", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11.5)), const SizedBox(height: 2), Text(message, style: TextStyle(color: Colors.red.shade900, fontSize: 11, height: 1.3))]))]));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ProviderScope(
      overrides: [postItemProvider.overrideWith((ref) => PostItemNotifier(widget.post, ref))],
      child: Consumer(builder: (context, ref, _) {
        final post = ref.watch(postItemProvider);
        final isLiked = ref.watch(postItemProvider.select((p) => p.isLiked));
        final likesCount = ref.watch(postItemProvider.select((p) => p.likesCount));
        final isOwner = widget.currentProfileId == post.userId;

        return AnimatedContainer(duration: const Duration(milliseconds: 200), transform: Matrix4.identity()..scale(_isPressed? 0.98 : 1.0), child: Container(margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 7), decoration: BoxDecoration(color: _PostColors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: _PostColors.border), boxShadow: [BoxShadow(color: _PostColors.shadow, blurRadius: _isPressed? 6 : 16, offset: Offset(0, _isPressed? 2 : 8))]), child: ClipRRect(borderRadius: BorderRadius.circular(22), child: InkWell(onTapDown: (_) => setState(() => _isPressed = true), onTapUp: (_) => setState(() => _isPressed = false), onTapCancel: () => setState(() => _isPressed = false), onTap: widget.onTap?? () => _openPostDetails(post.id), child: Padding(padding: const EdgeInsets.all(_cardHorizontalPadding), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            GestureDetector(onTap: () => context.push('/network/profile/${post.userId}'), child: Container(width: 42, height: 42, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [_PostColors.primaryDeep, _PostColors.primary])), child: CircleAvatar(radius: 19, backgroundColor: _PostColors.softBlue, backgroundImage: post.authorAvatar!= null && post.authorAvatar!.isNotEmpty? CachedNetworkImageProvider(post.authorAvatar!) : null, child: post.authorAvatar == null || post.authorAvatar!.isEmpty? const Icon(Icons.person_rounded, size: 18, color: _PostColors.primaryDeep) : null))),
            const SizedBox(width: 10),
            Expanded(child: GestureDetector(onTap: () => context.push('/network/profile/${post.userId}'), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: _PostColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis), if (post.authorTitle!= null && post.authorTitle!.isNotEmpty) Text(post.authorTitle!, style: const TextStyle(fontSize: 10.5, color: _PostColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis), Row(children: [Text(_getTimeAgo(post.createdAt), style: const TextStyle(fontSize: 10, color: _PostColors.textSecondary)), const SizedBox(width: 4), const Icon(Icons.public_rounded, size: 11, color: _PostColors.textSecondary)])]))),
            PopupMenuButton<String>(icon: const Icon(Icons.more_vert_rounded, size: 18, color: _PostColors.textSecondary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), onSelected: (v) async {
              switch(v){
                case 'edit': _editPost(post, ref); break;
                case 'pin': await ref.read(networkServiceProvider).pinPost(post.id); widget.onPin?.call(); break;
                case 'delete': final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Supprimer?'), actions: [TextButton(onPressed: ()=>Navigator.pop(context,false), child: const Text('Annuler')), TextButton(onPressed: ()=>Navigator.pop(context,true), child: const Text('Supprimer'))])); if(ok==true){ await ref.read(networkServiceProvider).deletePost(post.id); widget.onDelete?.call(); widget.onRefresh?.call(); } break;
                case 'save': await ref.read(postItemProvider.notifier).toggleSave(); widget.onSave?.call(); break;
                case 'repost': _repost(post, ref); break;
                case 'hide': await ref.read(networkServiceProvider).hidePost(post.id); widget.onRefresh?.call(); break;
                case 'report': _reportPost(post, ref); break;
                case 'share': widget.onShare?.call(); break;
              }
            }, itemBuilder: (_) => [if(isOwner)...[const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 18, color: _PostColors.primary), SizedBox(width: 8), Text('Modifier')])), const PopupMenuItem(value: 'pin', child: Row(children: [Icon(Icons.push_pin_rounded, size: 18, color: _PostColors.gold), SizedBox(width: 8), Text('Épingler')])), const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_rounded, size: 18, color: _PostColors.red), SizedBox(width: 8), Text('Supprimer', style: TextStyle(color: _PostColors.red))]))], const PopupMenuItem(value: 'save', child: Row(children: [Icon(Icons.bookmark_border_rounded, size: 18, color: _PostColors.primaryDeep), SizedBox(width: 8), Text('Sauvegarder')])), const PopupMenuItem(value: 'repost', child: Row(children: [Icon(Icons.repeat_rounded, size: 18), SizedBox(width: 8), Text('Reposter')])), const PopupMenuItem(value: 'hide', child: Row(children: [Icon(Icons.visibility_off_rounded, size: 18), SizedBox(width: 8), Text('Masquer')])), const PopupMenuItem(value: 'report', child: Row(children: [Icon(Icons.flag_rounded, size: 18, color: Colors.orange), SizedBox(width: 8), Text('Signaler')])), const PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.share_rounded, size: 18), SizedBox(width: 8), Text('Partager')]))]),
          ]),
          const SizedBox(height: 12),
          if (post.content.isNotEmpty) Column(crossAxisAlignment: CrossAxisAlignment.start, children: [RichText(text: TextSpan(children: _isExpanded? (_cachedFullSpans?? []) : (_cachedTruncatedSpans?? []))), if (_isTruncatable) GestureDetector(onTap: () => setState(() => _isExpanded =!_isExpanded), child: Padding(padding: const EdgeInsets.only(top: 3), child: Text(_isExpanded? 'Voir moins' : 'Voir plus', style: const TextStyle(color: _PostColors.primary, fontSize: 12.5, fontWeight: FontWeight.w700))))]),
          _buildFactCheckBanner(post.isMisinformation, post.factCheckMessage),
          if (post.postType == 'poll')...[_buildImageGrid(post.imageUrls, post.id), const SizedBox(height: 8), _buildPollWidget(post, ref)]
          else if (post.postType == 'challenge')...[_buildImageGrid(post.imageUrls, post.id), const SizedBox(height: 8), _buildChallengeWidget(post)]
          else if (post.imageUrls.isNotEmpty)...[const SizedBox(height: 8), _buildImageGrid(post.imageUrls, post.id)],
          const SizedBox(height: 12),
          Row(children: [
            InkWell(onTap: () async { setState(()=>_isLikedAnimating=true); await ref.read(postItemProvider.notifier).toggleLike(); Future.delayed(const Duration(milliseconds: 300), (){ if(mounted) setState(()=>_isLikedAnimating=false); }); widget.onLike?.call(); }, borderRadius: BorderRadius.circular(20), child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [AnimatedScale(scale: _isLikedAnimating?1.3:1.0, duration: const Duration(milliseconds: 200), child: Icon(isLiked?Icons.favorite_rounded:Icons.favorite_border_rounded, color: isLiked?_PostColors.red:_PostColors.textSecondary, size: 19)), const SizedBox(width: 5), Text(_formatCount(likesCount), style: const TextStyle(fontSize: 12, color: _PostColors.textSecondary, fontWeight: FontWeight.w600))]))),
            const SizedBox(width: 18),
            InkWell(onTap: widget.onComment??()=>_openPostDetails(post.id), borderRadius: BorderRadius.circular(20), child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: _PostColors.textSecondary), const SizedBox(width: 5), Text(_formatCount(post.commentsCount), style: const TextStyle(fontSize: 12, color: _PostColors.textSecondary, fontWeight: FontWeight.w600))]))),
            const SizedBox(width: 18),
            InkWell(onTap: ()=>_repost(post, ref), borderRadius: BorderRadius.circular(20), child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [Icon(Icons.repeat_rounded, size: 18, color: post.isReposted?_PostColors.green:_PostColors.textSecondary), const SizedBox(width: 5), Text(_formatCount(post.repostsCount), style: const TextStyle(fontSize: 12, color: _PostColors.textSecondary, fontWeight: FontWeight.w600))]))),
            const SizedBox(width: 18),
            InkWell(onTap: widget.onShare, borderRadius: BorderRadius.circular(20), child: const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Row(children: [Icon(Icons.share_rounded, size: 18, color: _PostColors.textSecondary), SizedBox(width: 5), Text('Partager', style: TextStyle(fontSize: 12, color: _PostColors.textSecondary, fontWeight: FontWeight.w600))]))),
          ]),
        ]))))));
      }),
    );
  }

  Future<void> _repost(NetworkPost post, WidgetRef ref) async {
    if (_isReposting) return;
    final result = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: const Text('Reposter'), content: TextField(controller: _quoteController, decoration: InputDecoration(hintText: 'Ajouter un commentaire (optionnel)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))), maxLines: 3), actions: [TextButton(onPressed: ()=>Navigator.pop(ctx,false), child: const Text('Annuler')), ElevatedButton(onPressed: ()=>Navigator.pop(ctx,true), style: ElevatedButton.styleFrom(backgroundColor: _PostColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: const Text('Reposter'))]));
    if (result!=true) return;
    setState(()=>_isReposting=true);
    try { await ref.read(networkServiceProvider).repost(post.id, _quoteController.text); ref.read(postItemProvider.notifier).incRepost(); if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post reposté'), backgroundColor: _PostColors.green)); widget.onRefresh?.call(); } catch(e){ if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: _PostColors.red)); } finally { if(mounted) setState(()=>_isReposting=false); _quoteController.clear(); }
  }

  Future<void> _editPost(NetworkPost post, WidgetRef ref) async {
    final controller = TextEditingController(text: post.content);
    final newContent = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: const Text('Modifier'), content: TextField(controller: controller, maxLines: 5, decoration: InputDecoration(hintText: 'Modifiez...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))), actions: [TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text('Annuler')), ElevatedButton(onPressed: ()=>Navigator.pop(ctx, controller.text), style: ElevatedButton.styleFrom(backgroundColor: _PostColors.primary), child: const Text('Enregistrer'))]));
    if (newContent==null||newContent==post.content) return;
    try { await ref.read(networkServiceProvider).updatePost(post.id, newContent); ref.read(postItemProvider.notifier).updateContent(newContent); setState((){ _disposeRecognizers(); _isExpanded=false; _cacheParsedContent(); }); widget.onEdit?.call(); widget.onRefresh?.call(); } catch(e){ if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: _PostColors.red)); }
  }

  Future<void> _reportPost(NetworkPost post, WidgetRef ref) async {
    final reason = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: const Text('Signaler'), content: Column(mainAxisSize: MainAxisSize.min, children: [ListTile(leading: const Icon(Icons.warning, color: Colors.orange), title: const Text('Spam'), onTap: ()=>Navigator.pop(ctx,'Spam')), ListTile(leading: const Icon(Icons.block, color: _PostColors.red), title: const Text('Contenu inapproprié'), onTap: ()=>Navigator.pop(ctx,'Contenu inapproprié')), ListTile(leading: const Icon(Icons.person_off, color: Colors.purple), title: const Text('Harcèlement'), onTap: ()=>Navigator.pop(ctx,'Harcèlement')), ListTile(leading: const Icon(Icons.info_outline, color: _PostColors.primary), title: const Text('Fausse information'), onTap: ()=>Navigator.pop(ctx,'Fausse information'))])));
    if (reason==null) return;
    try { await ref.read(networkServiceProvider).reportPost(post.id, reason); if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Publication signalée'), backgroundColor: Colors.orange)); } catch(e){ if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: _PostColors.red)); }
  }
}

class _AdaptiveSingleImage extends StatefulWidget { final String imageUrl; const _AdaptiveSingleImage({required this.imageUrl}); @override State<_AdaptiveSingleImage> createState() => _AdaptiveSingleImageState(); }
class _AdaptiveSingleImageState extends State<_AdaptiveSingleImage> {
  static const _minHeight = 220.0; static const _maxHeight = 520.0; double? _aspectRatio; ImageStream? _stream; late ImageStreamListener _listener;
  @override void initState() { super.initState(); _listener = ImageStreamListener(_onResolved, onError: (_, __){ if(mounted) setState(()=>_aspectRatio=1.0); }); _resolve(); }
  void _resolve() { final p = CachedNetworkImageProvider(widget.imageUrl); _stream = p.resolve(const ImageConfiguration()); _stream!.addListener(_listener); }
  void _onResolved(ImageInfo info, bool _) { if(!mounted) return; final w=info.image.width.toDouble(); final h=info.image.height.toDouble(); if(h>0) setState(()=>_aspectRatio=w/h); }
  @override void didUpdateWidget(covariant _AdaptiveSingleImage old){ super.didUpdateWidget(old); if(old.imageUrl!=widget.imageUrl){ _stream?.removeListener(_listener); _aspectRatio=null; _resolve(); } }
  @override void dispose(){ _stream?.removeListener(_listener); super.dispose(); }
  @override Widget build(BuildContext context) => LayoutBuilder(builder: (context, c){ final width=c.maxWidth; if(_aspectRatio==null) return Container(height: 300, width: width, color: _PostColors.softBlue, child: const Center(child: CircularProgressIndicator(color: _PostColors.primary, strokeWidth: 2))); double nh=width/_aspectRatio!; final ch=nh.clamp(_minHeight,_maxHeight); final needCrop=nh!=ch; return SizedBox(width: width, height: ch, child: CachedNetworkImage(imageUrl: widget.imageUrl, width: width, height: ch, fit: needCrop?BoxFit.cover:BoxFit.contain, alignment: Alignment.topCenter)); });
}

class _AdaptivePairImage extends StatefulWidget { final String imageUrl; final List<String> groupKey; const _AdaptivePairImage({required this.imageUrl, required this.groupKey}); @override State<_AdaptivePairImage> createState() => _AdaptivePairImageState(); }
class _AdaptivePairImageState extends State<_AdaptivePairImage> {
  static const _minHeight=180.0; static const _maxHeight=320.0; double? _aspectRatio; ImageStream? _stream; late ImageStreamListener _listener;
  @override void initState(){ super.initState(); _listener=ImageStreamListener(_onResolved, onError: (_, __){ if(mounted) setState(()=>_aspectRatio=0.75); }); _resolve(); }
  void _resolve(){ final p=CachedNetworkImageProvider(widget.imageUrl); _stream=p.resolve(const ImageConfiguration()); _stream!.addListener(_listener); }
  void _onResolved(ImageInfo info, bool _){ if(!mounted) return; final w=info.image.width.toDouble(); final h=info.image.height.toDouble(); if(h>0) setState(()=>_aspectRatio=w/h); }
  @override void didUpdateWidget(covariant _AdaptivePairImage old){ super.didUpdateWidget(old); if(old.imageUrl!=widget.imageUrl){ _stream?.removeListener(_listener); _aspectRatio=null; _resolve(); } }
  @override void dispose(){ _stream?.removeListener(_listener); super.dispose(); }
  @override Widget build(BuildContext context)=>LayoutBuilder(builder: (context,c){ final cw=c.maxWidth; if(_aspectRatio==null) return Container(height: 240, width: cw, color: _PostColors.softBlue, child: const Center(child: CircularProgressIndicator(color: _PostColors.primary, strokeWidth: 2))); final nh=(cw/_aspectRatio!).clamp(_minHeight,_maxHeight); return SizedBox(width: cw, height: nh, child: CachedNetworkImage(imageUrl: widget.imageUrl, width: cw, height: nh, fit: BoxFit.cover, alignment: Alignment.topCenter)); });
}

class _FullScreenGallery extends StatefulWidget { final List<String> imageUrls; final int initialIndex; final String postId; const _FullScreenGallery({required this.imageUrls, required this.initialIndex, required this.postId}); @override State<_FullScreenGallery> createState() => _FullScreenGalleryState(); }
class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late final PageController _pageController; late int _currentIndex;
  @override void initState(){ super.initState(); _currentIndex=widget.initialIndex; _pageController=PageController(initialPage: widget.initialIndex); }
  @override void dispose(){ _pageController.dispose(); super.dispose(); }
  @override Widget build(BuildContext context){
    return Scaffold(backgroundColor: Colors.black, body: Stack(children: [
      PageView.builder(controller: _pageController, itemCount: widget.imageUrls.length, onPageChanged: (i)=>setState(()=>_currentIndex=i), itemBuilder: (context,index)=>GestureDetector(onTap: ()=>Navigator.of(context).pop(), child: Center(child: Hero(tag: 'post_${widget.postId}_image_$index', child: InteractiveViewer(minScale: 1, maxScale: 4, child: CachedNetworkImage(imageUrl: widget.imageUrls[index], fit: BoxFit.contain, placeholder: (_, __)=>const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)), errorWidget: (_, __, ___)=>const Icon(Icons.broken_image_rounded, color: Colors.white54, size: 48))))))),
      Positioned(top: 12, right: 12, child: SafeArea(child: GestureDetector(onTap: ()=>Navigator.of(context).pop(), child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle), child: const Icon(Icons.close_rounded, color: Colors.white, size: 22))))),
      if(widget.imageUrls.length>1) Positioned(top: 12, left: 0, right: 0, child: SafeArea(child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(20)), child: Text('${_currentIndex+1} / ${widget.imageUrls.length}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)))))),
      if(widget.imageUrls.length>1) Positioned(bottom: 24, left: 0, right: 0, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(widget.imageUrls.length, (i){ final active=i==_currentIndex; return AnimatedContainer(duration: const Duration(milliseconds: 200), margin: const EdgeInsets.symmetric(horizontal: 3), width: active?18:6, height: 6, decoration: BoxDecoration(color: active?Colors.white:Colors.white38, borderRadius: BorderRadius.circular(3))); }))),
    ]));
  }
}
