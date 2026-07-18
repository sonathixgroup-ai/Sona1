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

// ===== CHARTE THIX MEDIA =====
const Color kBg = Color(0xFFF9F8FD);
const Color kNavyDeep = Color(0xFF0F0A24);
const Color kViolet = Color(0xFF7C5CFC);
const Color kVioletDark = Color(0xFF5B3DE0);
const Color kSoftViolet = Color(0xFFF1EDFF);
const Color kRedLive = Color(0xFFE5484D);
const Color kTextBlack = Color(0xFF14101F);
const Color kTextGrey = Color(0xFF8A8696);
const Color kBorderLight = Color(0xFFEEEAF8);
const Color kGreen = Color(0xFF1FA97C);
const Color kOrange = Color(0xFFE67E22);

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
      if (!mounted ||!_bannerController.hasClients) return;
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
      base = base.where((m) => m.title.toLowerCase().contains(q) || (m.subtitle?.toLowerCase().contains(q)?? false));
    }
    setState(() {
      _bannerItems = base.where((m) => m.isNewRelease).toList();
      _filteredTrending = base.where((item) => item.rankPosition!= null).toList();
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
    if (_error!= null) return Scaffold(backgroundColor: kBg, body: Center(child: Text('Erreur : $_error', style: const TextStyle(color: kTextGrey))));

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopHeader(),
              _buildCategoryTabs(),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedCategory == 'Accueil' && _bannerItems.isNotEmpty) _buildBannerCinema(),
                    const SizedBox(height: 14),
                    _buildQuickAccessRow(),
                    const SizedBox(height: 22),
                    if (_selectedCategory == 'Accueil')...[
                      _buildSectionTitle('Tendances', icon: Icons.trending_up_rounded),
                      const SizedBox(height: 10),
                      _buildTendances(),
                      const SizedBox(height: 22),
                    ],
                    Container(
                      key: _recommendationsKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(_selectedCategory == 'Accueil'? 'Recommandé pour vous' : _selectedCategory),
                          const SizedBox(height: 10),
                          _buildRecommandeGrid(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    _buildPremiumBanner(),
                    const SizedBox(height: 22),
                    _buildSectionTitle(_selectedCategory == 'Accueil'? 'Nouveautés' : 'Nouveautés ($_selectedCategory)'),
                    const SizedBox(height: 10),
                    _buildNouveautes(),
                    const SizedBox(height: 22),
                    _buildSectionTitle('À venir'),
                    const SizedBox(height: 10),
                    _buildAVenir(),
                    const SizedBox(height: 90),
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

  // ===== HEADER AVEC CERCLE ADMIN BLANC =====
  Widget _buildTopHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(10, 8, 12, 10),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: kBorderLight)),
            child: const Icon(Icons.menu_rounded, size: 18, color: kTextBlack),
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
                TextSpan(text: 'THIX ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: kTextBlack, letterSpacing: 0.3)),
                TextSpan(text: 'MEDIA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: kViolet, letterSpacing: 0.3)),
              ])),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(color: const Color(0xFFF5F3FB), borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, size: 16, color: kTextGrey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: _onSearchChanged,
                      style: const TextStyle(fontSize: 11, color: kTextBlack),
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
          // NOTIF
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: const Color(0xFFF5F3FB), shape: BoxShape.circle),
                child: const Icon(Icons.notifications_none_rounded, size: 18, color: kTextBlack),
              ),
              Positioned(top: -2, right: -2, child: Container(
                width: 14, height: 14,
                decoration: const BoxDecoration(color: kRedLive, shape: BoxShape.circle),
                child: const Center(child: Text('3', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800))),
              )),
            ],
          ),
          const SizedBox(width: 8),
          // CERCLE BLANC ADMIN - connecté comme avant
          InkWell(
            onTap: () => context.pushNamed('thixMediaAdmin'),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: kBorderLight, width: 1.2),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
              ),
              child: const Icon(Icons.person_outline_rounded, size: 16, color: kTextBlack),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final tabs = [
      {'label':'Accueil','icon':Icons.home_rounded},
      {'label':'Vidéos','icon':Icons.play_circle_outline_rounded},
      {'label':'Films','icon':Icons.movie_creation_outlined},
      {'label':'Séries','icon':Icons.live_tv_rounded},
      {'label':'Musique','icon':Icons.music_note_rounded},
      {'label':'Playlists','icon':Icons.queue_music_rounded},
      {'label':'En direct','icon':Icons.sensors_rounded},
    ];
    return Container(
      color: Colors.white,
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        physics: const BouncingScrollPhysics(),
        itemCount: tabs.length,
        separatorBuilder: (_,__)=> const SizedBox(width: 8),
        itemBuilder: (context,i){
          final t = tabs[i];
          final selected = _selectedCategory == t['label'];
          return GestureDetector(
            onTap: ()=> setState(()=> _selectedCategory = t['label'] as String),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: selected? kViolet : const Color(0xFFF5F3FB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(t['icon'] as IconData, size: 14, color: selected? Colors.white : kTextGrey),
                  const SizedBox(width: 5),
                  Text(t['label'] as String, style: TextStyle(fontSize: 11, fontWeight: selected? FontWeight.w700: FontWeight.w500, color: selected? Colors.white: kTextBlack)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // BANNER 100% DYNAMIQUE SUPABASE - PAS DE MOCK
  Widget _buildBannerCinema() {
    return Column(
      children: [
        SizedBox(
          height: 184,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: PageView.builder(
              controller: _bannerController,
              onPageChanged: (i)=> setState(()=> _currentBannerIndex = i),
              itemCount: _bannerItems.length,
              itemBuilder: (context, idx){
                final item = _bannerItems[idx];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(imageUrl: item.coverUrl, fit: BoxFit.cover, placeholder: (_,__)=> Container(color: kSoftViolet), errorWidget: (_,__,___)=> Container(color: kSoftViolet)),
                    Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerRight, end: Alignment.centerLeft, colors: [Colors.transparent, kNavyDeep.withOpacity(0.92)]))),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: kViolet, borderRadius: BorderRadius.circular(12)),
                            child: const Text('NOUVEAUTÉ', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
                          ),
                          const SizedBox(height: 8),
                          // TITRE DYNAMIQUE DE SUPABASE
                          Text(item.title.toUpperCase(), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
                          if(item.subtitle!= null && item.subtitle!.isNotEmpty)...[
                            const SizedBox(height: 2),
                            Text(item.subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.white70, height: 1.2)),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: ()=> _navigateToVideo(item),
                                icon: const Icon(Icons.play_arrow_rounded, size: 14),
                                label: const Text('Regarder maintenant', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                                style: ElevatedButton.styleFrom(backgroundColor: kViolet, foregroundColor: Colors.white, minimumSize: const Size(0, 30), padding: const EdgeInsets.symmetric(horizontal: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: (){},
                                icon: const Icon(Icons.add_rounded, size: 12, color: Colors.white),
                                label: const Text('Ma liste', style: TextStyle(fontSize: 10, color: Colors.white)),
                                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white54), minimumSize: const Size(0,30), padding: const EdgeInsets.symmetric(horizontal: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
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
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_bannerItems.length, (i)=> AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            width: _currentBannerIndex==i? 16:6, height: 5,
            decoration: BoxDecoration(color: _currentBannerIndex==i? kViolet : kSoftViolet, borderRadius: BorderRadius.circular(3)),
          )),
        ),
      ],
    );
  }

  Widget _buildQuickAccessRow() {
    final items = [
      {'label':'Vidéos','icon':Icons.play_circle_fill_rounded,'color':kRedLive},
      {'label':'Films','icon':Icons.movie_filter_rounded,'color':kViolet},
      {'label':'Séries','icon':Icons.live_tv_rounded,'color':kGreen},
      {'label':'Musique','icon':Icons.music_note_rounded,'color':kOrange},
      {'label':'En direct','icon':Icons.sensors_rounded,'color':kRedLive},
      {'label':'Genres','icon':Icons.grid_view_rounded,'color':kViolet},
    ];
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_,__)=> const SizedBox(width: 18),
        itemBuilder: (context,i){
          final it = items[i];
          return GestureDetector(
            onTap: ()=> _goToCategoryAndScroll(it['label'] as String),
            child: Column(
              children: [
                Container(width: 42, height: 42, decoration: BoxDecoration(color: (it['color'] as Color).withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Icon(it['icon'] as IconData, color: it['color'] as Color, size: 20)),
                const SizedBox(height: 5),
                Text(it['label'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kTextBlack)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title,{IconData? icon}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          if(icon!=null) Icon(icon,size: 14,color: kViolet),
          if(icon!=null) const SizedBox(width: 4),
          Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: kTextBlack)),
        ]),
        Row(children: const [Text('Voir tout', style: TextStyle(fontSize: 10.5, color: kTextGrey, fontWeight: FontWeight.w600)), SizedBox(width: 2), Icon(Icons.chevron_right_rounded,size: 14,color: kTextGrey)]),
      ],
    );
  }

  Widget _buildTendances() {
    if(_filteredTrending.isEmpty) return const Text('Aucune tendance', style: TextStyle(fontSize: 11, color: kTextGrey));
    return SizedBox(
      height: 132,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filteredTrending.length,
        itemBuilder: (context,i){
          final item = _filteredTrending[i];
          return GestureDetector(
            onTap: ()=> _navigateToVideo(item),
            child: Container(
              width: 148, margin: EdgeInsets.only(right: i==_filteredTrending.length-1?0:10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorderLight)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), child: CachedNetworkImage(imageUrl: item.coverUrl, height: 76, width: 148, fit: BoxFit.cover)),
                      Positioned(top: 6, left: 6, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: kViolet, borderRadius: BorderRadius.circular(10)), child: Text('#${item.rankPosition??i+1}', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white)))),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8,6,6,4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: kTextBlack)),
                        const SizedBox(height: 2),
                        Text('${item.type} • ${item.year??''}', maxLines: 1, style: const TextStyle(fontSize: 9, color: kTextGrey)),
                      ],
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

  Widget _buildRecommandeGrid() {
    final list = _filteredRecommendations.where((e)=> _selectedCategory=='Accueil'? true: e.type==_selectedCategory).toList();
    if(list.isEmpty) return const Text('Aucun contenu', style: TextStyle(fontSize: 11, color: kTextGrey));
    return SizedBox(
      height: 148,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: list.length,
        itemBuilder: (context,i){
          final item = list[i];
          return GestureDetector(
            onTap: ()=> _navigateToVideo(item),
            child: Container(
              width: 108, margin: EdgeInsets.only(right: i==list.length-1?0:10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(children: [
                    ClipRRect(borderRadius: BorderRadius.circular(10), child: CachedNetworkImage(imageUrl: item.coverUrl, height: 112, width: 108, fit: BoxFit.cover)),
                    if(item.isNewRelease) Positioned(top: 6, left: 6, child: Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: BoxDecoration(color: kRedLive, borderRadius: BorderRadius.circular(6)), child: const Text('NOUVEAU', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w800, color: Colors.white)))),
                  ]),
                  const SizedBox(height: 5),
                  Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kTextBlack)),
                  Text('${item.type} • ${item.year??2024}', style: const TextStyle(fontSize: 8.5, color: kTextGrey)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPremiumBanner(){
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: kSoftViolet, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          const Text('👑', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('THIX MEDIA Premium', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: kVioletDark)),
            Text('Accédez à tout le contenu sans publicité, téléchargez et regardez hors ligne.', style: TextStyle(fontSize: 9, color: kTextGrey)),
          ])),
          ElevatedButton(onPressed: (){}, style: ElevatedButton.styleFrom(backgroundColor: kViolet, minimumSize: const Size(0,28), padding: const EdgeInsets.symmetric(horizontal: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: const Text('Passer Premium', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  Widget _buildNouveautes(){
    final list = _filteredNewReleases.where((e)=> _selectedCategory=='Accueil' || e.type==_selectedCategory).toList();
    if(list.isEmpty) return const Text('Aucune nouveauté', style: TextStyle(fontSize: 11, color: kTextGrey));
    return SizedBox(
      height: 148,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: list.length,
        itemBuilder: (context,i){
          final item = list[i];
          return GestureDetector(onTap: ()=> _navigateToVideo(item), child: Container(width: 108, margin: EdgeInsets.only(right: i==list.length-1?0:10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(borderRadius: BorderRadius.circular(10), child: CachedNetworkImage(imageUrl: item.coverUrl, height: 112, width: 108, fit: BoxFit.cover)),
            const SizedBox(height: 5),
            Text(item.title, maxLines: 1, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kTextBlack)),
            Text('${item.type} • ${item.year??2024}', style: const TextStyle(fontSize: 8.5, color: kTextGrey)),
          ])));
        },
      ),
    );
  }

  Widget _buildAVenir(){
    if(_filteredUpcoming.isEmpty) return const Text('Bientôt disponible...', style: TextStyle(fontSize: 11, color: kTextGrey));
    return SizedBox(
      height: 148,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filteredUpcoming.length,
        itemBuilder: (context,i){
          final item = _filteredUpcoming[i];
          return GestureDetector(
            onTap: ()=> _navigateToVideo(item),
            child: Container(width: 108, margin: const EdgeInsets.only(right: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Stack(children: [
                ClipRRect(borderRadius: BorderRadius.circular(10), child: ColorFiltered(colorFilter: const ColorFilter.mode(Colors.black38, BlendMode.darken), child: CachedNetworkImage(imageUrl: item.coverUrl, height: 112, width: 108, fit: BoxFit.cover))),
                Positioned.fill(child: Center(child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), shape: BoxShape.circle), child: const Icon(Icons.schedule_rounded, size: 16, color: kViolet)))),
                Positioned(top: 6, left: 6, child: Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: BoxDecoration(color: kTextBlack, borderRadius: BorderRadius.circular(6)), child: const Text('À VENIR', style: TextStyle(fontSize: 7, color: Colors.white, fontWeight: FontWeight.w800)))),
              ]),
              const SizedBox(height: 5),
              Text(item.title, maxLines: 1, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kTextBlack)),
              const Text('Bientôt', style: TextStyle(fontSize: 8.5, color: kTextGrey)),
            ])),
          );
        },
      ),
    );
  }

  Widget _buildBottomNavWithLive(){
    return Container(
      margin: const EdgeInsets.fromLTRB(14,0,14,10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), boxShadow: [BoxShadow(color: kNavyDeep.withOpacity(0.14), blurRadius: 22, offset: const Offset(0,9))]),
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

  Widget _liveCenterButton(){
    return GestureDetector(
      onTap: ()=> _goToCategoryAndScroll('En direct'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: kRedLive, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: kRedLive.withOpacity(0.35), blurRadius: 12)]),
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

  Widget _navItem(IconData icon, String label, bool selected, int idx){
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: (){
        if(idx==0){ _scrollController.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeOut); setState(()=> _selectedCategory='Accueil');}
        if(idx==1){ _scrollController.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeOut); FocusScope.of(context).requestFocus(_searchFocusNode);}
        if(idx==3) context.go(AppRoutes.userDashboard);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: selected? kSoftViolet: Colors.transparent, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: selected? kViolet: kTextGrey, size: 18)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 8.5, color: selected? kViolet: kTextGrey, fontWeight: selected? FontWeight.w800: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
