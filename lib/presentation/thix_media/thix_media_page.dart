import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'video_player_page.dart';
import '../../models/media_content.dart';
import 'providers/thix_media_provider.dart';
import 'package:thix_id/nav.dart' show AppRoutes;
import 'admin/thix_media_admin_page.dart';
import '../../services/media_service.dart';

const Color kBg = Color(0xFF050507);
const Color kSurface = Color(0xFF121214);
const Color kSurfaceLight = Color(0xFF1E1E28);
const Color kRed = Color(0xFFFF1A1A);
const Color kTextWhite = Color(0xFFFFFFFF);
const Color kTextGrey = Color(0xFF9CA3AF);
const Color kBorderLight = Color(0x14FFFFFF);
const Color kTdiaBlue = Color(0xFF2D6CDF);

class MediaCounts {
  final int likeCount, viewCount, commentCount;
  const MediaCounts({
    required this.likeCount,
    required this.viewCount,
    required this.commentCount,
  });
}

class _AnalyticsBatcher {
  static final Set<String> _pending = {};
  static Timer? _timer;
  
  static void register(String id) {
    _pending.add(id);
    _timer ??= Timer(const Duration(seconds: 8), _flush);
  }
  
  static Future<void> _flush() async {
    if (_pending.isEmpty) {
      _timer = null;
      return;
    }
    final batch = _pending.toList();
    _pending.clear();
    _timer = null;
    try {
      await Supabase.instance.client.rpc('batch_register_views', params: {'p_media_ids': batch});
    } catch (_) {
      _pending.addAll(batch);
    }
  }
}

final isMediaAdminProvider = FutureProvider.autoDispose<bool>((ref) async {
  final u = Supabase.instance.client.auth.currentUser;
  if (u == null) return false;
  final role = u.appMetadata['role'] ?? u.userMetadata?['role'];
  return role == 'admin' || role == 'superadmin';
});

// Provider pour récupérer l'avatar de l'utilisateur connecté pour le rond de profil du bas
final currentUserAvatarProvider = FutureProvider.autoDispose<String?>((ref) async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return null;
  final res = await Supabase.instance.client.from('profiles').select('avatar_url').eq('id', uid).maybeSingle();
  return res?['avatar_url'] as String?;
});

class CommentItem {
  final String id, userId, userName, content;
  final String? avatarUrl, parentId;
  final DateTime createdAt;
  final int likeCount, replyCount;
  
  CommentItem({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
    this.avatarUrl,
    this.parentId,
    this.likeCount = 0,
    this.replyCount = 0,
  });
  
  factory CommentItem.fromMap(Map<String, dynamic> m) {
    return CommentItem(
      id: m['id'] as String,
      userId: m['user_id'] as String,
      userName: (m['user_name'] as String?)?.trim().isNotEmpty == true ? m['user_name'] as String : 'Utilisateur',
      avatarUrl: m['avatar_url'] as String?,
      content: m['content'] as String,
      createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
      parentId: m['parent_id'] as String?,
      likeCount: (m['like_count'] as num?)?.toInt() ?? 0,
      replyCount: (m['reply_count'] as num?)?.toInt() ?? 0,
    );
  }
}

final commentCountProvider = FutureProvider.autoDispose.family<int, String>((ref, mediaId) async {
  final r = await Supabase.instance.client
      .from('media_stats')
      .select('comment_count')
      .eq('media_id', mediaId)
      .maybeSingle();
  return (r?['comment_count'] as int?) ?? 0;
});

final mediaCountsStreamProvider = StreamProvider.autoDispose.family<MediaCounts, String>((ref, mediaId) async* {
  while (true) {
    try {
      final r = await Supabase.instance.client
          .from('media_stats')
          .select('like_count,view_count,comment_count')
          .eq('media_id', mediaId)
          .maybeSingle();
          
      yield MediaCounts(
        likeCount: (r?['like_count'] as int?) ?? 0,
        viewCount: (r?['view_count'] as int?) ?? 0,
        commentCount: (r?['comment_count'] as int?) ?? 0,
      );
    } catch (_) {}
    await Future.delayed(const Duration(seconds: 12));
  }
});

class ThixMediaPage extends ConsumerStatefulWidget {
  const ThixMediaPage({super.key});
  @override
  ConsumerState<ThixMediaPage> createState() => _ThixMediaPageState();
}

class _ThixMediaPageState extends ConsumerState<ThixMediaPage> {
  late PageController _bannerController, _feedController;
  int _currentBannerIndex = 0;
  Timer? _bannerTimer, _searchDebounce, _uiIdleTimer;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final List<String> _filters = ["Accueil", "Fil", "Tendances", "NOVA Originals", "Live", "Courts", "Musique", "Gaming", "Formation"];
  Set<String> _likedMediaIds = {};
  final Set<String> _viewedMediaIds = {};
  bool _immersive = false;
  int _currentFeedIndex = 0;
  List<MediaContent> _filItems = [];
  final Set<String> _seenIds = {};
  bool _filLoading = false;
  bool _filInitialized = false;
  double _pullDistance = 0;
  bool _pullTriggering = false;
  static const double _pullThreshold = 90;
  static const Duration _uiIdleDelay = Duration(milliseconds: 1200);

