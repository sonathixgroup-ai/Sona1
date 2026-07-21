import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'video_player_page.dart';
import '../../models/media_content.dart';
import '../../services/media_service.dart';
import '../../app_router.dart';
import 'package:thix_id/nav.dart' show AppRoutes;

// ===== CHARTE THIX MEDIA — MODE CINÉMA =====
const Color kBg = Color(0xFF0B0714);
const Color kSurface = Color(0xFF161022);
const Color kSurfaceLight = Color(0xFF1F1830);
const Color kNavyDeep = Color(0xFF0F0A24);
const Color kViolet = Color(0xFF8B6BFF);
const Color kVioletDark = Color(0xFF5B3DE0);
const Color kSoftViolet = Color(0xFF241A3D);
const Color kRedLive = Color(0xFFE5484D);
const Color kTextWhite = Color(0xFFFFFFFF);
const Color kTextGrey = Color(0xFF9C97AD);
const Color kBorderLight = Color(0xFF2A2140);
const Color kGreen = Color(0xFF2ECC96);
const Color kOrange = Color(0xFFF0A23A);
const Color kGold = Color(0xFFE3B23C);

class ThixMediaPage extends StatefulWidget {
  const ThixMediaPage({super.key});
  @override
  State<ThixMediaPage> createState() => _ThixMediaPageState();
}

class _ThixMediaPageState extends State<ThixMediaPage> {
  late MediaService _mediaService;
  List<MediaContent> _allMedia = [];
  bool _isLoading = true;
  String? _error;

  String _selectedCategory = 'Accueil';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _searchDebounce;

  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _recommendationsKey = GlobalKey();

  List<MediaContent> _bannerItems = [];
  List<MediaContent> _filteredTrending = [];
  List<MediaContent> _filteredRecommendations = [];
  List<MediaContent> _filteredNewReleases = [];
  List<MediaContent> _filteredUpcoming = [];

  @override
  void initState() {
    super.initState();
    _mediaService = MediaService(client: Supabase.instance.client, bucket: 'media');
    _loadMedia();
  }

