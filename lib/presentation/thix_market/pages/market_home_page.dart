// lib/presentation/thix_market/pages/market_home_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../providers/market_provider.dart';
import '../widgets/market/category_grid.dart';
import '../widgets/market/flash_sale_timer.dart';

class MarketHomePage extends StatefulWidget {
  const MarketHomePage({super.key});

  @override
  State<MarketHomePage> createState() => _MarketHomePageState();
}

class _MarketHomePageState extends State<MarketHomePage> {
  final ScrollController _scrollController = ScrollController();
  bool _isAppBarExpanded = true;

  static const Color navy = Color(0xFF1B2A4A);
  static const Color navyDeep = Color(0xFF10192E);
  static const Color gold = Color(0xFFC9962C);
  static const Color goldLight = Color(0xFFE8C98A);
  static const Color bgApp = Color(0xFFF6F7FB);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A1D29);
  static const Color textMuted = Color(0xFF8A8FA3);
  static const Color divider = Color(0xFFEDEEF3);
  static const Color danger = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() => _isAppBarExpanded = _scrollController.offset < 90);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketProvider>().loadHomeData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // IMAGE HELPER — placeholder + erreur visibles partout
  // ============================================================
  Widget _networkImage(String? url, {BoxFit fit = BoxFit.cover, double iconSize = 22}) {
    if (url == null || url.trim().isEmpty) {
      return Container(
        color: bgApp,
        alignment: Alignment.center,
        child: Icon(Icons.image_outlined, color: textMuted, size: iconSize),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (context, u) => Container(
        color: bgApp,
        alignment: Alignment.center,
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: gold),
        ),
      ),
      errorWidget: (context, u, e) => Container(
        color: bgApp,
        alignment: Alignment.center,
        child: Icon(Icons.image_not_supported_outlined, color: textMuted, size: iconSize),
      ),
    );
  }

  // Regroupe les produits par catégorie (basé sur le champ 'category')
  Map<String, List<dynamic>> _groupByCategory(List<dynamic> products) {
    final Map<String, List<dynamic>> grouped = {};
    for (final p in products) {
      final cat = (p['category'] ?? 'Autres').toString();
      grouped.putIfAbsent(cat, () => []).add(p);
    }
    return grouped;
  }

  static const Map<String, String> _categoryLabels = {
    'fashion': 'Mode & Accessoires',
    'electronics': 'Électronique',
    'home': 'Maison & Jardin',
    'services': 'Services',
    'vehicles': 'Véhicules',
    'realestate': 'Immobilier',
    'food': 'Alimentation',
    'beauty': 'Beauté & Bien-être',
    'sports': 'Sports & Loisirs',
  };

  @override
  Widget build(BuildContext context) {
    final marketProvider = context.watch<MarketProvider>();

    // Liste combinée pour "Tous les produits" (dédupliquée par id)
    final Map<String, dynamic> allById = {};
    for (final p in [
      ...marketProvider.flashSales,
      ...marketProvider.recommendedProducts,
      ...marketProvider.forYouProducts,
    ]) {
      allById[p['id'].toString()] = p;
    }
    final allProducts = allById.values.toList();
    final grouped = _groupByCategory(allProducts);

    return Scaffold(
      backgroundColor: bgApp,
      body: RefreshIndicator(
        color: gold,
        onRefresh: () => marketProvider.refresh(),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            _buildAppBar(marketProvider),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    if (marketProvider.promoBanners.isNotEmpty) ...[
                      _MarqueeBanner(
                        banners: marketProvider.promoBanners,
                        imageBuilder: _networkImage,
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (marketProvider.liveSessions.isNotEmpty) ...[
                      _buildLiveSessions(marketProvider.liveSessions),
                      const SizedBox(height: 16),
                    ],
                    _buildSectionCard(const CategoryGrid()),
                    const SizedBox(height: 16),
                    _buildSuperPromo(),
                    const SizedBox(height: 18),
                    if (marketProvider.flashSales.isNotEmpty) ...[
                      _buildFlashSales(marketProvider.flashSales),
                      const SizedBox(height: 18),
                    ],
                    if (marketProvider.featuredShops.isNotEmpty) ...[
                      _buildFeaturedShops(marketProvider.featuredShops),
                      const SizedBox(height: 18),
                    ],
                    // Sections séparées par catégorie
                    ...grouped.entries.map((entry) {
                      final label = _categoryLabels[entry.key] ?? entry.key;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: _buildCategorySection(label, entry.value),
                      );
                    }),
                    // Bloc final : tous les produits, tout confondu
                    if (allProducts.isNotEmpty) ...[
                      _buildAllProductsSection(allProducts),
                    ],
                    const SizedBox(height: 90),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildSectionCard(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: navy.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: child,
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================
  Widget _buildAppBar(MarketProvider provider) {
    return SliverAppBar(
      expandedHeight: 118,
      pinned: true,
      floating: true,
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      title: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isAppBarExpanded ? 0 : 1,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('THIX', style: TextStyle(fontWeight: FontWeight.w800, color: navy, fontSize: 18)),
            Text(' Market', style: TextStyle(fontWeight: FontWeight.w600, color: gold, fontSize: 18)),
          ],
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: Colors.white,
          padding: const EdgeInsets.only(top: 42),
          child: Column(
            children: [
              Row(
                children: [
                  const SizedBox(width: 14),
                  RichText(
                    text: const TextSpan(children: [
                      TextSpan(text: 'THIX', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 21, color: navy)),
                      TextSpan(text: ' Market', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 21, color: gold)),
                    ]),
                  ),
                  const Spacer(),
                  _buildIconButton(Icons.qr_code_scanner_rounded, () => context.push('/scan-qr')),
                  _buildIconButton(Icons.notifications_none_rounded, () => context.push('/market/notifications')),
                  _buildIconButton(Icons.storefront_rounded, () => context.push('/market/sell')),
                  const SizedBox(width: 8),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: GestureDetector(
                  onTap: () => context.push('/market/search'),
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.only(left: 12, right: 4),
                    decoration: BoxDecoration(
                      color: bgApp,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: divider),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, color: textMuted, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text('Rechercher…', style: TextStyle(color: textMuted, fontSize: 12.5)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [navy, navyDeep]),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('Scanner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bgApp, borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, size: 17, color: navy),
      ),
    );
  }

  Widget _sectionHeader({required String title, IconData? icon, Color? iconColor, VoidCallback? onSeeAll, Widget? trailing}) {
    return Row(
      children: [
        if (icon != null) ...[Icon(icon, color: iconColor ?? navy, size: 16), const SizedBox(width: 5)],
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: textDark, letterSpacing: -0.2)),
        const Spacer(),
        if (trailing != null) trailing,
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Row(children: const [
              Text('Voir tout', style: TextStyle(color: gold, fontWeight: FontWeight.w700, fontSize: 11.5)),
              Icon(Icons.chevron_right_rounded, size: 15, color: gold),
            ]),
          ),
      ],
    );
  }

  // ============================================================
  // LIVES
  // ============================================================
  Widget _buildLiveSessions(List<dynamic> lives) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(title: 'Lives en cours', icon: Icons.podcasts_rounded, iconColor: danger, onSeeAll: () => context.push('/market/live')),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: lives.length,
            itemBuilder: (context, index) {
              final live = lives[index];
              return GestureDetector(
                onTap: () => context.push('/market/live/${live['id']}'),
                child: Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: cardBg,
                    boxShadow: [BoxShadow(color: navy.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 5))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                          child: Stack(fit: StackFit.expand, children: [
                            _networkImage(live['thumbnail']),
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.3)]),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 6, left: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: danger, borderRadius: BorderRadius.circular(5)),
                                child: const Row(children: [
                                  Icon(Icons.fiber_manual_record, size: 5, color: Colors.white),
                                  SizedBox(width: 2),
                                  Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                ]),
                              ),
                            ),
                          ]),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(7),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(live['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: textDark)),
                            Text(live['city'] ?? '', style: const TextStyle(fontSize: 9.5, color: textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSuperPromo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [navy, navyDeep], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: navy.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: const [
                  Icon(Icons.workspace_premium_rounded, color: gold, size: 14),
                  SizedBox(width: 5),
                  Text('OFFRE PREMIUM', style: TextStyle(color: gold, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1)),
                ]),
                const SizedBox(height: 5),
                const Text('-50% sur tout', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => context.push('/market/promo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gold, foregroundColor: navyDeep, elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('J\'en profite', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
          ),
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), shape: BoxShape.circle),
            child: const Icon(Icons.local_offer_rounded, color: gold, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashSales(List<dynamic> flashSales) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          title: 'Offres Flash', icon: Icons.flash_on_rounded, iconColor: danger,
          trailing: FlashSaleTimer(endTime: DateTime.now().add(const Duration(hours: 2, minutes: 45))),
        ),
        const SizedBox(height: 8),
        _productGrid(flashSales.take(8).toList(), isFlash: true),
      ],
    );
  }

  Widget _buildFeaturedShops(List<dynamic> shops) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(title: 'Boutiques mises en avant', onSeeAll: () => context.push('/market/shops')),
        const SizedBox(height: 8),
        SizedBox(
          height: 88,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: shops.length,
            itemBuilder: (context, index) {
              final shop = shops[index];
              return GestureDetector(
                onTap: () => context.push('/market/shop/${shop['id']}'),
                child: Container(
                  width: 84,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cardBg, borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: navy.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: goldLight, width: 1.3)),
                        child: ClipOval(
                          child: SizedBox(width: 34, height: 34, child: _networkImage(shop['logo_url'], iconSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(shop['name'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10, color: textDark)),
                      Text(shop['city'] ?? '', style: const TextStyle(fontSize: 8.5, color: textMuted)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(String label, List<dynamic> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(title: label, onSeeAll: () => context.push('/market/category/$label')),
        const SizedBox(height: 8),
        _productGrid(products.take(6).toList()),
      ],
    );
  }

  Widget _buildAllProductsSection(List<dynamic> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(title: 'Tous les produits', icon: Icons.grid_view_rounded),
        const SizedBox(height: 8),
        _productGrid(products),
      ],
    );
  }

  Widget _productGrid(List<dynamic> products, {bool isFlash = false}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.72,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) => _buildProductGridItem(products[index], isFlash: isFlash),
    );
  }

  Widget _buildProductGridItem(Map<String, dynamic> product, {bool isFlash = false}) {
    final hasDiscount = product['discount_price'] != null && product['discount_price'] < product['price'];
    final price = (hasDiscount ? product['discount_price'] : product['price']).toDouble();
    final originalPrice = product['price'].toDouble();

    return GestureDetector(
      onTap: () => context.push('/market/product/${product['id']}'),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: navy.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: Stack(fit: StackFit.expand, children: [
                  _networkImage(product['image_url']),
                  if (hasDiscount)
                    Positioned(top: 5, left: 5, child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(color: danger, borderRadius: BorderRadius.circular(5)),
                      child: Text('-${((1 - price / originalPrice) * 100).round()}%', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    )),
                  if (isFlash)
                    Positioned(top: 5, right: 5, child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(5)),
                      child: const Text('FLASH', style: TextStyle(color: navyDeep, fontSize: 7, fontWeight: FontWeight.bold)),
                    )),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: textDark)),
                  const SizedBox(height: 3),
                  Row(children: [
                    Text('${price.toInt()} FC', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: navy)),
                    if (hasDiscount) Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text('${originalPrice.toInt()}', style: const TextStyle(decoration: TextDecoration.lineThrough, fontSize: 8.5, color: textMuted)),
                    ),
                  ]),
                  const SizedBox(height: 3),
                  Row(children: [
                    Icon(Icons.location_on_rounded, size: 10, color: textMuted),
                    const SizedBox(width: 2),
                    Expanded(child: Text(product['city'] ?? '', style: const TextStyle(fontSize: 8.5, color: textMuted), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: navy.withOpacity(0.08), blurRadius: 14, offset: const Offset(0, -3))]),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, 'Accueil', 0),
              _buildNavItem(Icons.category_rounded, 'Catégories', 1),
              _buildNavItem(Icons.shopping_cart_rounded, 'Panier', 2),
              _buildNavItem(Icons.message_rounded, 'Messages', 3),
              _buildNavItem(Icons.person_rounded, 'Compte', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = index == 0;
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: () {
        switch (index) {
          case 1: context.push('/market/search'); break;
          case 2: context.push('/market/cart'); break;
          case 3: context.push('/market/messages'); break;
          case 4: context.push('/market/activity'); break;
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: isSelected ? navy : textMuted, size: 20),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 9.5, color: isSelected ? navy : textMuted, fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal)),
        ]),
      ),
    );
  }
}

