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
// PALETTE — Charte THIX (déclinaison mariage, fond clair)
// ============================================================
class _P {
  static const bg = Color(0xFFFDFBFA);
  static const surface = Colors.white;
  static const primary = Color(0xFFE25A6A);
  static const primaryDark = Color(0xFFC94356);
  static const primarySoft = Color(0xFFFCE9EB);
  static const ink = Color(0xFF232329);
  static const inkSoft = Color(0xFF9797A1);
  static const border = Color(0xFFF1EDEE);
  static const gold = Color(0xFFDDAA3E);
  static const blue = Color(0xFF4E8FE0);
  static const green = Color(0xFF5FAE72);
  static const purple = Color(0xFFA477D9);
}

// ============================================================
// PROVIDERS
// ============================================================
@riverpod
Future<List<Map<String, dynamic>>> homePromoSlides(HomePromoSlidesRef ref) async {
  await Future.delayed(const Duration(milliseconds: 250));
  return [
    {
      'tag': 'PROMO FLASH',
      'title': "Jusqu'à -40%",
      'subtitle': 'sur les salles de fête & traiteurs',
      'detail': "Valable jusqu'au 30 Septembre 2026",
      'cta': 'Profiter maintenant',
      'imageUrl': 'https://picsum.photos/seed/wedding-venue/900/600',
    },
    {
      'tag': 'NOUVEAU',
      'title': 'Créez votre site',
      'subtitle': "de mariage en 5 minutes",
      'detail': 'ID unique + invitations digitales',
      'cta': 'Commencer',
      'imageUrl': 'https://picsum.photos/seed/wedding-couple/900/600',
    },
    {
      'tag': 'PARTENAIRES',
      'title': '+300 prestataires',
      'subtitle': 'vérifiés partout en RDC',
      'detail': 'Avis authentiques & prix transparents',
      'cta': 'Découvrir',
      'imageUrl': 'https://picsum.photos/seed/wedding-deco/900/600',
    },
  ];
}

@riverpod
Future<List<Map<String, dynamic>>> homeCategories(HomeCategoriesRef ref) async {
  await Future.delayed(const Duration(milliseconds: 150));
  return [
    {'label': 'Salles', 'icon': Icons.villa_outlined},
    {'label': 'Traiteurs', 'icon': Icons.restaurant_outlined},
    {'label': 'Cérémonie', 'icon': Icons.mic_none_outlined},
    {'label': 'Décoration', 'icon': Icons.local_florist_outlined},
    {'label': 'Photo', 'icon': Icons.camera_alt_outlined},
    {'label': 'Robes', 'icon': Icons.checkroom_outlined},
    {'label': 'Plus', 'icon': Icons.grid_view_rounded},
  ];
}

@riverpod
Future<Map<String, int>> homeStats(HomeStatsRef ref) async {
  await Future.delayed(const Duration(milliseconds: 200));
  return {'Prestataires': 312, 'Avis vérifiés': 1840, 'Offres actives': 26, 'Événements': 97};
}

@riverpod
Future<List<Map<String, dynamic>>> homeOffers(HomeOffersRef ref) async {
  await Future.delayed(const Duration(milliseconds: 250));
  return [
    {'title': 'Salles de fête', 'subtitle': 'Réservez votre salle idéale', 'discount': '-25%', 'icon': Icons.villa_outlined, 'colors': [const Color(0xFFFBF0DB), const Color(0xFFF5E2B8)]},
    {'title': 'Traiteurs', 'subtitle': 'Menus spéciaux mariage', 'discount': '-20%', 'icon': Icons.restaurant_outlined, 'colors': [const Color(0xFFE4EEFB), const Color(0xFFCFE1F7)]},
    {'title': 'Décoration', 'subtitle': 'Ambiances inoubliables', 'discount': '-15%', 'icon': Icons.local_florist_outlined, 'colors': [const Color(0xFFE7F5EA), const Color(0xFFD3ECD9)]},
    {'title': 'Photographes', 'subtitle': 'Immortalisez vos moments', 'discount': '-20%', 'icon': Icons.camera_alt_outlined, 'colors': [const Color(0xFFF0E9FA), const Color(0xFFE1D3F5)]},
  ];
}