  void _startBannerAutoScroll() {
    _bannerTimer?.cancel();
    if (_bannerItems.isEmpty) return;
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || !_bannerController.hasClients) return;
      final next = (_currentBannerIndex + 1) % _bannerItems.length;
      _bannerController.animateToPage(next, duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _searchDebounce?.cancel();
    _bannerController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMedia() async {
    try {
      final media = await _mediaService.fetchPublishedMedia();
      if (!mounted) return;
      setState(() {
        _allMedia = media;
        _isLoading = false;
      });
      _updateFilteredLists();
      _startBannerAutoScroll();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _updateFilteredLists() {
    Iterable<MediaContent> base = _allMedia;
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      base = base.where((m) => m.title.toLowerCase().contains(q) || (m.subtitle?.toLowerCase().contains(q) ?? false));
    }
    setState(() {
      _bannerItems = base.where((m) => m.isNewRelease).toList();
      _filteredTrending = base.where((item) => item.rankPosition != null).toList();
      _filteredRecommendations = base.where((item) => item.rankPosition == null).toList();
      _filteredNewReleases = base.where((item) => item.isNewRelease).toList();
      _filteredUpcoming = base.where((item) => !item.isNewRelease).take(10).toList();
    });
  }

  void _onSearchChanged(String value) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchQuery = value);
      _updateFilteredLists();
    });
  }

  void _goToCategoryAndScroll(String category) {
    setState(() => _selectedCategory = category);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _recommendationsKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut, alignment: 0.05);
      }
    });
  }

  void _navigateToVideo(MediaContent item) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerPage(title: item.title, videoUrl: item.videoUrl)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: kBg, body: Center(child: CircularProgressIndicator(color: kViolet)));
    if (_error != null) return Scaffold(backgroundColor: kBg, body: Center(child: Text('Erreur : $_error', style: const TextStyle(color: kTextGrey))));

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopHeader(),
              _buildCategoryTabs(),
              const SizedBox(height: 4),
              if (_selectedCategory == 'Accueil' && _bannerItems.isNotEmpty) _buildBannerCinema(),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuickAccessRow(),
                    const SizedBox(height: 26),
                    if (_selectedCategory == 'Accueil') ...[
                      _buildSectionTitle('Tendances', icon: Icons.trending_up_rounded),
                      const SizedBox(height: 12),
                      _buildTendances(),
                      const SizedBox(height: 26),
                    ],
                    Container(
                      key: _recommendationsKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(_selectedCategory == 'Accueil' ? 'Recommandé pour vous' : _selectedCategory),
                          const SizedBox(height: 12),
                          _buildRecommandeGrid(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    _buildPremiumBanner(),
                    const SizedBox(height: 26),
                    _buildSectionTitle(_selectedCategory == 'Accueil' ? 'Nouveautés' : 'Nouveautés ($_selectedCategory)'),
                    const SizedBox(height: 12),
                    _buildNouveautes(),
                    const SizedBox(height: 26),
                    _buildSectionTitle('À venir'),
                    const SizedBox(height: 12),
                    _buildAVenir(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavWithLive(),
    );
  }

  // ===== HEADER SOMBRE =====
  Widget _buildTopHeader() {
    return Container(
      color: kBg,
      padding: const EdgeInsets.fromLTRB(10, 8, 12, 10),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(8), border: Border.all(color: kBorderLight)),
            child: const Icon(Icons.menu_rounded, size: 18, color: kTextWhite),
          ),
          const SizedBox(width: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [kViolet, kVioletDark]), borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 5),
              RichText(text: const TextSpan(children: [
                TextSpan(text: 'THIX ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: kTextWhite, letterSpacing: 0.3)),
                TextSpan(text: 'MEDIA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: kViolet, letterSpacing: 0.3)),
              ])),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(20), border: Border.all(color: kBorderLight)),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, size: 16, color: kTextGrey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: _onSearchChanged,
                      style: const TextStyle(fontSize: 11, color: kTextWhite),
                      decoration: const InputDecoration(
                        hintText: 'Rechercher un film, une série...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(fontSize: 10.5, color: kTextGrey),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: kSurface, shape: BoxShape.circle),
                child: const Icon(Icons.notifications_none_rounded, size: 18, color: kTextWhite),
              ),
              Positioned(top: -2, right: -2, child: Container(
                width: 14, height: 14,
                decoration: const BoxDecoration(color: kRedLive, shape: BoxShape.circle),
                child: const Center(child: Text('3', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800))),
              )),
            ],
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => context.pushNamed('thixMediaAdmin'),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [kViolet, kVioletDark]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: kViolet.withOpacity(0.4), blurRadius: 8)],
              ),
              child: const Icon(Icons.person_outline_rounded, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final tabs = [
      {'label': 'Accueil', 'icon': Icons.home_rounded},
      {'label': 'Vidéos', 'icon': Icons.play_circle_outline_rounded},
      {'label': 'Films', 'icon': Icons.movie_creation_outlined},
      {'label': 'Séries', 'icon': Icons.live_tv_rounded},
      {'label': 'Musique', 'icon': Icons.music_note_rounded},
      {'label': 'Playlists', 'icon': Icons.queue_music_rounded},
      {'label': 'En direct', 'icon': Icons.sensors_rounded},
    ];
    return Container(
      color: kBg,
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        physics: const BouncingScrollPhysics(),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final t = tabs[i];
          final selected = _selectedCategory == t['label'];
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = t['label'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                gradient: selected ? const LinearGradient(colors: [kViolet, kVioletDark]) : null,
                color: selected ? null : kSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? Colors.transparent : kBorderLight),
              ),
              child: Row(
                children: [
                  Icon(t['icon'] as IconData, size: 14, color: selected ? Colors.white : kTextGrey),
                  const SizedBox(width: 5),
                  Text(t['label'] as String, style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? Colors.white : kTextGrey)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ===== HERO IMMERSIF PLEIN ÉCRAN STYLE NETFLIX =====
  Widget _buildBannerCinema() {
    return Column(
      children: [
        SizedBox(
          height: 460,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _bannerController,
                onPageChanged: (i) => setState(() => _currentBannerIndex = i),
                itemCount: _bannerItems.length,
                itemBuilder: (context, idx) {
                  final item = _bannerItems[idx];
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(imageUrl: item.coverUrl, fit: BoxFit.cover, placeholder: (_, __) => Container(color: kSurface), errorWidget: (_, __, ___) => Container(color: kSurface)),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [kBg.withOpacity(0.75), Colors.transparent, kBg.withOpacity(0.5), kBg],
                            stops: const [0.0, 0.35, 0.7, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 54,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(gradient: const LinearGradient(colors: [kViolet, kVioletDark]), borderRadius: BorderRadius.circular(12)),
                              child: const Text('NOUVEAUTÉ THIX', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.8)),
                            ),
                            const SizedBox(height: 10),
                            Text(item.title.toUpperCase(), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, height: 1.08, letterSpacing: -0.5)),
                            if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(item.subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: kTextGrey, height: 1.3)),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _navigateToVideo(item),
                                    icon: const Icon(Icons.play_arrow_rounded, size: 18, color: kNavyDeep),
                                    label: const Text('Regarder maintenant', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kNavyDeep)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      minimumSize: const Size(0, 44),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(color: kSurfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorderLight)),
                                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
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
              Positioned(
                top: 10,
                left: 16,
                right: 16,
                child: Row(
                  children: List.generate(_bannerItems.length, (i) {
                    final active = i == _currentBannerIndex;
                    return Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(color: active ? kViolet : Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(2)),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessRow() {
    final items = [
      {'label': 'Vidéos', 'icon': Icons.play_circle_fill_rounded, 'color': kRedLive},
      {'label': 'Films', 'icon': Icons.movie_filter_rounded, 'color': kViolet},
      {'label': 'Séries', 'icon': Icons.live_tv_rounded, 'color': kGreen},
      {'label': 'Musique', 'icon': Icons.music_note_rounded, 'color': kOrange},
      {'label': 'En direct', 'icon': Icons.sensors_rounded, 'color': kRedLive},
      {'label': 'Genres', 'icon': Icons.grid_view_rounded, 'color': kViolet},
    ];
    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 18),
        itemBuilder: (context, i) {
          final it = items[i];
          return GestureDetector(
            onTap: () => _goToCategoryAndScroll(it['label'] as String),
            child: Column(
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(color: (it['color'] as Color).withOpacity(0.16), borderRadius: BorderRadius.circular(14), border: Border.all(color: (it['color'] as Color).withOpacity(0.3))),
                  child: Icon(it['icon'] as IconData, color: it['color'] as Color, size: 21),
                ),
                const SizedBox(height: 6),
                Text(it['label'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kTextGrey)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, {IconData? icon}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          if (icon != null) Icon(icon, size: 15, color: kViolet),
          if (icon != null) const SizedBox(width: 6),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kTextWhite, letterSpacing: -0.2)),
        ]),
        Row(children: const [
          Text('Voir tout', style: TextStyle(fontSize: 10.5, color: kTextGrey, fontWeight: FontWeight.w600)),
          SizedBox(width: 2),
          Icon(Icons.chevron_right_rounded, size: 14, color: kTextGrey),
        ]),
      ],
    );
  }

  // Tendances — badge de classement géant translucide façon Netflix Top 10
  Widget _buildTendances() {
    if (_filteredTrending.isEmpty) return const Text('Aucune tendance', style: TextStyle(fontSize: 11, color: kTextGrey));
    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filteredTrending.length,
        itemBuilder: (context, i) {
          final item = _filteredTrending[i];
          return GestureDetector(
            onTap: () => _navigateToVideo(item),
            child: Container(
              width: 148,
              margin: EdgeInsets.only(right: i == _filteredTrending.length - 1 ? 0 : 4),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: -6,
                    bottom: 20,
                    child: Text(
                      '${item.rankPosition ?? i + 1}',
                      style: TextStyle(
                        fontSize: 84,
                        fontWeight: FontWeight.w900,
                        height: 0.8,
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 2
                          ..color = kViolet.withOpacity(0.5),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: item.coverUrl,
                        height: 178,
                        width: 108,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Grille recommandations — posters verticaux type Netflix
  Widget _buildRecommandeGrid() {
    final list = _filteredRecommendations.where((e) => _selectedCategory == 'Accueil' ? true : e.type == _selectedCategory).toList();
    if (list.isEmpty) return const Text('Aucun contenu', style: TextStyle(fontSize: 11, color: kTextGrey));
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: list.length,
        itemBuilder: (context, i) {
          final item = list[i];
          return GestureDetector(
            onTap: () => _navigateToVideo(item),
            child: Container(
              width: 118,
              margin: EdgeInsets.only(right: i == list.length - 1 ? 0 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(imageUrl: item.coverUrl, height: 158, width: 118, fit: BoxFit.cover),
                    ),
                    if (item.isNewRelease)
                      Positioned(
                        top: 8, left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(color: kRedLive, borderRadius: BorderRadius.circular(6)),
                          child: const Text('NOUVEAU', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 7),
                  Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kTextWhite)),
                  Text('${item.type} • ${item.year ?? 2024}', style: const TextStyle(fontSize: 9, color: kTextGrey)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPremiumBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kSoftViolet, kSurfaceLight]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kViolet.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [kGold, Color(0xFFF3CD6B)]), shape: BoxShape.circle),
            child: const Icon(Icons.workspace_premium_rounded, color: kNavyDeep, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('THIX MEDIA Premium', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kTextWhite)),
              SizedBox(height: 2),
              Text('Contenu sans publicité, téléchargement et lecture hors ligne.', style: TextStyle(fontSize: 9.5, color: kTextGrey)),
            ]),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: kViolet, minimumSize: const Size(0, 32), padding: const EdgeInsets.symmetric(horizontal: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
            child: const Text('Passer Premium', style: TextStyle(fontSize: 10.5, color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildNouveautes() {
    final list = _filteredNewReleases.where((e) => _selectedCategory == 'Accueil' || e.type == _selectedCategory).toList();
    if (list.isEmpty) return const Text('Aucune nouveauté', style: TextStyle(fontSize: 11, color: kTextGrey));
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: list.length,
        itemBuilder: (context, i) {
          final item = list[i];
          return GestureDetector(
            onTap: () => _navigateToVideo(item),
            child: Container(
              width: 118,
              margin: EdgeInsets.only(right: i == list.length - 1 ? 0 : 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: item.coverUrl, height: 158, width: 118, fit: BoxFit.cover)),
                const SizedBox(height: 7),
                Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kTextWhite)),
                Text('${item.type} • ${item.year ?? 2024}', style: const TextStyle(fontSize: 9, color: kTextGrey)),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAVenir() {
    if (_filteredUpcoming.isEmpty) return const Text('Bientôt disponible...', style: TextStyle(fontSize: 11, color: kTextGrey));
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filteredUpcoming.length,
        itemBuilder: (context, i) {
          final item = _filteredUpcoming[i];
          return GestureDetector(
            onTap: () => _navigateToVideo(item),
            child: Container(
              width: 118,
              margin: const EdgeInsets.only(right: 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Stack(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.darken),
                      child: CachedNetworkImage(imageUrl: item.coverUrl, height: 158, width: 118, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
                        child: const Icon(Icons.schedule_rounded, size: 18, color: kViolet),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(color: kTextWhite, borderRadius: BorderRadius.circular(6)),
                      child: const Text('À VENIR', style: TextStyle(fontSize: 7, color: kNavyDeep, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ]),
                const SizedBox(height: 7),
                Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kTextWhite)),
                const Text('Bientôt', style: TextStyle(fontSize: 9, color: kTextGrey)),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNavWithLive() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: kBorderLight),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 22, offset: const Offset(0, 9))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_rounded, 'Accueil', true, 0),
              _navItem(Icons.search_rounded, 'Rechercher', false, 1),
              _liveCenterButton(),
              _navItem(Icons.favorite_border_rounded, 'Favoris', false, 2),
              _navItem(Icons.person_outline_rounded, 'Profil', false, 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _liveCenterButton() {
    return GestureDetector(
      onTap: () => _goToCategoryAndScroll('En direct'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: kRedLive, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: kRedLive.withOpacity(0.5), blurRadius: 14)]),
            child: const Row(children: [
              Icon(Icons.sensors_rounded, size: 14, color: Colors.white),
              SizedBox(width: 4),
              Text('LIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
            ]),
          ),
          const SizedBox(height: 3),
          const Text('Direct', style: TextStyle(fontSize: 9, color: kRedLive, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool selected, int idx) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        if (idx == 0) { _scrollController.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeOut); setState(() => _selectedCategory = 'Accueil'); }
        if (idx == 1) { _scrollController.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeOut); FocusScope.of(context).requestFocus(_searchFocusNode); }
        if (idx == 3) context.go(AppRoutes.userDashboard);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: selected ? kSoftViolet : Colors.transparent, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: selected ? kViolet : kTextGrey, size: 18)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 8.5, color: selected ? kViolet : kTextGrey, fontWeight: selected ? FontWeight.w800 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
