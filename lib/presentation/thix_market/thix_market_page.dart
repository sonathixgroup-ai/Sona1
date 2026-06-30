import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart' hide CarouselController;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import 'package:thix_id/models/market_category.dart';
import 'package:thix_id/models/market_live.dart';
import 'package:thix_id/models/market_product.dart';
import 'package:thix_id/models/market_store.dart';
import 'package:thix_id/presentation/thix_market/data/demo_data.dart';
import 'package:thix_id/presentation/thix_market/widgets/category_item.dart';
import 'package:thix_id/presentation/thix_market/widgets/flash_card.dart';
import 'package:thix_id/presentation/thix_market/widgets/live_card.dart';
import 'package:thix_id/presentation/thix_market/widgets/product_card.dart';
import 'package:thix_id/presentation/thix_market/widgets/store_card.dart';
import 'package:thix_id/services/market_service.dart';
import 'package:thix_id/theme.dart';

class ThixMarketPage extends StatefulWidget {
  const ThixMarketPage({super.key});

  @override
  State<ThixMarketPage> createState() => _ThixMarketPageState();
}

class _ThixMarketPageState extends State<ThixMarketPage> {
  final _market = ThixMarketService();
  final _searchController = TextEditingController();

  int _navIndex = 0;
  String? _selectedCategoryId;
  String _selectedCity = 'Abidjan';

  bool _loading = true;
  Object? _error;

  List<MarketCategory> _categories = const [];
  List<MarketProduct> _flash = const [];
  List<MarketStore> _stores = const [];
  List<MarketLive> _lives = const [];
  List<MarketProduct> _products = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await Future.wait([
        _market.listCategories(limit: 18),
        _market.listFlashProducts(limit: 12),
        _market.listRecommendedStores(limit: 10),
        _market.listLives(limit: 10),
        _market.listProducts(limit: 30, categoryId: _selectedCategoryId),
      ]);

      setState(() {
        _categories = (res[0] as List<MarketCategory>);
        _flash = (res[1] as List<MarketProduct>);
        _stores = (res[2] as List<MarketStore>);
        _lives = (res[3] as List<MarketLive>);
        _products = (res[4] as List<MarketProduct>);
      });
    } catch (e) {
      debugPrint('ThixMarketPage load failed: $e');
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MarketColors.bg,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Catégories'),
          NavigationDestination(icon: Icon(Icons.add_circle), label: 'Vendre'),
          NavigationDestination(icon: Icon(Icons.message_outlined), label: 'Messages'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Compte'),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: MarketColors.orangeDeep,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderRow(city: _selectedCity),
                const SizedBox(height: 12),
                _SearchField(controller: _searchController, onCameraTap: () {}),
                const SizedBox(height: 16),
                _BannerCarousel(),
                const SizedBox(height: 16),
                _CategoriesRow(
                  loading: _loading,
                  categories: _categories,
                  selectedCategoryId: _selectedCategoryId,
                  onSelect: (id) async {
                    setState(() => _selectedCategoryId = id);
                    await _load();
                  },
                ),
                const SizedBox(height: 18),
                _SectionTitle(title: 'Offres Flash', action: 'Voir tout', icon: Iconsax.flash_1),
                const SizedBox(height: 12),
                _FlashRow(loading: _loading, products: _flash),
                const SizedBox(height: 22),
                _SectionTitle(title: 'Boutiques recommandées', action: 'Voir tout'),
                const SizedBox(height: 12),
                _StoresRow(loading: _loading, stores: _stores),
                const SizedBox(height: 22),
                _SectionTitle(title: 'Lives en cours', action: 'Voir tout'),
                const SizedBox(height: 12),
                _LivesRow(loading: _loading, lives: _lives),
                const SizedBox(height: 22),
                _SectionTitle(title: 'Tous les produits', action: 'Filtrer', icon: Icons.tune_rounded),
                const SizedBox(height: 12),
                _ProductsGrid(loading: _loading, products: _products),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  _InlineErrorCard(error: _error!),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.city});
  final String city;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'THIX ',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: MarketColors.ink, fontWeight: FontWeight.w900, letterSpacing: -0.4),
              ),
              TextSpan(
                text: 'MARKET',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: MarketColors.orangeDeep, fontWeight: FontWeight.w900, letterSpacing: -0.4),
              ),
            ],
          ),
        ),
        Row(
          children: [
            const Icon(Icons.location_on_outlined, color: MarketColors.grayText, size: 18),
            const SizedBox(width: 4),
            Text(city, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: MarketColors.ink, fontWeight: FontWeight.w700))
          ],
        )
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onCameraTap});
  final TextEditingController controller;
  final VoidCallback onCameraTap;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Rechercher un produit…',
        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: MarketColors.grayText),
        prefixIcon: const Icon(Icons.search, color: MarketColors.grayText),
        suffixIcon: IconButton(
          onPressed: onCameraTap,
          icon: const Icon(Icons.camera_alt_outlined, color: MarketColors.grayText),
          highlightColor: Colors.transparent,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}

