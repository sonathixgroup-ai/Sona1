import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'video_player_page.dart';
import '../../models/media_content.dart';
import 'providers/thix_media_provider.dart';
import 'package:thix_id/nav.dart' show AppRoutes;

// Nouvelles couleurs exactes du design
const Color kBg = Color(0xFF050507);
const Color kSurface = Color(0xFF121214);
const Color kSurfaceLight = Color(0xFF1E1E28);
const Color kRed = Color(0xFFFF1A1A); // Le nouveau rouge vif
const Color kRedDark = Color(0xFFCC0843);
const Color kTextWhite = Color(0xFFFFFFFF);
const Color kTextGrey = Color(0xFF9CA3AF);
const Color kBorderLight = Color(0x14FFFFFF); // white/8
const Color kGreen = Color(0xFF3EFF88);

class ThixMediaPage extends ConsumerStatefulWidget {
  const ThixMediaPage({super.key});
  @override
  ConsumerState<ThixMediaPage> createState() => _ThixMediaPageState();
}

class _ThixMediaPageState extends ConsumerState<ThixMediaPage> {
  late PageController _bannerController;
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;
  Timer? _searchDebounce;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  final List<String> _filters = ["Pour vous", "Tendances", "NOVA Originals", "Live", "Courts", "Musique", "Gaming", "Formation"];

