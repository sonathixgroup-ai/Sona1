import 'dart:async'; // pour Timer
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:go_router/go_router.dart'; // pour context.go
import 'video_player_page.dart';
import '../../models/media_content.dart';
import '../../services/media_service.dart';
import '../../app_router.dart'; // ✅ chemin corrigé (deux niveaux)

// ============================================================
// CHARTE THIX MEDIA — Élite Institutionnel Bleu / Blanc
// ============================================================
const Color kBackgroundColor = Color(0xFFF7FAFF);
const Color kNavyDeep = Color(0xFF0A1F44);
const Color kNavy = Color(0xFF123B7A);
const Color kAccentColor = Color(0xFF2D6CDF); // ex-violet #7A4DF3 → bleu institutionnel
const Color kSoftBlue = Color(0xFFEFF5FF);
const Color kGold = Color(0xFFE3B23C);
const Color kHeaderIconColor = Color(0xFF7386A8);
const Color kTextDark = Color(0xFF10192E);
const Color kTextGrey = Color(0xFF7386A8);
const Color kBorder = Color(0xFFE7EEFC);

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

  // Pour le carrousel
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _mediaService = MediaService(client: Supabase.instance.client, bucket: 'media');
    _loadMedia();
    _startBannerAutoScroll();
  }

  void _startBannerAutoScroll() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_allMedia.isEmpty) return;
      final next = (_currentBannerIndex + 1) % _bannerItems.length;
      _bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _loadMedia() async {
    try {
      final media = await _mediaService.fetchPublishedMedia();
      setState(() {
        _allMedia = media;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<MediaContent> get _bannerItems => _allMedia.where((m) => m.isNewRelease).toList();

  List<MediaContent> get _filteredTrending => _allMedia.where((item) => item.rankPosition != null).toList();
  List<MediaContent> get _filteredRecommendations => _allMedia.where((item) => item.rankPosition == null && item.type != 'Vidéo').toList();
  List<MediaContent> get _filteredNewReleases => _allMedia.where((item) => item.year == '2024').toList();

  void _navigateToVideo(MediaContent item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerPage(title: item.title, videoUrl: item.videoUrl),
      ),
    );
  }

  void _showAll(String section) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Voir tout : $section')));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: kBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: kAccentColor)),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: kBackgroundColor,
        body: Center(child: Text('Erreur : $_error', style: const TextStyle(color: kTextGrey))),
      );
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategoryChips(),
            const SizedBox(height: 18),
            if (_selectedCategory == 'Accueil' && _bannerItems.isNotEmpty) ...[
              _buildCarouselBanner(),
              const SizedBox(height: 22),
            ],
            if (_selectedCategory == 'Accueil') ...[
              _SectionHeader(title: 'Tendances', showSeeAll: true, onSeeAll: () => _showAll('Tendances')),
              const SizedBox(height: 10),
              _TrendingList(items: _filteredTrending, onItemTap: _navigateToVideo),
              const SizedBox(height: 22),
            ],
            if (_selectedCategory == 'Accueil')
              _SectionHeader(title: 'Recommandé pour vous', showSeeAll: true, onSeeAll: () => _showAll('Recommandations'))
            else
              _SectionHeader(title: 'Recommandations ($_selectedCategory)', showSeeAll: true, onSeeAll: () => _showAll('Recommandations')),
            const SizedBox(height: 10),
            _RecommendationGrid(
              items: _filteredRecommendations.where((item) => _selectedCategory == 'Accueil' || item.type == _selectedCategory).toList(),
              onItemTap: _navigateToVideo,
            ),
            const SizedBox(height: 22),
            if (_selectedCategory == 'Accueil') ...[
              _buildPremiumBanner(),
              const SizedBox(height: 22),
            ],
            if (_selectedCategory == 'Accueil')
              _SectionHeader(title: 'Nouveautés', showSeeAll: true, onSeeAll: () => _showAll('Nouveautés'))
            else
              _SectionHeader(title: 'Nouveautés ($_selectedCategory)', showSeeAll: true, onSeeAll: () => _showAll('Nouveautés')),
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

  // ============================================================
  // BOTTOM NAV BAR — flottante, incurvée
  // ============================================================
  Widget _buildBottomNavBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(color: kNavyDeep.withOpacity(0.12), blurRadius: 22, offset: const Offset(0, 9)),
        ],
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
    final bool isSelected = index == 0; // conforme à currentIndex: 0 original
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        switch (index) {
          case 0:
            // déjà sur accueil
            break;
          case 1:
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recherche avancée à venir')));
            break;
          case 2:
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Favoris à venir')));
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
                color: isSelected ? kSoftBlue : Colors.transparent,
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

  // ============================================================
  // CARROUSEL BANNIÈRE
  // ============================================================
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
          children: List.generate(_bannerItems.length, (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: _currentBannerIndex == i ? 16 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: _currentBannerIndex == i ? kAccentColor : kSoftBlue,
              borderRadius: BorderRadius.circular(3),
            ),
          )),
        ),
      ],
    );
  }

  Widget _buildBannerCard(MediaContent item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: kNavyDeep.withOpacity(0.16), blurRadius: 20, offset: const Offset(0, 10)),
        ],
        image: DecorationImage(image: NetworkImage(item.coverUrl), fit: BoxFit.cover),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [kNavyDeep.withOpacity(0.82), Colors.transparent],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(color: kGold, borderRadius: BorderRadius.circular(20)),
              child: const Text('NOUVEAUTÉ', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: kNavyDeep)),
            ),
            const SizedBox(height: 8),
            Text(item.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 4),
            Text(item.subtitle ?? '', style: const TextStyle(fontSize: 14, color: Colors.white70)),
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
    );
  }

  // ============================================================
  // APP BAR — dégradé incurvé bleu institutionnel
  // ============================================================
  PreferredSizeWidget _buildAppBar() => PreferredSize(
        preferredSize: const Size.fromHeight(76),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kNavyDeep, kNavy, kAccentColor],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(26),
              bottomRight: Radius.circular(26),
            ),
            boxShadow: [
              BoxShadow(color: Color(0x332D6CDF), blurRadius: 22, offset: Offset(0, 10)),
            ],
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
                            child: const Icon(Icons.play_circle_fill_rounded, size: 15, color: kGold),
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
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, size: 18, color: kTextGrey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) => setState(() => _searchQuery = value),
                              style: const TextStyle(fontSize: 13, color: kTextDark),
                              decoration: const InputDecoration(
                                hintText: 'Rechercher un film, une série...',
                                border: InputBorder.none,
                                hintStyle: TextStyle(fontSize: 12.5, color: kTextGrey),
                                isDense: true,
                              ),
                            ),
                          ),
                          Icon(Icons.tune_rounded, size: 17, color: kTextGrey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
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
                  const SizedBox(width: 10),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.14),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  // ============================================================
  // CATÉGORIES
  // ============================================================
  Widget _buildCategoryChips() => SizedBox(
        height: 38,
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          children: [
            _MediaChip(label: 'Accueil', selected: _selectedCategory == 'Accueil', onTap: () => setState(() => _selectedCategory = 'Accueil')),
            _MediaChip(label: 'Vidéos', icon: Icons.video_library_rounded, selected: _selectedCategory == 'Vidéos', onTap: () => setState(() => _selectedCategory = 'Vidéos')),
            _MediaChip(label: 'Films', icon: Icons.movie_rounded, selected: _selectedCategory == 'Films', onTap: () => setState(() => _selectedCategory = 'Films')),
            _MediaChip(label: 'Séries', icon: Icons.tv_rounded, selected: _selectedCategory == 'Séries', onTap: () => setState(() => _selectedCategory = 'Séries')),
            _MediaChip(label: 'Musique', icon: Icons.music_note_rounded, selected: _selectedCategory == 'Musique', onTap: () => setState(() => _selectedCategory = 'Musique')),
            _MediaChip(label: 'Playlists', icon: Icons.playlist_play_rounded, selected: _selectedCategory == 'Playlists', onTap: () => setState(() => _selectedCategory = 'Playlists')),
            _MediaChip(label: 'En direct', icon: Icons.live_tv_rounded, selected: _selectedCategory == 'En direct', onTap: () => setState(() => _selectedCategory = 'En direct')),
          ],
        ),
      );

  // ============================================================
  // BANNIÈRE PREMIUM
  // ============================================================
  Widget _buildPremiumBanner() => Container(
        height: 130,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [kNavyDeep, kNavy, kAccentColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: kNavyDeep.withOpacity(0.18), blurRadius: 18, offset: const Offset(0, 9)),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(Icons.stars_rounded, color: kGold, size: 44),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('THIX MEDIA Premium', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5, color: Colors.white)),
                  SizedBox(height: 5),
                  Text('Accédez à tout le contenu sans publicité,\ntéléchargez et regardez hors ligne.', style: TextStyle(fontSize: 11, color: Colors.white70, height: 1.3)),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
              decoration: BoxDecoration(color: kGold, borderRadius: BorderRadius.circular(30)),
              child: const Icon(Icons.arrow_forward_ios_rounded, color: kNavyDeep, size: 15),
            ),
          ],
        ),
      );
}

