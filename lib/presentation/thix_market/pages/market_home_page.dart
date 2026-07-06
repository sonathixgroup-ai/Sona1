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

  // ============================================================
  // PALETTE PREMIUM — Identité THIX (navy + gold) revisitée
  // pour un rendu "marketplace internationale" (Alibaba/Amazon)
  // ============================================================
  static const Color navy = Color(0xFF1B2A4A);
  static const Color navyDeep = Color(0xFF10192E);
  static const Color gold = Color(0xFFC9962C);
  static const Color goldLight = Color(0xFFE8C98A);
  static const Color bgApp = Color(0xFFF6F7FB);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A1D29);
  static const Color textMuted = Color(0xFF8A8FA3);
  static const Color divider = Color(0xFFEDEEF3);

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
      backgroundColor: bgApp,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildAppBar(marketProvider),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 14),
                  if (marketProvider.liveSessions.isNotEmpty) ...[
                    _buildLiveSessions(marketProvider.liveSessions),
                    const SizedBox(height: 20),
                  ],
                  _buildSectionCard(const CategoryGrid()),
                  const SizedBox(height: 20),
                  if (marketProvider.promoBanners.isNotEmpty) ...[
                    _buildPromoBanners(marketProvider.promoBanners),
                    const SizedBox(height: 20),
                  ],
                  _buildSuperPromo(),
                  const SizedBox(height: 24),
                  if (marketProvider.flashSales.isNotEmpty) ...[
                    _buildFlashSales(marketProvider.flashSales),
                    const SizedBox(height: 24),
                  ],
                  if (marketProvider.recommendedProducts.isNotEmpty) ...[
                    _buildRecommendedSection(marketProvider.recommendedProducts),
                    const SizedBox(height: 24),
                  ],
                  if (marketProvider.featuredShops.isNotEmpty) ...[
                    _buildFeaturedShops(marketProvider.featuredShops),
                    const SizedBox(height: 24),
                  ],
                  if (marketProvider.forYouProducts.isNotEmpty) ...[
                    _buildForYouSection(marketProvider.forYouProducts),
                  ],
                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // Wrapper neutre pour donner de l'air/luminosité à un bloc existant
  Widget _buildSectionCard(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: navy.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================
  Widget _buildAppBar(MarketProvider provider) {
    return SliverAppBar(
      expandedHeight: 136,
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
            Text(
              'THIX',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: navy,
                fontSize: 20,
                letterSpacing: 0.2,
              ),
            ),
            Text(
              ' Market',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: gold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: Colors.white,
          padding: const EdgeInsets.only(top: 44),
          child: Column(
            children: [
              Row(
                children: [
                  const SizedBox(width: 16),
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'THIX',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 24,
                            color: navy,
                            letterSpacing: 0.2,
                          ),
                        ),
                        TextSpan(
                          text: ' Market',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 24,
                            color: gold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _buildIconButton(
                    Icons.qr_code_scanner_rounded,
                    () => context.push('/scan-qr'),
                  ),
                  _buildIconButton(
                    Icons.notifications_none_rounded,
                    () => context.push('/market/notifications'),
                  ),
                  _buildIconButton(
                    Icons.storefront_rounded,
                    () => context.push('/market/sell'),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () => context.push('/market/search'),
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.only(left: 14, right: 4),
                    decoration: BoxDecoration(
                      color: bgApp,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: divider),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, color: textMuted, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Rechercher des produits, boutiques…',
                            style: TextStyle(color: textMuted, fontSize: 13.5),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [navy, navyDeep],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
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
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgApp,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 19, color: navy),
      ),
    );
  }

  // ============================================================
  // SECTION HEADER réutilisable
  // ============================================================
  Widget _sectionHeader({
    required String title,
    IconData? icon,
    Color? iconColor,
    VoidCallback? onSeeAll,
    Widget? trailing,
  }) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: iconColor ?? navy, size: 18),
          const SizedBox(width: 6),
        ],
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: textDark,
            letterSpacing: -0.2,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing,
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Row(
              children: const [
                Text(
                  'Voir tout',
                  style: TextStyle(
                    color: gold,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 16, color: gold),
              ],
            ),
          ),
      ],
    );
  }

  // ============================================================
  // LIVES EN COURS
  // ============================================================
  Widget _buildLiveSessions(List<dynamic> lives) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          title: 'Lives en cours',
          icon: Icons.podcasts_rounded,
          iconColor: const Color(0xFFE53935),
          onSeeAll: () => context.push('/market/live'),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: lives.length,
            itemBuilder: (context, index) {
              final live = lives[index];
              return GestureDetector(
                onTap: () => context.push('/market/live/${live['id']}'),
                child: Container(
                  width: 145,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: cardBg,
                    boxShadow: [
                      BoxShadow(
                        color: navy.withOpacity(0.06),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
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
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.35),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE53935),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.fiber_manual_record, size: 6, color: Colors.white),
                                      SizedBox(width: 3),
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
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.remove_red_eye, size: 10, color: Colors.white),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${live['viewers'] ?? 0}',
                                        style: const TextStyle(color: Colors.white, fontSize: 9.5),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(9),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              live['title'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                                color: textDark,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              live['city'] ?? 'Kinshasa',
                              style: const TextStyle(fontSize: 10.5, color: textMuted),
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
  // SUPER PROMO
  // ============================================================
  Widget _buildSuperPromo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [navy, navyDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: navy.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: gold.withOpacity(0.12),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.workspace_premium_rounded, color: gold, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'OFFRE PREMIUM',
                          style: TextStyle(
                            color: gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '-50% sur tout',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => context.push('/market/promo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold,
                        foregroundColor: navyDeep,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'J\'en profite',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_offer_rounded, color: gold, size: 26),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BANNIÈRES PROMO
  // ============================================================
  Widget _buildPromoBanners(List<dynamic> banners) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: CarouselSlider(
        options: CarouselOptions(
          height: 140,
          viewportFraction: 1,
          autoPlay: true,
          enlargeCenterPage: false,
        ),
        items: banners.map((banner) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              image: DecorationImage(
                image: CachedNetworkImageProvider(
                  banner['image_url'] ?? '',
                ),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: navy.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // OFFRES FLASH
  // ============================================================
  Widget _buildFlashSales(List<dynamic> flashSales) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          title: 'Offres Flash',
          icon: Icons.flash_on_rounded,
          iconColor: const Color(0xFFE53935),
          trailing: FlashSaleTimer(
            endTime: DateTime.now().add(const Duration(hours: 2, minutes: 45)),
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.68,
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
  // RECOMMANDÉ POUR VOUS
  // ============================================================
  Widget _buildRecommendedSection(List<dynamic> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          title: 'Recommandé pour vous',
          onSeeAll: () => context.push('/market/recommended'),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.68,
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
  // BOUTIQUES MISES EN AVANT
  // ============================================================
  Widget _buildFeaturedShops(List<dynamic> shops) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          title: 'Boutiques mises en avant',
          onSeeAll: () => context.push('/market/shops'),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: shops.length,
            itemBuilder: (context, index) {
              final shop = shops[index];
              return GestureDetector(
                onTap: () => context.push('/market/shop/${shop['id']}'),
                child: Container(
                  width: 96,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: navy.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: goldLight, width: 1.5),
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: bgApp,
                          backgroundImage: shop['logo_url'] != null
                              ? CachedNetworkImageProvider(shop['logo_url'])
                              : null,
                          child: shop['logo_url'] == null
                              ? const Icon(Icons.store_rounded, size: 18, color: navy)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        shop['name'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        shop['city'] ?? 'Kinshasa',
                        style: const TextStyle(fontSize: 9, color: textMuted),
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
  // DÉCOUVRIR PLUS
  // ============================================================
  Widget _buildForYouSection(List<dynamic> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(title: 'Découvrir plus', onSeeAll: () {}),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.68,
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
  // PRODUIT GRID (réutilisable) — style carte premium
  // ============================================================
  Widget _buildProductGridItem(Map<String, dynamic> product, {bool isFlash = false}) {
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
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: navy.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
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
                      imageUrl: product['image_url'] ?? '',
                      fit: BoxFit.cover,
                    ),
                    if (hasDiscount)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '-${((1 - price / originalPrice) * 100).round()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    if (isFlash)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: gold,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'FLASH',
                            style: TextStyle(
                              color: navyDeep,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.favorite_border_rounded, size: 13, color: navy),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['title'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${price.toInt()} FC',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: navy,
                        ),
                      ),
                      if (hasDiscount)
                        Padding(
                          padding: const EdgeInsets.only(left: 5),
                          child: Text(
                            '${originalPrice.toInt()}',
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              fontSize: 9.5,
                              color: textMuted,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 11, color: textMuted),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          product['city'] ?? 'Kinshasa',
                          style: const TextStyle(fontSize: 9.5, color: textMuted),
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
  // BOTTOM NAV BAR
  // ============================================================
  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: navy.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
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
      borderRadius: BorderRadius.circular(10),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? navy : textMuted,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? navy : textMuted,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 2),
              Container(width: 4, height: 4, decoration: const BoxDecoration(color: gold, shape: BoxShape.circle)),
            ],
          ],
        ),
      ),
    );
  }
}
