import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'video_player_page.dart';
import '../../models/media_content.dart';
import 'providers/thix_media_provider.dart';
import 'package:thix_id/nav.dart' show AppRoutes;

const Color kBg = Color(0xFF050508);
const Color kSurface = Color(0xFF12121A);
const Color kSurfaceLight = Color(0xFF1E1E28);
const Color kViolet = Color(0xFFFF0A54);
const Color kVioletDark = Color(0xFFCC0843);
const Color kTextWhite = Color(0xFFFFFFFF);
const Color kTextGrey = Color(0xFF9CA3AF);
const Color kBorderLight = Color(0xFF222233);
const Color kGold = Color(0xFFFFC542);
const Color kGold2 = Color(0xFFFF8A00);

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
  final GlobalKey _recommendationsKey = GlobalKey();
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    _bannerController = PageController(viewportFraction: 0.90);
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
    _bannerTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || !_bannerController.hasClients) return;
      final next = (_currentBannerIndex + 1) % count;
      _bannerController.animateToPage(next, duration: const Duration(milliseconds: 700), curve: Curves.easeOutCubic);
    });
  }

  void _onSearchChanged(String v) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchQueryProvider.notifier).state = v;
    });
  }

  void _goToCategoryAndScroll(String category) {
    ref.read(selectedCategoryProvider.notifier).state = category;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _recommendationsKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 600), curve: Curves.easeOutCubic, alignment: 0.02);
      }
    });
  }

  void _navigateToVideo(MediaContent item) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerPage(title: item.title, videoUrl: item.videoUrl)));
  }

  // 🛠️ OUTIL ADAPTÉ POUR WEB ET MOBILE : Remplace CachedNetworkImage
  Widget _buildImage(String url, {double? width, double? height}) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height,
          color: kSurfaceLight,
          child: const Center(
            child: CircularProgressIndicator(color: kViolet, strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: kSurfaceLight,
          child: const Center(
            child: Icon(Icons.broken_image_rounded, color: kTextGrey),
          ),
        );
      },
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

    return asyncMedia.when(
      loading: () => Scaffold(backgroundColor: kBg, body: _skeleton()),
      error: (e, st) => Scaffold(
        backgroundColor: kBg,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, color: kTextGrey, size: 40),
            const SizedBox(height: 12),
            Text('Erreur: $e', style: const TextStyle(color: kTextGrey)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => ref.read(thixMediaListProvider.notifier).refresh(),
              style: ElevatedButton.styleFrom(backgroundColor: kViolet, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Réessayer'),
            ),
          ]),
        ),
      ),
      data: (_) {
        return Scaffold(
          backgroundColor: kBg,
          body: SafeArea(
            bottom: false,
            child: Column(children: [
              _header(),
              AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: _isSearchVisible ? _searchBar() : const SizedBox.shrink()),
              Expanded(
                child: RefreshIndicator(
                  color: kViolet,
                  backgroundColor: kSurface,
                  onRefresh: () => ref.read(thixMediaListProvider.notifier).refresh(),
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    slivers: [
                      if (selectedCategory == 'Accueil' && bannerItems.isNotEmpty) SliverToBoxAdapter(child: _bannerCinema(bannerItems)),
                      const SliverToBoxAdapter(child: SizedBox(height: 28)),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList.list(children: [
                          _categorySection(),
                          const SizedBox(height: 32),
                          if (selectedCategory == 'Accueil') ...[
                            _sectionTitle('Tendances • Top 10 Mondial', icon: Icons.local_fire_department_rounded, iconColor: kViolet),
                            const SizedBox(height: 16),
                            _tendances(),
                            const SizedBox(height: 32),
                          ],
                          Container(key: _recommendationsKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_sectionTitle(selectedCategory == 'Accueil' ? 'Recommandé pour vous' : selectedCategory), const SizedBox(height: 16), _recommandeGrid()])),
                          const SizedBox(height: 32),
                          _premiumBanner(),
                          const SizedBox(height: 32),
                          _sectionTitle(selectedCategory == 'Accueil' ? 'Nouveautés Exclusives' : 'Nouveautés $selectedCategory'),
                          const SizedBox(height: 16),
                          _nouveautes(),
                          const SizedBox(height: 32),
                          _sectionTitle('À venir • Bientôt disponible', icon: Icons.schedule_rounded),
                          const SizedBox(height: 16),
                          _aVenir(),
                          const SizedBox(height: 140),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
            ]),
          ),
          bottomNavigationBar: _bottomNav(),
          extendBody: true,
        );
      },
    );
  }

  Widget _skeleton() => ListView(padding: const EdgeInsets.all(16), children: [Row(children: [Container(height: 36, width: 36, decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(10))), const SizedBox(width: 12), Container(height: 20, width: 120, decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(6)))]), const SizedBox(height: 24), Container(height: 520, decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(24)))]);
  Widget _header() => ClipRRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24), child: Container(decoration: BoxDecoration(color: kBg.withOpacity(0.75), border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06)))), padding: const EdgeInsets.fromLTRB(16, 12, 16, 12), child: Row(children: [Container(width: 36, height: 36, decoration: BoxDecoration(gradient: const LinearGradient(colors: [kViolet, kVioletDark]), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.play_arrow_rounded, size: 22, color: Colors.white)), const SizedBox(width: 10), const Text.rich(TextSpan(children: [TextSpan(text: 'THIX ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19, color: Colors.white)), TextSpan(text: 'MEDIA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19, color: kViolet))])), const Spacer(), _iconBtn(Icons.search_rounded, () => setState(() => _isSearchVisible = !_isSearchVisible), isActive: _isSearchVisible)]))));
  Widget _iconBtn(IconData icon, VoidCallback onTap, {bool hasBg = false, bool isActive = false}) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Container(width: 38, height: 38, decoration: BoxDecoration(color: isActive ? kViolet : hasBg ? kSurface : kSurface.withOpacity(0.8), borderRadius: BorderRadius.circular(12), border: Border.all(color: isActive ? kViolet : Colors.white.withOpacity(0.08))), child: Icon(icon, size: 20, color: isActive ? Colors.white : kTextWhite)));
  Widget _searchBar() => Container(color: kBg, padding: const EdgeInsets.fromLTRB(16, 0, 16, 14), child: Container(height: 50, padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: kViolet.withOpacity(0.3))), child: Row(children: [const Icon(Icons.search_rounded, size: 20, color: kTextGrey), const SizedBox(width: 12), Expanded(child: TextField(controller: _searchController, focusNode: _searchFocusNode, autofocus: true, onChanged: _onSearchChanged, style: const TextStyle(fontSize: 14.5, color: kTextWhite), decoration: const InputDecoration(hintText: 'Films, séries...', border: InputBorder.none, hintStyle: TextStyle(fontSize: 14, color: kTextGrey), isDense: true)))])));
  
  Widget _bannerCinema(List<MediaContent> bannerItems) => Column(children: [SizedBox(height: 540, child: PageView.builder(controller: _bannerController, onPageChanged: (i) => setState(() => _currentBannerIndex = i), itemCount: bannerItems.length, itemBuilder: (context, idx) { final item = bannerItems[idx]; final isCenter = idx == _currentBannerIndex; return AnimatedScale(duration: const Duration(milliseconds: 500), scale: isCenter ? 1.0 : 0.94, child: AnimatedContainer(duration: const Duration(milliseconds: 500), margin: EdgeInsets.symmetric(horizontal: 6, vertical: isCenter ? 0 : 16), child: GestureDetector(onTap: () => _navigateToVideo(item), child: ClipRRect(borderRadius: BorderRadius.circular(24), child: Stack(fit: StackFit.expand, children: [
    _buildImage(item.coverUrl), // Remplacement ici
    Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.2), Colors.transparent, Colors.black.withOpacity(0.95)]))), Positioned(bottom: 0, left: 0, right: 0, child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.title.toUpperCase(), maxLines: 2, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)), const SizedBox(height: 10), Text('${item.type} • ${item.year ?? 2024}', style: const TextStyle(fontSize: 12, color: Colors.white70)), const SizedBox(height: 18), ElevatedButton.icon(onPressed: () => _navigateToVideo(item), icon: const Icon(Icons.play_arrow_rounded, color: Colors.black), label: const Text('Lecture', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, minimumSize: const Size(0, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))])))]))))); })), const SizedBox(height: 16), Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(bannerItems.length, (i) { final active = i == _currentBannerIndex; return AnimatedContainer(duration: const Duration(milliseconds: 300), margin: const EdgeInsets.symmetric(horizontal: 4), width: active ? 28 : 6, height: 6, decoration: BoxDecoration(color: active ? kViolet : Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(10))); }))]);
  
  Widget _sectionTitle(String title, {IconData? icon, Color iconColor = kViolet}) => Row(children: [if (icon != null) Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: iconColor)), if (icon != null) const SizedBox(width: 10), Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kTextWhite))]);
  
  Widget _categorySection() { final allMedia = ref.watch(filteredBaseProvider); final selectedCategory = ref.watch(selectedCategoryProvider); final cats = [{'label': 'Action', 'type': 'Films', 'color': kViolet}, {'label': 'Aventure', 'type': 'Séries', 'color': const Color(0xFF10B981)}, {'label': 'Comédie', 'type': 'Vidéos', 'color': const Color(0xFFF59E0B)}, {'label': 'Musique', 'type': 'Musique', 'color': kViolet}]; return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_sectionTitle('Explorer par univers'), const SizedBox(height: 16), SizedBox(height: 100, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: cats.length, separatorBuilder: (_, __) => const SizedBox(width: 12), itemBuilder: (context, i) { final cat = cats[i]; final selected = selectedCategory == cat['type']; final img = allMedia.where((e) => e.type == cat['type']).isNotEmpty ? allMedia.where((e) => e.type == cat['type']).first.coverUrl : ''; return GestureDetector(onTap: () => _goToCategoryAndScroll(cat['type'] as String), child: Container(width: 150, decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: selected ? (cat['color'] as Color) : Colors.white.withOpacity(0.08), width: selected ? 1.5 : 1)), child: ClipRRect(borderRadius: BorderRadius.circular(15), child: Stack(fit: StackFit.expand, children: [
    if (img.isNotEmpty) _buildImage(img) else Container(color: kSurface), // Remplacement ici
    Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [(cat['color'] as Color).withOpacity(0.65), Colors.black.withOpacity(0.85)]))), Center(child: Text(cat['label'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)))])))); }))]); }
  
  Widget _tendances() { final trending = ref.watch(trendingProvider); if (trending.isEmpty) return const Text('Aucune tendance', style: TextStyle(color: kTextGrey)); return SizedBox(height: 220, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: trending.length, separatorBuilder: (_, __) => const SizedBox(width: 18), itemBuilder: (context, i) { final item = trending[i]; return GestureDetector(onTap: () => _navigateToVideo(item), child: ClipRRect(borderRadius: BorderRadius.circular(16), child: 
    _buildImage(item.coverUrl, height: 200, width: 124) // Remplacement ici
  )); })); }
  
  Widget _recommandeGrid() { final list = ref.watch(recommendationsProvider); if (list.isEmpty) return Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(16)), child: const Center(child: Text('Aucun contenu', style: TextStyle(color: kTextGrey)))); return SizedBox(height: 252, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: list.length, separatorBuilder: (_, __) => const SizedBox(width: 14), itemBuilder: (context, i) { final item = list[i]; return GestureDetector(onTap: () => _navigateToVideo(item), child: SizedBox(width: 138, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ClipRRect(borderRadius: BorderRadius.circular(14), child: 
    _buildImage(item.coverUrl, height: 190, width: 138) // Remplacement ici
  ), const SizedBox(height: 10), Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: kTextWhite))]))) ; })); }
  
  Widget _premiumBanner() => Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1E1A12), Color(0xFF17101E)]), borderRadius: BorderRadius.circular(21)), child: Row(children: [const Icon(Icons.workspace_premium_rounded, color: kGold), const SizedBox(width: 12), const Expanded(child: Text('THIX PREMIUM • 4K sans pub', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))), ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black), child: const Text('Upgrade'))]));
  
  Widget _nouveautes() { final list = ref.watch(newReleasesProvider); return SizedBox(height: 252, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: list.length, separatorBuilder: (_, __) => const SizedBox(width: 14), itemBuilder: (context, i) { final item = list[i]; return GestureDetector(onTap: () => _navigateToVideo(item), child: ClipRRect(borderRadius: BorderRadius.circular(14), child: 
    _buildImage(item.coverUrl, height: 190, width: 138) // Remplacement ici
  )); })); }
  
  Widget _aVenir() { final list = ref.watch(upcomingProvider); return SizedBox(height: 252, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: list.length, separatorBuilder: (_, __) => const SizedBox(width: 14), itemBuilder: (context, i) { final item = list[i]; return ClipRRect(borderRadius: BorderRadius.circular(14), child: 
    _buildImage(item.coverUrl, height: 190, width: 138) // Remplacement ici
  ); })); }
  
  Widget _bottomNav() => Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 20), child: ClipRRect(borderRadius: BorderRadius.circular(28), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30), child: Container(height: 70, decoration: BoxDecoration(color: const Color(0xFF12121A).withOpacity(0.88), borderRadius: BorderRadius.circular(28)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_navItem(Icons.home_rounded, 'Accueil', true, 0), _navItem(Icons.search_rounded, 'Rechercher', false, 1), _navItem(Icons.favorite_rounded, 'Favoris', false, 2), _navItem(Icons.person_rounded, 'Profil', false, 3)])))));
  
  Widget _navItem(IconData icon, String label, bool selected, int idx) => InkWell(onTap: () { if (idx == 0) { _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic); ref.read(selectedCategoryProvider.notifier).state = 'Accueil'; } if (idx == 3) context.go(AppRoutes.userDashboard); }, child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: selected ? kViolet : kTextGrey, size: 22), const SizedBox(height: 3), Text(label, style: TextStyle(fontSize: 9.5, color: selected ? kViolet : kTextGrey))]));
}