// ==================== WIDGETS RÉUTILISABLES ====================

class _MediaChip extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback onTap;
  const _MediaChip({required this.label, this.selected = false, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 9),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: selected ? const LinearGradient(colors: [kNavyDeep, kAccentColor]) : null,
            color: selected ? null : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? Colors.transparent : kBorder),
            boxShadow: selected
                ? [BoxShadow(color: kAccentColor.withOpacity(0.28), blurRadius: 10, offset: const Offset(0, 4))]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) Icon(icon, size: 14, color: selected ? Colors.white : kNavy),
              if (icon != null) const SizedBox(width: 7),
              Text(label, style: TextStyle(color: selected ? Colors.white : kTextDark, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, fontSize: 12.5)),
            ],
          ),
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool showSeeAll;
  final VoidCallback? onSeeAll;
  const _SectionHeader({required this.title, this.showSeeAll = false, this.onSeeAll});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: kTextDark)),
          if (showSeeAll)
            GestureDetector(
              onTap: onSeeAll,
              child: const Row(
                children: [
                  Text('Voir tout', style: TextStyle(fontSize: 11.5, color: kAccentColor, fontWeight: FontWeight.w700)),
                  SizedBox(width: 3),
                  Icon(Icons.arrow_forward_ios_rounded, size: 10, color: kAccentColor),
                ],
              ),
            ),
        ],
      );
}