@riverpod
Future<List<Map<String, dynamic>>> homeProviders(HomeProvidersRef ref) async {
  await Future.delayed(const Duration(milliseconds: 300));
  return [
    {'name': 'Salle Émeraude', 'category': 'Salle de fête', 'zone': 'Gombe · 20-30 min', 'rating': 4.8, 'price': '\$\$', 'icon': Icons.villa_outlined, 'colors': [const Color(0xFFFBF0DB), const Color(0xFFF5E2B8)]},
    {'name': 'Chef Amani', 'category': 'Traiteur', 'zone': 'Limete · 15-25 min', 'rating': 4.7, 'price': '\$\$', 'icon': Icons.restaurant_outlined, 'colors': [const Color(0xFFE4EEFB), const Color(0xFFCFE1F7)]},
    {'name': 'Fleurs de Kin', 'category': 'Décoration', 'zone': 'Ngaliema · 20-30 min', 'rating': 4.9, 'price': '\$', 'icon': Icons.local_florist_outlined, 'colors': [const Color(0xFFE7F5EA), const Color(0xFFD3ECD9)]},
    {'name': 'Studio Lumière', 'category': 'Photographe', 'zone': 'Kintambo · 25-35 min', 'rating': 4.8, 'price': '\$\$\$', 'icon': Icons.camera_alt_outlined, 'colors': [const Color(0xFFF0E9FA), const Color(0xFFE1D3F5)]},
  ];
}

@riverpod
Future<List<Map<String, dynamic>>> homeAnnouncements(HomeAnnouncementsRef ref) async {
  await Future.delayed(const Duration(milliseconds: 200));
  return [
    {'tag': 'À VENDRE', 'tagColor': _P.blue, 'title': 'Robe de mariée taille 38', 'subtitle': '450.000 FC', 'icon': Icons.checkroom_outlined},
    {'tag': 'À LOUER', 'tagColor': _P.gold, 'title': 'Salle 200 places', 'subtitle': '800.000 FC / jour', 'icon': Icons.villa_outlined},
    {'tag': 'SERVICE', 'tagColor': _P.green, 'title': 'Coiffure & maquillage', 'subtitle': "À partir de 30.000 FC", 'icon': Icons.face_retouching_natural_outlined},
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
    _promoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_promoController.hasClients) return;
      final next = (_promoIndex + 1) % 3;
      _promoController.animateToPage(next, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
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

  void _onScanQr() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scanner QR bientôt disponible')));
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
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // RECHERCHE ID — compacte, fonctionnalité unique MARIAGE+
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _IdSearchBar(
                controller: _idController,
                focusNode: _focusNode,
                isLoading: _isSearching,
                onSearch: _onSearch,
                onScanQr: _onScanQr,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 14)),

          // CARROUSEL HERO — photos mock-up réelles + overlay dégradé
          SliverToBoxAdapter(
            child: promosAsync.when(
              data: (slides) => _PromoCarousel(
                slides: slides,
                controller: _promoController,
                onPageChanged: (i) => setState(() => _promoIndex = i),
                currentIndex: _promoIndex,
              ),
              loading: () => const SizedBox(height: 190),
              error: (_, __) => const SizedBox(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 18)),

          // RACCOURCIS CATEGORIES
          SliverToBoxAdapter(
            child: catsAsync.when(
              data: (cats) => _CategoryIconRow(categories: cats, onTap: _onTapGeneric),
              loading: () => const SizedBox(height: 84),
              error: (_, __) => const SizedBox(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 6)),

          // EN UN COUP D'OEIL — stats
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _SectionHeader(icon: Icons.insights_rounded, title: 'En un coup d\'œil'),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
          SliverToBoxAdapter(
            child: statsAsync.when(
              data: (stats) => _StatsRow(stats: stats),
              loading: () => const SizedBox(height: 78),
              error: (_, __) => const SizedBox(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 22)),

          // OFFRES SPECIALES
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _SectionHeader(title: 'Offres spéciales pour vous'),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
          SliverToBoxAdapter(
            child: offersAsync.when(
              data: (offers) => _OffersGrid(offers: offers, onTap: _onTapGeneric),
              loading: () => const SizedBox(height: 220, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
              error: (e, _) => SizedBox(height: 60, child: Center(child: Text('Erreur: $e'))),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 22)),

          // PRESTATAIRES A LA UNE
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _SectionHeader(title: 'Prestataires à la une'),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
          SliverToBoxAdapter(
            child: providersAsync.when(
              data: (providers) => _ProvidersList(providers: providers, onTap: _onTapGeneric),
              loading: () => const SizedBox(height: 208, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
              error: (_, __) => const SizedBox(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 22)),

          // ANNONCES
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _SectionHeader(title: 'Annonces'),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
          SliverToBoxAdapter(
            child: announcementsAsync.when(
              data: (ann) => _AnnouncementsList(items: ann, onTap: _onTapGeneric),
              loading: () => const SizedBox(height: 150, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
              error: (_, __) => const SizedBox(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 22)),

          // BANDEAU DE CONFIANCE
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _TrustRow(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _P.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: _P.primarySoft, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.favorite_rounded, color: _P.primary, size: 18),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.2),
                  children: [
                    TextSpan(text: 'MARIAGE', style: TextStyle(color: _P.ink)),
                    TextSpan(text: '+', style: TextStyle(color: _P.primary)),
                  ],
                ),
              ),
              const Text('Tout pour un mariage parfait', style: TextStyle(fontSize: 10, color: _P.inkSoft)),
            ],
          ),
        ],
      ),
      actions: [
        _AppBarIconButton(icon: Icons.notifications_none_rounded, badgeCount: 3, onTap: () {}),
        const SizedBox(width: 6),
        _AppBarIconButton(icon: Icons.person_outline_rounded, onTap: () {}),
        const SizedBox(width: 8),
      ],
    );
  }
}