  @override
  void initState() {
    super.initState();
    _bannerController = PageController(viewportFraction: 1.0);
    _feedController = PageController();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 600) {
        ref.read(thixMediaListProvider.notifier).loadMore();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedCategoryProvider.notifier).state = "Fil";
      _initFilFeed();
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _searchDebounce?.cancel();
    _uiIdleTimer?.cancel();
    _bannerController.dispose();
    _feedController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _hideUI() {
    if (!_immersive) {
      setState(() => _immersive = true);
    }
    _uiIdleTimer?.cancel();
  }

  void _scheduleShowUI() {
    _uiIdleTimer?.cancel();
    _uiIdleTimer = Timer(_uiIdleDelay, () {
      if (mounted && _immersive) {
        setState(() => _immersive = false);
      }
    });
  }

  MediaContent _mapMedia(Map<String, dynamic> e) {
    final s = e['media_stats'] as Map<String, dynamic>?;
    if (s != null) {
      e = {
        ...e,
        'likeCount': s['like_count'] ?? e['likeCount'] ?? 0,
        'viewCount': s['view_count'] ?? e['viewCount'] ?? 0,
        'commentCount': s['comment_count'] ?? e['commentCount'] ?? 0,
      };
    }
    return MediaContent.fromJson(e);
  }

  Future<void> _initFilFeed({bool reshuffle = false}) async {
    if (_filLoading) return;
    setState(() => _filLoading = true);
    try {
      if (reshuffle) _seenIds.clear();
      final res = await Supabase.instance.client.rpc('get_shuffled_feed', params: {'p_seen_ids': _seenIds.toList(), 'p_limit': 12});
      final items = (res as List).map((e) => MediaContent.fromJson(e as Map<String, dynamic>)).toList();
      if (!mounted) return;
      
      setState(() {
        _filItems = reshuffle ? items : [..._filItems, ...items.where((x) => !_seenIds.contains(x.id))];
        _seenIds.addAll(_filItems.map((e) => e.id));
        _filInitialized = true;
        if (reshuffle) _currentFeedIndex = 0;
      });
      await _syncLiked(_filItems.isNotEmpty ? [_filItems.first] : []);
      if (_filItems.isNotEmpty) _registerView(_filItems.first);
      if (reshuffle && _feedController.hasClients) _feedController.jumpToPage(0);
    } catch (_) {
      final res = await Supabase.instance.client.from('media_content').select('*, media_stats(like_count,view_count,comment_count)').order('created_at', ascending: false).limit(12);
      final items = (res as List).map((e) => _mapMedia(Map<String, dynamic>.from(e as Map))).toList();
      if (mounted) setState(() { _filItems = items; _filInitialized = true; });
    } finally {
      if (mounted) setState(() => _filLoading = false);
    }
  }

  Future<void> _loadMoreFil() async {
    if (_filLoading) return;
    setState(() => _filLoading = true);
    try {
      final res = await Supabase.instance.client.rpc('get_shuffled_feed', params: {'p_seen_ids': _seenIds.toList(), 'p_limit': 12});
      final items = (res as List).map((e) => MediaContent.fromJson(e as Map<String, dynamic>)).toList();
      if (!mounted) return;
      setState(() {
        _filItems.addAll(items.where((e) => !_seenIds.contains(e.id)));
        _seenIds.addAll(items.map((e) => e.id));
      });
      await _syncLiked(items);
    } catch (_) {} finally { 
      if (mounted) setState(() => _filLoading = false); 
    }
  }

