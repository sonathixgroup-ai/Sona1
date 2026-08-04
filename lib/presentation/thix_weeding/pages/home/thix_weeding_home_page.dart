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
// PALETTE PREMIUM — Charte THIX MARIAGE (Luxe, Amour, Élégance)
// ============================================================
class _P {
  static const bg = Color(0xFFFAFAFA); // Gris perle très clair, ultra propre
  static const surface = Colors.white;
  
  // Le "Rouge Roger" renforcé : Un rouge rubis profond et luxueux
  static const primary = Color(0xFFD60036); 
  static const primarySoft = Color(0xFFFFF0F3); // Fond léger pour les touches rouges
  
  static const accent = Color(0xFFD4AF37); // Or premium classique
  static const accentSoft = Color(0xFFFDF6E3);

  static const ink = Color(0xFF1A1A1A); // Noir riche pour les titres
  static const inkSoft = Color(0xFF757575); // Gris élégant pour les sous-titres
  static const border = Color(0xFFEEEEEE); // Bordures très subtiles

  static const gradPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD60036), Color(0xFFFF2A5F)],
  );

  static final shadow = [
    BoxShadow(
      color: const Color(0xFFD60036).withOpacity(0.15),
      blurRadius: 24,
      offset: const Offset(0, 10),
    )
  ];

  static final shadowSoft = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 16,
      offset: const Offset(0, 6),
    )
  ];
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
      'subtitle': 'Sur les salles de réception',
      'detail': "Valable jusqu'au 30 Septembre 2026",
      'cta': 'Profiter maintenant',
      'imageUrl': 'https://images.unsplash.com/photo-1519225421980-715cb0215aed?q=80&w=1000',
    },
    {
      'tag': 'NOUVEAU',
      'title': 'Créez votre site',
      'subtitle': "De mariage en 5 minutes",
      'detail': 'ID unique + invitations digitales',
      'cta': 'Commencer',
      'imageUrl': 'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?q=80&w=1000',
    },
  ];
}

@riverpod
Future<List<Map<String, dynamic>>> homeCategories(HomeCategoriesRef ref) async {
  await Future.delayed(const Duration(milliseconds: 100));
  return [
    {'label': 'Salles', 'icon': Icons.villa_outlined},
    {'label': 'Traiteurs', 'icon': Icons.restaurant_outlined},
    {'label': 'Cérémonie', 'icon': Icons.mic_none_outlined},
    {'label': 'Décoration', 'icon': Icons.local_florist_outlined},
    {'label': 'Photos', 'icon': Icons.camera_alt_outlined},
    {'label': 'Vidéastes', 'icon': Icons.videocam_outlined},
    {'label': 'DJ & Son', 'icon': Icons.music_note_outlined},
    {'label': 'Robes', 'icon': Icons.checkroom_outlined},
    {'label': 'Costumes', 'icon': Icons.checkroom_outlined}, // 🌟 CORRECTION ICI : Remplacement de styler_outlined
    {'label': 'Voir Plus', 'icon': Icons.grid_view_rounded},
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
    {'title': 'Salles de fête', 'subtitle': 'Réservez votre salle idéale', 'discount': '-30%', 'icon': Icons.villa_outlined, 'color': _P.primary},
    {'title': 'Traiteurs', 'subtitle': 'Menus spéciaux mariage', 'discount': '-20%', 'icon': Icons.restaurant_outlined, 'color': _P.accent},
    {'title': 'Photographe offert', 'subtitle': 'Pour tout package complet', 'discount': 'OFFERT', 'icon': Icons.camera_alt_outlined, 'color': _P.ink},
  ];
}

