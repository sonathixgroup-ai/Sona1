import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'video_player_page.dart';
import '../../models/media_content.dart';
import '../../services/media_service.dart';
import '../../app_router.dart';
import 'package:thix_id/nav.dart' show AppRoutes;

// ===== CHARTE PREMIUM ENTREPRISE MONDIAL =====
const Color kBg = Color(0xFF050508);
const Color kSurface = Color(0xFF12121A);
const Color kSurfaceLight = Color(0xFF1E1E28);
const Color kNavyDeep = Color(0xFF07070A);
const Color kViolet = Color(0xFFFF0A54); // PRIMARY PINK STREAMIT
const Color kVioletDark = Color(0xFFCC0843);
const Color kSoftViolet = Color(0xFF1A0A14);
const Color kRedLive = Color(0xFFFF0A54);
const Color kTextWhite = Color(0xFFFFFFFF);
const Color kTextGrey = Color(0xFF9CA3AF);
const Color kBorderLight = Color(0xFF222233);
const Color kGreen = Color(0xFF10B981);
const Color kOrange = Color(0xFFF59E0B);
const Color kGold = Color(0xFFFFC542);
const Color kGold2 = Color(0xFFFF8A00);

class ThixMediaPage extends StatefulWidget {
  const ThixMediaPage({super.key});
  @override
  State<ThixMediaPage> createState() => _ThixMediaPageState();
}

class _ThixMediaPageState extends State<ThixMediaPage> with SingleTickerProviderStateMixin {
  late MediaService _mediaService;
  List<MediaContent> _allMedia = [];
  bool _isLoading = true;
  String? _error;

  String _selectedCategory = 'Accueil';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _searchDebounce;
  bool _isSearchVisible = false;

