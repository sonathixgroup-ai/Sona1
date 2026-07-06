import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../providers/market_provider.dart';
import '../providers/shop_provider.dart';
import '../widgets/market/category_grid.dart';
import '../widgets/market/flash_sale_timer.dart';
import '../vendor/vendor_dashboard.dart'; // ✅ import du dashboard vendeur

class MarketHomePage extends StatefulWidget {
  const MarketHomePage({super.key});

  @override
  State<MarketHomePage> createState() => _MarketHomePageState();
}

class _MarketHomePageState extends State<MarketHomePage> {
  final ScrollController _scrollController = ScrollController();

  // Couleurs
  static const Color primaryBlue = Color(0xFF0066FF);
  static const Color softBlue = Color(0xFFF0F7FF);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF1A1A2E);
  static const Color mutedText = Color(0xFF6B7280);
  static const Color gold = Color(0xFFFFC107);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketProvider>().loadHomeData();
      context.read<ShopProvider>().loadMyShops();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ✅ Redirige vers l'espace vendeur (VendorDashboard)
  void _goToVendor() {
    context.push('/market/vendor/dashboard');
  }

  void _goToCart() => context.push('/market/cart');
  void _goToWishlist() => context.push('/market/buy'); // ✅ Wishlist → page Acheter

  Widget _networkImage(String? url, {BoxFit fit = BoxFit.cover}) {
    if (url == null || url.trim().isEmpty) {
      return Container(color: softBlue, alignment: Alignment.center, child: Icon(Icons.image_outlined, color: mutedText));
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (_, __) => Container(color: softBlue, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
      errorWidget: (_, __, ___) => Container(color: softBlue, child: Icon(Icons.image_not_supported_outlined, color: mutedText)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final marketProvider = context.watch<MarketProvider>();
    final shopProvider = context.watch<ShopProvider>();

    // Combinaison des produits pour la section "Tous les produits"
    final Map<String, dynamic> allById = {};
    for (final p in [
      ...marketProvider.flashSales,
      ...marketProvider.recommendedProducts,
      ...marketProvider.forYouProducts,
    ]) {
      allById[p['id'].toString()] = p;
    }
    final allProducts = allById.values.toList();

    // Bannières réelles
    final banners = marketProvider.promoBanners;

    return Scaffold(
      backgroundColor: pureWhite,
      body: RefreshIndicator(
        color: primaryBlue,
        onRefresh: () => marketProvider.refresh(),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // AppBar sans doublon de localisation
            _buildAppBar(marketProvider, shopProvider),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    // Bannières réelles (carousel)
                    if (banners.isNotEmpty) ...[
                      _buildBannerCarousel(banners),
                      const SizedBox(height: 16),
                    ],
                    // Catégories
                    _buildCategorySection(),
                    const SizedBox(height: 16),
                    // Flash Sale
                    if (marketProvider.flashSales.isNotEmpty) ...[
                      _buildFlashSaleSection(marketProvider.flashSales),
                      const SizedBox(height: 16),
                    ],
                    // Recommandé
                    if (marketProvider.recommendedProducts.isNotEmpty) ...[
                      _buildRecommendedSection(marketProvider.recommendedProducts),
                      const SizedBox(height: 16),
                    ],
                    // Tous les produits
                    if (allProducts.isNotEmpty) ...[
                      _sectionHeader('Tous les produits', onSeeAll: () => context.push('/market/buy')),
                      const SizedBox(height: 8),
                      _productGrid(allProducts),
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

  // ============================================================
  // APP BAR (sans doublon)
  // ============================================================
  Widget _buildAppBar(MarketProvider marketProvider, ShopProvider shopProvider) {
    // Récupérer la ville de l'utilisateur (mock pour l'instant, à remplacer par un vrai provider)
    final userCity = 'Abidjan, CI'; // À remplacer par la vraie localisation
    return SliverAppBar(
      pinned: true,
      floating: true,
      elevation: 0,
      backgroundColor: pureWhite,
      surfaceTintColor: pureWhite,
      title: Row(
        children: [
          Icon(Icons.location_on, size: 16, color: primaryBlue),
          const SizedBox(width: 4),
          Text(userCity, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: darkText)),
          const Spacer(),
          _buildIconButton(Icons.search, () => context.push('/market/search')),
          _buildIconButton(Icons.notifications_none, () => context.push('/market/notifications')),
          _buildIconButton(Icons.storefront, _goToVendor), // ✅ redirige vers l'espace vendeur
        ],
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
        decoration: BoxDecoration(color: softBlue, borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, size: 18, color: darkText),
      ),
    );
  }

  // ============================================================
  // BANNIÈRES (réelles, carousel)
  // ============================================================
  Widget _buildBannerCarousel(List<dynamic> banners) {
    return SizedBox(
      height: 140,
      child: PageView.builder(
        itemCount: banners.length,
        controller: PageController(viewportFraction: 0.92),
        itemBuilder: (context, index) {
          final banner = banners[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: NetworkImage(banner['image_url'] ?? ''),
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // CATÉGORIES
  // ============================================================
  Widget _buildCategorySection() {
    final categories = [
      {'icon': Icons.checkroom, 'label': 'Mode'},
      {'icon': Icons.phone_android, 'label': 'Électronique'},
      {'icon': Icons.home, 'label': 'Maison'},
      {'icon': Icons.build, 'label': 'Services'},
      {'icon': Icons.directions_car, 'label': 'Véhicules'},
      {'icon': Icons.house, 'label': 'Immobilier'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Catégories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkText)),
            TextButton(
              onPressed: () => context.push('/market/search'),
              child: const Text('Voir tout', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 70,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: softBlue,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(cat['icon'] as IconData, color: primaryBlue, size: 24),
                    ),
                    const SizedBox(height: 4),
                    Text(cat['label'] as String, style: TextStyle(fontSize: 11, color: darkText)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FLASH SALE
  // ============================================================
  Widget _buildFlashSaleSection(List<dynamic> flashSales) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Offres Flash', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkText)),
            FlashSaleTimer(endTime: DateTime.now().add(const Duration(hours: 2, minutes: 45))),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: flashSales.take(6).length,
            itemBuilder: (context, index) {
              final product = flashSales[index];
              return _buildProductHorizontalCard(product, isFlash: true);
            },
          ),
        ),
      ],
    );
  }

  // ============================================================
  // RECOMMANDÉ
  // ============================================================
  Widget _buildRecommendedSection(List<dynamic> products) {
    if (products.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recommandé', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkText)),
            TextButton(
              onPressed: () => context.push('/market/buy'),
              child: const Text('Voir tout', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: products.take(6).length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _buildProductHorizontalCard(product);
            },
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CARTE PRODUIT HORIZONTALE (pour Flash/Recommandé)
  // ============================================================
  Widget _buildProductHorizontalCard(Map<String, dynamic> product, {bool isFlash = false}) {
    final currency = product['currency'] ?? 'FC';
    final symbol = currency == 'USD' ? '\$' : 'FC';
    final price = (product['price'] as num).toInt();

    return GestureDetector(
      onTap: () => context.push('/market/product/${product['id']}'),
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: pureWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _networkImage(product['image_url']),
                    if (isFlash)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.deepOrange, borderRadius: BorderRadius.circular(4)),
                          child: const Text('FLASH', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['title'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: darkText),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '$price $symbol',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: primaryBlue),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 10, color: mutedText),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          product['city'] ?? 'Abidjan',
                          style: TextStyle(fontSize: 9, color: mutedText),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // GRILLE PRODUITS (Tous les produits)
  // ============================================================
  Widget _productGrid(List<dynamic> products) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.7,
      ),
      itemCount: products.length > 8 ? 8 : products.length,
      itemBuilder: (context, index) => _buildProductCard(products[index]),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final hasDiscount = product['discount_price'] != null && product['discount_price'] < product['price'];
    final price = (hasDiscount ? product['discount_price'] : product['price']).toDouble();
    final originalPrice = product['price'].toDouble();
    final currency = product['currency'] ?? 'FC';
    final symbol = currency == 'USD' ? '\$' : 'FC';

    return GestureDetector(
      onTap: () => context.push('/market/product/${product['id']}'),
      child: Container(
        decoration: BoxDecoration(
          color: pureWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _networkImage(product['image_url']),
                    if (hasDiscount)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '-${((1 - price / originalPrice) * 100).round()}%',
                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['title'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: darkText),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${price.toInt()} $symbol',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryBlue),
                      ),
                      if (hasDiscount)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(
                            '${originalPrice.toInt()} $symbol',
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              fontSize: 10,
                              color: mutedText,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 10, color: mutedText),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          product['city'] ?? 'Abidjan',
                          style: TextStyle(fontSize: 9, color: mutedText),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.store, size: 10, color: mutedText),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          product['shop']?['name'] ?? 'Vendeur',
                          style: TextStyle(fontSize: 9, color: mutedText),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkText)),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: const Text('Voir tout', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }

  // ============================================================
  // BOTTOM NAV BAR
  // ============================================================
  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: pureWhite,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, 'Accueil', true, () {}),
              _buildNavItem(Icons.favorite_border_rounded, 'Wishlist', false, _goToWishlist), // ✅ Wishlist → BuyPage
              _buildNavItem(Icons.shopping_cart_rounded, 'Panier', false, _goToCart),
              _buildNavItem(Icons.chat_rounded, 'Chat', false, () => context.push('/market/messages')),
              _buildNavItem(Icons.person_outline_rounded, 'Profil', false, () => context.push('/market/activity')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? primaryBlue : mutedText, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? primaryBlue : mutedText,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
