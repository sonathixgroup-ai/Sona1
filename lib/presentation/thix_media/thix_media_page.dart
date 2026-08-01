import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
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
import 'package:flutter/rendering.dart';

const Color kBg = Color(0xFF050507);
const Color kSurface = Color(0xFF121214);
const Color kSurfaceLight = Color(0xFF1E1E28);
const Color kRed = Color(0xFFFF1A1A);
const Color kTextWhite = Color(0xFFFFFFFF);
const Color kTextGrey = Color(0xFF9CA3AF);
const Color kBorderLight = Color(0x14FFFFFF);
const Color kTdiaBlue = Color(0xFF2D6CDF);

final isMediaAdminProvider = FutureProvider.autoDispose<bool>((ref) async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return false;
  try {
    final res = await Supabase.instance.client.from('profiles').select('role').eq('id', uid).maybeSingle();
    return res != null && (res['role'] == 'admin' || res['role'] == 'superadmin');
  } catch (_) {
    return false;
  }
});

class CommentItem {
  final String id;
  final String userId;
  final String userName;
  final String? avatarUrl;
  final String content;
  final DateTime createdAt;

  CommentItem({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
    this.avatarUrl,
  });

  factory CommentItem.fromMap(Map<String, dynamic> map) {
    return CommentItem(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      userName: (map['user_name'] as String?)?.trim().isNotEmpty == true ? map['user_name'] as String : 'Utilisateur',
      avatarUrl: map['avatar_url'] as String?,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }
}

final commentsListProvider = FutureProvider.autoDispose.family<List<CommentItem>, String>((ref, mediaId) async {
  final res = await Supabase.instance.client
      .from('media_comments')
      .select('id, user_id, user_name, avatar_url, content, created_at')
      .eq('media_id', mediaId)
      .order('created_at', ascending: false)
      .limit(300);
  return (res as List).map((e) => CommentItem.fromMap(e as Map<String, dynamic>)).toList();
});

final commentCountProvider = FutureProvider.autoDispose.family<int, String>((ref, mediaId) async {
  final res = await Supabase.instance.client
      .from('media_comments')
      .select('id')
      .eq('media_id', mediaId)
      .count(CountOption.exact);
  return res.count;
});

final mediaCountsStreamProvider = StreamProvider.autoDispose.family<MediaCounts, String>((ref, mediaId) {
  return MediaService().watchMediaCounts(mediaId);
});

class _NavItemData {
  final IconData icon;
  final String label;
  final bool selected;
  final int index;
  final Color? color;
  _NavItemData({required this.icon, required this.label, required this.selected, required this.index, this.color});
}

class ThixMediaPage extends ConsumerStatefulWidget {
  const ThixMediaPage({super.key});
  @override
  ConsumerState<ThixMediaPage> createState() => _ThixMediaPageState();
}

class _ThixMediaPageState extends ConsumerState<ThixMediaPage> {
  late PageController _bannerController, _feedController;
  int _currentBannerIndex = 0;
  Timer? _bannerTimer, _searchDebounce;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final List<String> _filters = ["Accueil", "Fil", "Tendances", "NOVA Originals", "Live", "Courts", "Musique", "Gaming", "Formation"];

  Set<String> _likedMediaIds = {};
  final Set<String> _viewedMediaIds = {};
  final Map<String, int> _likeDelta = {};
  final Map<String, int> _viewDelta = {};

  bool _immersive = false;
  int _currentFeedIndex = 0;
  bool _feedBootstrapped = false;
  final MediaService _mediaService = MediaService();

