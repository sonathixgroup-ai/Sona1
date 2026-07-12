// lib/presentation/thix_market/pages/market_home_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../providers/market_provider.dart';
import '../providers/shop_provider.dart';
import '../widgets/market/category_grid.dart';
import '../widgets/market/flash_sale_timer.dart';
import '../vendor/vendor_dashboard.dart';

// ============================================================
// CHARTE GRAPHIQUE B2B & RETAIL PREMIUM
// ============================================================
class _MarketColors {
  static const Color primaryBlue = Color(0xFF0B3D91);
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color lightBg = Color(0xFFF6F8FB);
  static const Color gold = Color(0xFFF7C948);
  static const Color mutedText = Color(0xFF6B7690);
  static const Color cardBorder = Color(0xFFEEF1F7);
  static const Color darkText = Color(0xFF10182B);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color softBlue = Color(0xFFEEF1F7);
  static const Color accentRed = Color(0xFFE63946); 
  static const Color successGreen = Color(0xFF00B074); 
}

class MarketHomePage extends StatefulWidget {
  const MarketHomePage({super.key});

  @override
  State<MarketHomePage> createState() => _MarketHomePageState();
}

class _MarketHomePageState extends State<MarketHomePage> {
  final ScrollController _scrollController = ScrollController();
  final PageController _bannerController = PageController(viewportFraction: 0.92);
  Timer? _bannerTimer;
  int _currentBannerIndex = 0;
  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketProvider>().loadHomeData();
      context.read<ShopProvider>().loadMyShops();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _bannerController.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  void _goToVendor() => context.push('/market/vendor/dashboard');
  void _goToCart() => context.push('/market/cart');
  void _goToWishlist() => context.push('/market/buy'); // À lier à ta vraie page Wishlist

  void _onNavTap(int index) {
    setState(() => _selectedNavIndex = index);
    HapticFeedback.lightImpact();
    switch (index) {
      case 0: break;
      case 1: _goToWishlist(); break;
      case 2: _goToCart(); break;
      case 3: context.push('/market/messages'); break;
      case 4: context.push('/market/activity'); break;
    }
  }