  Future<void> _syncLiked(List<MediaContent> items) async {
    if (items.isEmpty) return;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final res = await Supabase.instance.client.rpc('get_liked_media_ids', params: {'p_media_ids': items.map((e) => e.id).toList()});
      if (mounted) setState(() => _likedMediaIds.addAll((res as List).map((e) => e as String)));
    } catch (_) {}
  }

  void _startAutoScroll(int count) {
    _bannerTimer?.cancel();
    if (count == 0) return;
    _bannerTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted || !_bannerController.hasClients) return;
      final next = (_currentBannerIndex + 1) % count;
      _bannerController.animateToPage(next, duration: const Duration(milliseconds: 800), curve: Curves.fastOutSlowIn);
    });
  }

  void _onSearchChanged(String v) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () => ref.read(searchQueryProvider.notifier).state = v);
  }

  void _navigateToVideo(MediaContent item) => Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerPage(title: item.title, videoUrl: item.videoUrl)));
  
  String _formatNumber(int num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}k';
    return num.toString();
  }

  Widget _buildImage(String url, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    if (url.isEmpty) return Container(color: kSurface, child: const Icon(Icons.broken_image_rounded, color: kTextGrey));
    return Image.network(
      url, width: width, height: height, fit: fit, 
      cacheWidth: kIsWeb ? null : (width != null ? (width * 2).toInt() : 600), 
      loadingBuilder: (c, child, p) { 
        if (p == null) return child; 
        return Container(color: kSurface, child: const Center(child: CircularProgressIndicator(color: kRed, strokeWidth: 2))); 
      }, 
      errorBuilder: (c, e, s) => Container(color: kSurface, child: const Icon(Icons.broken_image_rounded, color: kTextGrey))
    );
  }

  void _registerView(MediaContent item) {
    if (_viewedMediaIds.contains(item.id)) return;
    _viewedMediaIds.add(item.id);
    _AnalyticsBatcher.register(item.id);
  }

  Future<void> _toggleLike(MediaContent item) async {
    if (Supabase.instance.client.auth.currentUser == null) return;
    final was = _likedMediaIds.contains(item.id);
    setState(() => was ? _likedMediaIds.remove(item.id) : _likedMediaIds.add(item.id));
    try { 
      await Supabase.instance.client.rpc('toggle_media_like', params: {'p_media_id': item.id}); 
    } catch (_) { 
      if (mounted) setState(() => was ? _likedMediaIds.add(item.id) : _likedMediaIds.remove(item.id)); 
    }
  }

  void _openComments(MediaContent item) {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (_) => _CommentsSheet(mediaId: item.id, mediaTitle: item.title)).then((_) { 
      ref.invalidate(commentCountProvider(item.id)); 
    });
  }

  void _handlePageChanged(int index) {
    if (index < 0 || index >= _filItems.length) return;
    if (index >= _filItems.length - 4) _loadMoreFil();
    _registerView(_filItems[index]);
  }

  @override
  Widget build(BuildContext context) {
    final asyncMedia = ref.watch(thixMediaListProvider);
    final bannerItems = ref.watch(bannerItemsProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    
    ref.listen<List<MediaContent>>(bannerItemsProvider, (prev, next) { 
      if (next.isNotEmpty) _startAutoScroll(next.length); 
    });
    
    return Scaffold(
      backgroundColor: kBg, 
      body: asyncMedia.when(
        loading: () => const Center(child: CircularProgressIndicator(color: kRed)), 
        error: (e, st) => Center(child: Text('Erreur: $e', style: const TextStyle(color: kTextWhite))), 
        data: (mediaList) {
          final currentItem = _filItems.isNotEmpty ? _filItems[_currentFeedIndex.clamp(0, _filItems.length - 1)] : null;
          final showBars = !(_immersive && selectedCategory == 'Fil');
          
          return Stack(
            children: [
              if (selectedCategory == 'Fil') 
                _buildTikTokFeed() 
              else 
                RefreshIndicator(
                  color: kRed, backgroundColor: kSurface, 
                  onRefresh: () => ref.read(thixMediaListProvider.notifier).refresh(), 
                  child: CustomScrollView(
                    controller: _scrollController, 
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()), 
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, 
                          children: [
                            const SizedBox(height: 100), 
                            if (bannerItems.isNotEmpty) _heroBanner(bannerItems), 
                            Transform.translate(
                              offset: const Offset(0, -40), 
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter, end: Alignment.bottomCenter, 
                                    colors: [Colors.transparent, kBg.withOpacity(0.6), kBg], 
                                    stops: const [0.0, 0.1, 0.3]
                                  )
                                ), 
                                child: Column(
                                  children: [
                                    _buildRow(title: 'Continuer à regarder', subtitle: 'Reprise intelligente', provider: recommendationsProvider, aspectRatio: 16 / 9, height: 180, width: 320, itemBuilder: (item, [index]) => _continueWatchingCard(item)), 
                                    const SizedBox(height: 40), 
                                    _buildRow(title: 'TDIA Originals Exclusifs', subtitle: 'Produit par TDIA Studios', provider: newReleasesProvider, aspectRatio: 2 / 3, height: 240, width: 160, itemBuilder: (item, [index]) => _originalCard(item)), 
                                    const SizedBox(height: 40), 
                                    _buildRow(title: 'Top 10 cette semaine', subtitle: 'Classement', provider: trendingProvider, aspectRatio: 16 / 9, height: 160, width: 300, itemBuilder: (item, [index]) => _top10Card(item, index ?? 0)), 
                                    const SizedBox(height: 120)
                                  ]
                                )
                              )
                            )
                          ]
                        )
                      )
                    ]
                  )
                ),

              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                top: showBars ? 0 : -100, 
                left: 0, right: 0, 
                child: IgnorePointer(
                  ignoring: !showBars,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: showBars ? 1 : 0,
                    child: Column(children: [_header(), _filtersRow(selectedCategory)])
                  ),
                )
              ),

              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                bottom: showBars ? 0 : -100, 
                left: 0, right: 0, 
                child: IgnorePointer(
                  ignoring: !showBars,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: showBars ? 1 : 0,
                    child: _bottomNav(selectedCategory, currentItem)
                  ),
                )
              ),
            ]
          );
        }
      )
    );
  }

  Widget _buildTikTokFeed() {
    if (!_filInitialized) return const Center(child: CircularProgressIndicator(color: kRed));
    if (_filItems.isEmpty) return const Center(child: Text("Aucun contenu", style: TextStyle(color: Colors.white)));
    
    return GestureDetector(
      onVerticalDragUpdate: (d) { 
        if (_currentFeedIndex == 0 && d.delta.dy > 0 && !_filLoading) {
          setState(() => _pullDistance = (_pullDistance + d.delta.dy).clamp(0, _pullThreshold * 1.6)); 
        }
      },
      onVerticalDragEnd: (d) async { 
        if (_pullDistance >= _pullThreshold && !_pullTriggering) { 
          _pullTriggering = true; 
          await _initFilFeed(reshuffle: true); 
          _pullTriggering = false; 
        } 
        setState(() => _pullDistance = 0); 
      },
      child: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is ScrollUpdateNotification || n is ScrollStartNotification) {
                _hideUI();
              }
              if (n is ScrollEndNotification) {
                _scheduleShowUI();
              }
              return false;
            },
            child: PageView.builder(
              controller: _feedController, 
              scrollDirection: Axis.vertical, 
              itemCount: _filItems.length, 
              onPageChanged: (i) { 
                setState(() { 
                  _currentFeedIndex = i; 
                  _immersive = true; 
                }); 
                _handlePageChanged(i); 
                _scheduleShowUI();
              }, 
              itemBuilder: (c, idx) {
                final item = _filItems[idx]; 
                final isFocused = _currentFeedIndex == idx; 
                final textBottom = _immersive ? 20.0 : 110.0;
                
                return Stack(
                  fit: StackFit.expand, 
                  children: [
                    FeedVideoPlayer(
                      videoUrl: item.videoUrl, 
                      coverUrl: item.coverUrl, 
                      isPlaying: isFocused, 
                      isImmersive: _immersive, 
                      onPlayStateChanged: (paused) { 
                        _uiIdleTimer?.cancel();
                        setState(() => _immersive = !paused); 
                      }
                    ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 250), 
                      curve: Curves.easeOutCubic, 
                      left: 20, 
                      bottom: textBottom, 
                      right: 20, 
                      child: IgnorePointer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, 
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), 
                              decoration: BoxDecoration(
                                color: kTdiaBlue.withOpacity(0.2), 
                                borderRadius: BorderRadius.circular(8), 
                                border: Border.all(color: kTdiaBlue.withOpacity(0.5))
                              ), 
                              child: Text(item.type, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700))
                            ), 
                            const SizedBox(height: 10), 
                            Text(
                              item.title, 
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1.1, shadows: [Shadow(color: Colors.black87, blurRadius: 6)])
                            ), 
                            if (item.subtitle != null) ...[
                              const SizedBox(height: 6), 
                              Text(item.subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, shadows: [Shadow(color: Colors.black87, blurRadius: 6)]))
                            ]
                          ]
                        )
                      )
                    ),
                  ]
                );
              }
            )
          ),
          if (_pullDistance > 0 || _filLoading) 
            Positioned(
              top: 90, left: 0, right: 0, 
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(10), 
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), 
                  child: _filLoading 
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: kRed, strokeWidth: 2)) 
                    : Icon(Icons.autorenew_rounded, color: Colors.white, size: (18 + (_pullDistance / _pullThreshold) * 6).clamp(18, 26))
                )
              )
            ),
        ]
      ),
    );
  }

  Widget _header() { 
    final isAdmin = ref.watch(isMediaAdminProvider).valueOrNull ?? false; 
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), 
        child: Container(
          height: 60, 
          padding: const EdgeInsets.only(top: 8, left: 12, right: 12, bottom: 8), 
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), border: const Border(bottom: BorderSide(color: kBorderLight))), 
          child: Row(
            children: [
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(colors: [kTdiaBlue, Color(0xFF00E5FF)]).createShader(b), 
                child: const Text('TDIA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18))
              ), 
              const SizedBox(width: 14), 
              Expanded(
                child: Container(
                  height: 36, 
                  padding: const EdgeInsets.symmetric(horizontal: 12), 
                  decoration: BoxDecoration(color: const Color(0xFF0D0D10), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.08))), 
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: Colors.white30, size: 16), 
                      const SizedBox(width: 8), 
                      Expanded(
                        child: TextField(
                          controller: _searchController, 
                          focusNode: _searchFocusNode, 
                          onChanged: _onSearchChanged, 
                          style: const TextStyle(color: Colors.white, fontSize: 13), 
                          decoration: const InputDecoration(hintText: "Rechercher...", hintStyle: TextStyle(color: Colors.white30, fontSize: 13), border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero)
                        )
                      )
                    ]
                  )
                )
              ), 
              const SizedBox(width: 12), 
              if (isAdmin) ...[
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ThixMediaAdminPage())), 
                  child: Container(
                    width: 32, height: 32, 
                    decoration: BoxDecoration(shape: BoxShape.circle, color: kRed.withOpacity(0.15), border: Border.all(color: kRed.withOpacity(0.3))), 
                    child: const Icon(Icons.admin_panel_settings_rounded, color: kRed, size: 16)
                  )
                ), 
                const SizedBox(width: 10)
              ], 
              Container(
                width: 32, height: 32, 
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white10), 
                child: const Icon(Icons.notifications_none_rounded, color: Colors.white70, size: 18)
              )
            ]
          )
        )
      ) 
    ); 
  }

  Widget _filtersRow(String sel) => ClipRRect(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), 
      child: Container(
        color: kBg.withOpacity(0.85), 
        padding: const EdgeInsets.symmetric(vertical: 10), 
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal, 
          padding: const EdgeInsets.symmetric(horizontal: 16), 
          child: Row(
            children: _filters.map((f) { 
              final s = sel == f; 
              return Padding(
                padding: const EdgeInsets.only(right: 8), 
                child: GestureDetector(
                  onTap: () { 
                    ref.read(selectedCategoryProvider.notifier).state = f; 
                    if (f != 'Fil') setState(() => _immersive = false); 
                  }, 
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200), 
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
                    decoration: BoxDecoration(color: s ? Colors.white : Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(20), border: Border.all(color: s ? Colors.white : kBorderLight)), 
                    child: Text(f, style: TextStyle(color: s ? Colors.black : Colors.white60, fontSize: 12, fontWeight: s ? FontWeight.w700 : FontWeight.w500))
                  )
                )
              ); 
            }).toList()
          )
        )
      )
    )
  );

  Widget _heroBanner(List<MediaContent> items) => SizedBox(
    height: MediaQuery.of(context).size.height * 0.82, 
    child: PageView.builder(
      controller: _bannerController, 
      onPageChanged: (i) => setState(() => _currentBannerIndex = i), 
      itemCount: items.length, 
      itemBuilder: (c, idx) { 
        final item = items[idx]; 
        return Stack(
          fit: StackFit.expand, 
          children: [
            _buildImage(item.coverUrl), 
            Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [kBg, kBg.withOpacity(0.7), Colors.transparent]))), 
            Positioned(
              bottom: 80, left: 24, right: 24, 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Text(item.title.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900, height: 0.9)), 
                  const SizedBox(height: 12), 
                  Text(item.type, style: const TextStyle(color: Colors.white54, fontSize: 13)), 
                  const SizedBox(height: 20), 
                  ElevatedButton.icon(
                    onPressed: () => _navigateToVideo(item), 
                    icon: const Icon(Icons.play_arrow_rounded, color: Colors.black), 
                    label: const Text('Lecture', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), 
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)))
                  )
                ]
              )
            )
          ]
        ); 
      }
    )
  );

  Widget _buildRow({required String title, required String subtitle, required ProviderListenable<List<MediaContent>> provider, required double aspectRatio, required double height, required double width, required Widget Function(MediaContent item, [int? index]) itemBuilder}) { 
    final list = ref.watch(provider); 
    if (list.isEmpty) return const SizedBox.shrink(); 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24), 
          child: Row(
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), 
              const SizedBox(width: 12), 
              Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12))
            ]
          )
        ), 
        const SizedBox(height: 16), 
        SizedBox(
          height: height, 
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24), 
            scrollDirection: Axis.horizontal, 
            itemCount: list.length, 
            itemBuilder: (c, i) => Padding(
              padding: const EdgeInsets.only(right: 16), 
              child: SizedBox(width: width, child: itemBuilder(list[i], i))
            )
          )
        )
      ]
    ); 
  }

  Widget _continueWatchingCard(MediaContent item) => GestureDetector(
    onTap: () => _navigateToVideo(item), 
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12), 
            child: Stack(
              fit: StackFit.expand, 
              children: [
                _buildImage(item.coverUrl), 
                Container(color: Colors.black.withOpacity(0.3)), 
                const Center(child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 44))
              ]
            )
          )
        ), 
        const SizedBox(height: 8), 
        Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))
      ]
    )
  );

  Widget _originalCard(MediaContent item) => GestureDetector(
    onTap: () => _navigateToVideo(item), 
    child: ClipRRect(
      borderRadius: BorderRadius.circular(14), 
      child: Stack(
        fit: StackFit.expand, 
        children: [
          _buildImage(item.coverUrl), 
          Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.9), Colors.transparent]))), 
          Positioned(
            bottom: 12, left: 12, right: 12, 
            child: Text(item.title, maxLines: 2, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))
          )
        ]
      )
    )
  );

  Widget _top10Card(MediaContent item, int index) => GestureDetector(
    onTap: () => _navigateToVideo(item), 
    child: Stack(
      clipBehavior: Clip.none, 
      children: [
        Positioned(
          left: -20, bottom: -10, 
          child: Text((index + 1).toString().padLeft(2, '0'), style: TextStyle(fontSize: 90, fontWeight: FontWeight.w900, color: Colors.transparent, shadows: [Shadow(color: Colors.white.withOpacity(0.2), blurRadius: 2)]))
        ), 
        Positioned(
          left: 40, top: 0, bottom: 0, right: 0, 
          child: ClipRRect(borderRadius: BorderRadius.circular(12), child: _buildImage(item.coverUrl))
        )
      ]
    )
  );

  Widget _bottomNav(String selCat, MediaContent? cur) { 
    final isFil = selCat == 'Fil'; 
    final isLiked = cur != null && _likedMediaIds.contains(cur.id); 
    MediaCounts? live; 
    
    if (isFil && cur != null) {
      live = ref.watch(mediaCountsStreamProvider(cur.id)).valueOrNull; 
    }
    
    // Remplacement du bouton TDIA par le cercle de profil et ajout d'un bouton '+' pour poster
    final avatarUrl = ref.watch(currentUserAvatarProvider).valueOrNull;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20), 
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26), 
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30), 
          child: Container(
            height: 60, 
            decoration: BoxDecoration(color: const Color(0xFF12121A).withOpacity(0.85), borderRadius: BorderRadius.circular(26), border: Border.all(color: Colors.white.withOpacity(0.1))), 
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
              children: [
                // 1. Cercle de Profil (Remplace l'ancien bouton TDIA)
                GestureDetector(
                  onTap: () {
                    final uid = Supabase.instance.client.auth.currentUser?.id;
                    if (uid != null) {
                      context.go('/profile/$uid');
                    } else {
                      context.go(AppRoutes.login);
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white70, width: 1.5),
                          image: avatarUrl != null && avatarUrl.isNotEmpty
                              ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover)
                              : null,
                        ),
                        child: avatarUrl == null || avatarUrl.isEmpty
                            ? const Icon(Icons.person, size: 14, color: Colors.white70)
                            : null,
                      ),
                      const SizedBox(height: 4),
                      const Text('Compte', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white70)),
                    ],
                  ),
                ),

                // 2. Bouton J'aime / Cœur
                _navItem(
                  isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                  cur != null ? _formatNumber(live?.likeCount ?? cur.likeCount) : "J'aime",
                  false,
                  1,
                  color: isLiked ? kRed : null,
                  onTap: () { if (cur != null) _toggleLike(cur); }
                ),

                // 3. Bouton Commentaires
                _navItem(
                  Icons.chat_bubble_outline_rounded,
                  cur != null ? _formatNumber(live?.commentCount ?? cur.commentCount) : 'Commenter',
                  false,
                  2,
                  onTap: () { if (cur != null) _openComments(cur); }
                ),

                // 4. Bouton Vues
                _navItem(
                  Icons.remove_red_eye_rounded,
                  cur != null ? _formatNumber(live?.viewCount ?? cur.viewCount) : 'Vu',
                  false,
                  3,
                  onTap: () {
                    if (cur != null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${cur.viewCount} vues uniques'), backgroundColor: kSurface));
                    }
                  }
                ),

                // 5. Bouton Créer un post (+) pour poster directement dans le Fil
                GestureDetector(
                  onTap: () => context.go('/create-post'),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add_circle_outline_rounded, color: kRed, size: 22),
                      SizedBox(height: 4),
                      Text('Poster', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kRed)),
                    ],
                  ),
                ),
              ],
            )
          )
        )
      )
    ); 
  }

  Widget _navItem(IconData icon, String label, bool sel, int idx, {Color? color, required VoidCallback onTap}) => InkWell(
    onTap: onTap, 
    child: Column(
      mainAxisSize: MainAxisSize.min, 
      mainAxisAlignment: MainAxisAlignment.center, 
      children: [
        Icon(icon, color: color ?? (sel ? Colors.white : Colors.white38), size: 22), 
        const SizedBox(height: 4), 
        Text(label, style: TextStyle(fontSize: 10, fontWeight: sel ? FontWeight.bold : FontWeight.w500, color: color ?? (sel ? Colors.white : Colors.white38))) 
      ]
    )
  );
}

