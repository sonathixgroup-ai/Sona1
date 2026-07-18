import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart'; // ✅ Cache des images
import 'video_player_page.dart';
import '../../models/media_content.dart';
import '../../services/media_service.dart';
import '../../app_router.dart';
import 'package:thix_id/nav.dart' show AppRoutes;
import 'admin/admin_guard.dart';

// ===== CHARTE THIX MEDIA — Violet renforcé =====
const Color kBackgroundColor = Color(0xFFF8F7FC);
const Color kNavyDeep = Color(0xFF120B2E); // fond sombre du banner (proche du screenshot)
const Color kNavy = Color(0xFF1B1140);
const Color kAccentColor = Color(0xFF7C5CFC); // violet principal
const Color kAccentDark = Color(0xFF5B3DE0); // violet profond (gradients / pressed)
const Color kSoftPurple = Color(0xFFF1EDFF); // fond léger violet pour sélections/hover
const Color kGold = Color(0xFFE3B23C); // réservé au badge ADMIN
const Color kHeaderIconColor = Color(0xFF9C8DC9);
const Color kTextDark = Color(0xFF15102B);
const Color kTextGrey = Color(0xFF7C7593);
const Color kBorder = Color(0xFFEAE6F7);

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
  final FocusNode _searchFocusNode = FocusNode(); // ✅ pour connecter le bouton "Rechercher" du bas
  Timer? _searchDebounce;

  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  // ✅ Scroll programmable + ancre pour amener l'utilisateur direct sur les résultats filtrés
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _recommendationsKey = GlobalKey();

  List<MediaContent> _bannerItems = [];
  List<MediaContent> _filteredTrending = [];
  List<MediaContent> _filteredRecommendations = [];
  List<MediaContent> _filteredNewReleases = [];

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

  // ✅ FIX : on ne retire plus les vidéos ici — l'exclusion "pas de doublon avec Tendances"
  // se fait uniquement à l'affichage, et seulement quand on est sur "Accueil".
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
    });
  }

  void _onSearchChanged(String value) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _searchQuery = value;
      _updateFilteredLists();
    });
  }

  void _onCategoryChanged(String category) {
    setState(() => _selectedCategory = category);
  }

  // ✅ Utilisé par les raccourcis (Vidéos, Films, Séries...) : change la catégorie ET
  // descend automatiquement jusqu'à la section Recommandations qui affiche les résultats.
  void _goToCategoryAndScroll(String category) {
    setState(() => _selectedCategory = category);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _recommendationsKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.05,
        );
      }
    });
  }

  void _focusSearchFromBottomNav() {
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_searchFocusNode);
    });
  }

  void _navigateToVideo(MediaContent item) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerPage(title: item.title, videoUrl: item.videoUrl)));
  }

  void _showAll(String section) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Voir tout : $section')));
  }

  void _openGenresSheet() {
    const genres = ['Vidéos', 'Films', 'Séries', 'Musique', 'Playlists', 'En direct'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Genres', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: kTextDark)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: genres.map((g) {
                  return _MediaChip(
                    label: g,
                    selected: _selectedCategory == g,
                    onTap: () {
                      Navigator.pop(context);
                      _goToCategoryAndScroll(g);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openMoreSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.playlist_add_check_rounded, color: kAccentColor),
              title: const Text('Ma liste'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.download_rounded, color: kAccentColor),
              title: const Text('Téléchargements'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.settings_rounded, color: kAccentColor),
              title: const Text('Paramètres THIX MEDIA'),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: kBackgroundColor, body: Center(child: CircularProgressIndicator(color: kAccentColor)));
    if (_error != null) return Scaffold(backgroundColor: kBackgroundColor, body: Center(child: Text('Erreur : $_error', style: const TextStyle(color: kTextGrey))));

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategoryChips(),
            const SizedBox(height: 16),
            _buildQuickAccessGrid(), // ✅ nouveau : raccourcis façon capture
            const SizedBox(height: 20),
            if (_selectedCategory == 'Accueil' && _bannerItems.isNotEmpty) ...[
              _buildCarouselBanner(),
              const SizedBox(height: 22),
            ],
            if (_selectedCategory == 'Accueil') ...[
              _SectionHeader(title: 'Tendances', showSeeAll: true, onSeeAll: () => _showAll('Tendances')),
              const SizedBox(height: 10),
              _TrendingList(items: _filteredTrending, onItemTap: _navigateToVideo),
              const SizedBox(height: 24),
            ],
            Container(
              key: _recommendationsKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    title: _selectedCategory == 'Accueil' ? 'Recommandé pour vous' : _selectedCategory,
                    showSeeAll: true,
                    onSeeAll: () => _showAll('Recommandations'),
                  ),
                  const SizedBox(height: 10),
                  _RecommendationGrid(
                    items: _filteredRecommendations.where((item) {
                      // Sur Accueil on évite le doublon avec Tendances (vidéos déjà affichées).
                      if (_selectedCategory == 'Accueil') return item.type != 'Vidéo';
                      return item.type == _selectedCategory;
                    }).toList(),
                    onItemTap: _navigateToVideo,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              title: _selectedCategory == 'Accueil' ? 'Nouveautés' : 'Nouveautés ($_selectedCategory)',
              showSeeAll: true,
              onSeeAll: () => _showAll('Nouveautés'),
            ),
            const SizedBox(height: 10),
            _NewReleasesGrid(
              items: _filteredNewReleases.where((item) => _selectedCategory == 'Accueil' || item.type == _selectedCategory).toList(),
              onItemTap: _navigateToVideo,
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // ===== Grille de raccourcis (façon capture) =====
  Widget _buildQuickAccessGrid() {
    final items = <_QuickAccessItem>[
      _QuickAccessItem('Vidéos', Icons.play_circle_fill_rounded, const Color(0xFFE5484D), () => _goToCategoryAndScroll('Vidéos')),
      _QuickAccessItem('Films', Icons.movie_rounded, kAccentColor, () => _goToCategoryAndScroll('Films')),
      _QuickAccessItem('Séries', Icons.tv_rounded, const Color(0xFF1FA97C), () => _goToCategoryAndScroll('Séries')),
      _QuickAccessItem('Musique', Icons.music_note_rounded, const Color(0xFFE39B3C), () => _goToCategoryAndScroll('Musique')),
      _QuickAccessItem('En direct', Icons.live_tv_rounded, const Color(0xFFE5484D), () => _goToCategoryAndScroll('En direct')),
      _QuickAccessItem('Genres', Icons.grid_view_rounded, kAccentColor, _openGenresSheet),
      _QuickAccessItem('Plus', Icons.more_horiz_rounded, kAccentDark, _openMoreSheet),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 92,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) => _QuickAccessButton(item: items[index]),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: kNavyDeep.withOpacity(0.14), blurRadius: 22, offset: const Offset(0, 9))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_rounded, 'Accueil', 0),
              _navItem(Icons.search_rounded, 'Rechercher', 1),
              _navItem(Icons.favorite_border_rounded, 'Favoris', 2),
              _navItem(Icons.person_outline_rounded, 'Profil', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final bool isSelected = index == 0;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        switch (index) {
          case 0:
            _scrollController.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
            _onCategoryChanged('Accueil');
            break;
          case 1:
            _focusSearchFromBottomNav(); // ✅ connecté : remonte et ouvre le clavier sur la vraie barre de recherche
            break;
          case 2:
            // ⚠️ Pas de table "favoris" côté Supabase pour l'instant → je ne simule rien.
            // Dis-moi le nom de la table/colonne (ex: user_favorites) et je branche la vraie requête.
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Favoris : en attente de la table Supabase dédiée')),
            );
            break;
          case 3:
            context.go(AppRoutes.userDashboard);
            break;
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: isSelected ? kSoftPurple : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isSelected ? kAccentColor : kTextGrey, size: 20),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                color: isSelected ? kAccentColor : kTextGrey,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselBanner() {
    if (_bannerItems.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (index) => setState(() => _currentBannerIndex = index),
            itemCount: _bannerItems.length,
            itemBuilder: (context, idx) => _buildBannerCard(_bannerItems[idx]),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _bannerItems.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentBannerIndex == i ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentBannerIndex == i ? kAccentColor : kSoftPurple,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBannerCard(MediaContent item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: kNavyDeep.withOpacity(0.22), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: item.coverUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: kSoftPurple),
              errorWidget: (context, url, error) => Container(color: kSoftPurple, child: const Icon(Icons.broken_image, color: kTextGrey)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [kNavyDeep.withOpacity(0.90), Colors.transparent],
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(color: kAccentColor, borderRadius: BorderRadius.circular(20)),
                    child: const Text('NOUVEAUTÉ', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                  const SizedBox(height: 8),
                  Text(item.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(item.subtitle ?? '', style: const TextStyle(fontSize: 14, color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _navigateToVideo(item),
                        icon: const Icon(Icons.play_arrow_rounded, size: 17),
                        label: const Text('Regarder maintenant'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kAccentColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                        label: const Text('Ma liste'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white70),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => PreferredSize(
        preferredSize: const Size.fromHeight(76),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kNavyDeep, kNavy, kAccentColor]),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(26), bottomRight: Radius.circular(26)),
            boxShadow: [BoxShadow(color: Color(0x337C5CFC), blurRadius: 22, offset: Offset(0, 10))],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(9)),
                            child: const Icon(Icons.play_circle_fill_rounded, size: 15, color: Colors.white),
                          ),
                          const SizedBox(width: 7),
                          const Text('THIX MEDIA', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: Colors.white, letterSpacing: 0.4)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      const Text('Regardez. Écoutez. Vibrez.', style: TextStyle(fontSize: 9.5, color: Colors.white70)),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, size: 18, color: kTextGrey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              onChanged: _onSearchChanged,
                              style: const TextStyle(fontSize: 13, color: kTextDark),
                              decoration: const InputDecoration(
                                hintText: 'Rechercher...',
                                border: InputBorder.none,
                                hintStyle: TextStyle(fontSize: 12.5, color: kTextGrey),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () => context.pushNamed('thixMediaAdmin'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: kGold,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: kGold.withOpacity(0.3), blurRadius: 8)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.admin_panel_settings_rounded, size: 14, color: kNavyDeep),
                          SizedBox(width: 4),
                          Text('ADMIN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: kNavyDeep)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 19),
                      ),
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(color: Color(0xFFE5484D), shape: BoxShape.circle),
                          child: const Center(child: Text('3', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800))),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.14), border: Border.all(color: Colors.white.withOpacity(0.2))),
                    child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildCategoryChips() => SizedBox(
        height: 38,
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          children: [
            _MediaChip(label: 'Accueil', selected: _selectedCategory == 'Accueil', onTap: () => _onCategoryChanged('Accueil')),
            _MediaChip(label: 'Vidéos', icon: Icons.video_library_rounded, selected: _selectedCategory == 'Vidéos', onTap: () => _onCategoryChanged('Vidéos')),
            _MediaChip(label: 'Films', icon: Icons.movie_rounded, selected: _selectedCategory == 'Films', onTap: () => _onCategoryChanged('Films')),
            _MediaChip(label: 'Séries', icon: Icons.tv_rounded, selected: _selectedCategory == 'Séries', onTap: () => _onCategoryChanged('Séries')),
            _MediaChip(label: 'Musique', icon: Icons.music_note_rounded, selected: _selectedCategory == 'Musique', onTap: () => _onCategoryChanged('Musique')),
            _MediaChip(label: 'Playlists', icon: Icons.playlist_play_rounded, selected: _selectedCategory == 'Playlists', onTap: () => _onCategoryChanged('Playlists')),
            _MediaChip(label: 'En direct', icon: Icons.live_tv_rounded, selected: _selectedCategory == 'En direct', onTap: () => _onCategoryChanged('En direct')),
          ],
        ),
      );
}

// ===== Widgets réutilisables =====

class _QuickAccessItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _QuickAccessItem(this.label, this.icon, this.color, this.onTap);
}

