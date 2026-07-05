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
      backgroundColor: const Color(0xFFF7F7F7),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildAppBar(marketProvider),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLiveSessions(marketProvider.liveSessions),

                const SizedBox(height: 10),

                // CATEGORY GRID
                const CategoryGrid(),

                _buildPromoBanners(marketProvider.promoBanners),

                _buildFlashSales(marketProvider.flashSales),

                _buildRecommendedSection(
                  marketProvider.recommendedProducts,
                ),

                _buildFeaturedShops(
                  marketProvider.featuredShops,
                ),

                _buildForYouSection(
                  marketProvider.forYouProducts,
                ),

                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  Widget _buildAppBar(MarketProvider provider) {
    return SliverAppBar(
      expandedHeight: 130,
      pinned: true,
      floating: true,
      elevation: _isAppBarExpanded ? 0 : 1,
      backgroundColor: Colors.white,

      title: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isAppBarExpanded ? 0 : 1,
        child: const Text(
          "THIX Market",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: primaryColor,
            fontSize: 20,
          ),
        ),
      ),

      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: Colors.white,
          padding: const EdgeInsets.only(
            top: 42,
            left: 16,
            right: 16,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/images/thix_logo.png',
                    height: 38,
                    errorBuilder: (_, __, ___) {
                      return const Text(
                        'THIX',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                          color: primaryColor,
                        ),
                      );
                    },
                  ),

                  const Spacer(),

                  _buildCircleButton(
                    icon: Icons.qr_code_scanner,
                    onTap: () => context.push('/scan-qr'),
                  ),

                  const SizedBox(width: 10),

                  Stack(
                    children: [
                      _buildCircleButton(
                        icon: Icons.notifications_none_rounded,
                        onTap: () {
                          context.push('/market/notifications');
                        },
                      ),

                      if (provider.unreadNotifications > 0)
                        Positioned(
                          right: 4,
                          top: 4,
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
                ],
              ),

              const SizedBox(height: 14),

              GestureDetector(
                onTap: () => context.push('/market/search'),
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: primaryColor.withOpacity(.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),

                      Icon(
                        Icons.search,
                        color: Colors.grey.shade500,
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          'Rechercher des produits, boutiques...',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      ),

                      Container(
                        margin: const EdgeInsets.all(6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.qr_code_scanner,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Scanner',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(50),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),
        child: Icon(
          icon,
          size: 22,
          color: Colors.black87,
        ),
      ),
    );
  }

  // ============================================================
  // LIVE SECTION
  // ============================================================

  Widget _buildLiveSessions(List<dynamic> lives) {
    if (lives.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          title: 'Lives en cours',
          onTap: () => context.push('/market/live'),
        ),

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
                onTap: () {
                  context.push('/market/live/${live['id']}');
                },
                child: Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.04),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(22),
                              ),
                              child: CachedNetworkImage(
                                imageUrl: live['thumbnail'] ?? '',
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),

                            Positioned(
                              top: 10,
                              left: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius:
                                      BorderRadius.circular(30),
                                ),
                                child: const Text(
                                  'LIVE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              live['title'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              live['category'] ?? '',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    live['city'] ?? 'Abidjan',
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color:
                                          Colors.grey.shade500,
                                      fontSize: 12,
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
            },
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PROMO BANNERS
  // ============================================================

  Widget _buildPromoBanners(List<dynamic> banners) {
    if (banners.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: CarouselSlider(
        options: CarouselOptions(
          height: 150,
          viewportFraction: .92,
          autoPlay: true,
          enlargeCenterPage: true,
        ),
        items: banners.map((banner) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
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
  // FLASH SALES
  // ============================================================

  Widget _buildFlashSales(List<dynamic> flashSales) {
    if (flashSales.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(top: 26),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.flash_on,
                  color: primaryColor,
                ),

                const SizedBox(width: 6),

                const Text(
                  "Offres Flash",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),

                const Spacer(),

                FlashSaleTimer(
                  endTime: DateTime.now().add(
                    const Duration(
                      hours: 2,
                      minutes: 45,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            height: 285,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: flashSales.length,
              itemBuilder: (context, index) {
                final product = flashSales[index];

                return ProductCard(
                  product: product,
                  isFlashSale: true,
                  onTap: (prod) {
                    context.push(
                      '/market/product/${prod['id']}',
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RECOMMENDED
  // ============================================================

  Widget _buildRecommendedSection(List<dynamic> products) {
    if (products.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          _sectionTitle(
            title: 'Recommandé pour vous',
            onTap: () {
              context.push('/market/recommended');
            },
          ),

          const SizedBox(height: 14),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: products.take(4).length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: .66,
            ),
            itemBuilder: (context, index) {
              final product = products[index];

              return ProductCard(
                product: product,
                showCity: true,
                showCategoryBottom: true,
                onTap: (prod) {
                  context.push(
                    '/market/product/${prod['id']}',
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FEATURED SHOPS
  // ============================================================

  Widget _buildFeaturedShops(List<dynamic> shops) {
    if (shops.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          _sectionTitle(
            title: 'Boutiques mises en avant',
            onTap: () => context.push('/market/shops'),
          ),

          const SizedBox(height: 14),

          SizedBox(
            height: 115,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: shops.length,
              itemBuilder: (context, index) {
                final shop = shops[index];

                return ShopCard(
                  shop: shop,
                  compact: true,
                  onTap: () {
                    context.push(
                      '/market/shop/${shop['id']}',
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FOR YOU
  // ============================================================

  Widget _buildForYouSection(List<dynamic> products) {
    if (products.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          _sectionTitle(
            title: 'Découvrir plus',
            onTap: () {},
          ),

          const SizedBox(height: 14),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: products.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: .66,
            ),
            itemBuilder: (context, index) {
              final product = products[index];

              return ProductCard(
                product: product,
                showCity: true,
                showCategoryBottom: true,
                onTap: (prod) {
                  context.push(
                    '/market/product/${prod['id']}',
                  );
                },
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

  Widget _sectionTitle({
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),

          const Spacer(),

          TextButton(
            onPressed: onTap,
            child: const Text(
              'Voir tout',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
