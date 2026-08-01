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

const Color kBg = Color(0xFF050507);
const Color kSurface = Color(0xFF121214);
const Color kSurfaceLight = Color(0xFF1E1E28);
const Color kRed = Color(0xFFFF1A1A);
const Color kRedDark = Color(0xFFCC0843);
const Color kTextWhite = Color(0xFFFFFFFF);
const Color kTextGrey = Color(0xFF9CA3AF);
const Color kBorderLight = Color(0x14FFFFFF);
const Color kGreen = Color(0xFF3EFF88);
const Color kTdiaBlue = Color(0xFF2D6CDF);

final isMediaAdminProvider = FutureProvider.autoDispose<bool>((ref) async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return false;
  try {
    final res = await Supabase.instance.client
        .from('profiles')
        .select('role')
        .eq('id', uid)
        .maybeSingle();
    return res != null && (res['role'] == 'admin' || res['role'] == 'superadmin');
  } catch (_) {
    return false;
  }
});

// ---------------- MODULE COMMENTAIRES (réel, imbriqué, éditable) ----------------

class CommentItem {
  final String id;
  final String userId;
  final String userName;
  final String? avatarUrl;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? parentId;
  final int likeCount;
  final int replyCount;

  CommentItem({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.avatarUrl,
    this.parentId,
    this.likeCount = 0,
    this.replyCount = 0,
  });

  factory CommentItem.fromMap(Map<String, dynamic> map) {
    return CommentItem(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      userName: (map['user_name'] as String?)?.trim().isNotEmpty == true ? map['user_name'] as String : 'Utilisateur',
      avatarUrl: map['avatar_url'] as String?,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String).toLocal() : null,
      parentId: map['parent_id'] as String?,
      likeCount: (map['like_count'] as num?)?.toInt() ?? 0,
      replyCount: (map['reply_count'] as num?)?.toInt() ?? 0,
    );
  }

  CommentItem copyWith({String? content, int? likeCount, int? replyCount, DateTime? updatedAt}) {
    return CommentItem(
      id: id, userId: userId, userName: userName, avatarUrl: avatarUrl,
      content: content ?? this.content, createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt, parentId: parentId,
      likeCount: likeCount ?? this.likeCount, replyCount: replyCount ?? this.replyCount,
    );
  }
}

/// Charge tous les commentaires d'un média en un seul appel (racines + réponses).
/// Le regroupement en arbre se fait en mémoire côté client via parent_id —
/// adapté au volume typique par vidéo (jusqu'à quelques centaines), sans
/// jamais faire de COUNT(*) ni de scan complet côté serveur.
final commentsListProvider = FutureProvider.autoDispose.family<List<CommentItem>, String>((ref, mediaId) async {
  final res = await Supabase.instance.client
      .from('media_comments')
      .select('id, user_id, user_name, avatar_url, content, created_at, updated_at, parent_id, like_count, reply_count')
      .eq('media_id', mediaId)
      .order('created_at', ascending: false)
      .limit(500);
  return (res as List).map((e) => CommentItem.fromMap(e as Map<String, dynamic>)).toList();
});

/// Compte réel de commentaires — lu depuis la colonne dénormalisée
/// media_content.comment_count, jamais recalculé par COUNT(*).
final commentCountProvider = FutureProvider.autoDispose.family<int, String>((ref, mediaId) async {
  final res = await Supabase.instance.client.from('media_content').select('comment_count').eq('id', mediaId).maybeSingle();
  return (res?['comment_count'] as num?)?.toInt() ?? 0;
});

/// Compteurs live (vues/likes/commentaires) via Realtime Postgres Changes.
/// N'est ouvert QUE pour la vidéo actuellement visible dans le fil —
/// c'est ce qui garde ça scalable à des millions d'utilisateurs simultanés :
/// chacun n'écoute qu'une seule ligne à la fois.
class MediaCounts {
  final int likeCount;
  final int viewCount;
  final int commentCount;
  const MediaCounts({required this.likeCount, required this.viewCount, required this.commentCount});
}

