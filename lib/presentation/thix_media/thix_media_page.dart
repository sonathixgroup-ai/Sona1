import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'video_player_page.dart';
import '../../models/media_content.dart';
import '../providers/thix_media_provider.dart';
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
  @override ConsumerState<ThixMediaPage> createState() => _ThixMediaPageState();
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

  @override void initState() {
    super.initState();
    _bannerController = PageController(viewportFraction: 0.90);
  }

  @override void dispose() {
    _bannerTimer?.cancel();
    _searchDebounce?.cancel();
    _bannerController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll(int count){
    _bannerTimer?.cancel();
    if(count==0) return;
    _bannerTimer = Timer.periodic(const Duration(seconds: 6), (_){
      if(!mounted ||!_bannerController.hasClients) return;
      final next = (_currentBannerIndex + 1) % count;
      _bannerController.animateToPage(next, duration: const Duration(milliseconds: 700), curve: Curves.easeOutCubic);
    });
  }

  void _onSearchChanged(String v){
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), (){
      ref.read(searchQueryProvider.notifier).state = v;
    });
  }

  void _goToCategoryAndScroll(String category){
    ref.read(selectedCategoryProvider.notifier).state = category;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _recommendationsKey.currentContext;
      if(ctx!=null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 600), curve: Curves.easeOutCubic, alignment: 0.02);
    });
  }

  void _navigateToVideo(MediaContent item){
    Navigator.push(context, MaterialPageRoute(builder: (_)=> VideoPlayerPage(title: item.title, videoUrl: item.videoUrl)));
  }

  @override Widget build(BuildContext context){
    final asyncMedia = ref.watch(thixMediaListProvider);
    final bannerItems = ref.watch(bannerItemsProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    // auto scroll quand banner change
    ref.listen(bannerItemsProvider, (prev, next){
      if(next.isNotEmpty) _startAutoScroll(next.length);
    });

    return asyncMedia.when(
      loading: ()=> Scaffold(backgroundColor: kBg, body: _skeleton()),
      error: (e,st)=> Scaffold(backgroundColor: kBg, body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.error_outline, color: kTextGrey, size: 40), const SizedBox(height: 12), Text('Erreur: $e', style: const TextStyle(color: kTextGrey)), const SizedBox(height: 20), ElevatedButton(onPressed: ()=> ref.read(thixMediaListProvider.notifier).refresh(), style: ElevatedButton.styleFrom(backgroundColor: kViolet, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Réessayer'))]))),
      data: (_){
        return Scaffold(
          backgroundColor: kBg,
          body: SafeArea(
            bottom: false,
            child: Column(children: [
              _header(),
              AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: _isSearchVisible? _searchBar() : const SizedBox.shrink()),
              Expanded(child: RefreshIndicator(
                color: kViolet, backgroundColor: kSurface,
                onRefresh: ()=> ref.read(thixMediaListProvider.notifier).refresh(),
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  slivers: [
                    if(selectedCategory=='Accueil' && bannerItems.isNotEmpty) SliverToBoxAdapter(child: _bannerCinema(bannerItems)),
                    SliverToBoxAdapter(child: const SizedBox(height: 28)),
                    SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 16), sliver: SliverList.list(children: [
                      _categorySection(),
                      const SizedBox(height: 32),
                      if(selectedCategory=='Accueil')...[
                        _sectionTitle('Tendances • Top 10 Mondial', icon: Icons.local_fire_department_rounded, iconColor: kViolet),
                        const SizedBox(height: 16),
                        _tendances(),
                        const SizedBox(height: 32),
                      ],
                      Container(key: _recommendationsKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _sectionTitle(selectedCategory=='Accueil'? 'Recommandé pour vous' : selectedCategory),
                        const SizedBox(height: 16),
                        _recommandeGrid(),
                      ])),
                      const SizedBox(height: 32),
                      _premiumBanner(),
                      const SizedBox(height: 32),
                      _sectionTitle(selectedCategory=='Accueil'? 'Nouveautés Exclusives' : 'Nouveautés $selectedCategory'),
                      const SizedBox(height: 16),
                      _nouveautes(),
                      const SizedBox(height: 32),
                      _sectionTitle('À venir • Bientôt disponible', icon: Icons.schedule_rounded),
                      const SizedBox(height: 16),
                      _aVenir(),
                      const SizedBox(height: 140),
                    ])),
                  ],
                ),
              )),
            ]),
          ),
          bottomNavigationBar: _bottomNav(),
          extendBody: true,
        );
      },
    );
  }

  // ====== UI IDENTIQUE (pas touché) ======
  Widget _skeleton()=> ListView(padding: const EdgeInsets.all(16), children: [Row(children: [Container(height: 36, width: 36, decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(10))), const SizedBox(width: 12), Container(height: 20, width: 120, decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(6)))]), const SizedBox(height: 24), Container(height: 520, decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(24))), const SizedBox(height: 24), Container(height: 90, decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(16)))]);

  Widget _header()=> ClipRRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24), child: Container(decoration: BoxDecoration(color: kBg.withOpacity(0.75), border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06)))), padding: const EdgeInsets.fromLTRB(16,12,16,12), child: Row(children: [
    Container(width: 36, height: 36, decoration: BoxDecoration(gradient: const LinearGradient(colors: [kViolet, kVioletDark]), borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: kViolet.withOpacity(0.35), blurRadius: 14, offset: const Offset(0,4))]), child: const Icon(Icons.play_arrow_rounded, size: 22, color: Colors.white)),
    const SizedBox(width: 10),
    const Text.rich(TextSpan(children: [TextSpan(text: 'THIX ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19, color: Colors.white, letterSpacing: 1.0)), TextSpan(text: 'MEDIA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19, color: kViolet, letterSpacing: 1.0))])),
    const Spacer(),
    _iconBtn(Icons.search_rounded, ()=> setState(()=> _isSearchVisible=!_isSearchVisible), isActive: _isSearchVisible),
    const SizedBox(width: 10),
    Stack(clipBehavior: Clip.none, children: [_iconBtn(Icons.notifications_none_rounded, (){}, hasBg: true), Positioned(top: -3, right: -3, child: Container(width: 16, height: 16, decoration: BoxDecoration(color: kViolet, shape: BoxShape.circle, border: Border.all(color: kBg, width: 2)), child: const Center(child: Text('3', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white)))))]),
    const SizedBox(width: 10),
    Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5)), child: Container(margin: const EdgeInsets.all(2), decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [kGold, kGold2])), child: const Icon(Icons.person_rounded, size: 18, color: Colors.black))),
  ]))));

  Widget _iconBtn(IconData icon, VoidCallback onTap, {bool hasBg=false, bool isActive=false})=> InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Container(width: 38, height: 38, decoration: BoxDecoration(color: isActive? kViolet : hasBg? kSurface : kSurface.withOpacity(0.8), borderRadius: BorderRadius.circular(12), border: Border.all(color: isActive? kViolet : Colors.white.withOpacity(0.08))), child: Icon(icon, size: 20, color: isActive? Colors.white : kTextWhite)));

  Widget _searchBar()=> Container(color: kBg, padding: const EdgeInsets.fromLTRB(16,0,16,14), child: Container(height: 50, padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: kViolet.withOpacity(0.3))), child: Row(children: [
    const Icon(Icons.search_rounded, size: 20, color: kTextGrey),
    const SizedBox(width: 12),
    Expanded(child: TextField(controller: _searchController, focusNode: _searchFocusNode, autofocus: true, onChanged: _onSearchChanged, style: const TextStyle(fontSize: 14.5, color: kTextWhite, fontWeight: FontWeight.w500), decoration: const InputDecoration(hintText: 'Films, séries, demander à l\'IA...', border: InputBorder.none, hintStyle: TextStyle(fontSize: 14, color: kTextGrey), isDense: true))),
    Consumer(builder: (c, ref, _){ final q = ref.watch(searchQueryProvider); return q.isNotEmpty? GestureDetector(onTap: (){_searchController.clear(); ref.read(searchQueryProvider.notifier).state='';}, child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: kSurfaceLight, shape: BoxShape.circle), child: const Icon(Icons.close_rounded, size: 14, color: kTextGrey))) : const SizedBox.shrink(); }),
  ])));

  Widget _bannerCinema(List<MediaContent> bannerItems)=> Column(children: [
    SizedBox(height: 540, child: PageView.builder(controller: _bannerController, onPageChanged: (i)=> setState(()=> _currentBannerIndex=i), itemCount: bannerItems.length, itemBuilder: (context, idx){
      final item = bannerItems[idx];
      final isCenter = idx==_currentBannerIndex;
      return AnimatedScale(duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic, scale: isCenter?1.0:0.94, child: AnimatedContainer(duration: const Duration(milliseconds: 500), margin: EdgeInsets.symmetric(horizontal: 6, vertical: isCenter?0:16), child: GestureDetector(onTap: ()=> _navigateToVideo(item), child: ClipRRect(borderRadius: BorderRadius.circular(24), child: Stack(fit: StackFit.expand, children: [
        CachedNetworkImage(imageUrl: item.coverUrl, fit: BoxFit.cover, placeholder: (_,__)=> Container(color: kSurface), errorWidget: (_,__,___)=> Container(color: kSurface)),
        Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.2), Colors.transparent, Colors.black.withOpacity(0.2), Colors.black.withOpacity(0.95)], stops: const [0,0.25,0.6,1]))),
        Positioned(top: 16, left: 16, right: 16, child: Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(gradient: const LinearGradient(colors: [kViolet, kVioletDark]), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: kViolet.withOpacity(0.4), blurRadius: 12)]), child: const Row(children: [Icon(Icons.bolt_rounded, size: 12, color: Colors.white), SizedBox(width: 4), Text('NOUVEAUTÉ ORIGINALE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.6))])), const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.15))), child: const Row(children: [Icon(Icons.hd_rounded, size: 14, color: Colors.white), SizedBox(width: 4), Text('4K', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white))]))])),
        Positioned(bottom: 0, left: 0, right: 0, child: Container(padding: const EdgeInsets.fromLTRB(20,20,20,20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if(item.rankPosition!=null && item.rankPosition!<=3) Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: kGold, borderRadius: BorderRadius.circular(6)), child: Text('TOP ${item.rankPosition} MONDIAL', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 0.5))),
          Text(item.title.toUpperCase(), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, height: 0.95, letterSpacing: -1.0, shadows: [Shadow(color: Colors.black87, blurRadius: 20)])),
          const SizedBox(height: 10),
          Row(children: [_badge('DOLBY VISION'), const SizedBox(width: 6), _badge('5.1'), const SizedBox(width: 10), Text('${item.type} • ${item.year??2024}', style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600)), const SizedBox(width: 8), const Icon(Icons.star_rounded, size: 14, color: kGold), const Text(' 4.9', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700))]),
          if(item.subtitle!=null && item.subtitle!.isNotEmpty)...[const SizedBox(height: 8), Text(item.subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Color(0xFFB8B8C0), height: 1.35, fontWeight: FontWeight.w400))],
          const SizedBox(height: 18),
          Row(children: [Expanded(child: ElevatedButton.icon(onPressed: ()=> _navigateToVideo(item), icon: const Icon(Icons.play_arrow_rounded, size: 22, color: Colors.black), label: const Text('Lecture', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black)), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, minimumSize: const Size(0,50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0))), const SizedBox(width: 12), _circleBtn(Icons.add_rounded), const SizedBox(width: 10), _circleBtn(Icons.info_outline_rounded)]),
        ])),
      ])))));
    })),
    const SizedBox(height: 16),
    Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(bannerItems.length, (i){ final active=i==_currentBannerIndex; return AnimatedContainer(duration: const Duration(milliseconds: 300), margin: const EdgeInsets.symmetric(horizontal: 4), width: active?28:6, height: 6, decoration: BoxDecoration(color: active? kViolet : Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(10), boxShadow: active? [BoxShadow(color: kViolet.withOpacity(0.5), blurRadius: 8)] : null)); })),
  ]);

  Widget _circleBtn(IconData icon)=> Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.18))), child: Icon(icon, color: Colors.white, size: 22));
  Widget _badge(String t)=> Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: Colors.white.withOpacity(0.16), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.white.withOpacity(0.2))), child: Text(t, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)));

  Widget _sectionTitle(String title, {IconData? icon, Color iconColor=kViolet})=> Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [if(icon!=null) Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: iconColor)), if(icon!=null) const SizedBox(width: 10), Text(title, style: const TextStyle(fontSize: 17.5, fontWeight: FontWeight.w800, color: kTextWhite, letterSpacing: -0.5))]), Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(20), border: Border.all(color: kBorderLight)), child: const Row(children: [Text('Voir tout', style: TextStyle(fontSize: 12, color: kTextGrey, fontWeight: FontWeight.w600)), SizedBox(width: 2), Icon(Icons.chevron_right_rounded, size: 14, color: kTextGrey)]))])]);

  Widget _categorySection(){
    final allMedia = ref.watch(filteredBaseProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final cats = [
      {'label': 'Action', 'type': 'Films', 'color': kViolet, 'icon': Icons.local_fire_department_rounded},
      {'label': 'Aventure', 'type': 'Séries', 'color': const Color(0xFF10B981), 'icon': Icons.explore_rounded},
      {'label': 'Comédie', 'type': 'Vidéos', 'color': const Color(0xFFF59E0B), 'icon': Icons.sentiment_very_satisfied_rounded},
      {'label': 'Musique', 'type': 'Musique', 'color': kViolet, 'icon': Icons.music_note_rounded},
      {'label': 'Live', 'type': 'En direct', 'color': kViolet, 'icon': Icons.sensors_rounded},
      {'label': 'Premium', 'type': 'Playlists', 'color': kGold, 'icon': Icons.workspace_premium_rounded},
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Explorer par univers'),
      const SizedBox(height: 16),
      SizedBox(height: 100, child: ListView.separated(scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(), itemCount: cats.length, separatorBuilder: (_,__)=> const SizedBox(width: 12), itemBuilder: (context,i){
        final cat = cats[i];
        final selected = selectedCategory==cat['type'];
        final img = allMedia.where((e)=> e.type==cat['type']).isNotEmpty? allMedia.where((e)=> e.type==cat['type']).first.coverUrl : (allMedia.isNotEmpty? allMedia[i % allMedia.length].coverUrl : '');
        return GestureDetector(onTap: ()=> _goToCategoryAndScroll(cat['type'] as String), child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: 150, decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: selected? (cat['color'] as Color) : Colors.white.withOpacity(0.08), width: selected?1.5:1), boxShadow: selected? [BoxShadow(color: (cat['color'] as Color).withOpacity(0.25), blurRadius: 16)] : null), child: ClipRRect(borderRadius: BorderRadius.circular(15), child: Stack(fit: StackFit.expand, children: [
          if(img.isNotEmpty) CachedNetworkImage(imageUrl: img, fit: BoxFit.cover, memCacheWidth: 300) else Container(color: kSurface),
          Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [(cat['color'] as Color).withOpacity(0.65), Colors.black.withOpacity(0.85)]))),
          Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), shape: BoxShape.circle), child: Icon(cat['icon'] as IconData, color: Colors.white, size: 20)), const SizedBox(height: 8), Text(cat['label'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13))])),
          if(selected) Positioned(top: 8, right: 8, child: Container(width: 8, height: 8, decoration: BoxDecoration(color: cat['color'] as Color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: cat['color'] as Color, blurRadius: 6)]))),
        ]))));
      })),
    ]);
  }

  Widget _tendances(){
    final trending = ref.watch(trendingProvider);
    if(trending.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('Aucune tendance', style: TextStyle(color: kTextGrey)));
    return SizedBox(height: 220, child: ListView.separated(scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(), itemCount: trending.length, separatorBuilder: (_,__)=> const SizedBox(width: 18), itemBuilder: (context,i){
      final item = trending[i];
      return GestureDetector(onTap: ()=> _navigateToVideo(item), child: SizedBox(width: 150, child: Stack(clipBehavior: Clip.none, children: [
        Positioned(left: -12, bottom: 4, child: Text('${item.rankPosition?? i+1}', style: TextStyle(fontSize: 96, fontWeight: FontWeight.w900, height: 0.8, foreground: Paint()..style=PaintingStyle.stroke..strokeWidth=1.2..color=Colors.white.withOpacity(0.14), shadows: [Shadow(color: kViolet.withOpacity(0.2), blurRadius: 20)]))),
        Positioned(right: 0, child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 16, offset: const Offset(0,8))]), child: ClipRRect(borderRadius: BorderRadius.circular(16), child: CachedNetworkImage(imageUrl: item.coverUrl, height: 200, width: 124, fit: BoxFit.cover, memCacheWidth: 250)))),
        Positioned(right: 0, bottom: 0, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: kViolet, borderRadius: BorderRadius.circular(8)), child: Text('TOP ${item.rankPosition?? i+1}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white)))),
      ])));
    }));
  }

  Widget _recommandeGrid(){
    final list = ref.watch(recommendationsProvider);
    if(list.isEmpty) return Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(16)), child: const Center(child: Text('Aucun contenu', style: TextStyle(color: kTextGrey))));
    return SizedBox(height: 252, child: ListView.separated(scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(), itemCount: list.length, separatorBuilder: (_,__)=> const SizedBox(width: 14), itemBuilder: (context,i){
      final item=list[i];
      return GestureDetector(onTap: ()=> _navigateToVideo(item), child: SizedBox(width: 138, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(children: [Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0,6))]), child: ClipRRect(borderRadius: BorderRadius.circular(14), child: CachedNetworkImage(imageUrl: item.coverUrl, height: 190, width: 138, fit: BoxFit.cover, memCacheWidth: 300))), if(item.isNewRelease) Positioned(top: 8, left: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(gradient: const LinearGradient(colors: [kViolet, kVioletDark]), borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: kViolet.withOpacity(0.4), blurRadius: 8)]), child: const Text('NOUVEAU', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white)))), Positioned(bottom: 8, right: 8, child: ClipRRect(borderRadius: BorderRadius.circular(20), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle), child: const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white)))))]),
        const SizedBox(height: 10),
        Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: kTextWhite)),
        const SizedBox(height: 2),
        Row(children: [Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)), const SizedBox(width: 5), Text('${item.type} • ${item.year??2024}', style: const TextStyle(fontSize: 10.5, color: kTextGrey))]),
      ])));
    }));
  }

  Widget _premiumBanner()=> Container(padding: const EdgeInsets.all(1.2), decoration: BoxDecoration(gradient: const LinearGradient(colors: [kGold, kGold2, kViolet, kVioletDark]), borderRadius: BorderRadius.circular(22)), child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18), decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1E1A12), Color(0xFF17101E)]), borderRadius: BorderRadius.circular(21)), child: Row(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(gradient: const LinearGradient(colors: [kGold, kGold2]), shape: BoxShape.circle, boxShadow: [BoxShadow(color: kGold.withOpacity(0.4), blurRadius: 16)]), child: const Icon(Icons.workspace_premium_rounded, color: Colors.black, size: 22)), const SizedBox(width: 16), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Text('THIX MEDIA ', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Colors.white)), Text('PREMIUM', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: kGold))]), SizedBox(height: 4), Text('4K • Sans pub • Offline • Dolby Atmos • Enterprise', style: TextStyle(fontSize: 11.5, color: kTextGrey))])), ElevatedButton(onPressed: (){}, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, minimumSize: const Size(0,40), padding: const EdgeInsets.symmetric(horizontal: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 0), child: const Text('Upgrade', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800))) ])));

  Widget _nouveautes(){
    final list = ref.watch(newReleasesProvider);
    if(list.isEmpty) return const Text('Aucune nouveauté', style: TextStyle(color: kTextGrey));
    return SizedBox(height: 252, child: ListView.separated(scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(), itemCount: list.length, separatorBuilder: (_,__)=> const SizedBox(width: 14), itemBuilder: (context,i){ final item=list[i]; return GestureDetector(onTap: ()=> _navigateToVideo(item), child: SizedBox(width: 138, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ClipRRect(borderRadius: BorderRadius.circular(14), child: CachedNetworkImage(imageUrl: item.coverUrl, height: 190, width: 138, fit: BoxFit.cover, memCacheWidth: 300)), const SizedBox(height: 10), Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: kTextWhite))]))); }));
  }

  Widget _aVenir(){
    final list = ref.watch(upcomingProvider);
    if(list.isEmpty) return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(16)), child: const Center(child: Text('Bientôt...', style: TextStyle(color: kTextGrey))));
    return SizedBox(height: 252, child: ListView.separated(scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(), itemCount: list.length, separatorBuilder: (_,__)=> const SizedBox(width: 14), itemBuilder: (context,i){ final item=list[i]; return GestureDetector(onTap: ()=> _navigateToVideo(item), child: SizedBox(width: 138, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Stack(children: [ClipRRect(borderRadius: BorderRadius.circular(14), child: ColorFiltered(colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.darken), child: CachedNetworkImage(imageUrl: item.coverUrl, height: 190, width: 138, fit: BoxFit.cover, memCacheWidth: 300))), Positioned.fill(child: Center(child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.92), shape: BoxShape.circle), child: const Icon(Icons.schedule_rounded, size: 20, color: kViolet)))), Positioned(top: 8, left: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: const Text('À VENIR', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.black))))]), const SizedBox(height: 10), Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: kTextWhite))]))); }));
  }

  Widget _bottomNav()=> Padding(padding: const EdgeInsets.fromLTRB(16,0,16,20), child: ClipRRect(borderRadius: BorderRadius.circular(28), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30), child: Container(height: 70, decoration: BoxDecoration(color: const Color(0xFF12121A).withOpacity(0.88), borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white.withOpacity(0.08)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 30, offset: const Offset(0,12))]), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
    _navItem(Icons.home_rounded, 'Accueil', true, 0),
    _navItem(Icons.search_rounded, 'Rechercher', false, 1),
    _liveCenter(),
    _navItem(Icons.favorite_rounded, 'Favoris', false, 2),
    _navItem(Icons.person_rounded, 'Profil', false, 3),
  ])))));

  Widget _liveCenter()=> GestureDetector(onTap: ()=> _goToCategoryAndScroll('En direct'), child: Column(mainAxisSize: MainAxisSize.min, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9), decoration: BoxDecoration(gradient: const LinearGradient(colors: [kViolet, kVioletDark]), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: kViolet.withOpacity(0.45), blurRadius: 18, offset: const Offset(0,6))]), child: Row(children: [Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)), const SizedBox(width: 7), const Text('LIVE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.8))])), const SizedBox(height: 4), const Text('Direct', style: TextStyle(fontSize: 9.5, color: kViolet, fontWeight: FontWeight.w700))]));

  Widget _navItem(IconData icon, String label, bool selected, int idx)=> InkWell(borderRadius: BorderRadius.circular(16), onTap: (){ if(idx==0){_scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic); ref.read(selectedCategoryProvider.notifier).state='Accueil';} if(idx==1){setState(()=> _isSearchVisible=true); FocusScope.of(context).requestFocus(_searchFocusNode);} if(idx==3) context.go(AppRoutes.userDashboard); }, child: Column(mainAxisSize: MainAxisSize.min, children: [AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: selected? kViolet.withOpacity(0.15) : Colors.transparent, borderRadius: BorderRadius.circular(12), border: Border.all(color: selected? kViolet.withOpacity(0.2) : Colors.transparent)), child: Icon(icon, color: selected? kViolet : kTextGrey, size: 22)), const SizedBox(height: 3), Text(label, style: TextStyle(fontSize: 9.5, color: selected? kViolet : kTextGrey, fontWeight: selected? FontWeight.w800 : FontWeight.w500))]));
}
