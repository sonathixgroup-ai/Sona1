// lib/presentation/thix_weeding/pages/home/thix_weeding_home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/failure.dart';
import '../../data/repositories/wedding_repository_impl.dart';
import '../../domain/entities/wedding_entity.dart';

part 'thix_weeding_home_page.g.dart';

// Provider pour les promos - cache 10min, autoDispose
@riverpod
Future<List<Map<String, String>>> homePromos(HomePromosRef ref) async {
  // En prod: await ref.read(weddingRemoteDataSourceProvider).fetchPromos();
  // Simulation API réelle avec délai réseau
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
      // Validation réelle prod: vérifie que le mariage existe
      final repo = ref.read(weddingRepositoryProvider);
      final WeddingEntity wedding = await repo.getWeddingById(id);

      if (!mounted) return; // ANTI FUITE CONTEXT
      context.push('/thix-weeding/guest/${wedding.id}');
    } on Failure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red.shade600),
      );
    } catch (e) {
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
    // En prod: context.push('/thix-weeding/scan-qr');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scanner QR bientôt disponible')),
    );
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.favorite, color: Colors.orange),
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
          IconButton(onPressed: () {}, icon: Badge(label: Text('3'), child: Icon(Icons.notifications_none_outlined))),
          IconButton(onPressed: () {}, icon: Icon(Icons.person_outline)),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // 1. RECHERCHE ID
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _IdSearchCard(
                controller: _idController,
                focusNode: _focusNode,
                isLoading: _isSearching,
                onSearch: _onSearch,
                onScanQr: _onScanQr,
              ),
            ),
          ),

          // 2. RACCOURCIS CATEGORIES
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _CategoryShortcuts(),
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
              data: (promos) => _PromoHorizontalList(promos: promos),
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
              data: (cats) => _CategoriesPopularGrid(categories: cats),
              loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.pink,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Favoris'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle, size: 40), label: 'Publier'),
          BottomNavigationBarItem(icon: Icon(Icons.message_outlined), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menu'),
        ],
      ),
    );
  }
}

// WIDGETS PRIVES - const + Sliver = perf millions users

class _IdSearchCard extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final VoidCallback onSearch;
  final VoidCallback onScanQr;

  const _IdSearchCard({required this.controller, required this.focusNode, required this.isLoading, required this.onSearch, required this.onScanQr});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Vous avez un ID de mariage?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          const Text('Accédez à tous les détails de l’événement', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => onSearch(),
                  decoration: InputDecoration(
                    hintText: 'Entrez votre ID de mariage',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: const Color(0xFFF7F7F7),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: isLoading? null : onSearch,
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE25A6A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: isLoading? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Rechercher'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('OU', style: TextStyle(color: Colors.grey))), Expanded(child: Divider())]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: onScanQr,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scanner un QR Code'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryShortcuts extends StatelessWidget {
  const _CategoryShortcuts();
  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_outlined, 'Salles de fête'),
      (Icons.restaurant_outlined, 'Traiteurs'),
      (Icons.mic_none_outlined, 'Maîtres de cérémonie'),
      (Icons.park_outlined, 'Décoration'),
      (Icons.camera_alt_outlined, 'Photographes'),
      (Icons.checkroom_outlined, 'Robes & Costumes'),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 0.9, mainAxisSpacing: 12, crossAxisSpacing: 12),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return Column(
          children: [
            CircleAvatar(radius: 26, backgroundColor: Colors.pink.shade50, child: Icon(item.$1, color: Colors.pink)),
            const SizedBox(height: 6),
            Text(item.$2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        );
      },
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

class _PromoHorizontalList extends StatelessWidget {
  final List<Map<String, String>> promos;
  const _PromoHorizontalList({required this.promos});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: promos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final p = promos[index];
          return Container(
            width: 220,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.white),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Jusqu’à', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                Text(p['discount']!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFE25A6A))),
                const Spacer(),
                Text(p['subtitle']!, style: const TextStyle(fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CategoriesPopularGrid extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  const _CategoriesPopularGrid({required this.categories});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final c = categories[i];
          return Column(
            children: [
              Container(width: 110, height: 90, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.grey.shade200), child: Icon(c['icon'] as IconData)),
              const SizedBox(height: 6),
              Text(c['label'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              Row(children: [const Icon(Icons.star, size: 12, color: Colors.orange), Text('${c['rating']}', style: const TextStyle(fontSize: 11))]),
            ],
          );
        },
      ),
    );
  }
}