final mediaCountsStreamProvider = StreamProvider.autoDispose.family<MediaCounts, String>((ref, mediaId) {
  return Supabase.instance.client
      .from('media_content')
      .stream(primaryKey: ['id'])
      .eq('id', mediaId)
      .map((rows) {
    if (rows.isEmpty) return const MediaCounts(likeCount: 0, viewCount: 0, commentCount: 0);
    final row = rows.first;
    return MediaCounts(
      likeCount: (row['like_count'] as num?)?.toInt() ?? 0,
      viewCount: (row['view_count'] as num?)?.toInt() ?? 0,
      commentCount: (row['comment_count'] as num?)?.toInt() ?? 0,
    );
  });
});

class _NavItemData {
  final IconData icon;
  final String label;
  final bool selected;
  final int index;
  final Color? color;
  _NavItemData({
    required this.icon,
    required this.label,
    required this.selected,
    required this.index,
    this.color,
  });
}

class ThixMediaPage extends ConsumerStatefulWidget {
  const ThixMediaPage({super.key});
  @override
  ConsumerState<ThixMediaPage> createState() => _ThixMediaPageState();
}

class _ThixMediaPageState extends ConsumerState<ThixMediaPage> {
  late PageController _bannerController;
  late PageController _feedController;
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;
  Timer? _searchDebounce;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final List<String> _filters = ["Accueil", "Fil", "Tendances", "NOVA Originals", "Live", "Courts", "Musique", "Gaming", "Formation"];

  final Set<String> _likedMediaIds = {};
  final Set<String> _viewedMediaIds = {};

  bool _immersive = false;
  int _currentFeedIndex = 0;
  bool _feedBootstrapped = false;

  List<MediaContent> _lastSourceList = [];
  List<MediaContent> _memoFeedList = [];

  // Garde-fou anti-empilement de bottom sheets
  bool _commentsSheetOpen = false;

  @override
  void initState() {
    super.initState();
    _bannerController = PageController(viewportFraction: 1.0);
    _feedController = PageController();

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
    super.dispose();
  }