class _QuickAccessButton extends StatelessWidget {
  final _QuickAccessItem item;
  const _QuickAccessButton({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: item.color.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
            child: Icon(item.icon, color: item.color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            item.label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: kTextDark),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MediaChip extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback onTap;

  const _MediaChip({required this.label, this.selected = false, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 9),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? kAccentColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? Colors.transparent : kBorder),
          boxShadow: selected ? [BoxShadow(color: kAccentColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) Icon(icon, size: 14, color: selected ? Colors.white : kNavy),
            if (icon != null) const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : kTextDark,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool showSeeAll;
  final VoidCallback? onSeeAll;

  const _SectionHeader({required this.title, this.showSeeAll = false, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: kTextDark)),
        if (showSeeAll)
          GestureDetector(
            onTap: onSeeAll,
            child: Row(
              children: const [
                Text('Voir tout', style: TextStyle(fontSize: 11.5, color: kAccentColor, fontWeight: FontWeight.w700)),
                SizedBox(width: 3),
                Icon(Icons.arrow_forward_ios_rounded, size: 10, color: kAccentColor),
              ],
            ),
          ),
      ],
    );
  }
}

class _TrendingList extends StatelessWidget {
  final List<MediaContent> items;
  final Function(MediaContent) onItemTap;