@riverpod
Future<List<Map<String, dynamic>>> homeProviders(HomeProvidersRef ref) async {
  await Future.delayed(const Duration(milliseconds: 300));
  return [
    {'name': 'Palais des Congrès', 'category': 'Salle de fête', 'zone': 'Douala', 'rating': 4.8, 'reviews': 128, 'price': 'À partir de 600.000 FC', 'image': 'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?q=80&w=500'},
    {'name': "Saveurs d'Or", 'category': 'Traiteur', 'zone': 'Douala', 'rating': 4.9, 'reviews': 96, 'price': 'À partir de 450.000 FC', 'image': 'https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?q=80&w=500'},
    {'name': 'Lens Prod', 'category': 'Photographe', 'zone': 'Yaoundé', 'rating': 4.9, 'reviews': 215, 'price': 'À partir de 300.000 FC', 'image': 'https://images.unsplash.com/photo-1520854221256-17451cc331bf?q=80&w=500'},
    {'name': 'Dream Décor', 'category': 'Décoration', 'zone': 'Douala', 'rating': 4.7, 'reviews': 78, 'price': 'À partir de 250.000 FC', 'image': 'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?q=80&w=500'},
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

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _idController.dispose();
    _focusNode.dispose();
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
    final catsAsync = ref.watch(homeCategoriesProvider);
    final offersAsync = ref.watch(homeOffersProvider);
    final providersAsync = ref.watch(homeProvidersProvider);
    final announcementsAsync = ref.watch(homeAnnouncementsProvider);

    return Scaffold(
      backgroundColor: _P.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // HERO — Bannière Premium Plein Écran
          SliverToBoxAdapter(
            child: _HeroPremiumSection(
              controller: _idController,
              focusNode: _focusNode,
              isLoading: _isSearching,
              onSearch: _onSearch,
            ),
          ),

          // BOUTON SCAN QR (Flottant sous le hero)
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -25),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: InkWell(
                  onTap: _onScanQr,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _P.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _P.shadowSoft,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner_rounded, size: 20, color: _P.primary),
                        SizedBox(width: 12),
                        Text('Scanner une invitation QR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _P.ink)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // RACCOURCIS CATEGORIES ÉPURÉES
          SliverToBoxAdapter(
            child: catsAsync.when(
              data: (cats) => _CategoryPremiumGrid(categories: cats, onTap: _onTapGeneric),
              loading: () => const SizedBox(height: 180, child: Center(child: CircularProgressIndicator(color: _P.primary))),
              error: (_, __) => const SizedBox(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 36)),

          // OFFRES DU MOMENT
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _SectionHeader(title: 'Offres Exclusives'),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: offersAsync.when(
              data: (offers) => _OffersRow(offers: offers, onTap: _onTapGeneric),
              loading: () => const SizedBox(height: 170, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _P.primary))),
              error: (e, _) => SizedBox(height: 60, child: Center(child: Text('Erreur: $e'))),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 36)),

          // PRESTATAIRES A LA UNE
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _SectionHeader(title: "Prestataires d'Excellence"),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: providersAsync.when(
              data: (providers) => _ProvidersGrid(providers: providers, onTap: _onTapGeneric),
              loading: () => const SizedBox(height: 220, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _P.primary))),
              error: (_, __) => const SizedBox(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 36)),

          // BANDEAU DE CONFIANCE
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _TrustRow(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ],
      ),
    );
  }
}

// ============================================================
// HERO SECTION PREMIUM — Carrousel Auto-scrolling + Overlay
// ============================================================
class _HeroPremiumSection extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final VoidCallback onSearch;

  const _HeroPremiumSection({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSearch,
  });

  @override
  State<_HeroPremiumSection> createState() => _HeroPremiumSectionState();
}

