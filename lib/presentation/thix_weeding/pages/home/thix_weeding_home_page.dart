// lib/presentation/thix_weeding/pages/home/thix_weeding_home_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/failure.dart';
import '../../data/repositories/wedding_repository_impl.dart';
import '../../domain/entities/wedding_entity.dart';

part 'thix_weeding_home_page.g.dart';

// ============================================================
// PALETTE — Charte THIX (déclinaison mariage, style épuré)
// ============================================================
class _P {
  static const bg = Color(0xFFF4F6F9); 
  static const surface = Colors.white;
  static const primary = Color(0xFFE25A6A);
  static const primaryDark = Color(0xFFC94356);
  static const primaryLight = Color(0xFFFDF0F2);
  static const ink = Color(0xFF171722);
  static const inkSoft = Color(0xFF6B6B78); 
  static const border = Color(0xFFE5E7EB);
  static const gold = Color(0xFFF59E0B);
  static const blue = Color(0xFF3B82F6);
  static const green = Color(0xFF10B981);
}

// Ombre standardisée pour les cartes
final _cardShadow = BoxShadow(
  color: Colors.black.withOpacity(0.04),
  blurRadius: 16,
  offset: const Offset(0, 4),
);

// ============================================================
// PROVIDERS (AVEC VRAIES IMAGES MOCK-UP)
// ============================================================
@riverpod
Future<List<Map<String, dynamic>>> homePromoSlides(HomePromoSlidesRef ref) async {
  await Future.delayed(const Duration(milliseconds: 250));
  return [
    {
      'tag': 'PROMO FLASH',
      'title': "Jusqu'à -40%",
      'subtitle': 'sur les salles de fête',
      'detail': "Valable jusqu'au 30 Septembre 2026",
      'cta': 'Profiter',
      'imageUrl': 'https://images.unsplash.com/photo-1519741497674-611481863552?auto=format&fit=crop&q=80&w=800',
    },
    {
      'tag': 'NOUVEAU',
      'title': 'Invitations 100% digitales',
      'subtitle': 'Créez votre site web',
      'detail': 'ID unique pour vos invités',
      'cta': 'Commencer',
      'imageUrl': 'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?auto=format&fit=crop&q=80&w=800',
    },
  ];
}

@riverpod
Future<List<Map<String, dynamic>>> homeCategories(HomeCategoriesRef ref) async {
  await Future.delayed(const Duration(milliseconds: 150));
  return [
    {'label': 'Salles', 'icon': Icons.villa_outlined},
    {'label': 'Traiteurs', 'icon': Icons.restaurant_outlined},
    {'label': 'Robes', 'icon': Icons.checkroom_outlined},
    {'label': 'Photo', 'icon': Icons.camera_alt_outlined},
    {'label': 'Déco', 'icon': Icons.local_florist_outlined},
  ];
}

@riverpod
Future<Map<String, int>> homeStats(HomeStatsRef ref) async {
  await Future.delayed(const Duration(milliseconds: 200));
  return {'Mes mariages': 2, 'En attente': 1, 'Terminés': 5, 'Annulés': 0};
}

@riverpod
Future<List<Map<String, dynamic>>> homeOffers(HomeOffersRef ref) async {
  await Future.delayed(const Duration(milliseconds: 250));
  return [
    {'title': 'Salles de fête', 'subtitle': 'Réservez votre salle', 'discount': '-25%', 'imageUrl': 'https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?auto=format&fit=crop&q=80&w=400'},
    {'title': 'Traiteurs', 'subtitle': 'Menus mariage', 'discount': '-20%', 'imageUrl': 'https://images.unsplash.com/photo-1555244162-803834f70033?auto=format&fit=crop&q=80&w=400'},
  ];
}

@riverpod
Future<List<Map<String, dynamic>>> homeProviders(HomeProvidersRef ref) async {
  await Future.delayed(const Duration(milliseconds: 300));
  return [
    {'name': 'Salle Émeraude', 'category': 'Salle de fête', 'zone': 'Gombe', 'rating': 4.8, 'price': '\$\$', 'imageUrl': 'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?auto=format&fit=crop&q=80&w=400'},
    {'name': 'Chef Amani', 'category': 'Traiteur', 'zone': 'Limete', 'rating': 4.7, 'price': '\$\$\$', 'imageUrl': 'https://images.unsplash.com/photo-1655195671120-2c701fc3e593?auto=format&fit=crop&q=80&w=400'},
    {'name': 'Studio Lumière', 'category': 'Photographe', 'zone': 'Kintambo', 'rating': 4.9, 'price': '\$\$', 'imageUrl': 'https://images.unsplash.com/photo-1520854221256-17451cc331bf?auto=format&fit=crop&q=80&w=400'},
  ];
}