// ============================================================
// APP BAR ICON BUTTON
// ============================================================
class _AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final int? badgeCount;
  final VoidCallback onTap;
  const _AppBarIconButton({required this.icon, required this.onTap, this.badgeCount});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: _P.bg, borderRadius: BorderRadius.circular(10)),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 19, color: _P.ink),
            if (badgeCount != null)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: const BoxDecoration(color: _P.primary, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                  child: Text('$badgeCount', textAlign: TextAlign.center, style: const TextStyle(fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.w800)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// RECHERCHE ID — barre compacte
// ============================================================
class _IdSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final VoidCallback onSearch;
  final VoidCallback onScanQr;

  const _IdSearchBar({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSearch,
    required this.onScanQr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _P.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _P.ink),
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: _P.inkSoft),
                hintText: 'Votre ID de mariage',
                hintStyle: const TextStyle(fontSize: 13, color: _P.inkSoft, fontWeight: FontWeight.w500),
                filled: true,
                fillColor: _P.bg,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => onSearch(),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onScanQr,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: _P.bg, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.qr_code_scanner_rounded, size: 20, color: _P.ink),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: isLoading ? null : onSearch,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: _P.primary, borderRadius: BorderRadius.circular(12)),
              child: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                    )
                  : const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CARROUSEL HERO — photos mock-up + overlay dégradé
