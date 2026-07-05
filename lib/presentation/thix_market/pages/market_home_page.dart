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

  // Couleurs Amazon-like
  static const Color primaryBlue = Color(0xFF146EB4);
  static const Color secondaryBlue = Color(0xFF232F3E);
  static const Color accentOrange = Color(0xFFFF9900);
  static const Color bgLight = Color(0xFFEAEDED);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF111111);
  static const Color textLight = Color(0xFF555555);
  static const Color textWhite = Color(0xFFFFFFFF);

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
      backgroundColor: bgLight,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildAppBar(marketProvider),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. LIVES EN COURS (version compacte)
                _buildLiveSessions(marketProvider.liveSessions),
                const SizedBox(height: 12),

                // 2. CATÉGORIES (version Amazon)
                const CategoryGrid(),
                const SizedBox(height: 8),

                // 3. BANNIÈRES PROMO (carrousel)
                _buildPromoBanners(marketProvider.promoBanners),
                const SizedBox(height: 12),

                // 4. SUPER PROMO (style Amazon)
                _buildSuperPromo(),
                const SizedBox(height: 12),

                // 5. OFFRES FLASH (4 produits par ligne)
                _buildFlashSales(marketProvider.flashSales),
                const SizedBox(height: 8),

                // 6. RECOMMANDÉ POUR VOUS (4 produits par ligne)
                _buildRecommendedSection(marketProvider.recommendedProducts),
                const SizedBox(height: 8),

                // 7. BOUTIQUES MISES EN AVANT (version Amazon)
                _buildFeaturedShops(marketProvider.featuredShops),
                const SizedBox(height: 8),

                // 8. DÉCOUVRIR PLUS (4 produits par ligne)
                _buildForYouSection(marketProvider.forYouProducts),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // ============================================================
  // APP BAR (style Amazon)
  // ============================================================
  Widget _buildAppBar(MarketProvider provider) {
    return SliverAppBar(
      expandedHeight: 130,
      pinned: true,
      floating: true,
      elevation: 0,
      backgroundColor: secondaryBlue,
      title: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isAppBarExpanded ? 0 : 1,
        child: const Text(
          'THIX Market',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textWhite,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: secondaryBlue,
          padding: const EdgeInsets.only(top: 42, left: 16, right: 16),
          child: Column(
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/images/thix_logo.png',
                    height: 34,
                    errorBuilder: (_, __, ___) => const Text(
                      'THIX',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                        color: textWhite,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _buildIconButton(Icons.qr_code_scanner, () => context.push('/scan-qr'), Colors.white70),
                  const SizedBox(width: 4),
                  Stack(
                    children: [
                      _buildIconButton(
                        Icons.notifications_none,
                        () => context.push('/market/notifications'),
                        Colors.white70,
                      ),
                      if (provider.unreadNotifications > 0)
                        Positioned(
                          right: 2,
                          top: 2,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: accentOrange,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${provider.unreadNotifications}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  _buildIconButton(
                    Icons.storefront_outlined,
                    () => context.push('/market/sell'),
                    Colors.white70,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Barre de recherche Amazon
              GestureDetector(
                onTap: () => context.push('/market/search'),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Icon(Icons.search, color: Colors.grey[500], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Rechercher des produits...',
                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                        ),
                      ),
                      Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: const BoxDecoration(
                          color: accentOrange,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Scanner',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
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
        width: 38,
        height: 38,
        alignment: Alignment.center,
        child: Icon(icon, size: 22, color: color),
      ),
    );
  }

  // ============================================================
  // 1. LIVES EN COURS (version Amazon compact)
  // ============================================================
  Widget _buildLiveSessions(List<dynamic> lives) {
    if (lives.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
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
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
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
                              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
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
  // 2. SUPER PROMO (style Amazon)
  // ============================================================
  Widget _buildSuperPromo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF146EB4), Color(0xFF1A7FC4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🔥 SUPER PROMO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '-50% SUR TOUT !',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => context.push('/market/promo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primaryBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'J\'EN PROFITE →',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.local_offer,
            color: Colors.white,
            size: 40,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 3. BANNIÈRES PROMOTIONNELLES
  // ============================================================
  Widget _buildPromoBanners(List<dynamic> banners) {
    if (banners.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CarouselSlider(
        options: CarouselOptions(
          height: 120,
          viewportFraction: 1,
          autoPlay: true,
          enlargeCenterPage: false,
        ),
        items: banners.map((banner) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image: CachedNetworkImageProvider(
                  banner['image_url'] ?? '',
                ),
                fit: BoxFit.cover,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // 4. OFFRES FLASH (style Amazon - 4 par ligne)
  // ============================================================
  Widget _buildFlashSales(List<dynamic> flashSales) {
    if (flashSales.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on, color: accentOrange, size: 18),
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
              final hasDiscount = product['discount_price'] != null &&
                  product['discount_price'] < product['price'];
              final price = (hasDiscount
                      ? product['discount_price']
                      : product['price'])
                  .toDouble();
              final originalPrice = product['price'].toDouble();

              return GestureDetector(
                onTap: () =>
                    context.push('/market/product/${product['id']}'),
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
                          borderRadius:
                              const BorderRadius.vertical(top: Radius.circular(10)),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl: product['image_url'] ?? '',
                                fit: BoxFit.cover,
                              ),
                              if (hasDiscount)
                                Positioned(
                                  top: 4,
                                  left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 2),
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
                              if (product['is_flash_sale'] == true)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: accentOrange,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: const Text(
                                      'FLASH',
                                      style: TextStyle(
                                        color: Colors.black,
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
                                  '${price.toInt()} FCFA',
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
                                      '${originalPrice.toInt()} FCFA',
                                      style: TextStyle(
                                        decoration: TextDecoration.lineThrough,
                                        fontSize: 9,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    size: 10, color: Colors.grey[400]),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    product['city'] ?? 'Abidjan',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.grey[500],
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
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 5. RECOMMANDÉ POUR VOUS (4 par ligne)
  // ============================================================
  Widget _buildRecommendedSection(List<dynamic> products) {
    if (products.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
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
      ),
    );
  }

  // ============================================================
  // 6. BOUTIQUES MISES EN AVANT (Amazon style)
  // ============================================================
  Widget _buildFeaturedShops(List<dynamic> shops) {
    if (shops.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
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
                          style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 7. DÉCOUVRIR PLUS (4 par ligne)
  // ============================================================
  Widget _buildForYouSection(List<dynamic> products) {
    if (products.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Découvrir plus',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: textDark,
            ),
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
      ),
    );
  }

  // ============================================================
  // WIDGET PRODUIT GRID (réutilisable)
  // ============================================================
  Widget _buildProductGridItem(Map<String, dynamic> product) {
    final hasDiscount = product['discount_price'] != null &&
        product['discount_price'] < product['price'];
    final price = (hasDiscount ? product['discount_price'] : product['price'])
        .toDouble();
    final originalPrice = product['price'].toDouble();

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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: product['image_url'] ?? '',
                      fit: BoxFit.cover,
                    ),
                    if (hasDiscount)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
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
                        '${price.toInt()} FCFA',
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
                            '${originalPrice.toInt()} FCFA',
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              fontSize: 9,
                              color: Colors.grey[500],
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
                            color: Colors.grey[500],
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
  // BOTTOM NAV BAR (style Amazon)
  // ============================================================
  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
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