  const _TrendingList({required this.items, required this.onItemTap});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Center(child: Text('Aucune donnée.', style: TextStyle(color: kTextGrey)));
    return SizedBox(
      height: 168,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: () => onItemTap(item),
            child: Container(
              width: 170,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: kBorder),
                boxShadow: [BoxShadow(color: kNavyDeep.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                        child: CachedNetworkImage(
                          imageUrl: item.coverUrl,
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(height: 100, color: kSoftPurple),
                          errorWidget: (context, url, error) => Container(height: 100, color: kSoftPurple, child: const Icon(Icons.broken_image, color: kTextGrey)),
                        ),
                      ),
                      if (item.rankPosition != null)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: kAccentColor, borderRadius: BorderRadius.circular(20)),
                            child: Text('#${item.rankPosition}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white)),
                          ),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: kTextDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text('${(item.viewCount / 1000).round()} k vues', style: const TextStyle(fontSize: 9.5, color: kTextGrey), maxLines: 1, overflow: TextOverflow.ellipsis),
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
}

class _RecommendationGrid extends StatelessWidget {
  final List<MediaContent> items;
  final Function(MediaContent) onItemTap;

  const _RecommendationGrid({required this.items, required this.onItemTap});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Center(child: Text('Aucune recommandation.', style: TextStyle(color: kTextGrey)));
    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: () => onItemTap(item),
            child: Container(
              width: 138,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: kBorder),
                boxShadow: [BoxShadow(color: kNavyDeep.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                        child: CachedNetworkImage(
                          imageUrl: item.coverUrl,
                          height: 128,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(height: 128, color: kSoftPurple),
                          errorWidget: (context, url, error) => Container(height: 128, color: kSoftPurple, child: const Icon(Icons.broken_image, color: kTextGrey)),
                        ),
                      ),
                      if (item.isNewRelease)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: kAccentColor, borderRadius: BorderRadius.circular(20)),
                            child: const Text('NOUVEAU', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Colors.white)),
                          ),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: kTextDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text('${item.type} • ${item.year ?? ''}', style: const TextStyle(fontSize: 9.5, color: kTextGrey), maxLines: 1, overflow: TextOverflow.ellipsis),
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
}

class _NewReleasesGrid extends StatelessWidget {
  final List<MediaContent> items;
  final Function(MediaContent) onItemTap;

  const _NewReleasesGrid({required this.items, required this.onItemTap});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Center(child: Text('Aucune nouveauté.', style: TextStyle(color: kTextGrey)));
    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: () => onItemTap(item),
            child: Container(
              width: 138,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: kBorder),
                boxShadow: [BoxShadow(color: kNavyDeep.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                        child: CachedNetworkImage(
                          imageUrl: item.coverUrl,
                          height: 128,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(height: 128, color: kSoftPurple),
                          errorWidget: (context, url, error) => Container(height: 128, color: kSoftPurple, child: const Icon(Icons.broken_image, color: kTextGrey)),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: kAccentColor, borderRadius: BorderRadius.circular(20)),
                          child: const Text('NOUVEAU', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: kTextDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text('${item.type} • ${item.year ?? ''}', style: const TextStyle(fontSize: 9.5, color: kTextGrey), maxLines: 1, overflow: TextOverflow.ellipsis),
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
}