class FeedVideoPlayer extends StatefulWidget { 
  final String videoUrl, coverUrl; 
  final bool isPlaying, isImmersive; 
  final Function(bool) onPlayStateChanged; 
  
  const FeedVideoPlayer({
    super.key, 
    required this.videoUrl, 
    required this.coverUrl, 
    required this.isPlaying, 
    required this.isImmersive, 
    required this.onPlayStateChanged
  }); 
  
  @override 
  State<FeedVideoPlayer> createState() => _FeedVideoPlayerState(); 
}

class _FeedVideoPlayerState extends State<FeedVideoPlayer> {
  late VideoPlayerController _c; 
  bool _init = false, _paused = false; 
  final ValueNotifier<Duration> _pos = ValueNotifier(Duration.zero); 
  Duration _dur = Duration.zero;
  bool _isDragging = false;
  
  @override 
  void initState() { 
    super.initState(); 
    _c = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl)); 
    _c.initialize().then((_) { 
      if (!mounted) return; 
      _c.setLooping(true); 
      _c.setVolume(1.0); 
      _c.addListener(() { 
        if (mounted && !_isDragging) _pos.value = _c.value.position; 
      }); 
      setState(() { 
        _init = true; 
        _dur = _c.value.duration; 
      }); 
      if (widget.isPlaying) _c.play(); 
    }); 
  }

  @override 
  void didUpdateWidget(covariant FeedVideoPlayer o) { 
    super.didUpdateWidget(o); 
    if (!_init) return; 
    if (widget.isPlaying && !o.isPlaying) { 
      _paused = false; 
      _c.play(); 
    } else if (!widget.isPlaying && o.isPlaying) { 
      _c.pause(); 
      _c.seekTo(Duration.zero); 
    } 
  }

  @override 
  void dispose() { 
    _c.dispose(); 
    _pos.dispose(); 
    super.dispose(); 
  }

  void _seekToPercent(double pct) {
    if (!_init) return;
    final newPos = Duration(milliseconds: (_dur.inMilliseconds * pct).round());
    _c.seekTo(newPos);
    _pos.value = newPos;
  }

  @override 
  Widget build(BuildContext context) {
    if (!_init) return Image.network(widget.coverUrl, fit: BoxFit.cover);
    
    return GestureDetector(
      onTap: () { 
        if (_c.value.isPlaying) { 
          _c.pause(); 
          _paused = true; 
        } else { 
          _c.play(); 
          _paused = false; 
        } 
        setState(() {}); 
        widget.onPlayStateChanged(_paused); 
      }, 
      child: Stack(
        fit: StackFit.expand, 
        children: [
          FittedBox(
            fit: BoxFit.cover, 
            child: SizedBox(width: _c.value.size.width, height: _c.value.size.height, child: VideoPlayer(_c))
          ), 
          if (_paused) const Center(child: Icon(Icons.play_arrow_rounded, color: Colors.white70, size: 64)), 
          
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250), 
            curve: Curves.easeInOutCubic,
            left: 0, right: 0, 
            bottom: widget.isImmersive ? -20 : 80, 
            child: GestureDetector(
              onHorizontalDragStart: (d) {
                _isDragging = true;
                _c.pause();
              },
              onHorizontalDragUpdate: (d) {
                final width = context.size!.width;
                final pct = (d.localPosition.dx / width).clamp(0.0, 1.0);
                _pos.value = Duration(milliseconds: (_dur.inMilliseconds * pct).round());
              },
              onHorizontalDragEnd: (d) {
                _isDragging = false;
                _c.seekTo(_pos.value);
                if (!_paused) _c.play();
              },
              onTapDown: (d) {
                final width = context.size!.width;
                final pct = (d.localPosition.dx / width).clamp(0.0, 1.0);
                _seekToPercent(pct);
              },
              child: Container(
                height: 24, 
                color: Colors.transparent,
                alignment: Alignment.bottomCenter,
                child: ValueListenableBuilder<Duration>(
                  valueListenable: _pos, 
                  builder: (_, pos, __) { 
                    final pct = _dur.inMilliseconds == 0 ? 0.0 : pos.inMilliseconds / _dur.inMilliseconds; 
                    return Stack(
                      alignment: Alignment.bottomLeft,
                      children: [
                        Container(height: _isDragging ? 6 : 3, width: double.infinity, color: Colors.white38),
                        Container(height: _isDragging ? 6 : 3, width: MediaQuery.of(context).size.width * pct, color: kRed),
                      ]
                    ); 
                  }
                )
              )
            )
          ) 
        ]
      )
    );
  }
}

