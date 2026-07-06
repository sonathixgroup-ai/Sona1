// lib/presentation/thix_market/pages/market_home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
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

  static const Color primaryBlue = Color(0xFF1A73E8);
  static const Color lightBlue = Color(0xFFE8F0FE);
  static const Color secondaryBg = Color(0xFFF8F9FA);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF202124);
  static const Color textLight = Color(0xFF9AA0A6);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _isAppBarExpanded = _scrollController.offset < 100;
      });
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

  @override
  Widget build(BuildContext context) {
    final marketProvider = context.watch<MarketProvider>();

    return Scaffold(
      backgroundColor: secondaryBg,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildAppBar(marketProvider),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Lives en cours (dynamique)
                  if (marketProvider.liveSessions.isNotEmpty) ...[
                    _buildLiveSessions(marketProvider.liveSessions),
                    const SizedBox(height: 12),
                  ],
                  // 2. Catégories (widget statique, mais fonctionnel)
                  const CategoryGrid(),
                  const SizedBox(height: 12),
                  // 3. Bannières promotionnelles (dynamique)
                  if (marketProvider.promoBanners.isNotEmpty) ...[
                    _buildPromoBanners(marketProvider.promoBanners),
                    const SizedBox(height: 12),
                  ],
                  // 4. Offres Flash (dynamique)
                  if (marketProvider.flashSales.isNotEmpty) ...[
                    _buildFlashSales(marketProvider.flashSales),
                    const SizedBox(height: 16),
                  ],
                  // 5. Recommandé pour vous (dynamique)
                  if (marketProvider.recommendedProducts.isNotEmpty) ...[
                    _buildRecommendedSection(marketProvider.recommendedProducts),
                    const SizedBox(height: 16),
                  ],
                  // 6. Boutiques mises en avant (dynamique)
                  if (marketProvider.featuredShops.isNotEmpty) ...[
                    _buildFeaturedShops(marketProvider.featuredShops),
                    const SizedBox(height: 16),
                  ],
                  // 7. Découvrir plus (dynamique)
                  if (marketProvider.forYouProducts.isNotEmpty) ...[
                    _buildForYouSection(marketProvider.forYouProducts),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // ============================================================
  // APP BAR (inchangée)
  // ============================================================
  Widget _buildAppBar(MarketProvider provider) {
    return SliverAppBar(
      expandedHeight: 130,
      pinned: true,
      floating: true,
      elevation: 0,
      backgroundColor: Colors.white,
      title: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isAppBarExpanded ? 0 : 1,
        child: const Text(
          'THIX Market',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: primaryBlue,
            fontSize: 20,
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: Colors.white,
          padding: const EdgeInsets.only(top: 42, left: 0, right: 0),
          child: Column(
            children: [
              Row(
                children: [
                  const SizedBox(width: 16),
                  Image.asset(
                    'assets/images/thix_logo.png',
                    height: 32,
                    errorBuilder: (_, __, ___) => const Text(
                      'THIX',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _buildIconButton(
                    Icons.qr_code_scanner,
                    () => context.push('/scan-qr'),
                    Colors.grey.shade600,
                  ),
                  _buildIconButton(
                    Icons.notifications_none,
                    () => context.push('/market/notifications'),
                    Colors.grey.shade600,
                  ),
                  _buildIconButton(
                    Icons.storefront_outlined,
                    () => context.push('/market/sell'),
                    Colors.grey.shade600,
                  ),
                  const SizedBox(width: 16),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () => context.push('/market/search'),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: lightBlue,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Colors.grey[500], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Rechercher des produits...',
                            style: TextStyle(color: Colors.grey[500], fontSize: 14),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: primaryBlue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Scanner',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
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

  Widget _buildIconButton(IconData icon, VoidCallback onTap, Color color) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        child: Icon(icon, size: 22, color: color),
      ),
    );
  }

  // ============================================================
  // LIVES EN COURS (inchangé, dynamique)
  // ============================================================
  Widget _buildLiveSessions(List<dynamic> lives) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Lives en cours',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textDark,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => context.push('/market/live'),
              child: const Text(
                'Voir tout',
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: lives.length,
            itemBuilder: (context, index) {
              final live = lives[index];
              return GestureDetector(
                onTap: () => context.push('/market/live/${live['id']}'),
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: cardBg,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl: live['thumbnail'] ?? '',
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 6,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.fiber_manual_record, size: 6, color: Colors.white),
                                      SizedBox(width: 3),
                                      Text(
                                        'LIVE',
                                        style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    '${live['viewers'] ?? 0}',
                                    style: const TextStyle(color: Colors.white, fontSize: 9),
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
                              live['title'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              live['city'] ?? 'Abidjan',
                              style: TextStyle(fontSize: 10, color: textLight),
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
        ),
      ],
    );
  }

  // ============================================================
  // BANNIÈRES PROMO (dynamique)
  // ============================================================
  Widget _buildPromoBanners(List<dynamic> banners) {
    return CarouselSlider(
      options: CarouselOptions(
        height: 130,
        viewportFraction: 1,
        autoPlay: true,
        enlargeCenterPage: false,
      ),
      items: banners.map((banner) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: CachedNetworkImageProvider(
                banner['image_url'] ?? '',
              ),
              fit: BoxFit.cover,
            ),
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // OFFRES FLASH (dynamique)
  // ============================================================
  Widget _buildFlashSales(List<dynamic> flashSales) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.flash_on, color: Colors.red, size: 18),
            const SizedBox(width: 6),
            const Text(
              'Offres Flash',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textDark,
              ),
            ),
            const Spacer(),
            FlashSaleTimer(
              endTime: DateTime.now().add(
                const Duration(hours: 2, minutes: 45),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.55,
          ),
          itemCount: flashSales.take(8).length,
          itemBuilder: (context, index) {
            final product = flashSales[index];
            return _buildProductGridItem(product, isFlash: true);
          },
        ),
      ],
    );
  }

  // ============================================================
  // RECOMMANDÉ POUR VOUS (dynamique)
  // ============================================================
  Widget _buildRecommendedSection(List<dynamic> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Recommandé pour vous',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textDark,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => context.push('/market/recommended'),
              child: const Text(
                'Voir tout',
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.55,
          ),
          itemCount: products.take(8).length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _buildProductGridItem(product);
          },
        ),
      ],
    );
  }

  // ============================================================
  // BOUTIQUES MISES EN AVANT (dynamique)
  // ============================================================
  Widget _buildFeaturedShops(List<dynamic> shops) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Boutiques mises en avant',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textDark,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => context.push('/market/shops'),
              child: const Text(
                'Voir tout',
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 95,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: shops.length,
            itemBuilder: (context, index) {
              final shop = shops[index];
              return GestureDetector(
                onTap: () => context.push('/market/shop/${shop['id']}'),
                child: Container(
                  width: 90,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: shop['logo_url'] != null
                            ? CachedNetworkImageProvider(shop['logo_url'])
                            : null,
                        child: shop['logo_url'] == null
                            ? const Icon(Icons.store, size: 20, color: Colors.grey)
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        shop['name'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        shop['city'] ?? 'Abidjan',
                        style: TextStyle(fontSize: 9, color: textLight),
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

  // ============================================================
  // DÉCOUVRIR PLUS (dynamique)
  // ============================================================
  Widget _buildForYouSection(List<dynamic> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Découvrir plus',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textDark,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Voir tout',
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.55,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _buildProductGridItem(product);
          },
        ),
      ],
    );
  }

  // ============================================================
  // PRODUIT GRID (réutilisable, avec devise et image)
  // ============================================================
  Widget _buildProductGridItem(Map<String, dynamic> product, {bool isFlash = false}) {
    final hasDiscount = product['discount_price'] != null &&
        product['discount_price'] < product['price'];
    final price = (hasDiscount ? product['discount_price'] : product['price'])
        .toDouble();
    final originalPrice = product['price'].toDouble();

    final currency = product['currency'] ?? 'CDF';
    final currencySymbol = currency == 'USD' ? '\$' : 'FC';

    String imageUrl = product['image_url'] ?? '';
    if (imageUrl.isEmpty) {
      final images = product['images'] as List?;
      if (images != null && images.isNotEmpty) {
        imageUrl = images[0].toString();
      }
    }

    return GestureDetector(
      onTap: () => context.push('/market/product/${product['id']}'),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, size: 30, color: Colors.grey),
                          ),
                    if (hasDiscount)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            '-${((1 - price / originalPrice) * 100).round()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    if (isFlash)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'FLASH',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                            ),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '${price.toInt()} $currencySymbol',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: primaryBlue,
                        ),
                      ),
                      if (hasDiscount)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            '${originalPrice.toInt()} $currencySymbol',
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              fontSize: 9,
                              color: textLight,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 10, color: Colors.grey[400]),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          product['city'] ?? 'Abidjan',
                          style: TextStyle(
                            fontSize: 9,
                            color: textLight,
                          ),
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
  // BOTTOM NAV BAR (inchangé)
  // ============================================================
  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Accueil', 0),
              _buildNavItem(Icons.category, 'Catégories', 1),
              _buildNavItem(Icons.shopping_cart, 'Panier', 2),
              _buildNavItem(Icons.message, 'Messages', 3),
              _buildNavItem(Icons.person, 'Compte', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = index == 0;
    return InkWell(
      onTap: () {
        switch (index) {
          case 0:
            break;
          case 1:
            context.push('/market/search');
            break;
          case 2:
            context.push('/market/cart');
            break;
          case 3:
            context.push('/market/messages');
            break;
          case 4:
            context.push('/market/activity');
            break;
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? primaryBlue : Colors.grey[500],
            size: 22,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? primaryBlue : Colors.grey[500],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