// ============================================================
class _PromoCarousel extends StatelessWidget {
  final List<Map<String, dynamic>> slides;
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  const _PromoCarousel({
    required this.slides,
    required this.controller,
    required this.currentIndex,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // PHOTO MOCK-UP — remplacer par les assets réels
                      Image.network(
                        s['imageUrl'] as String,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: _P.primarySoft),
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(color: _P.primarySoft);
                        },
                      ),
                      // Overlay dégradé pour la lisibilité du texte
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [Colors.black.withOpacity(0.62), Colors.black.withOpacity(0.08)],
                            stops: const [0.0, 0.85],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(6)),
                              child: Text(s['tag'] as String, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: _P.primaryDark, letterSpacing: 0.4)),
                            ),
                            const SizedBox(height: 8),
                            Text(s['title'] as String, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                            Text(s['subtitle'] as String, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white)),
                            const SizedBox(height: 4),
                            Text(s['detail'] as String, style: TextStyle(fontSize: 10.5, color: Colors.white.withOpacity(0.85))),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                              decoration: BoxDecoration(color: _P.primary, borderRadius: BorderRadius.circular(10)),
                              child: Text(s['cta'] as String, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(slides.length, (i) {
                final active = i == currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? Colors.white : Colors.white.withOpacity(0.5),
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

// ============================================================
// SECTION HEADER
// ============================================================
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  const _SectionHeader({required this.title, this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: _P.primary),
              const SizedBox(width: 6),
            ],
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: _P.ink)),
          ],
        ),
        InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(6),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text('Voir tout', style: TextStyle(fontSize: 12, color: _P.primary, fontWeight: FontWeight.w600)),
                Icon(Icons.chevron_right_rounded, size: 15, color: _P.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// CATEGORY ICON ROW
// ============================================================
class _CategoryIconRow extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final void Function(String) onTap;
  const _CategoryIconRow({required this.categories, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: _P.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: _P.border)),
      child: SizedBox(
        height: 66,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (context, i) {
            final c = categories[i];
            return InkWell(
              onTap: () => onTap(c['label'] as String),
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 56,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(c['icon'] as IconData, size: 26, color: _P.primary),
                    const SizedBox(height: 6),
                    Text(
                      c['label'] as String,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: _P.ink),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// STATS ROW — "En un coup d'œil"
// ============================================================
class _StatsRow extends StatelessWidget {
  final Map<String, int> stats;
  const _StatsRow({required this.stats});

  static const _icons = {
    'Prestataires': Icons.storefront_outlined,
    'Avis vérifiés': Icons.reviews_outlined,
    'Offres actives': Icons.local_offer_outlined,
    'Événements': Icons.celebration_outlined,
  };

  static const _colors = {
    'Prestataires': _P.blue,
    'Avis vérifiés': _P.gold,
    'Offres actives': _P.green,
    'Événements': _P.primary,
  };

  @override
  Widget build(BuildContext context) {
    final entries = stats.entries.toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(entries.length, (i) {
          final e = entries[i];
          final color = _colors[e.key] ?? _P.primary;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i == entries.length - 1 ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(color: _P.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: _P.border)),
              child: Column(
                children: [
                  Icon(_icons[e.key] ?? Icons.info_outline, size: 18, color: color),
                  const SizedBox(height: 6),
                  Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _P.ink)),
                  const SizedBox(height: 2),
                  Text(e.key, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8.5, color: _P.inkSoft, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ============================================================
// OFFERS GRID — grandes cartes avec bloc icône dégradé
// ============================================================
class _OffersGrid extends StatelessWidget {
  final List<Map<String, dynamic>> offers;
  final void Function(String) onTap;
  const _OffersGrid({required this.offers, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: offers.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.92,
        ),
        itemBuilder: (context, i) {
          final o = offers[i];
          final colors = o['colors'] as List<Color>;
          return InkWell(
            onTap: () => onTap(o['title'] as String),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(color: _P.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _P.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: Center(child: Icon(o['icon'] as IconData, size: 34, color: Colors.white.withOpacity(0.9))),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(7)),
                            child: Text(o['discount'] as String, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: _P.primaryDark)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(o['title'] as String, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _P.ink)),
                        const SizedBox(height: 2),
                        Text(o['subtitle'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: _P.inkSoft, fontWeight: FontWeight.w500)),
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

// ============================================================
// PRESTATAIRES A LA UNE — style "Restaurants à proximité"
// ============================================================
class _ProvidersList extends StatelessWidget {
  final List<Map<String, dynamic>> providers;
  final void Function(String) onTap;
  const _ProvidersList({required this.providers, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 208,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: providers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final p = providers[i];
          final colors = p['colors'] as List<Color>;
          return InkWell(
            onTap: () => onTap(p['name'] as String),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 158,
              decoration: BoxDecoration(color: _P.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _P.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 100,
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: Center(child: Icon(p['icon'] as IconData, size: 32, color: Colors.white.withOpacity(0.9))),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.92), borderRadius: BorderRadius.circular(6)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, size: 12, color: _P.gold),
                                const SizedBox(width: 2),
                                Text('${p['rating']}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _P.ink)),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.92), shape: BoxShape.circle),
                            child: const Icon(Icons.favorite_border_rounded, size: 13, color: _P.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p['name'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _P.ink)),
                        Text(p['category'] as String, style: const TextStyle(fontSize: 10.5, color: _P.inkSoft, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(child: Text(p['zone'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, color: _P.inkSoft))),
                            Text(p['price'] as String, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: _P.primary)),
                          ],
                        ),
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

// ============================================================
// ANNONCES
// ============================================================
class _AnnouncementsList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final void Function(String) onTap;
  const _AnnouncementsList({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final a = items[i];
          final tagColor = a['tagColor'] as Color;
          return InkWell(
            onTap: () => onTap(a['title'] as String),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 148,
              decoration: BoxDecoration(color: _P.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _P.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 76,
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(color: tagColor.withOpacity(0.10), borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
                          child: Center(child: Icon(a['icon'] as IconData, size: 26, color: tagColor)),
                        ),
                        Positioned(
                          top: 7,
                          left: 7,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: tagColor, borderRadius: BorderRadius.circular(6)),
                            child: Text(a['tag'] as String, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3)),
                          ),
                        ),
                        Positioned(
                          top: 7,
                          right: 7,
                          child: Container(
                            width: 21,
                            height: 21,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(Icons.favorite_border_rounded, size: 11, color: _P.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(9, 7, 9, 9),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a['title'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _P.ink)),
                        Text(a['subtitle'] as String, style: const TextStyle(fontSize: 10, color: _P.inkSoft, fontWeight: FontWeight.w600)),
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

// ============================================================
// BANDEAU DE CONFIANCE
// ============================================================
class _TrustRow extends StatelessWidget {
  const _TrustRow();

  static const _items = [
    {'icon': Icons.verified_user_outlined, 'label': 'Paiement\nsécurisé'},
    {'icon': Icons.support_agent_rounded, 'label': 'Support\n24/7'},
    {'icon': Icons.workspace_premium_outlined, 'label': 'Prestataires\nvérifiés'},
    {'icon': Icons.autorenew_rounded, 'label': 'Annulation\nflexible'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(color: _P.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _P.border)),
      child: Row(
        children: _items.map((e) {
          return Expanded(
            child: Column(
              children: [
                Icon(e['icon'] as IconData, size: 20, color: _P.primary),
                const SizedBox(height: 6),
                Text(e['label'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: _P.inkSoft, fontWeight: FontWeight.w600, height: 1.2)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