class _HeroPremiumSectionState extends State<_HeroPremiumSection> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  // Images inspirantes de haute qualité
  final List<String> _bgImages = [
    'https://images.unsplash.com/photo-1519741497674-611481863552?q=80&w=1000', // Couple
    'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?q=80&w=1000', // Salle / Déco
    'https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?q=80&w=1000', // Repas / Table
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_pageController.hasClients) {
        _currentPage++;
        if (_currentPage >= _bgImages.length) _currentPage = 0;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 380, // Hauteur généreuse pour inspirer
      width: double.infinity,
      child: Stack(
        children: [
          // 1. Carrousel d'images de fond
          PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(), // Défilement géré par le timer uniquement
            itemCount: _bgImages.length,
            itemBuilder: (context, index) {
              return Image.network(
                _bgImages[index],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              );
            },
          ),

          // 2. Overlay sombre/dégradé pour rendre le texte parfaitement lisible
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7), // Plus sombre en bas pour le champ de recherche
                ],
              ),
            ),
          ),

          // 3. Contenu (Textes + Barre de recherche)
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end, // Aligner vers le bas
                children: [
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                      children: [
                        TextSpan(text: 'THIX ', style: TextStyle(color: Colors.white)),
                        TextSpan(text: 'MARIAGE', style: TextStyle(color: _P.primary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Le mariage de vos rêves\ncommence ici.',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, height: 1.15),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Accédez au planning, au menu et aux photos\nde l\'événement avec votre ID invité.',
                    style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w400, height: 1.4),
                  ),
                  const SizedBox(height: 28),
                  
                  // Barre de recherche Premium
                  Container(
                    height: 56,
                    padding: const EdgeInsets.only(left: 16, right: 6),
                    decoration: BoxDecoration(
                      color: _P.surface,
                      borderRadius: BorderRadius.circular(100), // Bordures très arrondies
                      boxShadow: _P.shadow,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, size: 22, color: _P.inkSoft),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: widget.controller,
                            focusNode: widget.focusNode,
                            textCapitalization: TextCapitalization.characters,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _P.ink),
                            decoration: const InputDecoration(
                              isDense: true,
                              hintText: 'Code d\'invitation (ID)',
                              hintStyle: TextStyle(fontSize: 14, color: _P.inkSoft, fontWeight: FontWeight.w500),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => widget.onSearch(),
                          ),
                        ),
                        InkWell(
                          onTap: widget.isLoading ? null : widget.onSearch,
                          borderRadius: BorderRadius.circular(100),
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: _P.gradPrimary,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: widget.isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                                  )
                                : const Text('Go', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24), // Espace pour laisser dépasser le bouton de scan
                ],
              ),
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
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 19, color: _P.ink, letterSpacing: -0.5)),
        InkWell(
          onTap: () {},
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text('Voir tout', style: TextStyle(fontSize: 13, color: _P.primary, fontWeight: FontWeight.w700)),
                Icon(Icons.chevron_right_rounded, size: 18, color: _P.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// CATEGORY GRID PREMIUM — Épuré et chic
// ============================================================
class _CategoryPremiumGrid extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final void Function(String) onTap;
  const _CategoryPremiumGrid({required this.categories, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5, // 5 colonnes
          mainAxisSpacing: 20,
          crossAxisSpacing: 8,
          childAspectRatio: 0.65, // Plus d'espace vertical pour éviter que le texte ne se coupe
        ),
        itemBuilder: (context, i) {
          final c = categories[i];
          final isMore = c['label'] == 'Voir Plus';
          
          return InkWell(
            onTap: () => onTap(c['label'] as String),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: isMore ? _P.surface : _P.primary.withOpacity(0.06), // Rouge très clair
                    shape: BoxShape.circle,
                    border: isMore ? Border.all(color: _P.border) : null,
                  ),
                  child: Icon(
                    c['icon'] as IconData, 
                    size: 24, 
                    color: isMore ? _P.inkSoft : _P.primary, // Rouge profond pour les icônes
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  c['label'] as String,
                  textAlign: TextAlign.center,
                  maxLines: 1, // Forcer sur 1 ligne
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11, 
                    fontWeight: isMore ? FontWeight.w600 : FontWeight.w700, 
                    color: isMore ? _P.inkSoft : _P.ink,
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

// ============================================================
// OFFRES DU MOMENT — Design Luxe
// ============================================================
class _OffersRow extends StatelessWidget {
  final List<Map<String, dynamic>> offers;
  final void Function(String) onTap;
  const _OffersRow({required this.offers, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: offers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, i) {
          final o = offers[i];
          final color = o['color'] as Color;
          return InkWell(
            onTap: () => onTap(o['title'] as String),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 150,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _P.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: _P.shadowSoft,
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(o['icon'] as IconData, size: 24, color: color),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: Text(o['discount'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(o['title'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _P.ink)),
                  const SizedBox(height: 4),
                  Text(o['subtitle'] as String, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: _P.inkSoft, fontWeight: FontWeight.w500, height: 1.3)),
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
// PRESTATAIRES D'EXCELLENCE — Design Éditorial
// ============================================================
class _ProvidersGrid extends StatelessWidget {
  final List<Map<String, dynamic>> providers;
  final void Function(String) onTap;
  const _ProvidersGrid({required this.providers, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: providers.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 16,
          childAspectRatio: 0.75, // Ajusté pour les images réelles
        ),
        itemBuilder: (context, i) {
          final p = providers[i];
          return InkWell(
            onTap: () => onTap(p['name'] as String),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _P.shadowSoft,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            p['image'] as String,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
                          child: const Icon(Icons.favorite_border_rounded, size: 16, color: _P.ink),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(p['name'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _P.ink)),
                const SizedBox(height: 4),
                Text('${p['category']} · ${p['zone']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: _P.inkSoft, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 15, color: _P.accent),
                    const SizedBox(width: 4),
                    Text('${p['rating']} (${p['reviews']})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _P.ink)),
                  ],
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
// BANDEAU DE CONFIANCE
// ============================================================
class _TrustRow extends StatelessWidget {
  const _TrustRow();

  static const _items = [
    {'icon': Icons.verified_user_outlined, 'label': 'Prestataires\nVérifiés'},
    {'icon': Icons.stars_rounded, 'label': 'Avis\nAuthentiques'},
    {'icon': Icons.headset_mic_outlined, 'label': 'Support\n7j/7'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _P.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _items.map((e) {
          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(e['icon'] as IconData, size: 28, color: _P.primary),
                const SizedBox(height: 12),
                Text(e['label'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: _P.ink, fontWeight: FontWeight.w700, height: 1.3)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
