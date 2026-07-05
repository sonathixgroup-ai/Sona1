// lib/presentation/thix_market/pages/market_home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../providers/market_provider.dart';
import '../widgets/market/category_grid.dart';
import '../widgets/market/flash_sale_timer.dart';
import '../widgets/products/product_card.dart';
import '../widgets/shops/shop_card.dart';

class MarketHomePage extends StatefulWidget {
  const MarketHomePage({super.key});

  @override
  State<MarketHomePage> createState() => _MarketHomePageState();
}

class _MarketHomePageState extends State<MarketHomePage> {
  final ScrollController _scrollController = ScrollController();
  bool _isAppBarExpanded = true;

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
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ================================
          // APP BAR (style Alibaba)
          // ================================
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: _isAppBarExpanded ? 0 : 1,
            title: AnimatedOpacity(
              opacity: _isAppBarExpanded ? 0 : 1,
              duration: const Duration(milliseconds: 200),
              child: const Text(
                'THIX Market',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE5592F),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors.white,
                padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo + Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Image.asset(
                          'assets/images/thix_logo.png',
                          height: 40,
                          errorBuilder: (_, __, ___) => const Text(
                            'THIX',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE5592F),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            // 📷 QR Code Scanner
                            IconButton(
                              icon: const Icon(Icons.qr_code_scanner),
                              onPressed: () => _scanQRCode(),
                              color: Colors.grey[700],
                            ),
                            // 🔔 Notifications
                            Stack(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.notifications_outlined),
                                  onPressed: () => _gotoNotifications(),
                                  color: Colors.grey[700],
                                ),
                                if (marketProvider.unreadNotifications > 0)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        '${marketProvider.unreadNotifications}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            // 🏪 MODE VENDEUR (NOUVEAU)
                            IconButton(
                              icon: const Icon(Icons.storefront_outlined),
                              onPressed: () => _toggleSellerMode(),
                              color: Colors.grey[700],
                              tooltip: 'Mode Vendeur',
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Barre de recherche
                    GestureDetector(
                      onTap: () => _gotoSearch(),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 16),
                            Icon(Icons.search, color: Colors.grey[400]),
                            const SizedBox(width: 8),
                            Text(
                              'Rechercher des produits...',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5592F),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Scanner',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ================================
          // CONTENU PRINCIPAL
          // ================================
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. LIVES EN COURS
                _buildLiveSessions(marketProvider.liveSessions),

                // 2. CATÉGORIES (une ligne horizontale)
                const CategoryGrid(),

                // 3. BANNIÈRES PROMOTIONNELLES
                _buildPromoBanners(marketProvider.promoBanners),

                // 4. OFFRES FLASH
                _buildFlashSales(marketProvider.flashSales),

                // 5. PRODUITS RECOMMANDÉS
                _buildRecommendedSection(marketProvider.recommendedProducts),

                // 6. BOUTIQUES MISES EN AVANT
                _buildFeaturedShops(marketProvider.featuredShops),

                // 7. POUR VOUS
                _buildForYouSection(marketProvider.forYouProducts),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WIDGETS
  // ============================================================

  Widget _buildLiveSessions(List<dynamic> lives) {
    if (lives.isEmpty) return const SizedBox(height: 8);
    return Container(
      height: 280,
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Lives en cours',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => _gotoAllLives(),
                  child: const Text(
                    'Voir tout',
                    style: TextStyle(color: Color(0xFFE5592F)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: lives.length,
              itemBuilder: (context, index) {
                final live = lives[index];
                return Container(
                  width: 180,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: live['thumbnail'] ?? '',
                              height: 160,
                              width: 180,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: Colors.grey[200],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.fiber_manual_record,
                                    color: Colors.white,
                                    size: 10,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'LIVE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${live['viewers'] ?? 0} vues',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        live['title'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        live['shop_name'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoBanners(List<dynamic> banners) {
    if (banners.isEmpty) return const SizedBox(height: 8);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
      child: CarouselSlider(
        options: CarouselOptions(
          height: 140,
          autoPlay: true,
          enlargeCenterPage: true,
          viewportFraction: 0.92,
          autoPlayInterval: const Duration(seconds: 4),
          autoPlayAnimationDuration: const Duration(milliseconds: 800),
        ),
        items: banners.map((banner) {
          return Builder(
            builder: (BuildContext context) {
              return GestureDetector(
                onTap: () => _gotoPromoLink(banner['link'] ?? ''),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(
                        banner['image_url'] ?? '',
                      ),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          banner['title'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFlashSales(List<dynamic> flashSales) {
    if (flashSales.isEmpty) return const SizedBox(height: 8);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [const Color(0xFFE5592F), const Color(0xFFFF6B35)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'FLASH',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Vente flash',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                FlashSaleTimer(endTime: DateTime.now().add(const Duration(hours: 2, minutes: 45))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 260,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: flashSales.length,
              itemBuilder: (context, index) {
                final product = flashSales[index];
                return ProductCard(
                  product: product,
                  isFlashSale: true,
                  onTap: (_) => _gotoProductDetail(product['id']),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedSection(List<dynamic> products) {
    if (products.isEmpty) return const SizedBox(height: 8);
    return Container(
      margin: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '⭐ Recommandé pour vous',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => _gotoRecommended(),
                  child: const Text(
                    'Voir tout',
                    style: TextStyle(color: Color(0xFFE5592F)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: products.take(4).length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                onTap: (_) => _gotoProductDetail(product['id']),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedShops(List<dynamic> shops) {
    if (shops.isEmpty) return const SizedBox(height: 8);
    return Container(
      margin: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🏪 Boutiques mises en avant',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => _gotoAllShops(),
                  child: const Text(
                    'Voir tout',
                    style: TextStyle(color: Color(0xFFE5592F)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: shops.length,
              itemBuilder: (context, index) {
                final shop = shops[index];
                return ShopCard(
                  shop: shop,
                  onTap: () => _gotoShop(shop['id']),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForYouSection(List<dynamic> products) {
    if (products.isEmpty) return const SizedBox(height: 8);
    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '📦 Découvrir plus',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                onTap: (_) => _gotoProductDetail(product['id']),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NAVIGATION
  // ============================================================
  
  void _scanQRCode() => Navigator.pushNamed(context, '/scan-qr');
  void _gotoNotifications() => Navigator.pushNamed(context, '/notifications');
  void _gotoSearch() => Navigator.pushNamed(context, '/search');
  void _gotoAllLives() => Navigator.pushNamed(context, '/lives');
  void _gotoProductDetail(String id) => Navigator.pushNamed(context, '/product/$id');
  void _gotoPromoLink(String link) => debugPrint('Promo link: $link');
  void _gotoRecommended() => Navigator.pushNamed(context, '/recommended');
  void _gotoAllShops() => Navigator.pushNamed(context, '/shops');
  void _gotoShop(String id) => Navigator.pushNamed(context, '/shop/$id');
  
  // 🏪 MODE VENDEUR
  void _toggleSellerMode() {
    // Redirige vers la page de vente / création de boutique
    Navigator.pushNamed(context, '/sell');
  }
}
