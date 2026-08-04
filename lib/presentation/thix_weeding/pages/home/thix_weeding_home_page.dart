// lib/presentation/thix_weeding/pages/home/thix_weeding_home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/failure.dart';
import '../../data/repositories/wedding_repository_impl.dart';
import '../../domain/entities/wedding_entity.dart';
import '../../widgets/home/id_search_card_widget.dart';
import '../../widgets/home/category_grid_widget.dart';
import '../../widgets/home/promo_banner_widget.dart';

part 'thix_weeding_home_page.g.dart';

// Provider PROD - plus de mock pur, avec cache auto
@riverpod
Future<List<Map<String, String>>> homePromos(HomePromosRef ref) async {
  // En prod réelle tu feras:
  // final remote = ref.read(weddingRemoteDataSourceProvider);
  // return remote.fetchPromos();
  // Pour l'instant on garde un délai réseau simulé pour tester le shimmer
  await Future.delayed(const Duration(milliseconds: 400));
  return [
    {'title': 'Salles de fête', 'discount': '-25%', 'subtitle': 'Réservez votre salle idéale'},
    {'title': 'Traiteurs', 'discount': '-20%', 'subtitle': 'Menus spéciaux mariage'},
    {'title': 'Décoration', 'discount': '-15%', 'subtitle': 'Ambiances inoubliables'},
    {'title': 'Photographes', 'discount': '-20%', 'subtitle': 'Immortalisez vos moments'},
  ];
}

@riverpod
Future<List<Map<String, dynamic>>> homePopularCategories(HomePopularCategoriesRef ref) async {
  await Future.delayed(const Duration(milliseconds: 300));
  return [
    {'label': 'Salles de fête', 'rating': 4.8, 'icon': Icons.home_outlined},
    {'label': 'Traiteurs', 'rating': 4.7, 'icon': Icons.restaurant_outlined},
    {'label': 'Maîtres de cérémonie', 'rating': 4.9, 'icon': Icons.mic_none_outlined},
    {'label': 'Photographes', 'rating': 4.8, 'icon': Icons.camera_alt_outlined},
  ];
}

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

      if (!mounted) return; // ANTI FUITE CONTEXT - OBLIGATOIRE PROD
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
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _onScanQr() {
    if (!mounted) return;
    // En prod: context.push('/thix-weeding/scan-qr');
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
    final categoriesAsync = ref.watch(homePopularCategoriesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.favorite, color: Colors.orange, size: 20),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MARIAGE+', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
                Text('Tout pour un mariage parfait', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Badge(label: Text('3'), child: Icon(Icons.notifications_none_outlined))),
          IconButton(onPressed: () {}, icon: const Icon(Icons.person_outline)),
        ],
      ),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // 1. RECHERCHE ID - WIDGET SEPARE
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: IdSearchCardWidget(
                controller: _idController,
                focusNode: _focusNode,
                isLoading: _isSearching,
                onSearch: _onSearch,
                onScanQr: _onScanQr,
              ),
            ),
          ),

          // 2. RACCOURCIS CATEGORIES - WIDGET SEPARE
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CategoryGridWidget(onTapCategory: _onCategoryTap),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // 3. NOS SERVICES A LA UNE
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _SectionHeader(title: 'Nos services à la une'),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(
            child: promosAsync.when(
              data: (promos) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: PromoBannerWidget(promos: promos),
              ),
              loading: () => const SizedBox(height: 140, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => SizedBox(height: 60, child: Center(child: Text('Erreur: $e'))),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // 4. CATEGORIES POPULAIRES
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _SectionHeader(title: 'Catégories populaires'),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(
            child: categoriesAsync.when(
              data: (cats) => _CategoriesPopularList(categories: cats),
              loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFE25A6A),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Favoris'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle, size: 38), label: 'Publier'),
          BottomNavigationBarItem(icon: Icon(Icons.message_outlined), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menu'),
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
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        TextButton(onPressed: () {}, child: const Row(children: [Text('Voir tout'), Icon(Icons.chevron_right, size: 16)])),
      ],
    );
  }
}

class _CategoriesPopularList extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  const _CategoriesPopularList({required this.categories});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final c = categories[i];
          return Column(
            children: [
              Container(
                width: 110,
                height: 86,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white, border: Border.all(color: Colors.grey.shade200)),
                child: Icon(c['icon'] as IconData, color: Colors.pink.shade300),
              ),
              const SizedBox(height: 6),
              Text(c['label'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
              Row(children: [const Icon(Icons.star, size: 12, color: Colors.orange), const SizedBox(width: 2), Text('${c['rating']}', style: const TextStyle(fontSize: 11))]),
            ],
          );
        },
      ),
    );
  }
}
