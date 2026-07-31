import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:go_router/go_router.dart';
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

/// Flux live du compteur (likes/vues/commentaires) — n'est ouvert que pour
/// la vidéo actuellement visible du Fil (voir _handlePageChanged), jamais
/// pour tout le feed. C'est ce qui garde ça scalable à des millions d'utilisateurs.
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

  bool _immersive = false;
  int _currentFeedIndex = 0;
  final MediaService _mediaService = MediaService();

  // ---- ÉTAT DU FIL MÉLANGÉ (indépendant de la date, scalable) ----
  final List<MediaContent> _filItems = [];
  double _filCursor = 0;
  bool _filLoading = false;
  bool _filInitialized = false;

  // ---- PULL-TO-REFRESH MANUEL DANS LE FIL (re-mix à chaque tirage) ----
  double _pullDistance = 0;
  bool _pullTriggering = false;
  static const double _pullThreshold = 90;

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
    _bannerController.dispose();
    _feedController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------- FIL MÉLANGÉ : init / pagination / refresh ----------------

  Future<void> _initFilFeed({bool reshuffle = false}) async {
    if (_filLoading) return;
    setState(() => _filLoading = true);
    
    try {
      // Si l'utilisateur tire vers le bas pour rafraîchir, on vide son historique de session
      if (reshuffle) _viewedMediaIds.clear();
      
      // On utilise seenIds au lieu de cursor
      final page = await _mediaService.fetchShuffledFeed(seenIds: _viewedMediaIds.toList(), limit: 12);
      
      if (!mounted) return;
      setState(() {
        _filItems.clear();
        _filItems.addAll(page.items);
        _filInitialized = true;
        _currentFeedIndex = 0;
      });
      
      await _syncLikedMedias(_filItems);
      if (_filItems.isNotEmpty) _registerView(_filItems.first);
      
      if (reshuffle && _feedController.hasClients) {
        _feedController.jumpToPage(0);
      }
    } catch (e) {
      if (!mounted) return;
      // Empêche le chargement infini en cas d'erreur
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur serveur: $e'), backgroundColor: kRed));
      setState(() => _filInitialized = true); 
    } finally {
      if (mounted) setState(() => _filLoading = false);
    }
  }

  Future<void> _loadMoreFil() async {
    if (_filLoading) return;
    setState(() => _filLoading = true);
    
    try {
      // Pareil ici, on utilise seenIds pour charger la suite sans doublons
      final page = await _mediaService.fetchShuffledFeed(seenIds: _viewedMediaIds.toList(), limit: 12);
      if (!mounted) return;
      
      setState(() {
        _filItems.addAll(page.items);
      });
      await _syncLikedMedias(page.items);
    } catch (e) {
      debugPrint('Erreur lors du chargement de la suite : $e');
    } finally {
      if (mounted) setState(() => _filLoading = false);
    }
  }

  Future<void> _syncLikedMedias(List<MediaContent> items) async {
    if (items.isEmpty) return;
    final ids = items.map((e) => e.id).toList();
    final liked = await _mediaService.getLikedMediaIds(ids);
    if (mounted && liked.isNotEmpty) {
      setState(() => _likedMediaIds.addAll(liked));
    }
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

  void _navigateToVideo(MediaContent item) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerPage(title: item.title, videoUrl: item.videoUrl)));

  String _formatNumber(int num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}k';
    return num.toString();
  }

  Widget _buildImage(String url, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    if (url.isEmpty) return Container(color: kSurface, child: const Icon(Icons.broken_image_rounded, color: kTextGrey));
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: kIsWeb ? null : (width != null ? (width * 2).toInt() : 600),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(color: kSurface, child: const Center(child: CircularProgressIndicator(color: kRed, strokeWidth: 2)));
      },
      errorBuilder: (context, error, stackTrace) => Container(color: kSurface, child: const Icon(Icons.broken_image_rounded, color: kTextGrey)),
    );
  }

  void _registerView(MediaContent item) {
    if (_viewedMediaIds.contains(item.id)) return;
    _viewedMediaIds.add(item.id);
    _mediaService.registerView(item.id); // le compteur live se met à jour via Realtime, pas besoin de delta local
  }

  Future<void> _toggleLike(MediaContent item) async {
    if (Supabase.instance.client.auth.currentUser == null) {
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
      await _mediaService.toggleLike(item.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur serveur : $e'), backgroundColor: kRed));
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CommentsSheet(mediaId: item.id, mediaTitle: item.title),
    );
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

          return Stack(children: [
            if (selectedCategory == 'Fil')
              _buildTikTokFeed()
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
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const SizedBox(height: 100),
                        if (bannerItems.isNotEmpty) _heroBanner(bannerItems),
                        Transform.translate(
                          offset: const Offset(0, -40),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, kBg.withOpacity(0.6), kBg], stops: const [0.0, 0.1, 0.3]),
                            ),
                            child: Column(children: [
                              const SizedBox(height: 20),
                              _buildRow(title: 'Continuer à regarder', subtitle: 'Reprise intelligente', provider: recommendationsProvider, aspectRatio: 16 / 9, height: 180, width: 320, itemBuilder: (item, [index]) => _continueWatchingCard(item)),
                              const SizedBox(height: 40),
                              _buildRow(title: 'TDIA Originals Exclusifs', subtitle: 'Produit par TDIA Studios', provider: newReleasesProvider, aspectRatio: 2 / 3, height: 240, width: 160, itemBuilder: (item, [index]) => _originalCard(item)),
                              const SizedBox(height: 40),
                              _buildRow(title: 'Top 10 cette semaine', subtitle: 'Classement', provider: trendingProvider, aspectRatio: 16 / 9, height: 160, width: 300, itemBuilder: (item, [index]) => _top10Card(item, index ?? 0)),
                              const SizedBox(height: 120),
                            ]),
                          ),
                        ),
                      ]),
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
          ]);
        },
      ),
    );
  }

  // ---------------- FIL TIKTOK : mix scalable + pull-to-refresh manuel + autoplay ----------------
  Widget _buildTikTokFeed() {
    if (!_filInitialized) {
      return const Center(child: CircularProgressIndicator(color: kRed));
    }
    if (_filItems.isEmpty) {
      return const Center(child: Text("Aucun contenu disponible", style: TextStyle(color: Colors.white)));
    }

    return GestureDetector(
      // Pull-to-refresh manuel : uniquement actif quand on est sur la 1ère vidéo,
      // pour ne pas interférer avec le scroll vertical normal du fil.
      onVerticalDragUpdate: (details) {
        if (_currentFeedIndex == 0 && details.delta.dy > 0 && !_filLoading) {
          setState(() => _pullDistance = (_pullDistance + details.delta.dy).clamp(0, _pullThreshold * 1.6));
        }
      },
      onVerticalDragEnd: (details) async {
        if (_pullDistance >= _pullThreshold && !_pullTriggering) {
          _pullTriggering = true;
          await _initFilFeed(reshuffle: true); // nouveau mélange à chaque refresh manuel
          _pullTriggering = false;
        }
        setState(() => _pullDistance = 0);
      },
      child: Stack(children: [
        PageView.builder(
          controller: _feedController,
          scrollDirection: Axis.vertical,
          itemCount: _filItems.length,
          onPageChanged: (index) {
            setState(() => _currentFeedIndex = index);
            _handlePageChanged(index);
          },
          itemBuilder: (context, index) {
            final item = _filItems[index];
            final isFocused = _currentFeedIndex == index;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _immersive = !_immersive),
              child: Stack(fit: StackFit.expand, children: [
                FeedVideoPlayer(videoUrl: item.videoUrl, coverUrl: item.coverUrl, isPlaying: isFocused),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter, 
                      end: Alignment.topCenter, 
                      colors: [
                        Colors.black.withOpacity(0.8), // Sombre en bas pour lire le texte
                        Colors.transparent,            // 100% transparent au milieu (PLUS DE FLOU !)
                        Colors.black.withOpacity(0.1)  // Légèrement sombre en haut pour la barre de menu
                      ], 
                      stops: const [0.0, 0.25, 1.0]    // Le centre clair commence beaucoup plus bas
                    ),
                  ),
                ),
                Positioned(
                  left: 20, bottom: 40, right: 20,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: kTdiaBlue.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: kTdiaBlue.withOpacity(0.5))),
                      child: Text(item.type, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 10),
                    Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1.1)),
                    const SizedBox(height: 8),
                    if (item.subtitle != null)
                      Text(item.subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
                  ]),
                ),
              ]),
            );
          },
        ),
        // Indicateur de tirage du pull-to-refresh
        if (_pullDistance > 0 || _filLoading)
          Positioned(
            top: 90, left: 0, right: 0,
            child: Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: (_pullDistance > 20 || _filLoading) ? 1 : 0,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: _filLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: kRed, strokeWidth: 2))
                      : Icon(Icons.autorenew_rounded, color: Colors.white, size: (18 + (_pullDistance / _pullThreshold) * 6).clamp(18, 26)),
                ),
              ),
            ),
          ),
      ]),
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
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: kRed.withOpacity(0.15), border: Border.all(color: kRed.withOpacity(0.3))),
                  child: const Icon(Icons.admin_panel_settings_rounded, color: kRed, size: 16),
                ),
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
            Positioned(
              bottom: 12, left: 12, right: 12,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                if (item.year != null) ...[const SizedBox(height: 4), Text("${item.year}", style: const TextStyle(color: Colors.white54, fontSize: 11))],
              ]),
            ),
          ]),
        ),
      );

  Widget _top10Card(MediaContent item, int index) => GestureDetector(
        onTap: () => _navigateToVideo(item),
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned(left: -20, bottom: -10, child: Text((index + 1).toString().padLeft(2, '0'), style: TextStyle(fontSize: 100, fontWeight: FontWeight.w900, color: Colors.transparent, shadows: [Shadow(color: Colors.white.withOpacity(0.2), blurRadius: 2)]))),
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
              selected: false, index: 1, color: isLiked ? kRed : null,
            ),
            _NavItemData(
              icon: Icons.chat_bubble_outline_rounded,
              label: currentItem != null ? _formatNumber(liveCounts?.commentCount ?? currentItem.commentCount) : 'Commenter',
              selected: false, index: 2,
            ),
            _NavItemData(
              // Nombre réel d'utilisateurs uniques ayant vu la vidéo, mis à jour en direct — plus jamais figé.
              icon: Icons.remove_red_eye_rounded,
              label: currentItem != null ? _formatNumber(liveCounts?.viewCount ?? currentItem.viewCount) : 'Vu',
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

// ---------------- LECTEUR VIDÉO DU FIL : autoplay + pause + barre de progression + double clic ----------------

class FeedVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String coverUrl;
  final bool isPlaying;
  const FeedVideoPlayer({super.key, required this.videoUrl, required this.coverUrl, required this.isPlaying});

  @override
  State<FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<FeedVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _showControls = false;
  bool _userPaused = false;
  Timer? _hideTimer;
  final ValueNotifier<Duration> _position = ValueNotifier(Duration.zero);
  Duration _duration = Duration.zero;

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
    _position.value = _controller.value.position;
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
      _showControls = true;
    });
    _scheduleHide();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && !_userPaused) setState(() => _showControls = false);
    });
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }

  // --- NOUVELLE FONCTION : Gestion de l'avance/recul ---
  void _seekRelative(int seconds) {
    if (!_isInitialized) return;
    final newPos = _position.value + Duration(seconds: seconds);
    Duration target = newPos;
    if (target < Duration.zero) target = Duration.zero;
    if (target > _duration) target = _duration;
    _controller.seekTo(target);
    _scheduleHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.removeListener(_listener);
    _controller.dispose();
    _position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
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

    return GestureDetector(
      // Un tap court sur la vidéo affiche/masque play-pause + barre de progression
      onTap: _togglePlayPause,
      
      // --- AJOUT : Double clic pour avancer/reculer de 10s ---
      onDoubleTapDown: (d) {
        final w = MediaQuery.of(context).size.width;
        if (d.globalPosition.dx < w / 2) {
          _seekRelative(-10); // Clic gauche = reculer
        } else {
          _seekRelative(10);  // Clic droit = avancer
        }
      },

      child: Stack(fit: StackFit.expand, children: [
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(width: _controller.value.size.width, height: _controller.value.size.height, child: VideoPlayer(_controller)),
        ),
        // Icône play centrale quand en pause
        if (_userPaused)
          const Center(
            child: Icon(Icons.play_arrow_rounded, color: Colors.white70, size: 64),
          ),
        // Barre de progression tap/drag pour avancer ou reculer
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _showControls || _userPaused ? 1 : 0,
          child: Positioned(
            left: 16, right: 16, bottom: 130,
            child: IgnorePointer(
              ignoring: !(_showControls || _userPaused),
              child: Row(children: [
                ValueListenableBuilder<Duration>(valueListenable: _position, builder: (_, pos, __) => Text(_fmt(pos), style: const TextStyle(color: Colors.white70, fontSize: 10))),
                Expanded(
                  child: ValueListenableBuilder<Duration>(
                    valueListenable: _position,
                    builder: (_, pos, __) {
                      final total = _duration.inMilliseconds == 0 ? 1 : _duration.inMilliseconds;
                      final progress = (pos.inMilliseconds / total).clamp(0.0, 1.0);
                      return SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 2.5,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                          activeTrackColor: kRed,
                          inactiveTrackColor: Colors.white30,
                          thumbColor: kRed,
                        ),
                        child: Slider(
                          value: progress,
                          onChangeStart: (_) {
                            _hideTimer?.cancel();
                            setState(() => _showControls = true);
                          },
                          onChanged: (v) {
                            final newPos = Duration(milliseconds: (v * total).round());
                            _position.value = newPos;
                          },
                          onChangeEnd: (v) {
                            final newPos = Duration(milliseconds: (v * total).round());
                            _controller.seekTo(newPos);
                            if (!_userPaused) _scheduleHide();
                          },
                        ),
                      );
                    },
                  ),
                ),
                Text(_fmt(_duration), style: const TextStyle(color: Colors.white70, fontSize: 10)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

// ----------------------------------------------------------------------
// SHEET DE COMMENTAIRES — 1 seul niveau d'imbrication, réponses repliées
// par défaut et chargées à la demande (aucun gaspillage d'espace ni de réseau)
// ----------------------------------------------------------------------

class _CommentsSheet extends ConsumerStatefulWidget {
  final String mediaId, mediaTitle;
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

  final List<CommentItem> _rootComments = [];
  bool _rootLoading = true;
  bool _rootHasMore = true;
  String? _rootCursor;

  // Réponses chargées à la demande, par commentaire parent
  final Map<String, List<CommentItem>> _repliesByParent = {};
  final Set<String> _expandedParents = {};
  final Set<String> _loadingReplies = {};

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadFirstPage() async {
    setState(() => _rootLoading = true);
    final page = await _service.fetchRootComments(widget.mediaId, limit: 20);
    if (!mounted) return;
    setState(() {
      _rootComments
        ..clear()
        ..addAll(page.items);
      _rootHasMore = page.hasMore;
      _rootCursor = page.nextCursorCreatedAt;
      _rootLoading = false;
    });
  }

  Future<void> _loadMoreRoot() async {
    if (!_rootHasMore || _rootCursor == null) return;
    final page = await _service.fetchRootCommentsNext(widget.mediaId, cursorCreatedAt: _rootCursor!, limit: 20);
    if (!mounted) return;
    setState(() {
      _rootComments.addAll(page.items);
      _rootHasMore = page.hasMore;
      _rootCursor = page.nextCursorCreatedAt;
    });
  }

  Future<void> _toggleExpandReplies(String parentId) async {
    if (_expandedParents.contains(parentId)) {
      setState(() => _expandedParents.remove(parentId));
      return;
    }
    setState(() => _expandedParents.add(parentId));
    if (_repliesByParent.containsKey(parentId)) return; // déjà chargé
    setState(() => _loadingReplies.add(parentId));
    final page = await _service.fetchReplies(parentId, limit: 15);
    if (!mounted) return;
    setState(() {
      _repliesByParent[parentId] = page.items;
      _loadingReplies.remove(parentId);
    });
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
    if (Supabase.instance.client.auth.currentUser == null) return;
    final wasLiked = _likedCommentIds.contains(commentId);
    setState(() {
      if (wasLiked) _likedCommentIds.remove(commentId);
      else _likedCommentIds.add(commentId);
    });
    try {
      await _service.toggleCommentLike(commentId);
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
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
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
              onTap: () {
                Navigator.pop(context);
                _deleteComment(com);
              },
            ),
          ListTile(
            leading: const Icon(Icons.flag_outlined, color: Colors.orangeAccent),
            title: const Text('Signaler', style: TextStyle(color: Colors.orangeAccent)),
            onTap: () {
              Navigator.pop(context);
              _service.reportComment(com.id);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signalé aux modérateurs'), backgroundColor: kSurface));
            },
          ),
        ]),
      ),
    );
  }

  Future<void> _deleteComment(CommentItem com) async {
    try {
      await _service.deleteComment(com.id);
      if (com.parentId == null) {
        setState(() => _rootComments.removeWhere((c) => c.id == com.id));
      } else {
        setState(() => _repliesByParent[com.parentId]?.removeWhere((c) => c.id == com.id));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: kRed));
    }
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    if (Supabase.instance.client.auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez vous connecter.'), backgroundColor: kSurface));
      return;
    }

    setState(() => _sending = true);
    try {
      if (_editingComment != null) {
        await _service.updateComment(_editingComment!.id, text);
        final list = _editingComment!.parentId == null ? _rootComments : _repliesByParent[_editingComment!.parentId!];
        final idx = list?.indexWhere((c) => c.id == _editingComment!.id) ?? -1;
        if (list != null && idx != -1) {
          list[idx] = CommentItem(
            id: list[idx].id, userId: list[idx].userId, userName: list[idx].userName, avatarUrl: list[idx].avatarUrl,
            content: text, createdAt: list[idx].createdAt, parentId: list[idx].parentId, likeCount: list[idx].likeCount, replyCount: list[idx].replyCount,
          );
        }
        _controller.clear();
        setState(() => _editingComment = null);
        return;
      }

      final replyParentId = _replyingTo?.parentId ?? _replyingTo?.id; // toujours attaché à la racine (1 seul niveau)
      final newComment = await _service.postComment(widget.mediaId, text, parentId: replyParentId);

      if (replyParentId != null) {
        setState(() {
          _repliesByParent.putIfAbsent(replyParentId, () => []);
          _repliesByParent[replyParentId]!.add(newComment);
          _expandedParents.add(replyParentId);
          final idx = _rootComments.indexWhere((c) => c.id == replyParentId);
          if (idx != -1) {
            final c = _rootComments[idx];
            _rootComments[idx] = CommentItem(
              id: c.id, userId: c.userId, userName: c.userName, avatarUrl: c.avatarUrl, content: c.content,
              createdAt: c.createdAt, parentId: c.parentId, likeCount: c.likeCount, replyCount: c.replyCount + 1,
            );
          }
        });
      } else {
        setState(() => _rootComments.insert(0, newComment));
      }

      _controller.clear();
      setState(() => _replyingTo = null);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: kRed));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Widget _buildCommentTile(CommentItem com, bool isAdmin, {bool isChild = false}) {
    final isLiked = _likedCommentIds.contains(com.id);
    final isExpanded = _expandedParents.contains(com.id);
    final replies = _repliesByParent[com.id] ?? [];
    final isLoadingReplies = _loadingReplies.contains(com.id);

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
                  child: com.avatarUrl == null || com.avatarUrl!.isEmpty ? Icon(Icons.person_rounded, size: isChild ? 12 : 16, color: kTextGrey) : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(com.userName, style: TextStyle(color: Colors.white, fontSize: isChild ? 12 : 13, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 8),
                        Text(_relativeTime(com.createdAt), style: const TextStyle(color: kTextGrey, fontSize: 11)),
                        const Spacer(),
                        IconButton(icon: const Icon(Icons.more_vert_rounded, color: kTextGrey, size: 16), onPressed: () => _showCommentOptions(com, isAdmin), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                      ]),
                      const SizedBox(height: 2),
                      Text(com.content, style: TextStyle(color: Colors.white70, fontSize: isChild ? 12.5 : 13.5)),
                      const SizedBox(height: 6),
                      Row(children: [
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
                          child: Row(children: [
                            Icon(isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 14, color: isLiked ? kRed : kTextGrey),
                            const SizedBox(width: 4),
                            Text(com.likeCount > 0 ? '${com.likeCount}' : "J'aime", style: TextStyle(color: isLiked ? kRed : kTextGrey, fontSize: 12)),
                          ]),
                        ),
                      ]),
                      // "Voir X réponses" — replié par défaut, charge à la demande (économise espace + réseau)
                      if (!isChild && com.replyCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: GestureDetector(
                            onTap: () => _toggleExpandReplies(com.id),
                            child: Row(children: [
                              Container(width: 24, height: 1, color: kBorderLight),
                              const SizedBox(width: 8),
                              Text(
                                isExpanded ? 'Masquer les réponses' : 'Voir ${com.replyCount} réponse${com.replyCount > 1 ? 's' : ''}',
                                style: const TextStyle(color: kTdiaBlue, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              if (isLoadingReplies) ...[
                                const SizedBox(width: 8),
                                const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5, color: kTdiaBlue)),
                              ],
                            ]),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Réponses affichées à un seul niveau — jamais imbriquées davantage (économise l'espace)
          if (!isChild && isExpanded)
            Column(children: replies.map((r) => _buildCommentTile(r, isAdmin, isChild: true)).toList()),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdminAsync = ref.watch(isMediaAdminProvider);
    final isAdmin = isAdminAsync.valueOrNull ?? false;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(color: kSurface, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(
          top: false,
          child: Column(children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 14),
            Text('${_rootComments.length}+ commentaires', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const Divider(color: kBorderLight, height: 1),
            Expanded(
              child: _rootLoading
                  ? const Center(child: CircularProgressIndicator(color: kRed))
                  : _rootComments.isEmpty
                      ? const Center(child: Text('Aucun commentaire pour le moment', style: TextStyle(color: kTextGrey)))
                      : NotificationListener<ScrollNotification>(
                          onNotification: (n) {
                            if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) _loadMoreRoot();
                            return false;
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _rootComments.length,
                            itemBuilder: (c, i) => _buildCommentTile(_rootComments[i], isAdmin),
                          ),
                        ),
            ),
            const Divider(color: kBorderLight, height: 1),
            if (_replyingTo != null || _editingComment != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: kSurfaceLight.withOpacity(0.6),
                child: Row(children: [
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
                ]),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(children: [
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
                        hintText: _editingComment != null ? 'Modifier votre commentaire...' : (_replyingTo != null ? 'Ajouter une réponse...' : 'Ajouter un commentaire...'),
                        hintStyle: const TextStyle(color: kTextGrey),
                        border: InputBorder.none,
                        isDense: true,
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
                    child: _sending
                        ? const Padding(padding: EdgeInsets.all(11), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
 