  final Map<String, VideoPlayerController> _videoControllers = {};
  List<MediaContent> _lastSourceList = [];
  List<MediaContent> _memoFeedList = [];

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
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _searchDebounce?.cancel();
    _bannerController.dispose();
    _feedController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    for (final c in _videoControllers.values) c.dispose();
    super.dispose();
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
    return Image.network(
      url, width: width, height: height, fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(color: kSurface, child: const Center(child: CircularProgressIndicator(color: kRed, strokeWidth: 2)));
      },
      errorBuilder: (context, error, stackTrace) => Container(color: kSurface, child: const Center(child: Icon(Icons.broken_image_rounded, color: kTextGrey))),
    );
  }

  List<MediaContent> _getFeedList(List<MediaContent> source) {
    if (!_sameIds(source, _lastSourceList)) {
      _memoFeedList = List<MediaContent>.from(source)..shuffle();
      _lastSourceList = source;
    }
    return _memoFeedList;
  }

  bool _sameIds(List<MediaContent> a, List<MediaContent> b) {
    if (a.length != b.length) return false;
    final idsA = a.map((e) => e.id).toSet();
    final idsB = b.map((e) => e.id).toSet();
    return idsA.length == idsB.length && idsA.containsAll(idsB);
  }

  int _realLikeCount(MediaContent item) => item.likeCount + (_likeDelta[item.id] ?? 0);
  int _realViewCount(MediaContent item) => item.viewCount + (_viewDelta[item.id] ?? 0);

  Future<void> _registerView(MediaContent item) async {
    if (_viewedMediaIds.contains(item.id)) return;
    _viewedMediaIds.add(item.id);
    if (mounted) setState(() => _viewDelta[item.id] = (_viewDelta[item.id] ?? 0) + 1);
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await Supabase.instance.client.from('media_views').upsert({'media_id': item.id, 'user_id': uid}, onConflict: 'media_id,user_id', ignoreDuplicates: true);
    } catch (_) {}
  }

  Future<void> _toggleLike(MediaContent item) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    final wasLiked = _likedMediaIds.contains(item.id);
    setState(() {
      if (wasLiked) {
        _likedMediaIds.remove(item.id);
        _likeDelta[item.id] = (_likeDelta[item.id] ?? 0) - 1;
      } else {
        _likedMediaIds.add(item.id);
        _likeDelta[item.id] = (_likeDelta[item.id] ?? 0) + 1;
      }
    });
    try {
      if (wasLiked) {
        await Supabase.instance.client.from('media_likes').delete().eq('media_id', item.id).eq('user_id', uid);
      } else {
        await Supabase.instance.client.from('media_likes').upsert({'media_id': item.id, 'user_id': uid}, onConflict: 'media_id,user_id', ignoreDuplicates: true);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (wasLiked) {
          _likedMediaIds.add(item.id);
          _likeDelta[item.id] = (_likeDelta[item.id] ?? 0) + 1;
        } else {
          _likedMediaIds.remove(item.id);
          _likeDelta[item.id] = (_likeDelta[item.id] ?? 0) - 1;
        }
      });
    }
  }

  void _openComments(MediaContent item) {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (_) => _CommentsSheet(mediaId: item.id, mediaTitle: item.title)).then((_) {
      ref.invalidate(commentCountProvider(item.id));
    });
  }

  void _showViewsInfo(MediaContent item) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${_realViewCount(item)} vues uniques'), backgroundColor: kSurface));
  }

  Future<void> _ensureController(MediaContent item, {required bool play}) async {
    var controller = _videoControllers[item.id];
    if (controller == null) {
      controller = VideoPlayerController.networkUrl(Uri.parse(item.videoUrl));
      _videoControllers[item.id] = controller;
      try {
        await controller.initialize();
        controller.setLooping(true);
        controller.setVolume(1.0);
      } catch (_) {
        _videoControllers.remove(item.id);
        return;
      }
      if (!mounted) return;
      setState(() {});
    }
    if (play) controller.play();
  }

  void _cleanupControllers(List<MediaContent> list, int currentIndex) {
    final keepIds = <String>{};
    for (int i = currentIndex - 1; i <= currentIndex + 1; i++) {
      if (i >= 0 && i < list.length) keepIds.add(list[i].id);
    }
    final toRemove = _videoControllers.keys.where((id) => !keepIds.contains(id)).toList();
    for (final id in toRemove) {
      _videoControllers[id]?.pause();
      _videoControllers[id]?.dispose();
      _videoControllers.remove(id);
    }
  }

  void _handlePageChanged(int index, List<MediaContent> list) {
    if (index < 0 || index >= list.length) return;
    final current = list[index];
    for (final entry in _videoControllers.entries) {
      if (entry.key != current.id) entry.value.pause();
    }
    _cleanupControllers(list, index);
    _ensureController(current, play: true);
    if (index + 1 < list.length) _ensureController(list[index + 1], play: false);
    _registerView(current);
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
          final feedList = _getFeedList(mediaList);
          final currentItem = feedList.isNotEmpty ? feedList[_currentFeedIndex.clamp(0, feedList.length - 1)] : null;

          if (selectedCategory == 'Fil' && feedList.isNotEmpty && !_feedBootstrapped) {
            _feedBootstrapped = true;
            WidgetsBinding.instance.addPostFrameCallback((_) => _handlePageChanged(0, feedList));
          }

          final showBars = !(_immersive && selectedCategory == 'Fil');

          return Stack(
            children: [
              if (selectedCategory == 'Fil')
                _buildTikTokFeed(feedList)
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
                                decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, kBg.withOpacity(0.6), kBg], stops: const [0.0, 0.1, 0.3])),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 20),
                                    _buildRow(title: 'Continuer à regarder', subtitle: 'Reprise intelligente', provider: recommendationsProvider, aspectRatio: 16 / 9, height: 180, width: 320, itemBuilder: (item, [index]) => _continueWatchingCard(item)),
                                    const SizedBox(height: 40),
                                    _buildRow(title: 'TDIA Originals Exclusifs', subtitle: 'Produit par TDIA Studios', provider: newReleasesProvider, aspectRatio: 2 / 3, height: 240, width: 160, itemBuilder: (item, [index]) => _originalCard(item)),
                                    const SizedBox(height: 40),
                                    _buildRow(title: 'Top 10 cette semaine', subtitle: 'Classement', provider: trendingProvider, aspectRatio: 16 / 9, height: 160, width: 300, itemBuilder: (item, [index]) => _top10Card(item, index ?? 0)),
                                    const SizedBox(height: 120),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              Positioned(
                top: 0, left: 0, right: 0,
                child: IgnorePointer(
                  ignoring: !showBars,
                  child: AnimatedOpacity(duration: const Duration(milliseconds: 250), opacity: showBars ? 1 : 0, child: Column(children: [_header(), _filtersRow(selectedCategory)])),
                ),
              ),

              Positioned(
                bottom: 0, left: 0, right: 0,
                child: IgnorePointer(
                  ignoring: !showBars,
                  child: AnimatedOpacity(duration: const Duration(milliseconds: 250), opacity: showBars ? 1 : 0, child: _bottomNav(selectedCategory, currentItem)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTikTokFeed(List<MediaContent> mediaList) {
    if (mediaList.isEmpty) return const Center(child: Text("Aucun contenu disponible", style: TextStyle(color: Colors.white)));

    // 1. IMMERSION AUTOMATIQUE : Dès qu'on scrolle, les barres disparaissent.
    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        if (notification.direction != ScrollDirection.idle && !_immersive) {
          FocusScope.of(context).unfocus();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _immersive = true); // Cache les menus = Plein écran pur
          });
        }
        return false;
      },
      child: PageView.builder(
        controller: _feedController,
        scrollDirection: Axis.vertical,
        itemCount: mediaList.length,
        onPageChanged: (index) {
          setState(() {
            _currentFeedIndex = index;
            _immersive = true; // Plein écran pur assuré au changement de vidéo
          });
          _handlePageChanged(index, mediaList);
        },
        itemBuilder: (context, index) {
          final item = mediaList[index];
          final isFocused = _currentFeedIndex == index;
          
          // 2. ANIMATION DU TEXTE : Glisse vers le bas si plein écran, remonte si UI visible.
          final double textBottomPadding = _immersive ? 20.0 : 110.0;

          return Stack(
            fit: StackFit.expand,
            children: [
              // Lecteur intelligent (Gère Play/Pause + Barre VLC)
              FeedVideoPlayer(
                videoUrl: item.videoUrl,
                coverUrl: item.coverUrl,
                isPlaying: isFocused,
                isImmersive: _immersive, // Informe le lecteur qu'il est en plein écran
                onPlayStateChanged: (isPaused) {
                  // 3. APPARITION DE L'INTERFACE : Pause = Interface visible, Lecture = Plein écran
                  setState(() => _immersive = !isPaused);
                },
              ),

              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                left: 20,
                bottom: textBottomPadding,
                right: 20,
                child: IgnorePointer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: kTdiaBlue.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: kTdiaBlue.withOpacity(0.5))),
                        child: Text(item.type, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: 10),
                      Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1.1, shadows: [Shadow(color: Colors.black87, blurRadius: 6)])),
                      if (item.subtitle != null) ...[
                        const SizedBox(height: 6),
                        Text(item.subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4, shadows: [Shadow(color: Colors.black87, blurRadius: 6)])),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _header() {
    final isAdminAsync = ref.watch(isMediaAdminProvider);
    final isAdmin = isAdminAsync.valueOrNull ?? false;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 60,
          padding: const EdgeInsets.only(top: 8, left: 12, right: 12, bottom: 8),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), border: const Border(bottom: BorderSide(color: kBorderLight))),
          child: Row(children: [
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(colors: [kTdiaBlue, Color(0xFF00E5FF)]).createShader(b),
              child: const Text('TDIA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: const Color(0xFF0D0D10), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.08))),
                child: Row(children: [
                  const Icon(Icons.search_rounded, color: Colors.white30, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: _onSearchChanged,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(hintText: "Rechercher...", hintStyle: TextStyle(color: Colors.white30, fontSize: 13), border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(width: 12),
            if (isAdmin) ...[
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ThixMediaAdminPage())),
                child: Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, color: kRed.withOpacity(0.15), border: Border.all(color: kRed.withOpacity(0.3))), child: const Icon(Icons.admin_panel_settings_rounded, color: kRed, size: 16)),
              ),
              const SizedBox(width: 10),
            ],
            Container(width: 32, height: 32, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white10), child: const Icon(Icons.notifications_none_rounded, color: Colors.white70, size: 18)),
          ]),
        ),
      ),
    );
  }

  Widget _filtersRow(String selectedCategory) => ClipRRect(
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
                  final sel = selectedCategory == f;
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
                        decoration: BoxDecoration(color: sel ? Colors.white : Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? Colors.white : kBorderLight)),
                        child: Text(f, style: TextStyle(color: sel ? Colors.black : Colors.white60, fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      );

  Widget _heroBanner(List<MediaContent> bannerItems) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.82,
        child: PageView.builder(
          controller: _bannerController,
          onPageChanged: (i) => setState(() => _currentBannerIndex = i),
          itemCount: bannerItems.length,
          itemBuilder: (c, idx) {
            final item = bannerItems[idx];
            return Stack(fit: StackFit.expand, children: [
              _buildImage(item.coverUrl),
              Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [kBg, kBg.withOpacity(0.7), kBg.withOpacity(0.1), Colors.transparent]))),
              Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [kBg, kBg.withOpacity(0.6), Colors.transparent]))),
              Positioned(
                bottom: 80, left: 24, right: 24,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.title.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, height: 0.9, letterSpacing: -2)),
                  const SizedBox(height: 16),
                  Row(children: [
                    if (item.year != null) ...[Text("${item.year}", style: const TextStyle(color: Colors.white54, fontSize: 13)), const SizedBox(width: 10)],
                    Text(item.type, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  ]),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 16),
                    Text(item.subtitle!, style: const TextStyle(color: Colors.white70, fontSize: 14.5, height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 24),
                  Row(children: [
                    ElevatedButton.icon(
                      onPressed: () => _navigateToVideo(item),
                      icon: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 22),
                      label: const Text('Lecture', style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add, color: Colors.white, size: 22),
                      label: const Text('Ma Liste', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.1), padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), side: BorderSide(color: Colors.white.withOpacity(0.1))),
                    ),
                  ]),
                ]),
              ),
            ]);
          },
        ),
      );

  Widget _buildRow({required String title, required String subtitle, required ProviderListenable<List<MediaContent>> provider, required double aspectRatio, required double height, required double width, required Widget Function(MediaContent item, [int? index]) itemBuilder}) {
    final list = ref.watch(provider);
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w500)),
        ]),
      ),
      const SizedBox(height: 16),
      SizedBox(
        height: height,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          scrollDirection: Axis.horizontal,
          itemCount: list.length,
          itemBuilder: (c, i) => Padding(padding: const EdgeInsets.only(right: 16), child: SizedBox(width: width, child: itemBuilder(list[i], i))),
        ),
      ),
    ]);
  }

  Widget _continueWatchingCard(MediaContent item) => GestureDetector(
        onTap: () => _navigateToVideo(item),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(fit: StackFit.expand, children: [
                _buildImage(item.coverUrl),
                Container(decoration: BoxDecoration(color: Colors.black.withOpacity(0.3))),
                const Center(child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 44)),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _originalCard(MediaContent item) => GestureDetector(
        onTap: () => _navigateToVideo(item),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(fit: StackFit.expand, children: [
            _buildImage(item.coverUrl),
            Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.9), Colors.transparent]))),
            Positioned(bottom: 12, left: 12, right: 12, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              if (item.year != null) ...[const SizedBox(height: 4), Text("${item.year}", style: const TextStyle(color: Colors.white54, fontSize: 11))],
            ])),
          ],
        ),
      ),
    );

  Widget _top10Card(MediaContent item, int index) => GestureDetector(
        onTap: () => _navigateToVideo(item),
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned(left: -20, bottom: -10, child: Text((index + 1).toString().padLeft(2, '0'), style: TextStyle(fontSize: 100, fontWeight: FontWeight.w900, color: Colors.transparent, shadows: [Shadow(color: Colors.white.withOpacity(0.2), blurRadius: 2, offset: const Offset(0, 0))]))),
          Positioned(
            left: 40, top: 0, bottom: 0, right: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(fit: StackFit.expand, children: [
                _buildImage(item.coverUrl),
                Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.8), Colors.transparent]))),
                Positioned(bottom: 8, left: 8, right: 8, child: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
              ]),
            ),
          ),
        ]),
      );

  Widget _bottomNav(String selectedCategory, MediaContent? currentItem) {
    final isFil = selectedCategory == 'Fil';
    final isLiked = currentItem != null && _likedMediaIds.contains(currentItem.id);

    MediaCounts? liveCounts;
    if (isFil && currentItem != null) {
      liveCounts = ref.watch(mediaCountsStreamProvider(currentItem.id)).valueOrNull;
    }

    final List<_NavItemData> items = isFil
        ? [
            _NavItemData(icon: Icons.movie_filter_rounded, label: 'TDIA', selected: true, index: 0),
            _NavItemData(
              icon: isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
              label: currentItem != null ? _formatNumber(_realLikeCount(currentItem)) : "J'aime",
              selected: false, index: 1, color: isLiked ? kRed : null,
            ),
            _NavItemData(
              icon: Icons.chat_bubble_outline_rounded,
              label: currentItem != null ? _formatNumber(liveCounts?.commentCount ?? currentItem.commentCount) : 'Commenter',
              selected: false, index: 2,
            ),
            _NavItemData(
              icon: Icons.remove_red_eye_rounded,
              label: currentItem != null ? _formatNumber(_realViewCount(currentItem)) : 'Vu',
              selected: false, index: 3,
            ),
          ]
        : [
            _NavItemData(icon: Icons.movie_filter_rounded, label: 'TDIA', selected: true, index: 0),
            _NavItemData(icon: Icons.search_rounded, label: 'Recherche', selected: false, index: 1),
            _NavItemData(icon: Icons.favorite_rounded, label: 'Favoris', selected: false, index: 2),
            _NavItemData(icon: Icons.person_rounded, label: 'Profil', selected: false, index: 3),
          ];

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
              children: items.map((d) => _navItem(d.icon, d.label, d.selected, d.index, isFil: isFil, currentItem: currentItem, color: d.color)).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool selected, int idx, {required bool isFil, MediaContent? currentItem, Color? color}) {
    return InkWell(
      onTap: () {
        if (idx == 0) {
          if (ref.read(selectedCategoryProvider.notifier).state == 'Fil') {
            _feedController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
          } else {
            ref.read(selectedCategoryProvider.notifier).state = 'Fil';
          }
          return;
        }
        if (isFil) {
          switch (idx) {
            case 1:
              if (currentItem != null) _toggleLike(currentItem);
              break;
            case 2:
              if (currentItem != null) _openComments(currentItem);
              break;
            case 3:
              if (currentItem != null) _showViewsInfo(currentItem);
              break;
          }
        } else {
          if (idx == 3) context.go(AppRoutes.userDashboard);
        }
      },
      child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color ?? (selected ? Colors.white : Colors.white38), size: 22),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: selected ? FontWeight.bold : FontWeight.w500, color: color ?? (selected ? Colors.white : Colors.white38))),
      ]),
    );
  }
}

