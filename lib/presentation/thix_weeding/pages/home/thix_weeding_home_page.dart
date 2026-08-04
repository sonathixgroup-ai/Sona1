// lib/presentation/thix_weeding/pages/home/thix_weeding_home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/failure.dart';
import '../../data/repositories/wedding_repository_impl.dart';
import '../../domain/entities/wedding_entity.dart';
import '../../widgets/home/id_search_card_widget.dart';

part 'thix_weeding_home_page.g.dart';

// ============================================================
// PALETTE
// ============================================================
class _WeddingPalette {
  static const bg = Color(0xFFF9F7F8);
  static const primary = Color(0xFFE25A6A);
  static const primaryDark = Color(0xFFC94356);
  static const primarySoft = Color(0xFFFCE9EB);
  static const ink = Color(0xFF1E1E24);
  static const inkSoft = Color(0xFF8B8B96);
  static const border = Color(0xFFF0EAEC);
}

// ============================================================
// PROVIDERS
// ============================================================
@riverpod
Future<List<Map<String, dynamic>>> homePromos(HomePromosRef ref) async {
  await Future.delayed(const Duration(milliseconds: 300));
  return [
    {'title': 'Salles de fête', 'discount': '-25%', 'icon': Icons.villa_outlined, 'color': const Color(0xFFE8B84B)},
    {'title': 'Traiteurs', 'discount': '-20%', 'icon': Icons.restaurant_outlined, 'color': const Color(0xFF5AA9E2)},
    {'title': 'Décoration', 'discount': '-15%', 'icon': Icons.local_florist_outlined, 'color': const Color(0xFF6BBF7B)},
    {'title': 'Photographes', 'discount': '-20%', 'icon': Icons.camera_alt_outlined, 'color': const Color(0xFFB07AE0)},
  ];
}

