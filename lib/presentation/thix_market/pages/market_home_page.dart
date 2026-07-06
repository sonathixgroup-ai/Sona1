import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../providers/market_provider.dart';
import '../providers/shop_provider.dart';
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

  // Couleurs - Bleu lumineux
  static const Color primaryBlue = Color(0xFF0066FF);
  static const Color lightBlue = Color(0xFFE8F4FD);
  static const Color softBlue = Color(0xFFF0F7FF);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF1A1A2E);
  static const Color mutedText = Color(0xFF6B7280);
  static const Color gold = Color(0xFFFFC107);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() => _isAppBarExpanded = _scrollController.offset < 90);
    });
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

  void _goToSell(ShopProvider shopProvider) {
    if (shopProvider.hasShop) {
      context.push('/market/sell');
    } else {
      context.push('/market/shop/create');
    }
  }

  void _goToCart() => context.push('/market/cart');

  Widget _networkImage(String? url, {BoxFit fit = BoxFit.cover, double iconSize = 22, IconData icon = Icons.image_outlined}) {
    if (url == null || url.trim().isEmpty) {
      return Container(color: softBlue, alignment: Alignment.center, child: Icon(icon, color: mutedText, size: iconSize));
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (_, __) => Container(
        color: softBlue,
        alignment: Alignment.center,
        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: primaryBlue)),
      ),
      errorWidget: (_, __, ___) => Container(
        color: softBlue,
        alignment: Alignment.center,
        child: Icon(Icons.image_not_supported_outlined, color: mutedText, size: iconSize),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final marketProvider = context.watch<MarketProvider>();
    final shopProvider = context.watch<ShopProvider>();

    final Map<String, dynamic> allById = {};
    for (final p in [
      ...marketProvider.flashSales,
      ...marketProvider.recommendedProducts,
      ...marketProvider.forYouProducts,
    ]) {
      allById[p['id'].toString()] = p;
    }
    final allProducts = allById.values.toList();

    return Scaffold(
      backgroundColor: pureWhite,
      body: RefreshIndicator(
        color: primaryBlue,
        onRefresh: () => marketProvider.refresh(),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // AppBar avec localisation et recherche
            _buildSearchHeader(marketProvider, shopProvider),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bannière "Special Offer"
                    _buildSpecialOfferBanner(),
                    const SizedBox(height: 16),
                    // Catégories (style badges)
                    _buildCategorySection(),
                    const SizedBox(height: 16),
                    // Flash Sale avec compteur
                    if (marketProvider.flashSales.isNotEmpty) ...[
                      _buildFlashSaleSection(marketProvider.flashSales),
                      const SizedBox(height: 16),
                    ],
                    // Recommandé
                    _buildRecommendedSection(marketProvider.recommendedProducts),
                    const SizedBox(height: 16),
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
      bottomNavigationBar: _buildBottomNavBar(marketProvider, shopProvider),
    );
  }

  // ============================================================
  // HEADER : Localisation + Recherche
  // ============================================================
  Widget _buildSearchHeader(MarketProvider marketProvider, ShopProvider shopProvider) {
    return SliverAppBar(
      expandedHeight: 90,
      pinned: true,
      floating: true,
      elevation: 0,
      backgroundColor: pureWhite,
      surfaceTintColor: pureWhite,
      title: Row(
        children: [
          const Icon(Icons.location_on, size: 14, color: primaryBlue),
          const SizedBox(width: 4),
          const Text('New York, USA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: darkText)),
          const Spacer(),
          _buildIconButton(Icons.search, () => context.push('/market/search')),
          _buildIconButton(Icons.notifications_none, () => context.push('/market/notifications')),
          _buildIconButton(Icons.storefront, () => _goToSell(shopProvider)),
        ],
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: pureWhite,
          padding: const EdgeInsets.only(top: 44),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(Icons.location_on, size: 14, color: primaryBlue),
              const SizedBox(width: 4),
              const Text('New York, USA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: darkText)),
              const Spacer(),
              _buildIconButton(Icons.search, () => context.push('/market/search')),
              _buildIconButton(Icons.notifications_none, () => context.push('/market/notifications')),
              _buildIconButton(Icons.storefront, () => _goToSell(shopProvider)),
              const SizedBox(width: 8),
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
        decoration: BoxDecoration(color: softBlue, borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, size: 17, color: darkText),
      ),
    );
  }

  // ============================================================
  // BANNIÈRE SPECIAL OFFER
  // ============================================================
  Widget _buildSpecialOfferBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0066FF), Color(0xFF0044CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Limited time!',
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Get Special Offer',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Up to 40%',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text(
                  'All Services Available | T&C Applied',
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Text(
                    'Claim',
                    style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.local_offer, color: Colors.white, size: 60),
        ],
      ),
    );
  }

  // ============================================================
  // CATÉGORIES (style badges)
  // ============================================================
  Widget _buildCategorySection() {
    final categories = [
      {'icon': Icons.checkroom, 'label': 'Clothes'},
      {'icon': Icons.phone_android, 'label': 'Electronics'},
      {'icon': Icons.shopping_bag, 'label': 'Shoes'},
      {'icon': Icons.watch, 'label': 'Watch'},
      {'icon': Icons.home, 'label': 'Home'},
      {'icon': Icons.sports_soccer, 'label': 'Sports'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkText)),
            TextButton(
              onPressed: () => context.push('/market/search'),
              child: const Text('See All', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w600)),
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
            const Text('Flash Sale', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkText)),
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
              return Container(
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
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.deepOrange,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'FLASH',
                                  style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
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
                          Text(
                            '${(product['price'] as num).toInt()} FCFA',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: primaryBlue),
                          ),
                        ],
                      ),
                    ),
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
              child: const Text('See All', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w600)),
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
              return Container(
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
                        child: _networkImage(product['image_url']),
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
                          Text(
                            '${(product['price'] as num).toInt()} FCFA',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: primaryBlue),
                          ),
                        ],
                      ),
                    ),
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
            child: const Text('See All', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }

  // ============================================================
  // BOTTOM NAV BAR
  // ============================================================
  Widget _buildBottomNavBar(MarketProvider marketProvider, ShopProvider shopProvider) {
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
              _buildNavItem(Icons.home_rounded, 'Home', true, () {}),
              _buildNavItem(Icons.favorite_border_rounded, 'Wishlist', false, () => context.push('/market/activity')),
              _buildNavItem(Icons.shopping_cart_rounded, 'Cart', false, _goToCart),
              _buildNavItem(Icons.chat_rounded, 'Chat', false, () => context.push('/market/messages')),
              _buildNavItem(Icons.person_outline_rounded, 'Profile', false, () => context.push('/market/activity')),
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
