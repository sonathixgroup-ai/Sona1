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

// ⚠️ Ce fichier suppose que le modèle MediaContent expose :
//    - likeCount (int), commentCount (int), viewCount (int)
//
// ⚠️ Tables Supabase nécessaires :
//    - media_likes(media_id, user_id)      UNIQUE(media_id, user_id)
//    - media_views(media_id, user_id)      UNIQUE(media_id, user_id)
//    - media_comments(id, media_id, user_id, user_name, avatar_url, content, created_at)

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

// ---------------- MODULE COMMENTAIRES (100% réel, connecté DB) ----------------

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

/// Récupère la liste réelle des commentaires d'un média, triée du plus récent au plus ancien.
final commentsListProvider = FutureProvider.autoDispose.family<List<CommentItem>, String>((ref, mediaId) async {
  final res = await Supabase.instance.client
      .from('media_comments')
      .select('id, user_id, user_name, avatar_url, content, created_at')
      .eq('media_id', mediaId)
      .order('created_at', ascending: false)
      .limit(300);
  return (res as List).map((e) => CommentItem.fromMap(e as Map<String, dynamic>)).toList();
});

/// Compte réel des commentaires (utilisé dans la barre de navigation, léger côté réseau).
final commentCountProvider = FutureProvider.autoDispose.family<int, String>((ref, mediaId) async {
  final res = await Supabase.instance.client
      .from('media_comments')
      .select('id')
      .eq('media_id', mediaId)
      .count(CountOption.exact);
  return res.count;
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
  late PageController _feedController; // Contrôleur pour le scroll vertical TikTok
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;
  Timer? _searchDebounce;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // "Accueil" en premier, "Fil" en second (mais sélectionné par défaut)
  final List<String> _filters = ["Accueil", "Fil", "Tendances", "NOVA Originals", "Live", "Courts", "Musique", "Gaming", "Formation"];

  // Gestion de l'état local des "Likes" pour une UI réactive
  final Set<String> _likedMediaIds = {};
  final Set<String> _viewedMediaIds = {};
  final Map<String, int> _likeDelta = {};
  final Map<String, int> _viewDelta = {};

  // Immersion (masquage des barres au tap dans le Fil)
  bool _immersive = false;
  int _currentFeedIndex = 0;
  bool _feedBootstrapped = false;

  // Lecteurs vidéo pour l'autoplay dans le Fil
  final Map<String, VideoPlayerController> _videoControllers = {};

  // Mémoïsation du feed mélangé pour ne pas re-mélanger à chaque rebuild
  List<MediaContent> _lastSourceList = [];
  List<MediaContent> _memoFeedList = [];

  @override
  void initState() {
    super.initState();
    _bannerController = PageController(viewportFraction: 1.0);
    _feedController = PageController();

    // Forcer la sélection sur "Fil" au démarrage (onglet par défaut)
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
    for (final c in _videoControllers.values) {
      c.dispose();
    }
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

  // ---------------- MÉMOÏSATION DU FEED ----------------
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

  // ---------------- LIKES / VUES RÉELS ----------------
  int _realLikeCount(MediaContent item) => item.likeCount + (_likeDelta[item.id] ?? 0);
  int _realViewCount(MediaContent item) => item.viewCount + (_viewDelta[item.id] ?? 0);

  Future<void> _registerView(MediaContent item) async {
    if (_viewedMediaIds.contains(item.id)) return;
    _viewedMediaIds.add(item.id);
    if (mounted) {
      setState(() => _viewDelta[item.id] = (_viewDelta[item.id] ?? 0) + 1);
    }

    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      // La contrainte UNIQUE(media_id, user_id) garantit une vue unique par utilisateur.
      await Supabase.instance.client.from('media_views').upsert(
        {'media_id': item.id, 'user_id': uid},
        onConflict: 'media_id,user_id',
        ignoreDuplicates: true,
      );
    } catch (_) {
      // Échec silencieux : ne bloque jamais la lecture pour un souci de comptage
    }
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
        await Supabase.instance.client
            .from('media_likes')
            .delete()
            .eq('media_id', item.id)
            .eq('user_id', uid);
      } else {
        await Supabase.instance.client.from('media_likes').upsert(
          {'media_id': item.id, 'user_id': uid},
          onConflict: 'media_id,user_id',
          ignoreDuplicates: true,
        );
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CommentsSheet(mediaId: item.id, mediaTitle: item.title),
    ).then((_) {
      // Rafraîchit le compteur affiché dans la barre du bas après fermeture
      ref.invalidate(commentCountProvider(item.id));
    });
  }

  void _showViewsInfo(MediaContent item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_realViewCount(item)} vues uniques'), backgroundColor: kSurface),
    );
  }

  // ---------------- GESTION DES CONTRÔLEURS VIDÉO (AUTOPLAY) ----------------
  Widget _buildFeedVideo(MediaContent item) {
    final controller = _videoControllers[item.id];
    if (controller != null && controller.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      );
    }
    return _buildImage(item.coverUrl);
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
    if (play) {
      controller.play();
    }
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
    if (index + 1 < list.length) {
      _ensureController(list[index + 1], play: false);
    }
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
              // 1. GESTION DU CORPS DE L'APPLICATION (Fil TikTok OU Accueil Classique)
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
                            const SizedBox(height: 100), // Espace pour le header
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

              // 2. HEADER + FILTRES (masqués en mode immersif dans le Fil)
              Positioned(
                top: 0, left: 0, right: 0,
                child: IgnorePointer(
                  ignoring: !showBars,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: showBars ? 1 : 0,
                    child: Column(
                      children: [
                        _header(),
                        _filtersRow(selectedCategory),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. NAVIGATION DU BAS (masquée en mode immersif dans le Fil)
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

  // ---------------- FIL INTELLIGENT (Style TikTok, autoplay) ----------------
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

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _immersive = !_immersive),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Vidéo en lecture automatique (ou couverture pendant le chargement)
              _buildFeedVideo(item),

              // Overlay sombre pour lisibilité
              Container(
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

              // Informations du média (bas gauche)
              Positioned(
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
            ],
          ),
        );
      },
    );
  }

  // ---------------- HEADER COMPACT ET LOGO TDIA (un seul mot) ----------------
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
              // LOGO TDIA — un seul mot, pas de séparation
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [kTdiaBlue, Color(0xFF00E5FF)],
                ).createShader(bounds),
                child: const Text(
                  'TDIA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: -0.5,
                  ),
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

  // ---------------- NAVIGATION DU BAS (fonctions changent en mode "Fil") ----------------
  Widget _bottomNav(String selectedCategory, MediaContent? currentItem) {
    final isFil = selectedCategory == 'Fil';
    final isLiked = currentItem != null && _likedMediaIds.contains(currentItem.id);

    // Compteur réel de commentaires (issu de la table media_comments), rafraîchi après post/fermeture
    int? realCommentCount;
    if (isFil && currentItem != null) {
      realCommentCount = ref.watch(commentCountProvider(currentItem.id)).valueOrNull;
    }

    final List<_NavItemData> items = isFil
        ? [
            _NavItemData(icon: Icons.movie_filter_rounded, label: 'TDIA', selected: true, index: 0),
            _NavItemData(
              icon: isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
              label: currentItem != null ? _formatNumber(_realLikeCount(currentItem)) : "J'aime",
              selected: false,
              index: 1,
              color: isLiked ? kRed : null,
            ),
            _NavItemData(
              icon: Icons.chat_bubble_outline_rounded,
              label: currentItem != null ? _formatNumber(realCommentCount ?? currentItem.commentCount) : 'Commenter',
              selected: false,
              index: 2,
            ),
            _NavItemData(
              icon: Icons.remove_red_eye_rounded,
              label: currentItem != null ? _formatNumber(_realViewCount(currentItem)) : 'Vu',
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
              if (currentItem != null) _showViewsInfo(currentItem);
              break;
          }
        } else {
          if (idx == 3) context.go(AppRoutes.userDashboard);
          // idx == 1 (Recherche) et idx == 2 (Favoris) : à brancher vers vos routes dédiées
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

// ---------------- SHEET DE COMMENTAIRES (production réelle, connectée DB) ----------------

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour commenter'), backgroundColor: kSurface),
      );
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
      } catch (_) {
        // Si la table profiles n'a pas ces colonnes, on garde les valeurs par défaut
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

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(commentsListProvider(widget.mediaId));
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
                data: (list) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('${list.length} commentaire${list.length > 1 ? 's' : ''}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              const Divider(color: kBorderLight, height: 1),
              Expanded(
                child: commentsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: kRed, strokeWidth: 2)),
                  error: (e, st) => Center(child: Text('Erreur de chargement', style: const TextStyle(color: kTextGrey))),
                  data: (comments) {
                    if (comments.isEmpty) {
                      return const Center(
                        child: Text('Aucun commentaire pour le moment.\nSoyez le premier à réagir !', textAlign: TextAlign.center, style: TextStyle(color: kTextGrey, fontSize: 13)),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: comments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final c = comments[index];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: kSurfaceLight,
                              backgroundImage: c.avatarUrl != null && c.avatarUrl!.isNotEmpty ? NetworkImage(c.avatarUrl!) : null,
                              child: c.avatarUrl == null || c.avatarUrl!.isEmpty
                                  ? const Icon(Icons.person_rounded, size: 16, color: kTextGrey)
                                  : null,
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
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(c.content, style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.3)),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(color: kBorderLight, height: 1),
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
                          decoration: const InputDecoration(
                            hintText: 'Ajouter un commentaire...',
                            hintStyle: TextStyle(color: kTextGrey, fontSize: 13.5),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
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
