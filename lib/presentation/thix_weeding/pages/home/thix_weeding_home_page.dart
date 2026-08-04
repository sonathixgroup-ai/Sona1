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
// PALETTE — Charte THIX Premium (Entreprise & Épuré)
// ============================================================
class _P {
  static const bg = Color(0xFFF8F9FA); // Fond perle très clair, moderne
  static const surface = Colors.white;
  static const primary = Color(0xFF0F172A); // Bleu nuit très profond / Slate
  static const accent = Color(0xFFD4AF37); // Or premium / Champagne
  static const accentSoft = Color(0xFFFDF8EE); // Fond champagne très léger
  
  static const ink = Color(0xFF1E293B); // Texte principal
  static const inkSoft = Color(0xFF64748B); // Texte secondaire
  static const border = Color(0xFFE2E8F0); // Bordures très discrètes
  
  // Ombre standardisée pour les cartes (effet flottant premium)
  static final shadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 15,
      offset: const Offset(0, 4),
    )
  ];
}

// ============================================================
// PROVIDERS (Données allégées des couleurs hardcodées)
// ============================================================
@riverpod
Future<List<Map<String, dynamic>>> homePromoSlides(HomePromoSlidesRef ref) async {
  await Future.delayed(const Duration(milliseconds: 250));
  return [
    {
      'tag': 'PROMO FLASH',
      'title': "Jusqu'à -40%",
      'subtitle': 'Sur les salles de réception & traiteurs',
      'detail': "Valable jusqu'au 30 Septembre 2026",
      'cta': 'Profiter maintenant',
      'imageUrl': 'https://picsum.photos/seed/wedding-venue/900/600',
    },
    {
      'tag': 'NOUVEAU',
      'title': 'Créez votre site',
      'subtitle': "De mariage en 5 minutes",
      'detail': 'ID unique + invitations digitales',
      'cta': 'Commencer',
      'imageUrl': 'https://picsum.photos/seed/wedding-couple/900/600',
    },
    {
      'tag': 'PARTENAIRES',
      'title': '+300 prestataires',
      'subtitle': 'Vérifiés partout en RDC',
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
    {'title': 'Salles de fête', 'subtitle': 'Réservez votre salle', 'discount': '-25%', 'icon': Icons.villa_outlined},
    {'title': 'Traiteurs', 'subtitle': 'Menus spéciaux', 'discount': '-20%', 'icon': Icons.restaurant_outlined},
    {'title': 'Décoration', 'subtitle': 'Ambiances uniques', 'discount': '-15%', 'icon': Icons.local_florist_outlined},
    {'title': 'Photographes', 'subtitle': 'Immortalisez tout', 'discount': '-20%', 'icon': Icons.camera_alt_outlined},
  ];
}

@riverpod
Future<List<Map<String, dynamic>>> homeProviders(HomeProvidersRef ref) async {
  await Future.delayed(const Duration(milliseconds: 300));
  return [
    {'name': 'Salle Émeraude', 'category': 'Salle de fête', 'zone': 'Gombe · 20-30 min', 'rating': 4.8, 'price': '\$\$', 'icon': Icons.villa_outlined},
    {'name': 'Chef Amani', 'category': 'Traiteur', 'zone': 'Limete · 15-25 min', 'rating': 4.7, 'price': '\$\$', 'icon': Icons.restaurant_outlined},
    {'name': 'Fleurs de Kin', 'category': 'Décoration', 'zone': 'Ngaliema · 20-30 min', 'rating': 4.9, 'price': '\$', 'icon': Icons.local_florist_outlined},
    {'name': 'Studio Lumière', 'category': 'Photographe', 'zone': 'Kintambo · 25-35 min', 'rating': 4.8, 'price': '\$\$\$', 'icon': Icons.camera_alt_outlined},
  ];
}

@riverpod
Future<List<Map<String, dynamic>>> homeAnnouncements(HomeAnnouncementsRef ref) async {
  await Future.delayed(const Duration(milliseconds: 200));
  return [
    {'tag': 'À VENDRE', 'title': 'Robe de mariée T38', 'subtitle': '450.000 FC', 'icon': Icons.checkroom_outlined},
    {'tag': 'À LOUER', 'title': 'Salle 200 places', 'subtitle': '800.000 FC / jour', 'icon': Icons.villa_outlined},
    {'tag': 'SERVICE', 'title': 'Coiffure & maquillage', 'subtitle': "Dès 30.000 FC", 'icon': Icons.face_retouching_natural_outlined},
  ];
}

// ============================================================
// PAGE PRINCIPALE
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
      final next = (_promoIndex + 1) % 3;
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
        physics: const BouncingScrollPhysics(),
        slivers: [
          // RECHERCHE ID
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: _IdSearchBar(
                controller: _idController,
                focusNode: _focusNode,
                isLoading: _isSearching,
                onSearch: _onSearch,
                onScanQr: _onScanQr,
              ),
            ),
          ),

          // CARROUSEL HERO
          SliverToBoxAdapter(
            child: promosAsync.when(
              data: (slides) => _PromoCarousel(
                slides: slides,
                controller: _promoController,
                onPageChanged: (i) => setState(() => _promoIndex = i),
                currentIndex: _promoIndex,
              ),
              loading: () => const SizedBox(height: 220, child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // RACCOURCIS CATEGORIES
          SliverToBoxAdapter(
            child: catsAsync.when(
              data: (cats) => _CategoryIconRow(categories: cats, onTap: _onTapGeneric),
              loading: () => const SizedBox(height: 90),
              error: (_, __) => const SizedBox(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // STATS "En un coup d'oeil"
          SliverToBoxAdapter(
            child: statsAsync.when(
              data: (stats) => _StatsRow(stats: stats),
              loading: () => const SizedBox(height: 90),
              error: (_, __) => const SizedBox(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 36)),

          // OFFRES SPECIALES
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _SectionHeader(title: 'Offres Privilèges'),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: offersAsync.when(
              data: (offers) => _OffersGrid(offers: offers, onTap: _onTapGeneric),
              loading: () => const SizedBox(height: 220, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
              error: (e, _) => SizedBox(height: 60, child: Center(child: Text('Erreur: $e'))),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 36)),

          // PRESTATAIRES A LA UNE
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _SectionHeader(title: 'Prestataires d\'Excellence'),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: providersAsync.when(
              data: (providers) => _ProvidersList(providers: providers, onTap: _onTapGeneric),
              loading: () => const SizedBox(height: 220, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
              error: (_, __) => const SizedBox(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 36)),

          // ANNONCES
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _SectionHeader(title: 'Dernières Annonces'),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: announcementsAsync.when(
              data: (ann) => _AnnouncementsList(items: ann, onTap: _onTapGeneric),
              loading: () => const SizedBox(height: 160, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
              error: (_, __) => const SizedBox(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 36)),

          // BANDEAU DE CONFIANCE
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _TrustRow(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _P.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 16,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: const TextSpan(
              style: TextStyle(fontFamily: 'Roboto', fontSize: 18, letterSpacing: 1.5, fontWeight: FontWeight.w700),
              children: [
                TextSpan(text: 'THIX ', style: TextStyle(color: _P.primary)),
                TextSpan(text: 'MARIAGE', style: TextStyle(color: _P.accent, fontWeight: FontWeight.w400)),
              ],
            ),
          ),
          const SizedBox(height: 2),
          const Text('L\'excellence pour votre événement', style: TextStyle(fontSize: 11, color: _P.inkSoft, fontWeight: FontWeight.w400)),
        ],
      ),
      actions: [
        _AppBarIconButton(icon: Icons.notifications_none_rounded, badgeCount: 3, onTap: () {}),
        const SizedBox(width: 8),
        _AppBarIconButton(icon: Icons.person_outline_rounded, onTap: () {}),
        const SizedBox(width: 16),
      ],
    );
  }
}

// ============================================================
// APP BAR ICON BUTTON (Clean)
// ============================================================
class _AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final int? badgeCount;
  final VoidCallback onTap;
  const _AppBarIconButton({required this.icon, required this.onTap, this.badgeCount});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _P.surface,
          shape: BoxShape.circle,
          boxShadow: _P.shadow,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 20, color: _P.primary),
            if (badgeCount != null)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: _P.accent, shape: BoxShape.circle),
                  child: Text('$badgeCount', style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// RECHERCHE ID — Premium Style
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _P.shadow,
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search_rounded, size: 22, color: _P.inkSoft),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _P.ink, letterSpacing: 1.0),
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Entrez un ID de mariage...',
                hintStyle: TextStyle(fontSize: 14, color: _P.inkSoft, fontWeight: FontWeight.w400, letterSpacing: 0),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => onSearch(),
            ),
          ),
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
// CARROUSEL HERO — Elegant
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
      height: 220, // Plus haut pour plus d'impact
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
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        s['imageUrl'] as String,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: _P.border),
                      ),
                      // Dégradé sombre luxueux
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                            stops: const [0.0, 0.7],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: _P.accent, borderRadius: BorderRadius.circular(4)),
                              child: Text(
                                (s['tag'] as String).toUpperCase(), 
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1.0)
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(s['title'] as String, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white, height: 1.1)),
                            const SizedBox(height: 4),
                            Text(s['subtitle'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Colors.white70)),
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
            bottom: 16,
            right: 32,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: List.generate(slides.length, (i) {
                final active = i == currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 24 : 8,
                  height: 4,
                  decoration: BoxDecoration(
                    color: active ? _P.accent : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
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
// SECTION HEADER — Épuré
// ============================================================
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: _P.primary, letterSpacing: -0.5)),
        InkWell(
          onTap: () {},
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text('VOIR TOUT', style: TextStyle(fontSize: 11, color: _P.inkSoft, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// CATEGORY ICON ROW — Flottant & Clean
// ============================================================
class _CategoryIconRow extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final void Function(String) onTap;
  const _CategoryIconRow({required this.categories, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, i) {
          final c = categories[i];
          return InkWell(
            onTap: () => onTap(c['label'] as String),
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _P.surface,
                    shape: BoxShape.circle,
                    boxShadow: _P.shadow,
                  ),
                  child: Icon(c['icon'] as IconData, size: 24, color: _P.primary),
                ),
                const SizedBox(height: 10),
                Text(
                  c['label'] as String,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _P.ink),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// STATS ROW — Float Cards
// ============================================================
class _StatsRow extends StatelessWidget {
  final Map<String, int> stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final entries = stats.entries.toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(entries.length, (i) {
          final e = entries[i];
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i == entries.length - 1 ? 0 : 12),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                color: _P.surface, 
                borderRadius: BorderRadius.circular(16), 
                boxShadow: _P.shadow,
              ),
              child: Column(
                children: [
                  Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: _P.primary)),
                  const SizedBox(height: 4),
                  Text(e.key.toUpperCase(), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8.5, color: _P.inkSoft, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
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
// OFFERS GRID — Style Corporate Premium
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
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.85, // Cartes un peu plus élancées
        ),
        itemBuilder: (context, i) {
          final o = offers[i];
          return InkWell(
            onTap: () => onTap(o['title'] as String),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: _P.surface, 
                borderRadius: BorderRadius.circular(16), 
                boxShadow: _P.shadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            color: _P.accentSoft,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: Center(child: Icon(o['icon'] as IconData, size: 36, color: _P.accent)),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: _P.primary, borderRadius: BorderRadius.circular(4)),
                            child: Text(o['discount'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(o['title'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _P.ink)),
                        const SizedBox(height: 4),
                        Text(o['subtitle'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: _P.inkSoft, fontWeight: FontWeight.w400)),
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
// PRESTATAIRES A LA UNE — Élégance & Clarté
// ============================================================
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
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 170,
              decoration: BoxDecoration(
                color: _P.surface, 
                borderRadius: BorderRadius.circular(16), 
                boxShadow: _P.shadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 110,
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: _P.primary,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: Center(child: Icon(p['icon'] as IconData, size: 36, color: Colors.white24)),
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: _P.surface, borderRadius: BorderRadius.circular(6)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, size: 12, color: _P.accent),
                                const SizedBox(width: 4),
                                Text('${p['rating']}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _P.ink)),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(color: _P.surface, shape: BoxShape.circle),
                            child: const Icon(Icons.favorite_border_rounded, size: 14, color: _P.inkSoft),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p['name'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _P.ink)),
                        const SizedBox(height: 2),
                        Text(p['category'] as String, style: const TextStyle(fontSize: 11, color: _P.accent, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 12, color: _P.inkSoft),
                            const SizedBox(width: 4),
                            Expanded(child: Text(p['zone'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: _P.inkSoft))),
                            Text(p['price'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _P.primary)),
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
// ANNONCES — Cartes minimalistes
// ============================================================
class _AnnouncementsList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final void Function(String) onTap;
  const _AnnouncementsList({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, i) {
          final a = items[i];
          return InkWell(
            onTap: () => onTap(a['title'] as String),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 150,
              decoration: BoxDecoration(
                color: _P.surface, 
                borderRadius: BorderRadius.circular(16), 
                boxShadow: _P.shadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 80,
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(color: _P.accentSoft, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                          child: Center(child: Icon(a['icon'] as IconData, size: 28, color: _P.accent)),
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(color: _P.surface, borderRadius: BorderRadius.circular(4)),
                            child: Text(a['tag'] as String, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: _P.ink, letterSpacing: 0.5)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a['title'] as String, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _P.ink, height: 1.2)),
                        const Spacer(),
                        Text(a['subtitle'] as String, style: const TextStyle(fontSize: 11, color: _P.primary, fontWeight: FontWeight.w700)),
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
// BANDEAU DE CONFIANCE — Intégration fondue
// ============================================================
class _TrustRow extends StatelessWidget {
  const _TrustRow();

  static const _items = [
    {'icon': Icons.shield_outlined, 'label': 'Sécurisé'},
    {'icon': Icons.headset_mic_outlined, 'label': 'Support 24/7'},
    {'icon': Icons.verified_outlined, 'label': 'Vérifié'},
    {'icon': Icons.sync_alt_rounded, 'label': 'Flexible'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _P.shadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _items.map((e) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(e['icon'] as IconData, size: 22, color: _P.accent),
              const SizedBox(height: 8),
              Text(e['label'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: _P.inkSoft, fontWeight: FontWeight.w500)),
            ],
          );
        }).toList(),
      ),
    );
  }
}