  Widget _networkImage(String? url, {BoxFit fit = BoxFit.cover}) {
    if (url == null || url.trim().isEmpty) {
      return Container(color: _MarketColors.softBlue, alignment: Alignment.center, child: const Icon(Icons.image_outlined, color: _MarketColors.mutedText));
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (_, __) => Container(color: _MarketColors.softBlue, child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _MarketColors.primaryBlue))),
      errorWidget: (_, __, ___) => Container(color: _MarketColors.softBlue, child: const Icon(Icons.image_not_supported_outlined, color: _MarketColors.mutedText)),
    );
  }

  void _startBannerAutoplay(List<dynamic> banners) {
    if (banners.isEmpty) return;
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_bannerController.hasClients && banners.isNotEmpty) {
        final nextPage = (_currentBannerIndex + 1) % banners.length;
        _bannerController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
        );
        setState(() => _currentBannerIndex = nextPage);
      }
    });
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature : Bientôt disponible !'), backgroundColor: _MarketColors.gold, duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final marketProvider = context.watch<MarketProvider>();
    final allProducts = {
      ...marketProvider.flashSales,
      ...marketProvider.recommendedProducts,
      ...marketProvider.forYouProducts,
    }.toList();
    
    final banners = marketProvider.promoBanners;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (banners.isNotEmpty && _bannerTimer == null) _startBannerAutoplay(banners);
    });

    return Scaffold(
      backgroundColor: _MarketColors.lightBg,
      body: RefreshIndicator(
        color: _MarketColors.primaryBlue,
        onRefresh: () => marketProvider.refresh(),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(child: _buildPremiumHeader()),
            
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (banners.isNotEmpty)
                    Transform.translate(
                      offset: const Offset(0, -20),
                      child: _buildBannerCarousel(banners),
                    )
                  else
                    const SizedBox(height: 16),
                  
                  // ===============================================
                  // NOUVEAU : OUTILS B2B (Comparateur, Alertes, Devis)
                  // ===============================================
                  Transform.translate(
                    offset: const Offset(0, -10),
                    child: _buildB2BTools(),
                  ),
                  
                  _buildCategorySection(),
                  const SizedBox(height: 24),
                  
                  _buildSupermarketsSection(),
                  const SizedBox(height: 24),
                  
                  if (marketProvider.flashSales.isNotEmpty) ...[
                    _buildFlashSaleSection(marketProvider.flashSales),
                    const SizedBox(height: 24),
                  ],
                  
                  if (marketProvider.recommendedProducts.isNotEmpty) ...[
                    _buildRecommendedSection(marketProvider.recommendedProducts),
                    const SizedBox(height: 24),
                  ],
                  
                  if (allProducts.isNotEmpty) ...[
                    _buildSectionHeader('Tous les produits', () => context.push('/market/buy')),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
            
            if (allProducts.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.65,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildProductCard(allProducts[index]),
                    childCount: allProducts.length,
                  ),
                ),
              ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // ============================================================
  // HEADER B2B PREMIUM
  // ============================================================
  Widget _buildPremiumHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 54, 16, 36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_MarketColors.navyDeep, _MarketColors.primaryBlue],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.shopping_bag_rounded, size: 20, color: _MarketColors.gold),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('THIX MARKET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5)),
                      Text('B2B & Retail International', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  _headerIconButton(Icons.storefront_rounded, _goToVendor),
                  const SizedBox(width: 8),
                  Stack(
                    clipBehavior: Clip.none, 
                    children: [
                      _headerIconButton(Icons.notifications_none_rounded, () => context.push('/market/notifications')),
                      Positioned(
                        top: -2, 
                        right: -2, 
                        child: Container(
                          padding: const EdgeInsets.all(4), 
                          decoration: const BoxDecoration(color: _MarketColors.accentRed, shape: BoxShape.circle), 
                          child: const Text('2', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white))
                        )
                      ),
                    ]
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => context.push('/market/search'),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _MarketColors.pureWhite,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: const Row(
                children: [
                  Icon(Icons.search_rounded, size: 20, color: _MarketColors.mutedText),
                  SizedBox(width: 12),
                  Text('Rechercher produits, grossistes...', style: TextStyle(fontSize: 12.5, color: _MarketColors.mutedText, fontWeight: FontWeight.w500)),
                  Spacer(),
                  Icon(Icons.qr_code_scanner_rounded, size: 20, color: _MarketColors.primaryBlue),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  // ============================================================
  // OUTILS B2B (Comparateur, Alerte, Devis, Favoris)
  // ============================================================
  Widget _buildB2BTools() {
    final tools = [
      {'icon': Icons.compare_arrows_rounded, 'label': 'Comparer', 'action': () => _showComingSoon('Comparateur')},
      {'icon': Icons.notifications_active_rounded, 'label': 'Alerte Prix', 'action': () => _showComingSoon('Alertes de Prix')},
      {'icon': Icons.request_quote_rounded, 'label': 'Devis B2B', 'action': () => _showComingSoon('Demandes de devis')},
      {'icon': Icons.favorite_rounded, 'label': 'Wishlist', 'action': _goToWishlist},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: _MarketColors.pureWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: _MarketColors.navyDeep.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: tools.map((t) => InkWell(
            onTap: t['action'] as VoidCallback,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                children: [
                  Icon(t['icon'] as IconData, color: _MarketColors.primaryBlue, size: 24),
                  const SizedBox(height: 6),
                  Text(t['label'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _MarketColors.darkText)),
                ],
              ),
            ),
          )).toList(),
        ),
      ),
    );
  }

  // ============================================================
  // CARROUSEL BANNIÈRES
  // ============================================================
  Widget _buildBannerCarousel(List<dynamic> banners) {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: banners.length,
            onPageChanged: (index) => setState(() => _currentBannerIndex = index),
            itemBuilder: (context, index) {
              final banner = banners[index];
              return GestureDetector(
                onTap: () => context.push('/market/flash-sales'),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: _MarketColors.navyDeep.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10))],
                    image: DecorationImage(
                      image: NetworkImage(banner['image_url'] ?? ''),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(banners.length, (i) {
            final active = i == _currentBannerIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 6,
              width: active ? 18 : 6,
              decoration: BoxDecoration(
                color: active ? _MarketColors.primaryBlue : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ============================================================
  // CATÉGORIES RAPIDES
  // ============================================================
  Widget _buildCategorySection() {
    final categories = [
      {'icon': Icons.store_rounded, 'label': 'Supermarchés'},
      {'icon': Icons.local_shipping_rounded, 'label': 'B2B & Gros'},
      {'icon': Icons.checkroom_rounded, 'label': 'Mode'},
      {'icon': Icons.phone_android_rounded, 'label': 'High-Tech'},
      {'icon': Icons.agriculture_rounded, 'label': 'Agro'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: categories.map((cat) {
          final isB2B = cat['label'] == 'B2B & Gros' || cat['label'] == 'Supermarchés';
          return InkWell(
            onTap: () => context.push('/market/search'),
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isB2B ? _MarketColors.softBlue : _MarketColors.pureWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isB2B ? _MarketColors.primaryBlue.withOpacity(0.3) : _MarketColors.cardBorder),
                    boxShadow: [if (isB2B) BoxShadow(color: _MarketColors.primaryBlue.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: Icon(cat['icon'] as IconData, color: isB2B ? _MarketColors.primaryBlue : _MarketColors.navy, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  cat['label'] as String,
                  style: TextStyle(fontSize: 10, color: _MarketColors.darkText, fontWeight: isB2B ? FontWeight.w800 : FontWeight.w600),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // SECTION SUPERMARCHÉS & PARTENAIRES OFFICIELS
  // ============================================================
  Widget _buildSupermarketsSection() {
    final partners = [
      {'name': 'THIX Fresh', 'type': 'Supermarché', 'icon': Icons.shopping_basket_rounded, 'color': _MarketColors.successGreen},
      {'name': 'ElectroPro B2B', 'type': 'Grossiste Tech', 'icon': Icons.memory_rounded, 'color': _MarketColors.primaryBlue},
      {'name': 'AgriCongo', 'type': 'Producteur Local', 'icon': Icons.eco_rounded, 'color': _MarketColors.gold},
      {'name': 'KinMart', 'type': 'Supermarché', 'icon': Icons.storefront_rounded, 'color': _MarketColors.accentRed},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Supermarchés & Distributeurs', () {}),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: partners.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final p = partners[i];
              final pColor = p['color'] as Color;
              return Container(
                width: 200,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _MarketColors.pureWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _MarketColors.cardBorder),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: pColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(p['icon'] as IconData, color: pColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.verified_rounded, color: _MarketColors.primaryBlue, size: 12),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(p['name'] as String, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: _MarketColors.darkText), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(p['type'] as String, style: const TextStyle(fontSize: 10, color: _MarketColors.mutedText, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: _MarketColors.softBlue, borderRadius: BorderRadius.circular(6)),
                            child: const Text('Visiter la boutique', style: TextStyle(fontSize: 9, color: _MarketColors.primaryBlue, fontWeight: FontWeight.bold)),
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
  // OFFRES FLASH
  // ============================================================
  Widget _buildFlashSaleSection(List<dynamic> flashSales) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.bolt_rounded, color: _MarketColors.accentRed, size: 22),
              const SizedBox(width: 6),
              const Text('Ventes Flash', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: _MarketColors.darkText)),
              const Spacer(),
              FlashSaleTimer(endTime: DateTime.now().add(const Duration(hours: 2, minutes: 45))),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 230,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: flashSales.take(6).length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _buildProductHorizontalCard(flashSales[index], isFlash: true),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // RECOMMANDÉ
  // ============================================================
  Widget _buildRecommendedSection(List<dynamic> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Recommandé pour vous', () => context.push('/market/buy')),
        const SizedBox(height: 12),
        SizedBox(
          height: 230,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: products.take(6).length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _buildProductHorizontalCard(products[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: _MarketColors.darkText)),
          GestureDetector(
            onTap: onTap,
            child: const Row(
              children: [
                Text('Voir tout', style: TextStyle(color: _MarketColors.primaryBlue, fontSize: 12, fontWeight: FontWeight.w800)),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios_rounded, size: 10, color: _MarketColors.primaryBlue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARTE PRODUIT (Carrousels horizontaux)
  // ============================================================
  Widget _buildProductHorizontalCard(Map<String, dynamic> product, {bool isFlash = false}) {
    final currency = product['currency'] ?? 'FC';
    final symbol = currency == 'USD' ? '\$' : 'FC';
    final price = (product['price'] as num).toInt();

    return GestureDetector(
      onTap: () => context.push('/market/product/${product['id']}'),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: _MarketColors.pureWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isFlash ? _MarketColors.accentRed.withOpacity(0.3) : _MarketColors.cardBorder, width: 1),
          boxShadow: [BoxShadow(color: _MarketColors.navyDeep.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: _networkImage(product['image_url']),
                  ),
                  if (isFlash)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: _MarketColors.accentRed, borderRadius: BorderRadius.circular(8)),
                        child: const Text('-30%', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product['title'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _MarketColors.darkText, height: 1.2),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isFlash)
                          Text('${(price * 1.3).toInt()} $symbol', style: const TextStyle(fontSize: 10, color: _MarketColors.mutedText, decoration: TextDecoration.lineThrough)),
                        Text(
                          '$price $symbol',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: isFlash ? _MarketColors.accentRed : _MarketColors.primaryBlue),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CARTE PRODUIT (Grille verticale)
  // ============================================================
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
          color: _MarketColors.pureWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _MarketColors.cardBorder),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: _networkImage(product['image_url']),
                  ),
                  if (hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(color: _MarketColors.accentRed, borderRadius: BorderRadius.circular(8)),
                        child: Text('-${((1 - price / originalPrice) * 100).round()}%', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['title'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _MarketColors.darkText, height: 1.2),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (hasDiscount)
                                Text('${originalPrice.toInt()} $symbol', style: const TextStyle(decoration: TextDecoration.lineThrough, fontSize: 10, color: _MarketColors.mutedText)),
                              Text('${price.toInt()} $symbol', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: _MarketColors.primaryBlue)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: _MarketColors.softBlue, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.add_shopping_cart_rounded, size: 16, color: _MarketColors.primaryBlue),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM NAV BAR FLOTTANTE
  // ============================================================
  Widget _buildBottomNavBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16), 
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), 
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(30), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20)]
      ), 
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround, 
          children: [
            _navItem(Icons.storefront_rounded, 'Market', 0), 
            _navItem(Icons.favorite_border_rounded, 'Wishlist', 1), 
            _navItem(Icons.shopping_cart_outlined, 'Panier', 2), 
            _navItem(Icons.chat_bubble_outline_rounded, 'Messages', 3), 
            _navItem(Icons.person_outline_rounded, 'Profil', 4),
          ]
        ),
      )
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isSelected = _selectedNavIndex == index;
    return InkWell(
      onTap: () => _onNavTap(index), 
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? _MarketColors.primaryBlue : _MarketColors.mutedText, size: 22), 
          Text(label, style: TextStyle(fontSize: 10, color: isSelected ? _MarketColors.primaryBlue : _MarketColors.mutedText, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))
        ]
      )
    );
  }
}