  void _startAutoScroll(int count) {
    _bannerTimer?.cancel();
    if (count == 0) return;
    _bannerTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted || !_bannerController.hasClients) return;
      final next = (_currentBannerIndex + 1) % count;
      _bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 800),
        curve: Curves.fastOutSlowIn,
      );
    });
  }

  void _onSearchChanged(String v) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchQueryProvider.notifier).state = v;
    });
  }

  void _navigateToVideo(MediaContent item) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerPage(title: item.title, videoUrl: item.videoUrl)));
  }

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

  // ---------------- VUES RÉELLES (RPC atomique, un enregistrement par utilisateur) ----------------
  Future<void> _registerView(MediaContent item) async {
    if (_viewedMediaIds.contains(item.id)) return;
    _viewedMediaIds.add(item.id);
    try {
      await Supabase.instance.client.rpc('register_media_view', params: {'p_media_id': item.id});
      // Le compteur affiché se met à jour tout seul via mediaCountsStreamProvider (Realtime).
    } catch (_) {
      // Échec silencieux : ne bloque jamais la lecture pour un souci de comptage
    }
  }

  // ---------------- LIKES (RPC atomique) ----------------
  Future<void> _toggleLike(MediaContent item) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez vous connecter pour aimer ce contenu.'), backgroundColor: kSurface));
      return;
    }
    final wasLiked = _likedMediaIds.contains(item.id);
    setState(() {
      if (wasLiked) {
        _likedMediaIds.remove(item.id);
      } else {
        _likedMediaIds.add(item.id);
      }
    });
    try {
      await Supabase.instance.client.rpc('toggle_media_like', params: {'p_media_id': item.id});
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (wasLiked) {
          _likedMediaIds.add(item.id);
        } else {
          _likedMediaIds.remove(item.id);
        }
      });
    }
  }

  void _openComments(MediaContent item) {
    if (_commentsSheetOpen) return;
    _commentsSheetOpen = true;
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CommentsSheet(mediaId: item.id, mediaTitle: item.title),
    ).then((_) {
      ref.invalidate(commentCountProvider(item.id));
    }).whenComplete(() {
      _commentsSheetOpen = false;
    });
  }

  void _handlePageChanged(int index, List<MediaContent> list) {
    if (index < 0 || index >= list.length) return;
    _registerView(list[index]);
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
          final currentItem = feedList.isNotEmpty
              ? feedList[_currentFeedIndex.clamp(0, feedList.length - 1)]
              : null;

          if (selectedCategory == 'Fil' && feedList.isNotEmpty && !_feedBootstrapped) {
            _feedBootstrapped = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _handlePageChanged(0, feedList);
            });
          }

          final showBars = !(_immersive && selectedCategory == 'Fil');

          return Stack(
            children: [
              if (selectedCategory == 'Fil')
                _buildTikTokFeed(feedList)
              else
                RefreshIndicator(
                  color: kRed,
                  backgroundColor: kSurface,
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
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.transparent, kBg.withOpacity(0.6), kBg],
                                    stops: const [0.0, 0.1, 0.3],
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 20),
                                    _buildRow(
                                      title: 'Continuer à regarder',
                                      subtitle: 'Reprise intelligente',
                                      provider: recommendationsProvider,
                                      aspectRatio: 16 / 9,
                                      height: 180,
                                      width: 320,
                                      itemBuilder: (item, [index]) => _continueWatchingCard(item),
                                    ),
                                    const SizedBox(height: 40),
                                    _buildRow(
                                      title: 'TDIA Originals Exclusifs',
                                      subtitle: 'Produit par TDIA Studios',
                                      provider: newReleasesProvider,
                                      aspectRatio: 2 / 3,
                                      height: 240,
                                      width: 160,
                                      itemBuilder: (item, [index]) => _originalCard(item),
                                    ),
                                    const SizedBox(height: 40),
                                    _buildRow(
                                      title: 'Top 10 cette semaine',
                                      subtitle: 'Classement',
                                      provider: trendingProvider,
                                      aspectRatio: 16 / 9,
                                      height: 160,
                                      width: 300,
                                      itemBuilder: (item, [index]) => _top10Card(item, index ?? 0),
                                    ),
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
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: showBars ? 1 : 0,
                    child: Column(children: [_header(), _filtersRow(selectedCategory)]),
                  ),
                ),
              ),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: IgnorePointer(
                  ignoring: !showBars,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: showBars ? 1 : 0,
                    child: _bottomNav(selectedCategory, currentItem),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------- FIL TIKTOK (autoplay + progress bar façon VLC) ----------------
  Widget _buildTikTokFeed(List<MediaContent> mediaList) {
    if (mediaList.isEmpty) {
      return const Center(child: Text("Aucun contenu disponible", style: TextStyle(color: Colors.white)));
    }

    return PageView.builder(
      controller: _feedController,
      scrollDirection: Axis.vertical,
      itemCount: mediaList.length,
      onPageChanged: (index) {
        setState(() => _currentFeedIndex = index);
        _handlePageChanged(index, mediaList);
      },
      itemBuilder: (context, index) {
        final item = mediaList[index];
        final isFocused = _currentFeedIndex == index;

        return Stack(
          fit: StackFit.expand,
          children: [
            FeedVideoPlayer(
              videoUrl: item.videoUrl,
              coverUrl: item.coverUrl,
              isPlaying: isFocused,
              onLongPress: () => setState(() => _immersive = !_immersive),
            ),
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.85),
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.4),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: Positioned(
                left: 20,
                bottom: 40,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: kTdiaBlue.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: kTdiaBlue.withOpacity(0.5))),
                      child: Text(item.type, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 10),
                    Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1.1)),
                    const SizedBox(height: 8),
                    if (item.subtitle != null)
                      Text(
                        item.subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
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
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            border: const Border(bottom: BorderSide(color: kBorderLight)),
          ),
          child: Row(
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [kTdiaBlue, Color(0xFF00E5FF)],
                ).createShader(bounds),
                child: const Text(
                  'TDIA',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5),
                ),
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
                          decoration: const InputDecoration(
                            hintText: "Rechercher...",
                            hintStyle: TextStyle(color: Colors.white30, fontSize: 13),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (isAdmin) ...[
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ThixMediaAdminPage()));
                  },
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kRed.withOpacity(0.15),
                      border: Border.all(color: kRed.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded, color: kRed, size: 16),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Container(
                width: 32, height: 32,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white10),
                child: const Icon(Icons.notifications_none_rounded, color: Colors.white70, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filtersRow(String selectedCategory) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: kBg.withOpacity(0.85),
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _filters.map((filter) {
                final isSelected = selectedCategory == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      ref.read(selectedCategoryProvider.notifier).state = filter;
                      if (filter != 'Fil') {
                        setState(() => _immersive = false);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? Colors.white : kBorderLight),
                        boxShadow: isSelected ? [BoxShadow(color: Colors.white.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 2))] : [],
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white60,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _heroBanner(List<MediaContent> bannerItems) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.82,
      child: PageView.builder(
        controller: _bannerController,
        onPageChanged: (i) => setState(() => _currentBannerIndex = i),
        itemCount: bannerItems.length,
        itemBuilder: (context, idx) {
          final item = bannerItems[idx];
          final hasSubtitle = item.subtitle != null && item.subtitle!.isNotEmpty;
          final hasYear = item.year != null;

          return Stack(
            fit: StackFit.expand,
            children: [
              _buildImage(item.coverUrl),
              Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [kBg, kBg.withOpacity(0.7), kBg.withOpacity(0.1), Colors.transparent]))),
              Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [kBg, kBg.withOpacity(0.6), Colors.transparent]))),
              Positioned(
                bottom: 80, left: 24, right: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, height: 0.9, letterSpacing: -2)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (hasYear) ...[
                          Text("${item.year}", style: const TextStyle(color: Colors.white54, fontSize: 13)),
                          const SizedBox(width: 10),
                        ],
                        Text(item.type, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                      ],
                    ),
                    if (hasSubtitle) ...[
                      const SizedBox(height: 16),
                      Text(item.subtitle!, style: const TextStyle(color: Colors.white70, fontSize: 14.5, height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
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
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRow({required String title, required String subtitle, required ProviderListenable<List<MediaContent>> provider, required double aspectRatio, required double height, required double width, required Widget Function(MediaContent item, [int? index]) itemBuilder}) {
    final list = ref.watch(provider);
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: height,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount: list.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: SizedBox(width: width, child: itemBuilder(list[index], index)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _continueWatchingCard(MediaContent item) {
    return GestureDetector(
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
                  Container(decoration: BoxDecoration(color: Colors.black.withOpacity(0.3))),
                  const Center(child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 44)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _originalCard(MediaContent item) {
    return GestureDetector(
      onTap: () => _navigateToVideo(item),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
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
  }

  Widget _top10Card(MediaContent item, int index) {
    return GestureDetector(
      onTap: () => _navigateToVideo(item),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: -20, bottom: -10, child: Text((index + 1).toString().padLeft(2, '0'), style: TextStyle(fontSize: 100, fontWeight: FontWeight.w900, color: Colors.transparent, shadows: [Shadow(color: Colors.white.withOpacity(0.2), blurRadius: 2, offset: const Offset(0, 0))]))),
          Positioned(
            left: 40, top: 0, bottom: 0, right: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImage(item.coverUrl),
                  Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.8), Colors.transparent]))),
                  Positioned(bottom: 8, left: 8, right: 8, child: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- NAVIGATION DU BAS (compteurs live via Realtime) ----------------
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
              label: currentItem != null ? _formatNumber(liveCounts?.likeCount ?? currentItem.likeCount) : "J'aime",
              selected: false,
              index: 1,
              color: isLiked ? kRed : null,
            ),
            _NavItemData(
              icon: Icons.chat_bubble_outline_rounded,
              label: currentItem != null ? _formatNumber(liveCounts?.commentCount ?? currentItem.commentCount) : 'Commenter',
              selected: false,
              index: 2,
            ),
            _NavItemData(
              // Nombre réel d'utilisateurs uniques ayant vu la vidéo — live, jamais figé.
              icon: Icons.remove_red_eye_rounded,
              label: currentItem != null ? _formatNumber(liveCounts?.viewCount ?? currentItem.viewCount) : 'Vu',
              selected: false,
              index: 3,
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
            decoration: BoxDecoration(
              color: const Color(0xFF12121A).withOpacity(0.85),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: items
                  .map((data) => _navItem(
                        data.icon,
                        data.label,
                        data.selected,
                        data.index,
                        isFil: isFil,
                        currentItem: currentItem,
                        color: data.color,
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label,
    bool selected,
    int idx, {
    required bool isFil,
    MediaContent? currentItem,
    Color? color,
  }) {
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
              break;
          }
        } else {
          if (idx == 3) context.go(AppRoutes.userDashboard);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color ?? (selected ? Colors.white : Colors.white38), size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              color: color ?? (selected ? Colors.white : Colors.white38),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- LECTEUR VIDÉO : autoplay + barre de progression façon VLC ----------------
// Tap = pause/lecture. Drag sur la barre = avance/recul en direct. Appui long = immersion.

class FeedVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String coverUrl;
  final bool isPlaying;
  final VoidCallback? onLongPress;

  const FeedVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.coverUrl,
    required this.isPlaying,
    this.onLongPress,
  });

  @override
  State<FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<FeedVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _showControls = false;
  bool _userPaused = false;
  bool _isSeeking = false;
  Timer? _hideTimer;
  final ValueNotifier<Duration> _position = ValueNotifier(Duration.zero);
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      _controller!.addListener(_listener);
      await _controller!.initialize();
      _controller!.setLooping(true);
      _controller!.setVolume(1.0);
      if (!mounted) return;
      setState(() {
        _isInitialized = true;
        _duration = _controller!.value.duration;
      });
      if (widget.isPlaying) _controller!.play();
    } catch (_) {
      // Reste sur la couverture en cas d'échec de chargement
    }
  }

  void _listener() {
    if (!mounted || _controller == null || _isSeeking) return;
    if (!_controller!.value.isInitialized) return;
    _position.value = _controller!.value.position;
  }

  @override
  void didUpdateWidget(covariant FeedVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isInitialized || _controller == null) return;
    try {
      if (widget.isPlaying && !oldWidget.isPlaying) {
        _userPaused = false;
        _controller!.play();
      } else if (!widget.isPlaying && oldWidget.isPlaying) {
        _controller!.pause();
        _controller!.seekTo(Duration.zero);
      }
    } catch (_) {}
  }

  void _togglePlayPause() {
    if (!_isInitialized || _controller == null) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _userPaused = true;
      } else {
        _controller!.play();
        _userPaused = false;
      }
      _showControls = true;
    });
    _scheduleHide();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 2500).inMilliseconds > 0 ? const Duration(seconds: 3) : const Duration(seconds: 3), () {
      if (mounted && !_userPaused) setState(() => _showControls = false);
    });
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller?.removeListener(_listener);
    _controller?.dispose();
    _position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return Image.network(
        widget.coverUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(color: kSurface, child: const Center(child: CircularProgressIndicator(color: kRed, strokeWidth: 2)));
        },
        errorBuilder: (context, error, stackTrace) => Container(color: kSurface, child: const Icon(Icons.broken_image_rounded, color: kTextGrey)),
      );
    }

    final videoSize = _controller!.value.size;
    if (videoSize.width <= 0 || videoSize.height <= 0) {
      return Image.network(widget.coverUrl, fit: BoxFit.cover);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _togglePlayPause,
      onLongPress: widget.onLongPress,
      child: Stack(fit: StackFit.expand, children: [
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(width: videoSize.width, height: videoSize.height, child: VideoPlayer(_controller!)),
        ),
        if (_userPaused) const Center(child: Icon(Icons.play_arrow_rounded, color: Colors.white70, size: 64)),

        // ---- Barre de progression façon VLC : tap pour révéler, drag pour naviguer ----
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _showControls || _userPaused ? 1 : 0,
          child: Positioned(
            left: 14, right: 14, bottom: 128,
            child: IgnorePointer(
              ignoring: !(_showControls || _userPaused),
              child: Row(
                children: [
                  ValueListenableBuilder<Duration>(
                    valueListenable: _position,
                    builder: (_, pos, __) => Text(_fmt(pos), style: const TextStyle(color: Colors.white70, fontSize: 10)),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ValueListenableBuilder<Duration>(
                      valueListenable: _position,
                      builder: (_, pos, __) {
                        final total = _duration.inMilliseconds == 0 ? 1 : _duration.inMilliseconds;
                        final progress = (pos.inMilliseconds / total).clamp(0.0, 1.0);
                        return SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 2.5,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                            activeTrackColor: kRed,
                            inactiveTrackColor: Colors.white30,
                            thumbColor: kRed,
                          ),
                          child: Slider(
                            value: progress,
                            onChangeStart: (_) {
                              _hideTimer?.cancel();
                              setState(() {
                                _isSeeking = true;
                                _showControls = true;
                              });
                            },
                            onChanged: (v) {
                              // Retour visuel immédiat sans attendre le contrôleur (fluide, façon VLC)
                              final newPos = Duration(milliseconds: (v * total).round());
                              _position.value = newPos;
                            },
                            onChangeEnd: (v) async {
                              final newPos = Duration(milliseconds: (v * total).round());
                              await _controller!.seekTo(newPos);
                              _isSeeking = false;
                              if (!_userPaused) _scheduleHide();
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(_fmt(_duration), style: const TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ----------------------------------------------------------------------
// SHEET DE COMMENTAIRES — édition, like, suppression, réponses imbriquées
// sur un seul niveau (repliées par défaut) pour ne jamais gaspiller l'espace
// ----------------------------------------------------------------------

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
  bool _sending = false;
  bool _optionsSheetOpen = false;

  CommentItem? _replyingTo;
  CommentItem? _editingComment;
  final Set<String> _likedCommentIds = {};
  final Set<String> _expandedParents = {};

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

  Future<void> _toggleCommentLike(String commentId) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    final wasLiked = _likedCommentIds.contains(commentId);
    setState(() {
      if (wasLiked) _likedCommentIds.remove(commentId);
      else _likedCommentIds.add(commentId);
    });
    try {
      await Supabase.instance.client.rpc('toggle_comment_like', params: {'p_comment_id': commentId});
    } catch (_) {
      if (mounted) {
        setState(() {
          if (wasLiked) _likedCommentIds.add(commentId);
          else _likedCommentIds.remove(commentId);
        });
      }
    }
  }

  void _showCommentOptions(CommentItem com, bool isAdmin) {
    if (_optionsSheetOpen) return;
    _optionsSheetOpen = true;

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isAuthor = currentUserId != null && currentUserId == com.userId;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black45,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 10),
          if (isAuthor)
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: Colors.white),
              title: const Text('Modifier', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(sheetContext).pop();
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
              onTap: () {
                Navigator.of(sheetContext).pop();
                _deleteComment(com);
              },
            ),
          ListTile(
            leading: const Icon(Icons.flag_outlined, color: Colors.orangeAccent),
            title: const Text('Signaler', style: TextStyle(color: Colors.orangeAccent)),
            onTap: () async {
              Navigator.of(sheetContext).pop();
              final uid = Supabase.instance.client.auth.currentUser?.id;
              if (uid != null) {
                try {
                  await Supabase.instance.client.from('comment_reports').insert({'comment_id': com.id, 'reporter_id': uid});
                } catch (_) {}
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signalé aux modérateurs'), backgroundColor: kSurface));
              }
            },
          ),
        ]),
      ),
    ).whenComplete(() {
      _optionsSheetOpen = false;
    });
  }

  Future<void> _deleteComment(CommentItem com) async {
    try {
      await Supabase.instance.client.from('media_comments').delete().eq('id', com.id);
      ref.invalidate(commentsListProvider(widget.mediaId));
      ref.invalidate(commentCountProvider(widget.mediaId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Commentaire supprimé'), backgroundColor: kSurface));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: kRed));
    }
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour commenter'), backgroundColor: kSurface),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      // ---- MODIFICATION D'UN COMMENTAIRE EXISTANT ----
      if (_editingComment != null) {
        await client.from('media_comments').update({
          'content': text,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', _editingComment!.id);
        _controller.clear();
        setState(() => _editingComment = null);
        ref.invalidate(commentsListProvider(widget.mediaId));
        return;
      }

      // ---- NOUVEAU COMMENTAIRE OU RÉPONSE ----
      String userName = 'Utilisateur';
      String? avatarUrl;
      try {
        final profile = await client.from('profiles').select('username, avatar_url').eq('id', uid).maybeSingle();
        if (profile != null) {
          userName = (profile['username'] as String?)?.trim().isNotEmpty == true ? profile['username'] as String : userName;
          avatarUrl = profile['avatar_url'] as String?;
        }
      } catch (_) {}

      // Une réponse est toujours rattachée à la racine, pour garder un seul
      // niveau d'imbrication (comme Instagram) — évite l'indentation infinie
      // qui gaspille l'espace horizontal.
      final replyParentId = _replyingTo?.parentId ?? _replyingTo?.id;

      final payload = {
        'media_id': widget.mediaId,
        'user_id': uid,
        'user_name': userName,
        'avatar_url': avatarUrl,
        'content': text,
        if (replyParentId != null) 'parent_id': replyParentId,
      };

      await client.from('media_comments').insert(payload);

      if (replyParentId != null) _expandedParents.add(replyParentId);

      _controller.clear();
      _focusNode.unfocus();
      setState(() => _replyingTo = null);
      ref.invalidate(commentsListProvider(widget.mediaId));
      ref.invalidate(commentCountProvider(widget.mediaId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de l\'envoi : $e'), backgroundColor: kSurface),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ---- Construit un commentaire + ses réponses repliées par défaut,
  // affichées à un seul niveau d'indentation pour économiser l'espace ----
  Widget _buildCommentTile(CommentItem com, List<CommentItem> allComments, bool isAdmin, {bool isChild = false}) {
    final isLiked = _likedCommentIds.contains(com.id);
    final isExpanded = _expandedParents.contains(com.id);
    final replies = allComments.where((c) => c.parentId == com.id).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final wasEdited = com.updatedAt != null;

    return Padding(
      padding: EdgeInsets.only(left: isChild ? 34.0 : 0.0, top: isChild ? 10.0 : 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: () => _showCommentOptions(com, isAdmin),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: isChild ? 12 : 16,
                  backgroundColor: kSurfaceLight,
                  backgroundImage: com.avatarUrl != null && com.avatarUrl!.isNotEmpty ? NetworkImage(com.avatarUrl!) : null,
                  child: com.avatarUrl == null || com.avatarUrl!.isEmpty
                      ? Icon(Icons.person_rounded, size: isChild ? 12 : 16, color: kTextGrey)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(com.userName, style: TextStyle(color: Colors.white, fontSize: isChild ? 12 : 13, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 8),
                          Text(_relativeTime(com.createdAt), style: const TextStyle(color: kTextGrey, fontSize: 11)),
                          if (wasEdited) ...[
                            const SizedBox(width: 6),
                            const Text('(modifié)', style: TextStyle(color: kTextGrey, fontSize: 10, fontStyle: FontStyle.italic)),
                          ],
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.more_vert_rounded, color: kTextGrey, size: 16),
                            onPressed: () => _showCommentOptions(com, isAdmin),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(com.content, style: TextStyle(color: Colors.white70, fontSize: isChild ? 12.5 : 13.5, height: 1.3)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _replyingTo = com;
                                _editingComment = null;
                              });
                              _focusNode.requestFocus();
                            },
                            child: const Text('Répondre', style: TextStyle(color: kTextGrey, fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 20),
                          GestureDetector(
                            onTap: () => _toggleCommentLike(com.id),
                            child: Row(
                              children: [
                                Icon(isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 14, color: isLiked ? kRed : kTextGrey),
                                const SizedBox(width: 4),
                                Text(com.likeCount > 0 ? '${com.likeCount}' : "J'aime", style: TextStyle(color: isLiked ? kRed : kTextGrey, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // "Voir X réponses" — replié par défaut, ne prend aucune
                      // place tant que l'utilisateur ne l'ouvre pas.
                      if (!isChild && com.replyCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: GestureDetector(
                            onTap: () => setState(() {
                              if (isExpanded) _expandedParents.remove(com.id);
                              else _expandedParents.add(com.id);
                            }),
                            child: Row(children: [
                              Container(width: 24, height: 1, color: kBorderLight),
                              const SizedBox(width: 8),
                              Text(
                                isExpanded ? 'Masquer les réponses' : 'Voir ${com.replyCount} réponse${com.replyCount > 1 ? 's' : ''}',
                                style: const TextStyle(color: kTdiaBlue, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ]),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Réponses affichées à un seul niveau — jamais d'indentation en cascade
          if (!isChild && isExpanded)
            Column(children: replies.map((r) => _buildCommentTile(r, allComments, isAdmin, isChild: true)).toList()),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(commentsListProvider(widget.mediaId));
    final isAdminAsync = ref.watch(isMediaAdminProvider);
    final isAdmin = isAdminAsync.valueOrNull ?? false;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 14),
              commentsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('Commentaires', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                error: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('Commentaires', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                data: (list) {
                  final rootCount = list.where((c) => c.parentId == null).length;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('$rootCount commentaire${rootCount > 1 ? 's' : ''}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  );
                },
              ),
              const Divider(color: kBorderLight, height: 1),
              Expanded(
                child: commentsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: kRed, strokeWidth: 2)),
                  error: (e, st) => const Center(child: Text('Erreur de chargement', style: TextStyle(color: kTextGrey))),
                  data: (comments) {
                    final rootComments = comments.where((c) => c.parentId == null).toList()
                      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                    if (rootComments.isEmpty) {
                      return const Center(
                        child: Text('Aucun commentaire pour le moment.\nSoyez le premier à réagir !', textAlign: TextAlign.center, style: TextStyle(color: kTextGrey, fontSize: 13)),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: rootComments.length,
                      itemBuilder: (context, index) => _buildCommentTile(rootComments[index], comments, isAdmin),
                    );
                  },
                ),
              ),
              const Divider(color: kBorderLight, height: 1),
              if (_replyingTo != null || _editingComment != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: kSurfaceLight.withOpacity(0.6),
                  child: Row(
                    children: [
                      Text(
                        _editingComment != null ? 'Modification du commentaire' : 'Réponse à @${_replyingTo!.userName}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() {
                          _replyingTo = null;
                          _editingComment = null;
                          _controller.clear();
                        }),
                        child: const Icon(Icons.close_rounded, size: 18, color: Colors.white70),
                      ),
                    ],
                  ),
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
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _submit(),
                          style: const TextStyle(color: Colors.white, fontSize: 13.5),
                          decoration: InputDecoration(
                            hintText: _editingComment != null
                                ? 'Modifier votre commentaire...'
                                : (_replyingTo != null ? 'Ajouter une réponse...' : 'Ajouter un commentaire...'),
                            hintStyle: const TextStyle(color: kTextGrey, fontSize: 13.5),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _submit,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _sending ? kSurfaceLight : kRed,
                          shape: BoxShape.circle,
                        ),
                        child: _sending
                            ? const Padding(
                                padding: EdgeInsets.all(11),
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
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