@riverpod
Future<List<Map<String, dynamic>>> homeAnnouncements(HomeAnnouncementsRef ref) async {
  await Future.delayed(const Duration(milliseconds: 200));
  return [
    {'tag': 'À VENDRE', 'tagColor': _P.blue, 'title': 'Robe de mariée 38', 'subtitle': '450.000 FC', 'imageUrl': 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?auto=format&fit=crop&q=80&w=400'},
    {'tag': 'À LOUER', 'tagColor': _P.gold, 'title': 'Décoration Champêtre', 'subtitle': '800.000 FC', 'imageUrl': 'https://images.unsplash.com/photo-1469334031218-e382a71b716b?auto=format&fit=crop&q=80&w=400'},
  ];
}

// ============================================================
// PAGE
// ============================================================
class ThixWeedingHomePage extends ConsumerStatefulWidget {
  const ThixWeedingHomePage({super.key});

  @override
  ConsumerState<ThixWeedingHomePage> createState() => _ThixWeedingHomePageState();
}

class _ThixWeedingHomePageState extends ConsumerState<ThixWeedingHomePage> {
  late final TextEditingController _idController;
  late final FocusNode _focusNode;
  bool _isSearching = false;

  final PageController _promoController = PageController();
  int _promoIndex = 0;
  Timer? _promoTimer;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController();
    _focusNode = FocusNode();
    _promoTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_promoController.hasClients) return;
      final next = (_promoIndex + 1) % 2;
      _promoController.animateToPage(next, duration: const Duration(milliseconds: 600), curve: Curves.fastOutSlowIn);
    });
  }

  @override
  void dispose() {
    _idController.dispose();
    _focusNode.dispose();
    _promoController.dispose();
    _promoTimer?.cancel();
    super.dispose();
  }

  Future<void> _onSearch() async {
    final id = _idController.text.trim();
    if (id.isEmpty) {
      _focusNode.requestFocus();
      return;
    }
    if (_isSearching) return;

    setState(() => _isSearching = true);
    FocusScope.of(context).unfocus();

    try {
      final repo = ref.read(weddingRepositoryProvider);
      final WeddingEntity wedding = await repo.getWeddingById(id);
      if (!mounted) return;
      context.push('/thix-weeding/guest/${wedding.id}');
    } on Failure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.red.shade600));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID introuvable, vérifiez et réessayez')));
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _onTapGeneric(String label) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label bientôt disponible')));
  }

  @override
  Widget build(BuildContext context) {
    final promosAsync = ref.watch(homePromoSlidesProvider);
    final catsAsync = ref.watch(homeCategoriesProvider);
    final statsAsync = ref.watch(homeStatsProvider);
    final offersAsync = ref.watch(homeOffersProvider);
    final providersAsync = ref.watch(homeProvidersProvider);
    final announcementsAsync = ref.watch(homeAnnouncementsProvider);

    return Scaffold(
      backgroundColor: _P.bg,
      appBar: _buildAppBar(),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // BARRE DE RECHERCHE — style pilule THIX ID
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _IdSearchBar(
                controller: _idController,
                focusNode: _focusNode,
                isLoading: _isSearching,
                onSearch: _onSearch,
              ),
            ),
          ),

          // CARROUSEL PROMO (HERO BANNER) — avec Mockups Photos
          SliverToBoxAdapter(
            child: promosAsync.when(
              data: (slides) => _PromoCarousel(
                slides: slides,
                controller: _promoController,
                onPageChanged: (i) => setState(() => _promoIndex = i),
                currentIndex: _promoIndex,
              ),
              loading: () => const SizedBox(height: 200),
              error: (_, __) => const SizedBox(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ICÔNES CATEGORIES — épuré
          SliverToBoxAdapter(
            child: catsAsync.when(
              data: (cats) => _CategoryIconRow(categories: cats, onTap: _onTapGeneric),
              loading: () => const SizedBox(height: 80),
              error: (_, __) => const SizedBox(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 28)),

          // MES RÉSERVATIONS (STATS)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _SectionHeader(title: 'Mes réservations'),
            ),
          ),
          SliverToBoxAdapter(
            child: statsAsync.when(
              data: (stats) => _StatsRow(stats: stats),
              loading: () => const SizedBox(height: 80),
              error: (_, __) => const SizedBox(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 28)),

          // OFFRES SPECIALES
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _SectionHeader(title: 'Offres spéciales pour vous'),
            ),
          ),
          SliverToBoxAdapter(
            child: offersAsync.when(
              data: (offers) => _OffersGrid(offers: offers, onTap: _onTapGeneric),
              loading: () => const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 28)),

          // PRESTATAIRES À LA UNE
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _SectionHeader(title: 'Prestataires à proximité'),
            ),
          ),
          SliverToBoxAdapter(
            child: providersAsync.when(
              data: (providers) => _ProvidersList(providers: providers, onTap: _onTapGeneric),
              loading: () => const SizedBox(height: 220, child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 28)),

          // ANNONCES
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _SectionHeader(title: 'Annonces'),
            ),
          ),
          SliverToBoxAdapter(
            child: announcementsAsync.when(
              data: (ann) => _AnnouncementsList(items: ann, onTap: _onTapGeneric),
              loading: () => const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 28)),

          // BANDEAU DE CONFIANCE (style footer de THIX Réservation)
          const SliverToBoxAdapter(
            child: _TrustRow(),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)), // Marges de bas de page ajustées
        ],
      ),
      // Le bottomNavigationBar a été supprimé ici 🌝
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _P.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(color: _P.primary, shape: BoxShape.circle),
            child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.5),
              children: [
                TextSpan(text: 'THIX ', style: TextStyle(color: _P.ink)),
                TextSpan(text: 'MARIAGE', style: TextStyle(color: _P.primary)),
              ],
            ),
          ),
        ],
      ),
      actions: [
        _AppBarIconButton(icon: Icons.notifications_none_rounded, badgeCount: 3, onTap: () {}),
        const SizedBox(width: 8),
        _AppBarIconButton(icon: Icons.person_outline_rounded, isFilled: true, onTap: () {}),
        const SizedBox(width: 16),
      ],
    );
  }
}

