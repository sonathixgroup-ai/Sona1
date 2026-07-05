// lib/presentation/thix_market/pages/market_home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:go_router/go_router.dart';

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

  static const primaryColor = Color(0xFFFF6B2C);
  static const secondaryColor = Color(0xFFE5592F);
  static const bgColor = Color(0xFFF5F5F5);

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
      backgroundColor: bgColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildAppBar(marketProvider),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. LIVES EN COURS
                _buildLiveSessions(marketProvider.liveSessions),

                // 2. CATÉGORIES
                const CategoryGrid(),

                // 3. SUPER PROMO
                _buildSuperPromo(),

                // 4. OFFRES FLASH
                _buildFlashSales(marketProvider.flashSales),

                // 5. RECOMMANDÉ POUR VOUS
                _buildRecommendedSection(marketProvider.recommendedProducts),

                // 6. BOUTIQUES MISES EN AVANT
                _buildFeaturedShops(marketProvider.featuredShops),

                // 7. DÉCOUVRIR PLUS
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
  // APP BAR (style Alibaba / Jumia)
  // ============================================================

  Widget _buildAppBar(MarketProvider provider) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      floating: true,
      elevation: _isAppBarExpanded ? 0 : 1,
      backgroundColor: Colors.white,
      title: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isAppBarExpanded ? 0 : 1,
        child: const Text(
          'THIX Market',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: secondaryColor,
            fontSize: 20,
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: Colors.white,
          padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
          child: Column(
            children: [
              // Logo + Actions
              Row(
                children: [
                  Image.asset(
                    'assets/images/thix_logo.png',
                    height: 36,
                    errorBuilder: (_, __, ___) => const Text(
                      'THIX',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                        color: secondaryColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _buildIconButton(Icons.qr_code_scanner, () => context.push('/scan-qr')),
                  const SizedBox(width: 4),
                  Stack(
                    children: [
                      _buildIconButton(
                        Icons.notifications_none,
                        () => context.push('/market/notifications'),
                      ),
                      if (provider.unreadNotifications > 0)
                        Positioned(
                          right: 2,
                          top: 2,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${provider.unreadNotifications}',
                              style: const TextStyle(
                                color: Colors.white,
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
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Barre de recherche
              GestureDetector(
                onTap: () => context.push('/market/search'),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      Icon(Icons.search, color: Colors.grey[400], size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Rechercher des produits, boutiques...',
                          style: TextStyle(color: Colors.grey[400], fontSize: 13),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [primaryColor, secondaryColor],
                          ),
                          borderRadius: BorderRadius.circular(20),
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
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Icon(icon, size: 22, color: Colors.black87),
      ),
    );
  }

  // ============================================================
  // 1. LIVES EN COURS
  // ============================================================

  Widget _buildLiveSessions(List<dynamic> lives) {
    if (lives.isEmpty) return const SizedBox(height: 8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Lives en cours', () => context.push('/market/live')),
        const SizedBox(height: 12),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: lives.length,
            itemBuilder: (context, index) {
              final live = lives[index];
              return GestureDetector(
                onTap: () => context.push('/market/live/${live['id']}'),
                child: Container(
                  width: 170,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
                    ],
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
                              CachedNetworkImage(
                                imageUrl: live['thumbnail'] ?? '',
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.fiber_manual_record, size: 8, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text(
                                        'LIVE',
                                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${live['viewers'] ?? 0}',
                                    style: const TextStyle(color: Colors.white, fontSize: 10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              live['title'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              live['category'] ?? '',
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 12, color: Colors.grey[400]),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    live['city'] ?? 'Abidjan',
                                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
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
        ),
      ],
    );
  }

  // ============================================================
  // 2. SUPER PROMO
  // ============================================================

  Widget _buildSuperPromo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE5592F), Color(0xFFFF6B35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: const Color(0xFFE5592F).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SUPER PROMO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '-50% SUR TOUT !',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => context.push('/market/promo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFE5592F),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text('J\'EN PROFITE →'),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.local_offer,
            color: Colors.white,
            size: 48,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 3. OFFRES FLASH
  // ============================================================

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
              children: [
                const Icon(Icons.flash_on, color: Color(0xFFE5592F)),
                const SizedBox(width: 6),
                const Text(
                  'Offres Flash',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const Spacer(),
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
                  onTap: (prod) => context.push('/market/product/${prod['id']}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 4. RECOMMANDÉ POUR VOUS
  // ============================================================

  Widget _buildRecommendedSection(List<dynamic> products) {
    if (products.isEmpty) return const SizedBox(height: 8);

    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          _sectionTitle('Recommandé pour vous', () => context.push('/market/recommended')),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.7,
            ),
            itemCount: products.take(4).length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                onTap: (prod) => context.push('/market/product/${prod['id']}'),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 5. BOUTIQUES MISES EN AVANT
  // ============================================================

  Widget _buildFeaturedShops(List<dynamic> shops) {
    if (shops.isEmpty) return const SizedBox(height: 8);

    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          _sectionTitle('Boutiques mises en avant', () => context.push('/market/shops')),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: shops.length,
              itemBuilder: (context, index) {
                final shop = shops[index];
                return ShopCard(
                  shop: shop,
                  onTap: () => context.push('/market/shop/${shop['id']}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 6. DÉCOUVRIR PLUS
  // ============================================================

  Widget _buildForYouSection(List<dynamic> products) {
    if (products.isEmpty) return const SizedBox(height: 8);

    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 20),
      child: Column(
        children: [
          _sectionTitle('Découvrir plus', () {}),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.7,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                onTap: (prod) => context.push('/market/product/${prod['id']}'),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const Spacer(),
          TextButton(
            onPressed: onTap,
            child: const Text(
              'Voir tout',
              style: TextStyle(color: Color(0xFFE5592F), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