@riverpod
Future<List<Map<String, dynamic>>> homeCategories(HomeCategoriesRef ref) async {
  await Future.delayed(const Duration(milliseconds: 200));
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
Future<List<Map<String, dynamic>>> homePopularCategories(HomePopularCategoriesRef ref) async {
  await Future.delayed(const Duration(milliseconds: 300));
  return [
    {'label': 'Salles de fête', 'rating': 4.8, 'icon': Icons.villa_outlined, 'color': const Color(0xFFE8B84B)},
    {'label': 'Traiteurs', 'rating': 4.7, 'icon': Icons.restaurant_outlined, 'color': const Color(0xFF5AA9E2)},
    {'label': 'Maîtres de cérémonie', 'rating': 4.9, 'icon': Icons.mic_none_outlined, 'color': const Color(0xFFB07AE0)},
    {'label': 'Photographes', 'rating': 4.8, 'icon': Icons.camera_alt_outlined, 'color': const Color(0xFF6BBF7B)},
    {'label': 'Robes de mariée', 'rating': 4.9, 'icon': Icons.checkroom_outlined, 'color': _WeddingPalette.primary},
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red.shade600),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID introuvable, vérifiez et réessayez')),
      );
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _onScanQr() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scanner QR bientôt disponible')),
    );
  }

  void _onCategoryTap(String label) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label bientôt disponible')));
  }

  @override
  Widget build(BuildContext context) {
    final promosAsync = ref.watch(homePromosProvider);
    final catsAsync = ref.watch(homeCategoriesProvider);
    final popularAsync = ref.watch(homePopularCategoriesProvider);

    return Scaffold(
      backgroundColor: _WeddingPalette.bg,
      appBar: _buildAppBar(),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // 1. RECHERCHE ID — seul visuel "mock-up" conservé (bannière du widget)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: IdSearchCardWidget(
                controller: _idController,
                focusNode: _focusNode,
                isLoading: _isSearching,
                onSearch: _onSearch,
                onScanQr: _onScanQr,
              ),
            ),
          ),

          // 2. RACCOURCIS CATEGORIES — icônes compactes, pas de photo
          SliverToBoxAdapter(
            child: catsAsync.when(
              data: (cats) => _CategoryIconRow(categories: cats, onTap: _onCategoryTap),
              loading: () => const SizedBox(height: 84),
              error: (_, __) => const SizedBox(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // 3. OFFRES SPECIALES — cartes compactes avec badge icône coloré
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _SectionHeader(title: 'Offres spéciales'),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
          SliverToBoxAdapter(
            child: promosAsync.when(
              data: (promos) => _PromoGrid(promos: promos),
              loading: () => const SizedBox(height: 140, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
              error: (e, _) => SizedBox(height: 60, child: Center(child: Text('Erreur: $e'))),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 22)),

          // 4. CATEGORIES POPULAIRES — liste compacte, icône + rating
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _SectionHeader(title: 'Catégories populaires'),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
          SliverToBoxAdapter(
            child: popularAsync.when(
              data: (cats) => _PopularCategoriesList(categories: cats),
              loading: () => const SizedBox(height: 96, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
              error: (_, __) => const SizedBox(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _WeddingPalette.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.favorite_rounded, color: _WeddingPalette.primary, size: 18),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MARIAGE+',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 0.2,
                  color: _WeddingPalette.ink,
                ),
              ),
              Text(
                'Tout pour un mariage parfait',
                style: TextStyle(fontSize: 10, color: _WeddingPalette.inkSoft),
              ),
            ],
          ),
        ],
      ),
      actions: [
        _AppBarIconButton(
          icon: Icons.notifications_none_rounded,
          badgeCount: 3,
          onTap: () {},
        ),
        const SizedBox(width: 6),
        _AppBarIconButton(icon: Icons.person_outline_rounded, onTap: () {}),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const _NavItem(icon: Icons.home_rounded, label: 'Accueil', selected: true),
              const _NavItem(icon: Icons.favorite_border_rounded, label: 'Favoris'),
              _PublishNavButton(onTap: () {}),
              const _NavItem(icon: Icons.chat_bubble_outline_rounded, label: 'Messages'),
              const _NavItem(icon: Icons.menu_rounded, label: 'Menu'),
            ],
          ),
        ),
      ),
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
        decoration: BoxDecoration(
          color: _WeddingPalette.bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 19, color: _WeddingPalette.ink),
            if (badgeCount != null)
              Positioned(
                top: 4,
                right: 5,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(color: _WeddingPalette.primary, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
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
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: _WeddingPalette.ink),
        ),
        InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(6),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text('Voir tout', style: TextStyle(fontSize: 12, color: _WeddingPalette.primary, fontWeight: FontWeight.w600)),
                Icon(Icons.chevron_right_rounded, size: 15, color: _WeddingPalette.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// CATEGORY ICON ROW (compact, no images)
// ============================================================
class _CategoryIconRow extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final void Function(String) onTap;
  const _CategoryIconRow({required this.categories, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 78,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final c = categories[i];
          return InkWell(
            onTap: () => onTap(c['label'] as String),
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 58,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _WeddingPalette.primarySoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(c['icon'] as IconData, size: 21, color: _WeddingPalette.primary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    c['label'] as String,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: _WeddingPalette.ink),
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
// PROMO GRID — cartes compactes avec badge icône (pas de photo)
// ============================================================
class _PromoGrid extends StatelessWidget {
  final List<Map<String, dynamic>> promos;
  const _PromoGrid({required this.promos});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: promos.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.65,
        ),
        itemBuilder: (context, i) {
          final p = promos[i];
          final Color color = p['color'] as Color;
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _WeddingPalette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(p['icon'] as IconData, size: 16, color: color),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p['discount'] as String,
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color),
                      ),
                    ),
                  ],
                ),
                Text(
                  p['title'] as String,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _WeddingPalette.ink),
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
// POPULAR CATEGORIES — liste compacte horizontale
// ============================================================
class _PopularCategoriesList extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  const _PopularCategoriesList({required this.categories});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final c = categories[i];
          final Color color = c['color'] as Color;
          return Container(
            width: 118,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _WeddingPalette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(c['icon'] as IconData, size: 15, color: color),
                ),
                const SizedBox(height: 8),
                Text(
                  c['label'] as String,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _WeddingPalette.ink, height: 1.15),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 13, color: Color(0xFFE8B84B)),
                    const SizedBox(width: 2),
                    Text('${c['rating']}', style: const TextStyle(fontSize: 10.5, color: _WeddingPalette.inkSoft, fontWeight: FontWeight.w600)),
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
// BOTTOM NAV ITEMS
// ============================================================
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  const _NavItem({required this.icon, required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    final color = selected ? _WeddingPalette.primary : _WeddingPalette.inkSoft;
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 21, color: color),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 9.5, color: color, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
        ],
      ),
    );
  }
}

class _PublishNavButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PublishNavButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          color: _WeddingPalette.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
      ),
    );
  }
}