// ============================================================
// WIDGETS
// ============================================================

class _AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final int? badgeCount;
  final VoidCallback onTap;
  final bool isFilled;

  const _AppBarIconButton({required this.icon, required this.onTap, this.badgeCount, this.isFilled = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isFilled ? _P.border.withOpacity(0.5) : Colors.transparent,
          shape: BoxShape.circle,
          border: isFilled ? null : Border.all(color: _P.border),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 22, color: _P.ink),
            if (badgeCount != null)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: _P.gold, shape: BoxShape.circle),
                  child: Text('$badgeCount', style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _IdSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final VoidCallback onSearch;

  const _IdSearchBar({required this.controller, required this.focusNode, required this.isLoading, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30), 
        boxShadow: [_cardShadow],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search_rounded, color: _P.inkSoft, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _P.ink),
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Code du mariage (ex: SARA2026)',
                hintStyle: TextStyle(fontSize: 14, color: _P.inkSoft, fontWeight: FontWeight.w400),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => onSearch(),
            ),
          ),
          InkWell(
            onTap: isLoading ? null : onSearch,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(color: _P.blue, borderRadius: BorderRadius.circular(24)),
              child: isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Vérifier', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoCarousel extends StatelessWidget {
  final List<Map<String, dynamic>> slides;
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  const _PromoCarousel({required this.slides, required this.controller, required this.currentIndex, required this.onPageChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: Stack(
        children: [
          PageView.builder(
            controller: controller,
            itemCount: slides.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, i) {
              final s = slides[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(image: NetworkImage(s['imageUrl']), fit: BoxFit.cover),
                    boxShadow: [_cardShadow],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.flash_on_rounded, color: _P.gold, size: 16),
                            const SizedBox(width: 4),
                            Text(s['tag'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(s['title'] as String, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1)),
                        const SizedBox(height: 4),
                        Text(s['subtitle'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white70)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(color: _P.blue, borderRadius: BorderRadius.circular(8)),
                          child: Text(s['cta'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(slides.length, (i) {
                final active = i == currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? _P.blue : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: _P.ink, letterSpacing: -0.3)),
        const Row(
          children: [
            Text('Voir tout', style: TextStyle(fontSize: 13, color: _P.inkSoft, fontWeight: FontWeight.w500)),
            Icon(Icons.chevron_right_rounded, size: 18, color: _P.inkSoft),
          ],
        ),
      ],
    );
  }
}

class _CategoryIconRow extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final void Function(String) onTap;
  const _CategoryIconRow({required this.categories, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ...categories.map((c) => _buildIcon(c['label'], c['icon'])),
          _buildIcon('Plus', Icons.grid_view_rounded, isPlus: true),
        ],
      ),
    );
  }

  Widget _buildIcon(String label, IconData icon, {bool isPlus = false}) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isPlus ? _P.primary.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isPlus ? [] : [_cardShadow],
          ),
          child: Icon(icon, size: 28, color: isPlus ? _P.primary : _P.blue),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _P.ink)),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final Map<String, int> stats;
  const _StatsRow({required this.stats});

  static const _icons = {
    'Mes mariages': Icons.work_outline_rounded,
    'En attente': Icons.schedule_rounded,
    'Terminés': Icons.check_circle_outline_rounded,
    'Annulés': Icons.cancel_outlined,
  };

  static const _colors = {
    'Mes mariages': _P.blue,
    'En attente': _P.gold,
    'Terminés': _P.green,
    'Annulés': _P.primary,
  };

  @override
  Widget build(BuildContext context) {
    final entries = stats.entries.toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(entries.length, (i) {
          final e = entries[i];
          final color = _colors[e.key] ?? _P.blue;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i == entries.length - 1 ? 0 : 12),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [_cardShadow]),
              child: Column(
                children: [
                  Icon(_icons[e.key], size: 24, color: color),
                  const SizedBox(height: 8),
                  Text(e.key, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: _P.inkSoft, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: _P.ink)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _OffersGrid extends StatelessWidget {
  final List<Map<String, dynamic>> offers;
  final void Function(String) onTap;
  const _OffersGrid({required this.offers, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: offers.map((o) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: o == offers.last ? 0 : 12),
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [_cardShadow],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    bottom: -10,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(o['imageUrl'], width: 120, height: 120, fit: BoxFit.cover),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(o['title'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _P.ink)),
                        const SizedBox(height: 8),
                        Text(o['discount'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _P.gold)),
                        const SizedBox(height: 4),
                        Text(o['subtitle'], style: const TextStyle(fontSize: 11, color: _P.inkSoft, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ProvidersList extends StatelessWidget {
  final List<Map<String, dynamic>> providers;
  final void Function(String) onTap;
  const _ProvidersList({required this.providers, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: providers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, i) {
          final p = providers[i];
          return InkWell(
            onTap: () => onTap(p['name'] as String),
            child: Container(
              width: 220,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [_cardShadow]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image.network(p['imageUrl'], height: 130, width: double.infinity, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 14, color: _P.gold),
                              const SizedBox(width: 4),
                              Text('${p['rating']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.favorite_border_rounded, size: 16, color: _P.inkSoft),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p['name'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _P.ink)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(p['category'] as String, style: const TextStyle(fontSize: 12, color: _P.inkSoft)),
                            const Spacer(),
                            Text(p['price'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _P.ink)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(p['zone'] as String, style: const TextStyle(fontSize: 12, color: _P.inkSoft)),
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

class _AnnouncementsList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final void Function(String) onTap;
  const _AnnouncementsList({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, i) {
          final a = items[i];
          final tagColor = a['tagColor'] as Color;
          return Container(
            width: 240,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [_cardShadow]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(a['imageUrl'], height: 110, width: double.infinity, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: tagColor, borderRadius: BorderRadius.circular(6)),
                        child: Text(a['tag'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a['title'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _P.ink)),
                      const SizedBox(height: 4),
                      Text(a['subtitle'] as String, style: const TextStyle(fontSize: 13, color: _P.inkSoft, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow();

  static const _items = [
    {'icon': Icons.verified_user_outlined, 'label': 'Paiement sécurisé'},
    {'icon': Icons.support_agent_rounded, 'label': 'Support 24/7'},
    {'icon': Icons.workspace_premium_outlined, 'label': 'Garantie incluse'},
    {'icon': Icons.autorenew_rounded, 'label': 'Annulation facile'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _items.map((e) {
          return Column(
            children: [
              Icon(e['icon'] as IconData, size: 24, color: _P.blue),
              const SizedBox(height: 8),
              Text(e['label'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: _P.inkSoft, fontWeight: FontWeight.w500)),
            ],
          );
        }).toList(),
      ),
    );
  }
}