// ---------------- LECTEUR VIDÉO : GESTION DES CLICS & BARRE DE PROGRESSION ----------------

class FeedVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String coverUrl;
  final bool isPlaying;
  final bool isImmersive;
  final Function(bool isPaused) onPlayStateChanged;

  const FeedVideoPlayer({
    super.key, 
    required this.videoUrl, 
    required this.coverUrl, 
    required this.isPlaying,
    required this.isImmersive,
    required this.onPlayStateChanged,
  });

  @override
  State<FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<FeedVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _userPaused = false;
  final ValueNotifier<Duration> _position = ValueNotifier(Duration.zero);
  Duration _duration = Duration.zero;
  Offset? _tapPosition;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    try {
      await _controller.initialize();
      _controller.setLooping(true);
      _controller.setVolume(1.0);
      _controller.addListener(_listener);
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _duration = _controller.value.duration;
        });
        if (widget.isPlaying) _controller.play();
      }
    } catch (_) {}
  }

  void _listener() {
    if (!mounted || !_controller.value.isInitialized) return;
    if (!_isDragging) {
      _position.value = _controller.value.position;
    }
  }

  @override
  void didUpdateWidget(covariant FeedVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isInitialized) {
      if (widget.isPlaying && !oldWidget.isPlaying) {
        _userPaused = false;
        _controller.play();
      } else if (!widget.isPlaying && oldWidget.isPlaying) {
        _controller.pause();
        _controller.seekTo(Duration.zero);
        _userPaused = false; // Reset au changement de page
      }
    }
  }

  void _togglePlayPause() {
    if (!_isInitialized) return;
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _userPaused = true;
      } else {
        _controller.play();
        _userPaused = false;
      }
    });
    widget.onPlayStateChanged(_userPaused);
  }

  void _seekRelative(int seconds) {
    if (!_isInitialized) return;
    final newPos = _position.value + Duration(seconds: seconds);
    Duration target = newPos;
    if (target < Duration.zero) target = Duration.zero;
    if (target > _duration) target = _duration;
    _controller.seekTo(target);
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }

  @override
  void dispose() {
    _controller.removeListener(_listener);
    _controller.dispose();
    _position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Image.network(
        widget.coverUrl, fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(color: kSurface, child: const Center(child: CircularProgressIndicator(color: kRed, strokeWidth: 2)));
        },
        errorBuilder: (context, error, stackTrace) => Container(color: kSurface, child: const Icon(Icons.broken_image_rounded, color: kTextGrey)),
      );
    }

    return GestureDetector(
      onTapDown: (details) => _tapPosition = details.globalPosition,
      onTap: _togglePlayPause,
      onDoubleTap: () {
        if (_tapPosition == null) return;
        final w = MediaQuery.of(context).size.width;
        if (_tapPosition!.dx < w / 2) _seekRelative(-10);
        else _seekRelative(10);
      },
      child: Stack(fit: StackFit.expand, children: [
        SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            alignment: Alignment.center,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          ),
        ),
        
        // Icône centrale Play
        if (_userPaused)
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 64),
            ),
          ),

        // ---------------- LA BARRE VLC QUI DISPARAÎT EN MODE IMMERSIF ----------------
        AnimatedPositioned(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          left: 0, right: 0,
          bottom: widget.isImmersive ? 0 : 80, // Remonte juste au-dessus de la navBar si elle est visible
          child: IgnorePointer(
            ignoring: widget.isImmersive, // Rendu incliquable en plein écran
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: widget.isImmersive ? 0.0 : 1.0, // Disparaît totalement avec les autres barres
              child: GestureDetector(
                onHorizontalDragStart: (details) {
                  _isDragging = true;
                  _controller.pause();
                },
                onHorizontalDragUpdate: (details) {
                  final RenderBox box = context.findRenderObject() as RenderBox;
                  final width = box.size.width;
                  final dx = details.localPosition.dx.clamp(0.0, width);
                  final percent = dx / width;
                  final newPos = Duration(milliseconds: (_duration.inMilliseconds * percent).round());
                  _position.value = newPos;
                },
                onHorizontalDragEnd: (details) {
                  _isDragging = false;
                  _controller.seekTo(_position.value);
                  if (!_userPaused) _controller.play();
                },
                child: ValueListenableBuilder<Duration>(
                  valueListenable: _position,
                  builder: (context, pos, child) {
                    final percent = _duration.inMilliseconds == 0 ? 0.0 : pos.inMilliseconds / _duration.inMilliseconds;
                    return Container(
                      height: 24,
                      color: Colors.transparent,
                      alignment: Alignment.bottomCenter,
                      child: Stack(
                        alignment: Alignment.bottomLeft,
                        clipBehavior: Clip.none,
                        children: [
                          Container(height: _isDragging ? 6 : 2, width: double.infinity, color: Colors.white.withOpacity(0.3)),
                          Container(height: _isDragging ? 6 : 2, width: MediaQuery.of(context).size.width * percent, color: kRed),
                          if (_isDragging)
                            Positioned(
                              top: -30,
                              left: (MediaQuery.of(context).size.width * percent).clamp(0.0, MediaQuery.of(context).size.width - 50),
                              child: Text(_fmt(pos), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
                            ),
                        ],
                      ),
                    );
                  }
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ---------------- MODULE DE COMMENTAIRES SCALABLE ----------------
class _CommentsSheet extends ConsumerStatefulWidget {
  final String mediaId;
  final String mediaTitle;
  const _CommentsSheet({required this.mediaId, required this.mediaTitle});
  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final MediaService _service = MediaService();
  bool _sending = false;
  CommentItem? _replyingTo;
  CommentItem? _editingComment;
  final Set<String> _likedCommentIds = {};
  final Set<String> _expandedParents = {};
  final Set<String> _loadingReplies = {};
  final Map<String, List<CommentItem>> _repliesByParent = {};

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _relativeTime(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 60) return "à l'instant";
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} h';
    if (diff.inDays < 7) return '${diff.inDays} j';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connectez-vous pour commenter'), backgroundColor: kSurface));
      return;
    }

    setState(() => _sending = true);
    try {
      String userName = 'Utilisateur';
      String? avatarUrl;
      try {
        final profile = await client.from('profiles').select('username, avatar_url').eq('id', uid).maybeSingle();
        if (profile != null) {
          userName = (profile['username'] as String?)?.trim().isNotEmpty == true ? profile['username'] as String : userName;
          avatarUrl = profile['avatar_url'] as String?;
        }
      } catch (_) {}

      if (_editingComment != null) {
        ref.invalidate(commentsListProvider(widget.mediaId));
        _controller.clear();
        setState(() => _editingComment = null);
        return;
      }

      await client.from('media_comments').insert({
        'media_id': widget.mediaId,
        'user_id': uid,
        'user_name': userName,
        'avatar_url': avatarUrl,
        'content': text,
      });

      _controller.clear();
      _focusNode.unfocus();
      setState(() => _replyingTo = null);
      ref.invalidate(commentsListProvider(widget.mediaId));
      ref.invalidate(commentCountProvider(widget.mediaId));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Échec de l\'envoi : $e'), backgroundColor: kSurface));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showCommentOptions(CommentItem com, bool isAdmin) {
    final client = Supabase.instance.client;
    final currentUserId = client.auth.currentUser?.id;
    final isAuthor = currentUserId != null && currentUserId == com.userId;

    showModalBottomSheet(
      context: context,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 10),
          if (isAuthor)
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: Colors.white),
              title: const Text('Modifier', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _editingComment = com;
                  _replyingTo = null;
                  _controller.text = com.content;
                });
                _focusNode.requestFocus();
              },
            ),
          if (isAuthor || isAdmin)
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: kRed),
              title: const Text('Supprimer', style: TextStyle(color: kRed)),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await client.from('media_comments').delete().eq('id', com.id);
                  ref.invalidate(commentsListProvider(widget.mediaId));
                  ref.invalidate(commentCountProvider(widget.mediaId));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: kRed));
                }
              },
            ),
          ListTile(
            leading: const Icon(Icons.flag_outlined, color: Colors.orangeAccent),
            title: const Text('Signaler', style: TextStyle(color: Colors.orangeAccent)),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signalé aux modérateurs'), backgroundColor: kSurface));
            },
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(commentsListProvider(widget.mediaId));
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final isAdminAsync = ref.watch(isMediaAdminProvider);
    final isAdmin = isAdminAsync.valueOrNull ?? false;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(color: kSurface, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 14),
              commentsAsync.when(
                loading: () => const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('Commentaires', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
                error: (_, __) => const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('Commentaires', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
                data: (list) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('${list.length} commentaire${list.length > 1 ? 's' : ''}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
              ),
              const Divider(color: kBorderLight, height: 1),
              Expanded(
                child: commentsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: kRed, strokeWidth: 2)),
                  error: (e, st) => Center(child: Text('Erreur de chargement', style: const TextStyle(color: kTextGrey))),
                  data: (comments) {
                    if (comments.isEmpty) return const Center(child: Text('Aucun commentaire pour le moment.\nSoyez le premier à réagir !', textAlign: TextAlign.center, style: TextStyle(color: kTextGrey, fontSize: 13)));
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: comments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final c = comments[index];
                        final isLiked = _likedCommentIds.contains(c.id);
                        return GestureDetector(
                          onLongPress: () => _showCommentOptions(c, isAdmin),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 16, backgroundColor: kSurfaceLight,
                                backgroundImage: c.avatarUrl != null && c.avatarUrl!.isNotEmpty ? NetworkImage(c.avatarUrl!) : null,
                                child: c.avatarUrl == null || c.avatarUrl!.isEmpty ? const Icon(Icons.person_rounded, size: 16, color: kTextGrey) : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(c.userName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                                        const SizedBox(width: 8),
                                        Text(_relativeTime(c.createdAt), style: const TextStyle(color: kTextGrey, fontSize: 11)),
                                        const Spacer(),
                                        IconButton(icon: const Icon(Icons.more_vert_rounded, color: kTextGrey, size: 16), onPressed: () => _showCommentOptions(c, isAdmin), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(c.content, style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.3)),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            setState(() { _replyingTo = c; _editingComment = null; });
                                            _focusNode.requestFocus();
                                          },
                                          child: const Text('Répondre', style: TextStyle(color: kTextGrey, fontSize: 12, fontWeight: FontWeight.w600)),
                                        ),
                                        const SizedBox(width: 24),
                                        GestureDetector(
                                          onTap: () => setState(() => isLiked ? _likedCommentIds.remove(c.id) : _likedCommentIds.add(c.id)),
                                          child: Row(
                                            children: [
                                              Icon(isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 14, color: isLiked ? kRed : kTextGrey),
                                              const SizedBox(width: 4),
                                              Text("J'aime", style: TextStyle(color: isLiked ? kRed : kTextGrey, fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(color: kBorderLight, height: 1),
              if (_replyingTo != null || _editingComment != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: kSurfaceLight.withOpacity(0.6),
                  child: Row(children: [
                    Text(_editingComment != null ? 'Modification du commentaire' : 'Réponse à @${_replyingTo!.userName}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    GestureDetector(onTap: () => setState(() { _replyingTo = null; _editingComment = null; _controller.clear(); }), child: const Icon(Icons.close_rounded, size: 18, color: Colors.white70)),
                  ]),
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
                          minLines: 1, maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _submit(),
                          style: const TextStyle(color: Colors.white, fontSize: 13.5),
                          decoration: InputDecoration(
                            hintText: _editingComment != null ? 'Modifier votre commentaire...' : (_replyingTo != null ? 'Ajouter une réponse...' : 'Ajouter un commentaire...'),
                            hintStyle: const TextStyle(color: kTextGrey, fontSize: 13.5),
                            border: InputBorder.none, isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _submit,
                      child: Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(color: _sending ? kSurfaceLight : kRed, shape: BoxShape.circle),
                        child: _sending ? const Padding(padding: EdgeInsets.all(11), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
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
}