class _CommentsSheet extends ConsumerStatefulWidget { 
  final String mediaId, mediaTitle; 
  const _CommentsSheet({required this.mediaId, required this.mediaTitle}); 
  @override 
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState(); 
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _controller = TextEditingController(); 
  final _focusNode = FocusNode();
  bool _sending = false;
  bool _loading = true;
  
  List<CommentItem> _roots = [];
  final Map<String, List<CommentItem>> _replies = {};
  final Set<String> _expanded = {};
  
  CommentItem? _replyingTo;
  CommentItem? _editingComment;
  final Set<String> _likedIds = {};

  @override
  void initState() {
    super.initState();
    _fetchRoots();
  }

  Future<void> _fetchRoots() async {
    try {
      final res = await Supabase.instance.client
          .from('media_comments')
          .select('id,user_id,user_name,avatar_url,content,created_at,parent_id,like_count,reply_count')
          .eq('media_id', widget.mediaId)
          .isFilter('parent_id', null)
          .order('created_at', ascending: false)
          .limit(50);
          
      if (mounted) {
        setState(() {
          _roots = (res as List).map((e) => CommentItem.fromMap(e as Map<String, dynamic>)).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchReplies(String parentId) async {
    try {
      final res = await Supabase.instance.client
          .from('media_comments')
          .select('id,user_id,user_name,avatar_url,content,created_at,parent_id,like_count,reply_count')
          .eq('parent_id', parentId)
          .order('created_at', ascending: true);
          
      if (mounted) {
        setState(() {
          _replies[parentId] = (res as List).map((e) => CommentItem.fromMap(e as Map<String, dynamic>)).toList();
          _expanded.add(parentId);
        });
      }
    } catch (_) {}
  }
  
  Future<void> _submit() async { 
    final t = _controller.text.trim(); 
    if (t.isEmpty || _sending) return; 
    final uid = Supabase.instance.client.auth.currentUser?.id; 
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez vous connecter.'), backgroundColor: kSurface));
      return; 
    }
    
    setState(() => _sending = true); 
    try { 
      if (_editingComment != null) {
        await Supabase.instance.client.from('media_comments').update({'content': t}).eq('id', _editingComment!.id);
        setState(() => _editingComment = null);
        _fetchRoots(); 
      } else {
        final p = await Supabase.instance.client.from('profiles').select('username,avatar_url').eq('id', uid).maybeSingle(); 
        final name = (p?['username'] as String?)?.isNotEmpty == true ? p!['username'] : 'Utilisateur'; 
        
        final parentId = _replyingTo?.parentId ?? _replyingTo?.id;

        await Supabase.instance.client.from('media_comments').insert({
          'media_id': widget.mediaId, 
          'user_id': uid, 
          'user_name': name, 
          'avatar_url': p?['avatar_url'], 
          'content': t,
          'parent_id': parentId,
        }); 
        
        if (parentId != null) {
          _fetchReplies(parentId);
        } else {
          _fetchRoots();
        }
      }
      
      _controller.clear(); 
      _focusNode.unfocus();
      setState(() => _replyingTo = null);
      
      ref.invalidate(commentCountProvider(widget.mediaId)); 
    } finally { 
      if (mounted) setState(() => _sending = false); 
    } 
  }

  Future<void> _delete(String id) async {
    await Supabase.instance.client.from('media_comments').delete().eq('id', id);
    _fetchRoots();
    ref.invalidate(commentCountProvider(widget.mediaId));
  }

  void _showOptions(CommentItem c) {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final isAuthor = uid == c.userId;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: kSurfaceLight,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAuthor) ListTile(
              leading: const Icon(Icons.edit, color: Colors.white),
              title: const Text('Modifier', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                setState(() { _editingComment = c; _replyingTo = null; });
                _controller.text = c.content;
                _focusNode.requestFocus();
              }
            ),
            if (isAuthor) ListTile(
              leading: const Icon(Icons.delete, color: kRed),
              title: const Text('Supprimer', style: TextStyle(color: kRed)),
              onTap: () {
                Navigator.pop(context);
                _delete(c.id);
              }
            ),
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.orange),
              title: const Text('Signaler', style: TextStyle(color: Colors.orange)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signalé aux modérateurs'), backgroundColor: kSurface));
              }
            ),
          ]
        )
      )
    );
  }

  String _formatDate(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 60) return "à l'instant";
    if (diff.inMinutes < 60) return "${diff.inMinutes} min";
    if (diff.inHours < 24) return "${diff.inHours} h";
    return "${diff.inDays} j";
  }

  Widget _buildCommentTile(CommentItem c, {bool isReply = false}) {
    final isLiked = _likedIds.contains(c.id);
    return Padding(
      padding: EdgeInsets.only(left: isReply ? 40 : 0, top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: isReply ? 12 : 16, 
            backgroundColor: kSurfaceLight, 
            backgroundImage: c.avatarUrl != null && c.avatarUrl!.isNotEmpty ? NetworkImage(c.avatarUrl!) : null,
            child: c.avatarUrl == null ? Icon(Icons.person, size: isReply ? 14 : 18, color: kTextGrey) : null,
          ), 
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onLongPress: () => _showOptions(c),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.go('/profile/${c.userId}'),
                        child: Text(c.userName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                      ), 
                      const SizedBox(width: 8),
                      Text(_formatDate(c.createdAt), style: const TextStyle(color: kTextGrey, fontSize: 11)),
                    ]
                  ),
                  const SizedBox(height: 4),
                  Text(c.content, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() { _replyingTo = c; _editingComment = null; });
                          _focusNode.requestFocus();
                        },
                        child: const Text('Répondre', style: TextStyle(color: kTextGrey, fontSize: 12, fontWeight: FontWeight.bold))
                      ),
                      const SizedBox(width: 24),
                      GestureDetector(
                        onTap: () {
                          setState(() => isLiked ? _likedIds.remove(c.id) : _likedIds.add(c.id));
                          Supabase.instance.client.rpc('toggle_comment_like', params: {'p_comment_id': c.id}).catchError((_) {});
                        },
                        child: Row(
                          children: [
                            Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? kRed : kTextGrey, size: 14),
                            const SizedBox(width: 4),
                            Text(c.likeCount > 0 ? '${c.likeCount}' : "J'aime", style: TextStyle(color: isLiked ? kRed : kTextGrey, fontSize: 11))
                          ]
                        )
                      )
                    ]
                  ),
                  
                  if (!isReply && (c.replyCount > 0 || _replies.containsKey(c.id))) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        if (_expanded.contains(c.id)) {
                          setState(() => _expanded.remove(c.id));
                        } else {
                          _fetchReplies(c.id);
                        }
                      },
                      child: Row(
                        children: [
                          Container(width: 24, height: 1, color: kBorderLight),
                          const SizedBox(width: 8),
                          Text(_expanded.contains(c.id) ? 'Masquer' : 'Voir les réponses', style: const TextStyle(color: kTdiaBlue, fontSize: 12, fontWeight: FontWeight.w600))
                        ]
                      )
                    )
                  ],
                  if (!isReply && _expanded.contains(c.id)) ...[
                    ...(_replies[c.id] ?? []).map((r) => _buildCommentTile(r, isReply: true))
                  ]
                ]
              )
            )
          )
        ]
      )
    );
  }

  @override 
  Widget build(BuildContext context) { 
    final insets = MediaQuery.of(context).viewInsets.bottom; 
    
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150), 
      padding: EdgeInsets.only(bottom: insets), 
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75, 
        decoration: const BoxDecoration(color: kSurface, borderRadius: BorderRadius.vertical(top: Radius.circular(20))), 
        child: Column(
          children: [
            const SizedBox(height: 10), 
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4))), 
            const SizedBox(height: 14), 
            const Text('Commentaires', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), 
            const Divider(color: kBorderLight, height: 1), 
            
            Expanded(
              child: _loading 
                ? const Center(child: CircularProgressIndicator(color: kRed)) 
                : _roots.isEmpty 
                  ? const Center(child: Text('Aucun commentaire', style: TextStyle(color: kTextGrey)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      itemCount: _roots.length,
                      itemBuilder: (c, i) => _buildCommentTile(_roots[i])
                    )
            ), 
            
            const Divider(color: kBorderLight, height: 1), 
            
            if (_replyingTo != null || _editingComment != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: kSurfaceLight.withOpacity(0.5),
                child: Row(
                  children: [
                    Text(_editingComment != null ? 'Modification' : 'Réponse à @${_replyingTo!.userName}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () { setState(() { _replyingTo = null; _editingComment = null; }); _controller.clear(); },
                      child: const Icon(Icons.close, color: Colors.white70, size: 18)
                    )
                  ]
                )
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10), 
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14), 
                      decoration: BoxDecoration(color: kSurfaceLight, borderRadius: BorderRadius.circular(24)), 
                      child: TextField(
                        controller: _controller, 
                        focusNode: _focusNode,
                        minLines: 1, 
                        maxLines: 4, 
                        onSubmitted: (_) => _submit(), 
                        style: const TextStyle(color: Colors.white, fontSize: 13.5), 
                        decoration: InputDecoration(
                          hintText: _editingComment != null ? 'Modifier le commentaire...' : (_replyingTox != null ? 'Ajouter une réponse...' : 'Ajouter un commentaire...'), 
                          hintStyle: const TextStyle(color: kTextGrey, fontSize: 13.5), 
                          border: InputBorder.none, 
                          isDense: true
                        )
                      )
                    )
                  ), 
                  const SizedBox(width: 8), 
                  GestureDetector(
                    onTap: _submit, 
                    child: Container(
                      width: 42, 
                      height: 42, 
                      decoration: BoxDecoration(color: _sending ? kSurfaceLight : kRed, shape: BoxShape.circle), 
                      child: _sending 
                        ? const Padding(padding: EdgeInsets.all(11), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 18)
                    )
                  ) 
                ]
              )
            )
          ]
        )
      )
    ); 
  }
}