class _BannerCarousel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CarouselSlider(
      items: const [_BannerCard(), _BannerCard(), _BannerCard()],
      options: CarouselOptions(height: 180, autoPlay: true, enlargeCenterPage: true, viewportFraction: 0.92),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(colors: [MarketColors.ink, MarketColors.orangeDeep]),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('SOLDE FLASH', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.orange, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
            const SizedBox(height: 8),
            Text(
              "Jusqu'à -70%",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900, height: 1.1),
            ),
            const SizedBox(height: 8),
            Text('sur des milliers de produits', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.action, this.icon});
  final String title;
  final String action;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: MarketColors.orangeDeep),
              const SizedBox(width: 8),
            ],
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: MarketColors.ink)),
          ],
        ),
        Text(action, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: MarketColors.orangeDeep, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _CategoriesRow extends StatelessWidget {
  const _CategoriesRow({required this.loading, required this.categories, required this.selectedCategoryId, required this.onSelect});

  final bool loading;
  final List<MarketCategory> categories;
  final String? selectedCategoryId;
  final Future<void> Function(String? categoryId) onSelect;

  @override
  Widget build(BuildContext context) {
    final cats = categories.isEmpty
        ? ThixMarketDemoData.categories.map((t) => MarketCategory(id: t.toLowerCase(), title: t, sortOrder: 0, createdAt: DateTime.now(), updatedAt: DateTime.now())).toList(growable: false)
        : categories;
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: cats.length,
        itemBuilder: (_, i) {
          final c = cats[i];
          final isSelected = selectedCategoryId == c.id || (selectedCategoryId == null && i == 0);
          return CategoryItem(
            title: c.title,
            selected: isSelected,
            onTap: loading ? null : () => onSelect(i == 0 ? null : c.id),
          );
        },
      ),
    );
  }
}

class _FlashRow extends StatelessWidget {
  const _FlashRow({required this.loading, required this.products});
  final bool loading;
  final List<MarketProduct> products;

  @override
  Widget build(BuildContext context) {
    final items = products.isEmpty ? ThixMarketDemoData.placeholderProducts : products;
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (_, i) => FlashCard(product: items[i]),
      ),
    );
  }
}

class _StoresRow extends StatelessWidget {
  const _StoresRow({required this.loading, required this.stores});
  final bool loading;
  final List<MarketStore> stores;

  @override
  Widget build(BuildContext context) {
    if (stores.isEmpty && loading) {
      return const SizedBox(height: 170, child: Center(child: CircularProgressIndicator()));
    }
    if (stores.isEmpty) {
      return const SizedBox(height: 90, child: Center(child: Text('Aucune boutique pour le moment')));
    }
    return SizedBox(
      height: 170,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stores.length,
        itemBuilder: (_, i) => StoreCard(store: stores[i]),
      ),
    );
  }
}

class _LivesRow extends StatelessWidget {
  const _LivesRow({required this.loading, required this.lives});
  final bool loading;
  final List<MarketLive> lives;

  @override
  Widget build(BuildContext context) {
    if (lives.isEmpty && loading) {
      return const SizedBox(height: 220, child: Center(child: CircularProgressIndicator()));
    }
    if (lives.isEmpty) {
      return const SizedBox(height: 90, child: Center(child: Text('Aucun live pour le moment')));
    }
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: lives.length,
        itemBuilder: (_, i) => LiveCard(live: lives[i]),
      ),
    );
  }
}

class _ProductsGrid extends StatelessWidget {
  const _ProductsGrid({required this.loading, required this.products});
  final bool loading;
  final List<MarketProduct> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty && loading) {
      return const Padding(padding: EdgeInsets.all(18), child: Center(child: CircularProgressIndicator()));
    }
    if (products.isEmpty) {
      return const SizedBox(height: 90, child: Center(child: Text('Aucun produit pour le moment')));
    }
    return GridView.builder(
      itemCount: products.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: .66, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemBuilder: (_, i) => ProductCard(product: products[i]),
    );
  }
}

class _InlineErrorCard extends StatelessWidget {
  const _InlineErrorCard({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: MarketColors.stroke)),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Erreur de chargement Market: $error',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: MarketColors.ink, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