// ============================================================
// BANNIÈRE PUB — défilement continu gauche → droite
// ============================================================
class _MarqueeBanner extends StatefulWidget {
  final List<dynamic> banners;
  final Widget Function(String? url, {BoxFit fit, double iconSize}) imageBuilder;

  const _MarqueeBanner({required this.banners, required this.imageBuilder});

  @override
  State<_MarqueeBanner> createState() => _MarqueeBannerState();
}

class _MarqueeBannerState extends State<_MarqueeBanner> {
  final ScrollController _controller = ScrollController();
  Timer? _timer;
  static const double _itemWidth = 260;
  static const double _speed = 0.6; // px par tick

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() {
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_controller.hasClients) return;
      final max = _controller.position.maxScrollExtent;
      double next = _controller.offset + _speed;
      if (next >= max) next = 0;
      _controller.jumpTo(next);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // On duplique la liste pour un effet de boucle fluide
    final loopBanners = [...widget.banners, ...widget.banners];
    return SizedBox(
      height: 110,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.builder(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: loopBanners.length,
          itemBuilder: (context, index) {
            final banner = loopBanners[index];
            return Container(
              width: _itemWidth,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
              clipBehavior: Clip.antiAlias,
              child: widget.imageBuilder(banner['image_url'], fit: BoxFit.cover, iconSize: 26),
            );
          },
        ),
      ),
    );
  }
}