class _TrendingList extends StatelessWidget {
  final List<MediaContent> items;
  final Function(MediaContent) onItemTap;
  const _TrendingList({required this.items, required this.onItemTap});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Center(child: Text('Aucune donnée pour les tendances.', style: TextStyle(color: kTextGrey)));
    return SizedBox(
      height: 122,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: () => onItemTap(item),
            child: Container(
              width: 150,
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
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: Image.network(item.coverUrl, height: 80, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 80, color: kSoftBlue)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: kTextDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text('${(item.viewCount / 1000).round()} k vues • il y a ${index + 2} jours', style: const TextStyle(fontSize: 9.5, color: kTextGrey), maxLines: 1, overflow: TextOverflow.ellipsis),
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
    if (items.isEmpty) return const Center(child: Text('Aucune recommandation disponible.', style: TextStyle(color: kTextGrey)));
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: () => onItemTap(item),
            child: Container(
              width: 130,
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
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: Image.network(item.coverUrl, height: 120, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 120, color: kSoftBlue)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: kTextDark), maxLines: 1, overflow: TextOverflow.ellipsis),
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
    if (items.isEmpty) return const Center(child: Text('Aucune nouveauté pour cette catégorie.', style: TextStyle(color: kTextGrey)));
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: () => onItemTap(item),
            child: Container(
              width: 130,
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
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: Image.network(item.coverUrl, height: 120, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 120, color: kSoftBlue)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: kTextDark), maxLines: 1, overflow: TextOverflow.ellipsis),
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