  late PageController _bannerController;
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
    _bannerController = PageController(viewportFraction: 0.88);
    _mediaService = MediaService(client: Supabase.instance.client, bucket: 'media');
    _loadMedia();
  }

  void _startBannerAutoScroll() {
    _bannerTimer?.cancel();
    if (_bannerItems.isEmpty) return;
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted ||!_bannerController.hasClients) return;
      final next = (_currentBannerIndex + 1) % _bannerItems.length;
      _bannerController.animateToPage(next, duration: const Duration(milliseconds: 600), curve: Curves.easeOutCubic);
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
      setState(() => _isLoading = true);
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
      base = base.where((m) => m.title.toLowerCase().contains(q) || (m.subtitle?.toLowerCase().contains(q)?? false));
    }
    setState(() {
      _bannerItems = base.where((m) => m.isNewRelease).toList();
      if (_bannerItems.isEmpty) _bannerItems = base.take(5).toList();
      _filteredTrending = base.where((item) => item.rankPosition!= null).toList()..sort((a,b)=> (a.rankPosition??99).compareTo(b.rankPosition??99));
      _filteredRecommendations = base.where((item) => item.rankPosition == null).toList();
      _filteredNewReleases = base.where((item) => item.isNewRelease).toList();
      _filteredUpcoming = base.where((item) =>!item.isNewRelease).take(10).toList();
    });
  }

  void _onSearchChanged(String value) {
    if (_searchDebounce?.isActive?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchQuery = value);
      _updateFilteredLists();
    });
  }

  void _goToCategoryAndScroll(String category) {
    setState(() => _selectedCategory = category);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _recommendationsKey.currentContext;
      if (ctx!= null) {
        Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 600), curve: Curves.easeOutCubic, alignment: 0.02);
      }
    });
  }

  void _navigateToVideo(MediaContent item) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerPage(title: item.title, videoUrl: item.videoUrl)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Scaffold(backgroundColor: kBg, body: _buildSkeletonLoader());
    if (_error!= null) return Scaffold(backgroundColor: kBg, body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.error_outline, color: kTextGrey), const SizedBox(height: 8), Text('Erreur : $_error', style: const TextStyle(color: kTextGrey)), const SizedBox(height: 16), ElevatedButton(onPressed: _loadMedia, style: ElevatedButton.styleFrom(backgroundColor: kViolet), child: const Text('Réessayer'))])));

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopHeaderPremium(),
            if (_isSearchVisible) _buildSearchBarPremium(),
            Expanded(
              child: RefreshIndicator(
                color: kViolet,
                backgroundColor: kSurface,
                onRefresh: _loadMedia,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedCategory == 'Accueil' && _bannerItems.isNotEmpty) _buildBannerCinemaPremium(),
                      const SizedBox(height: 28),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCategoryPremium(),
                            const SizedBox(height: 32),
                            if (_selectedCategory == 'Accueil')...[
                              _buildSectionTitlePremium('Tendances • Top 10 Mondial', icon: Icons.local_fire_department_rounded, showSeeAll: true),
                              const SizedBox(height: 16),
                              _buildTendancesPremium(),
                              const SizedBox(height: 32),
                            ],
                            Container(
                              key: _recommendationsKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitlePremium(_selectedCategory == 'Accueil'? 'Recommandé pour vous' : _selectedCategory, showSeeAll: true),
                                  const SizedBox(height: 16),
                                  _buildRecommandeGridPremium(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            _buildPremiumBannerEnterprise(),
                            const SizedBox(height: 32),
                            _buildSectionTitlePremium(_selectedCategory == 'Accueil'? 'Nouveautés Exclusives' : 'Nouveautés $_selectedCategory', showSeeAll: true),
                            const SizedBox(height: 16),
                            _buildNouveautesPremium(),
                            const SizedBox(height: 32),
                            _buildSectionTitlePremium('À venir • Bientôt disponible', icon: Icons.schedule_rounded, showSeeAll: false),
                            const SizedBox(height: 16),
                            _buildAVenirPremium(),
                            const SizedBox(height: 130),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavPremium(),
      extendBody: true,
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(height: 32, width: 150, decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(8))),
        const SizedBox(height: 24),
        Container(height: 460, decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(16))),
        const SizedBox(height: 24),
        Row(children: List.generate(4, (i) => Container(margin: const EdgeInsets.only(right: 12), width: 130, height: 80, decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(12))))),
      ],
    );
  }

  // ===== HEADER PREMIUM ENTREPRISE =====
  Widget _buildTopHeaderPremium() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: kBg.withOpacity(0.85),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [kViolet, kVioletDark]), borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: kViolet.withOpacity(0.4), blurRadius: 12)]),
                child: const Icon(Icons.play_arrow_rounded, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 8),
              RichText(text: const TextSpan(children: [
                TextSpan(text: 'THIX ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.white, letterSpacing: 1.2)),
                TextSpan(text: 'MEDIA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: kViolet, letterSpacing: 1.2)),
              ])),
              const Spacer(),
              _iconBtn(Icons.search_rounded, () => setState(() => _isSearchVisible =!_isSearchVisible)),
              const SizedBox(width: 12),
              Stack(clipBehavior: Clip.none, children: [
                _iconBtn(Icons.notifications_none_rounded, () {}, hasBg: true),
                Positioned(top: -2, right: -2, child: Container(width: 18, height: 18, decoration: BoxDecoration(color: kViolet, shape: BoxShape.circle, border: Border.all(color: kBg, width: 2)), child: const Center(child: Text('3', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white))))),
              ]),
              const SizedBox(width: 12),
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [kGold, kGold2]), border: Border.all(color: kBg, width: 2), boxShadow: [BoxShadow(color: kGold.withOpacity(0.4), blurRadius: 10)]),
                child: const Icon(Icons.person_rounded, size: 18, color: Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap, {bool hasBg = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: hasBg? kSurface : Colors.transparent, shape: BoxShape.circle, border: hasBg? Border.all(color: kBorderLight) : null),
        child: Icon(icon, size: 20, color: kTextWhite),
      ),
    );
  }

  Widget _buildSearchBarPremium() {
    return Container(
      color: kBg,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorderLight)),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, size: 20, color: kTextGrey),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _searchController, focusNode: _searchFocusNode, autofocus: true, onChanged: _onSearchChanged, style: const TextStyle(fontSize: 14, color: kTextWhite), decoration: const InputDecoration(hintText: 'Films, séries, artistes...', border: InputBorder.none, hintStyle: TextStyle(fontSize: 14, color: kTextGrey), isDense: true))),
            if (_searchQuery.isNotEmpty) GestureDetector(onTap: () {_searchController.clear(); _onSearchChanged('');}, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: kSurfaceLight, shape: BoxShape.circle), child: const Icon(Icons.close_rounded, size: 14, color: kTextGrey))),
          ],
        ),
      ),
    );
  }

  // ===== HERO PREMIUM 580PX CINEMA =====
  Widget _buildBannerCinemaPremium() {
    return Column(
      children: [
        SizedBox(
          height: 560,
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (i) => setState(() => _currentBannerIndex = i),
            itemCount: _bannerItems.length,
            itemBuilder: (context, idx) {
              final item = _bannerItems[idx];
              final isCenter = idx == _currentBannerIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: isCenter? 0 : 24),
                child: GestureDetector(
                  onTap: () => _navigateToVideo(item),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(imageUrl: item.coverUrl, fit: BoxFit.cover, placeholder: (_, __) => Container(color: kSurface), errorWidget: (_, __, ___) => Container(color: kSurface)),
                        // Gradients cinéma
                        Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.6), Colors.transparent, Colors.transparent, Colors.black.withOpacity(0.9)], stops: const [0, 0.3, 0.6, 1]))),
                        // Top badges
                        Positioned(
                          top: 14, left: 14, right: 14,
                          child: Row(
                            children: [
                              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(gradient: const LinearGradient(colors: [kViolet, kVioletDark]), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: kViolet.withOpacity(0.5), blurRadius: 10)]), child: const Row(children: [Icon(Icons.bolt_rounded, size: 12, color: Colors.white), SizedBox(width: 4), Text('NOUVEAUTÉ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.6))])),
                              const Spacer(),
                              if (item.rankPosition!= null && item.rankPosition! <= 3) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: kGold, borderRadius: BorderRadius.circular(6)), child: Text('TOP ${item.rankPosition}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black))),
                            ],
                          ),
                        ),
                        // Bottom content
                        Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(18, 30, 18, 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.title.toUpperCase(), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, height: 1.05, letterSpacing: -0.8, shadows: [Shadow(color: Colors.black54, blurRadius: 10)])),
                                const SizedBox(height: 8),
                                Row(children: [
                                  _badge('4K', isGold: true),
                                  const SizedBox(width: 6),
                                  _badge('DOLBY'),
                                  const SizedBox(width: 8),
                                  Text('${item.type} • ${item.year?? 2024}', style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.star_rounded, size: 12, color: kGold),
                                  const Text(' 4.9', style: TextStyle(fontSize: 11, color: Colors.white70)),
                                ]),
                                if (item.subtitle!= null && item.subtitle!.isNotEmpty)...[const SizedBox(height: 6), Text(item.subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFFB8B8C0), height: 1.3))],
                                const SizedBox(height: 16),
                                Row(children: [
                                  Expanded(child: ElevatedButton.icon(onPressed: () => _navigateToVideo(item), icon: const Icon(Icons.play_arrow_rounded, size: 20, color: Colors.black), label: const Text('Lecture', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black)), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, minimumSize: const Size(0, 46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0))),
                                  const SizedBox(width: 10),
                                  Container(width: 46, height: 46, decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.2))), child: const Icon(Icons.add_rounded, color: Colors.white, size: 22)),
                                  const SizedBox(width: 10),
                                  Container(width: 46, height: 46, decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.2))), child: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20)),
                                ]),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_bannerItems.length, (i) {
          final active = i == _currentBannerIndex;
          return AnimatedContainer(duration: const Duration(milliseconds: 300), margin: const EdgeInsets.symmetric(horizontal: 3), width: active? 22 : 6, height: 4, decoration: BoxDecoration(color: active? kViolet : Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)));
        })),
      ],
    );
  }

  Widget _badge(String text, {bool isGold = false}) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5), decoration: BoxDecoration(color: isGold? kGold : Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: isGold? kGold : Colors.white.withOpacity(0.3))), child: Text(text, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: isGold? Colors.black : Colors.white, letterSpacing: 0.5)));
  }

  Widget _buildSectionTitlePremium(String title, {IconData? icon, bool showSeeAll = true}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(children: [if (icon!= null) Icon(icon, size: 18, color: kViolet), if (icon!= null) const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: kTextWhite, letterSpacing: -0.4))]),
      if (showSeeAll) Row(children: const [Text('Voir tout', style: TextStyle(fontSize: 12.5, color: kTextGrey, fontWeight: FontWeight.w600)), SizedBox(width: 2), Icon(Icons.chevron_right_rounded, size: 16, color: kTextGrey)]),
    ]);
  }

  Widget _buildCategoryPremium() {
    final cats = [
      {'label': 'Action', 'type': 'Films', 'color': kViolet},
      {'label': 'Adventure', 'type': 'Séries', 'color': kGreen},
      {'label': 'Comédie', 'type': 'Vidéos', 'color': kOrange},
      {'label': 'Musique', 'type': 'Musique', 'color': kViolet},
      {'label': 'Live', 'type': 'En direct', 'color': kRedLive},
      {'label': 'Premium', 'type': 'Playlists', 'color': kGold},
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionTitlePremium('Explorer par univers'),
      const SizedBox(height: 16),
      SizedBox(
        height: 92,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: cats.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, i) {
            final cat = cats[i];
            final img = _allMedia.where((e) => e.type == cat['type']).isNotEmpty? _allMedia.where((e) => e.type == cat['type']).first.coverUrl : (_allMedia.isNotEmpty? _allMedia[i % _allMedia.length].coverUrl : '');
            final selected = _selectedCategory == cat['type'];
            return GestureDetector(
              onTap: () => _goToCategoryAndScroll(cat['type'] as String),
              child: Container(
                width: 142,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: selected? (cat['color'] as Color) : kBorderLight, width: selected? 1.5 : 1)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(fit: StackFit.expand, children: [
                    if (img.isNotEmpty) CachedNetworkImage(imageUrl: img, fit: BoxFit.cover) else Container(color: kSurface),
                    Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [(cat['color'] as Color).withOpacity(0.75), Colors.black.withOpacity(0.6)]))),
                    Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(cat['type'] == 'En direct'? Icons.sensors_rounded : Icons.category_rounded, color: Colors.white, size: 20), const SizedBox(height: 4), Text(cat['label'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13))])),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }

  Widget _buildTendancesPremium() {
    if (_filteredTrending.isEmpty) return const Text('Aucune tendance', style: TextStyle(color: kTextGrey));
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filteredTrending.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, i) {
          final item = _filteredTrending[i];
          return GestureDetector(
            onTap: () => _navigateToVideo(item),
            child: SizedBox(
              width: 150,
              child: Stack(clipBehavior: Clip.none, children: [
                Positioned(left: -10, bottom: 10, child: Text('${item.rankPosition?? i + 1}', style: TextStyle(fontSize: 92, fontWeight: FontWeight.w900, height: 0.8, foreground: Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5..color = Colors.white.withOpacity(0.12), shadows: [Shadow(color: kViolet.withOpacity(0.3), blurRadius: 20)]))),
                Positioned(right: 0, child: ClipRRect(borderRadius: BorderRadius.circular(14), child: CachedNetworkImage(imageUrl: item.coverUrl, height: 195, width: 120, fit: BoxFit.cover))),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecommandeGridPremium() {
    final list = _filteredRecommendations.where((e) => _selectedCategory == 'Accueil'? true : e.type == _selectedCategory).toList();
    if (list.isEmpty) return const Text('Aucun contenu', style: TextStyle(color: kTextGrey));
    return SizedBox(
      height: 232,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final item = list[i];
          return GestureDetector(
            onTap: () => _navigateToVideo(item),
            child: SizedBox(
              width: 128,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Stack(children: [
                  ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: item.coverUrl, height: 182, width: 128, fit: BoxFit.cover)),
                  if (item.isNewRelease) Positioned(top: 8, left: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: kViolet, borderRadius: BorderRadius.circular(6), boxShadow: [BoxShadow(color: kViolet.withOpacity(0.5), blurRadius: 8)]), child: const Text('NOUVEAU', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white)))),
                  Positioned(bottom: 6, right: 6, child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), shape: BoxShape.circle), child: const Icon(Icons.play_arrow_rounded, size: 14, color: Colors.white))),
                ]),
                const SizedBox(height: 8),
                Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kTextWhite)),
                Text('${item.type} • ${item.year?? 2024}', style: const TextStyle(fontSize: 10, color: kTextGrey)),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPremiumBannerEnterprise() {
    return Container(
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [kGold, kGold2, kViolet]), borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1A160F), Color(0xFF161022)]), borderRadius: BorderRadius.circular(19)),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(gradient: const LinearGradient(colors: [kGold, kGold2]), shape: BoxShape.circle, boxShadow: [BoxShadow(color: kGold.withOpacity(0.4), blurRadius: 16)]), child: const Icon(Icons.workspace_premium_rounded, color: Colors.black, size: 22)),
          const SizedBox(width: 14),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Text('THIX MEDIA ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)), Text('PREMIUM', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: kGold))]),
            SizedBox(height: 3),
            Text('4K • Sans pub • Offline • Dolby Atmos', style: TextStyle(fontSize: 11, color: kTextGrey)),
          ])),
          ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 0), child: const Text('Upgrade', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800))),
        ]),
      ),
    );
  }

  Widget _buildNouveautesPremium() {
    final list = _filteredNewReleases.where((e) => _selectedCategory == 'Accueil' || e.type == _selectedCategory).toList();
    if (list.isEmpty) return const Text('Aucune nouveauté', style: TextStyle(color: kTextGrey));
    return SizedBox(height: 232, child: ListView.separated(scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(), itemCount: list.length, separatorBuilder: (_, __) => const SizedBox(width: 12), itemBuilder: (context, i) { final item = list[i]; return GestureDetector(onTap: () => _navigateToVideo(item), child: SizedBox(width: 128, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: item.coverUrl, height: 182, width: 128, fit: BoxFit.cover)), const SizedBox(height: 8), Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kTextWhite))]))); }));
  }

  Widget _buildAVenirPremium() {
    if (_filteredUpcoming.isEmpty) return const Text('Bientôt disponible...', style: TextStyle(color: kTextGrey));
    return SizedBox(height: 232, child: ListView.separated(scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(), itemCount: _filteredUpcoming.length, separatorBuilder: (_, __) => const SizedBox(width: 12), itemBuilder: (context, i) { final item = _filteredUpcoming[i]; return GestureDetector(onTap: () => _navigateToVideo(item), child: SizedBox(width: 128, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Stack(children: [ClipRRect(borderRadius: BorderRadius.circular(12), child: ColorFiltered(colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.darken), child: CachedNetworkImage(imageUrl: item.coverUrl, height: 182, width: 128, fit: BoxFit.cover))), Positioned.fill(child: Center(child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle), child: const Icon(Icons.schedule_rounded, size: 18, color: kViolet)))), Positioned(top: 8, left: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)), child: const Text('À VENIR', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.black))))]), const SizedBox(height: 8), Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kTextWhite))]))) ; }));
  }

  Widget _buildBottomNavPremium() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            height: 66,
            decoration: BoxDecoration(color: kSurface.withOpacity(0.85), borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white.withOpacity(0.08)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 30, offset: const Offset(0, 10))]),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _navItemPremium(Icons.home_rounded, 'Accueil', true, 0),
              _navItemPremium(Icons.search_rounded, 'Rechercher', false, 1),
              _liveCenterPremium(),
              _navItemPremium(Icons.favorite_rounded, 'Favoris', false, 2),
              _navItemPremium(Icons.person_rounded, 'Profil', false, 3),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _liveCenterPremium() {
    return GestureDetector(
      onTap: () => _goToCategoryAndScroll('En direct'),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(gradient: const LinearGradient(colors: [kViolet, kVioletDark]), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: kViolet.withOpacity(0.5), blurRadius: 16)]), child: Row(children: [Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)), const SizedBox(width: 6), const Text('LIVE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.6))])),
        const SizedBox(height: 3),
        const Text('Direct', style: TextStyle(fontSize: 9, color: kViolet, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _navItemPremium(IconData icon, String label, bool selected, int idx) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        if (idx == 0) {_scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic); setState(() => _selectedCategory = 'Accueil');}
        if (idx == 1) {setState(() => _isSearchVisible = true); FocusScope.of(context).requestFocus(_searchFocusNode);}
        if (idx == 2) {}
        if (idx == 3) context.go(AppRoutes.userDashboard);
      },
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: selected? kViolet.withOpacity(0.15) : Colors.transparent, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: selected? kViolet : kTextGrey, size: 20)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 9, color: selected? kViolet : kTextGrey, fontWeight: selected? FontWeight.w800 : FontWeight.w500)),
      ]),
    );
  }
}