  @override
  void initState() {
    super.initState();
    // Le design original prend toute la largeur pour le Hero
    _bannerController = PageController(viewportFraction: 1.0);
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

  // Outil web-safe pour les images
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
        data: (_) {
          return Stack(
            children: [
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
                          if (bannerItems.isNotEmpty) _heroBanner(bannerItems),
                          
                          // Grille de contenu (avec dégradé derrière pour la transition)
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
                                    subtitle: 'Reprise intelligente • AV1',
                                    provider: recommendationsProvider,
                                    aspectRatio: 16 / 9,
                                    height: 180,
                                    width: 320,
                                    itemBuilder: (item) => _continueWatchingCard(item),
                                  ),
                                  const SizedBox(height: 40),
                                  _buildRow(
                                    title: 'THIX Originals Exclusifs',
                                    subtitle: 'Produit par THIX Studios • 4K',
                                    provider: newReleasesProvider,
                                    aspectRatio: 2 / 3,
                                    height: 240,
                                    width: 160,
                                    itemBuilder: (item) => _originalCard(item),
                                  ),
                                  const SizedBox(height: 40),
                                  _buildRow(
                                    title: 'Top 10 cette semaine',
                                    subtitle: 'Classement mondial',
                                    provider: trendingProvider,
                                    aspectRatio: 16 / 9,
                                    height: 160,
                                    width: 300,
                                    itemBuilder: (item, index) => _top10Card(item, index),
                                  ),
                                  const SizedBox(height: 40),
                                  _buildRow(
                                    title: 'Courts',
                                    subtitle: '9:16 • Swipe vertical',
                                    provider: upcomingProvider,
                                    aspectRatio: 9 / 16,
                                    height: 260,
                                    width: 150,
                                    itemBuilder: (item) => _shortsCard(item),
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
              
              // Header et filtres collés en haut
              Positioned(
                top: 0, left: 0, right: 0,
                child: Column(
                  children: [
                    _header(),
                    _filtersRow(selectedCategory),
                  ],
                ),
              ),
              
              // Bottom Nav
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: _bottomNav(),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- HEADER EXACT ---
  Widget _header() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            border: const Border(bottom: BorderSide(color: kBorderLight)),
          ),
          child: Row(
            children: [
              // Logo
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: kRed, borderRadius: BorderRadius.circular(9), boxShadow: [BoxShadow(color: kRed.withOpacity(0.4), blurRadius: 24)]),
                child: Center(child: Transform.rotate(angle: 0.785, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))))),
              ),
              const SizedBox(width: 10),
              const Text('THIX', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -1)),
              
              const Spacer(),
              
              // Search Bar
              Expanded(
                flex: 2,
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: const Color(0xFF0D0D10), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.08))),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: Colors.white30, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onChanged: _onSearchChanged,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(hintText: "Rechercher, demander à l'IA...", hintStyle: TextStyle(color: Colors.white30, fontSize: 14), border: InputBorder.none, isDense: true),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Right Actions
              Container(
                width: 36, height: 36,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white10),
                child: const Icon(Icons.notifications_none_rounded, color: Colors.white70, size: 20),
              ),
              const SizedBox(width: 12),
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 2), gradient: const LinearGradient(colors: [kRed, Color(0xFFFF8A00)])),
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- FILTRES ---
  Widget _filtersRow(String selectedCategory) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: kBg.withOpacity(0.8),
          padding: const EdgeInsets.symmetric(vertical: 12),
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
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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

  // --- HERO BANNER EXACT ---
  Widget _heroBanner(List<MediaContent> bannerItems) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.82, // 82vh
      child: PageView.builder(
        controller: _bannerController,
        onPageChanged: (i) => setState(() => _currentBannerIndex = i),
        itemCount: bannerItems.length,
        itemBuilder: (context, idx) {
          final item = bannerItems[idx];
          return Stack(
            fit: StackFit.expand,
            children: [
              _buildImage(item.coverUrl),
              
              // Dégradés
              Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [kBg, kBg.withOpacity(0.7), kBg.withOpacity(0.1), Colors.transparent]))),
              Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [kBg, kBg.withOpacity(0.6), Colors.transparent]))),
              
              // Contenu
              Positioned(
                bottom: 80, left: 24, right: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge N°1
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: kRed, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          const Text("N°1 AUJOURD'HUI • ORIGINAL", style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Titre
                    Text(item.title.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w900, height: 0.9, letterSpacing: -2)),
                    const SizedBox(height: 20),
                    
                    // Tags
                    Row(
                      children: [
                        const Text("98% Match", style: TextStyle(color: kGreen, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 12),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.white10)), child: const Text("4K DOLBY", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                        const SizedBox(width: 12),
                        Text("${item.year ?? 2026} • Thriller sci-fi", style: const TextStyle(color: Colors.white54, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Description
                    const Text("Dans un futur où la mémoire se monnaye, une archiviste découvre une faille qui pourrait effacer l'histoire humaine...", style: TextStyle(color: Colors.white70, fontSize: 14.5, height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 28),
                    
                    // Boutons
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _navigateToVideo(item),
                          icon: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 24),
                          label: const Text('Lecture', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.add, color: Colors.white, size: 24),
                          label: const Text('Ma Liste', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.1), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), side: BorderSide(color: Colors.white.withOpacity(0.1))),
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

  // --- REUSABLE ROW BUILDER ---
  Widget _buildRow({required String title, required String subtitle, required AutoDisposeProvider provider, required double aspectRatio, required double height, required double width, required Widget Function(dynamic item, [int index]) itemBuilder}) {
    final list = ref.watch(provider) as List<dynamic>;
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
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: SizedBox(width: width, child: itemBuilder(list[index], index)),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- CARDS ---
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
                  const Center(child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 48)),
                  Positioned(bottom: 0, left: 0, right: 0, child: LinearProgressIndicator(value: 0.6, backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation<Color>(kRed), minHeight: 4)),
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
            Positioned(top: 10, left: 10, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: kRed, borderRadius: BorderRadius.circular(4), boxShadow: [BoxShadow(color: kRed.withOpacity(0.5), blurRadius: 8)]), child: const Text("ORIGINAL", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)))),
            Positioned(bottom: 12, left: 12, right: 12, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text("${item.year ?? 2026} • 98% Match", style: const TextStyle(color: Colors.white54, fontSize: 11))])),
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
          // Le gros numéro derrière
          Positioned(
            left: -20, bottom: -10,
            child: Text((index + 1).toString().padLeft(2, '0'), style: TextStyle(fontSize: 100, fontWeight: FontWeight.w900, color: Colors.transparent, shadows: [Shadow(color: Colors.white.withOpacity(0.2), blurRadius: 2, offset: const Offset(0, 0))])),
          ),
          // L'image
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

  Widget _shortsCard(MediaContent item) {
    return GestureDetector(
      onTap: () => _navigateToVideo(item),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildImage(item.coverUrl),
            Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.8), Colors.transparent]))),
            Positioned(bottom: 12, left: 12, right: 12, child: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
            const Positioned(top: 10, right: 10, child: Icon(Icons.open_in_new_rounded, color: Colors.white, size: 16)),
          ],
        ),
      ),
    );
  }

  // --- BOTTOM NAV ---
  Widget _bottomNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF12121A).withOpacity(0.8),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _navItem(Icons.home_rounded, 'Accueil', true, 0),
                _navItem(Icons.search_rounded, 'Recherche', false, 1),
                _navItem(Icons.favorite_rounded, 'Favoris', false, 2),
                _navItem(Icons.person_rounded, 'Profil', false, 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool selected, int idx) {
    return InkWell(
      onTap: () {
        if (idx == 0) {
          _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
          ref.read(selectedCategoryProvider.notifier).state = 'Pour vous';
        }
        if (idx == 3) context.go(AppRoutes.userDashboard);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: selected ? Colors.white : Colors.white38, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: selected ? FontWeight.bold : FontWeight.w500, color: selected ? Colors.white : Colors.white38)),
        ],
      ),
    );
  }
}
