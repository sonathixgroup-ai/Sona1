import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../providers/market_provider.dart';
import '../providers/shop_provider.dart';
import '../widgets/market/category_grid.dart';
import '../widgets/market/flash_sale_timer.dart';
import '../vendor/vendor_dashboard.dart';

class MarketHomePage extends StatefulWidget {
  const MarketHomePage({super.key});

  @override
  State<MarketHomePage> createState() => _MarketHomePageState();
}

class _MarketHomePageState extends State<MarketHomePage> {
  final ScrollController _scrollController = ScrollController();
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;
  int _currentBannerIndex = 0;

  // ============================================================
  // CHARTE THIX ID — Design Institutionnel Premium (Navy / Bleu / Or)
  // ============================================================
  static const Color navyDeep = Color(0xFF0A1F44);   // fond header / texte fort
  static const Color navy = Color(0xFF123B7A);
  static const Color primaryBlue = Color(0xFF2D6CDF);
  static const Color gold = Color(0xFFE3B23C);        // accent premium unique
  static const Color goldSoft = Color(0xFFF3DFA6);
  static const Color ivory = Color(0xFFF6F7FB);       // fond général
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF10182B);
  static const Color mutedText = Color(0xFF6B7690);
  static const Color success = Color(0xFF1FA971);
  static const Color danger = Color(0xFFD64545);
  static const Color hairline = Color(0xFFE7EAF3);

  // ✅ Supermarchés fictifs — logos générés par initiales + dégradé de couleur
  static const List<Map<String, dynamic>> _supermarkets = [
    {'name': 'Kin Frais', 'tagline': 'Produits frais & légumes', 'time': '35 min'},
    {'name': 'AlimentPlus', 'tagline': 'Épicerie complète', 'time': '40 min'},
    {'name': 'ÉpiCash', 'tagline': 'Prix bas garantis', 'time': '30 min'},
    {'name': 'MaxiMarché', 'tagline': 'Supermarché familial', 'time': '45 min'},
    {'name': 'SuperGo', 'tagline': 'Livraison express', 'time': '25 min'},
  ];

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
    _bannerController.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  void _goToVendor() => context.push('/market/vendor/dashboard');
  void _goToCart() => context.push('/market/cart');
  void _goToWishlist() => context.push('/market/buy');
  void _goToSearch() => context.push('/market/search');
  void _goToNotifications() => context.push('/market/notifications');
  void _goToMessages() => context.push('/market/messages');
  void _goToProfile() => context.push('/market/activity');
  void _goToFlashSales() => context.push('/market/flash-sales');

  Widget _networkImage(String? url, {BoxFit fit = BoxFit.cover}) {
    if (url == null || url.trim().isEmpty) {
      return Container(
        color: ivory,
        alignment: Alignment.center,
        child: const Icon(Icons.image_outlined, color: mutedText),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (_, __) => Container(
        color: ivory,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: primaryBlue),
        ),
      ),
      errorWidget: (_, __, ___) => Container(
        color: ivory,
        child: const Icon(Icons.image_not_supported_outlined, color: mutedText),
      ),
    );
  }

  // ============================================================
  // BANNIÈRE : autoplay toutes les 6 secondes
  // ============================================================
  void _startBannerAutoplay(List<dynamic> banners) {
    if (banners.isEmpty) return;
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (_bannerController.hasClients && banners.isNotEmpty) {
        final nextPage = (_currentBannerIndex + 1) % banners.length;
        _bannerController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
        setState(() => _currentBannerIndex = nextPage);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final marketProvider = context.watch<MarketProvider>();
    context.watch<ShopProvider>();

    final Map<String, dynamic> allById = {};
    for (final p in [
      ...marketProvider.flashSales,
      ...marketProvider.recommendedProducts,
      ...marketProvider.forYouProducts,
    ]) {
      allById[p['id'].toString()] = p;
    }
    final allProducts = allById.values.toList();
    final banners = marketProvider.promoBanners;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (banners.isNotEmpty) _startBannerAutoplay(banners);
    });

    return Scaffold(
      backgroundColor: ivory,
      body: Stack(
        children: [
          RefreshIndicator(
            color: primaryBlue,
            onRefresh: () => marketProvider.refresh(),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                _buildInstitutionalHeader(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildQuickAccessRow(),
                        const SizedBox(height: 22),
                        if (banners.isNotEmpty) ...[
                          _buildBannerCarousel(banners),
                          const SizedBox(height: 24),
                        ],
                        _buildSupermarketsSection(),
                        const SizedBox(height: 24),
                        _buildCategorySection(),
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
                          _sectionHeader('Tous les produits', onSeeAll: () => context.push('/market/buy')),
                          const SizedBox(height: 12),
                          _productGrid(allProducts),
                        ],
                        const SizedBox(height: 110),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(left: 0, right: 0, bottom: 0, child: _buildFloatingNavBar()),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER INSTITUTIONNEL — dégradé navy profond, courbe généreuse, barre de recherche intégrée
  // ============================================================
  Widget _buildInstitutionalHeader() {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      expandedHeight: 178,
      backgroundColor: navyDeep,
      surfaceTintColor: navyDeep,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [navyDeep, navy, primaryBlue],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -40,
                right: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: gold.withOpacity(0.08),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: gold.withOpacity(0.55), width: 1),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.storefront_rounded, size: 17, color: gold),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'THIX MARKET',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              Text(
                                'Marketplace institutionnel',
                                style: TextStyle(fontSize: 9.5, color: Colors.white70, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const Spacer(),
                          _headerIconButton(Icons.notifications_none_rounded, _goToNotifications),
                          const SizedBox(width: 8),
                          _headerIconButton(Icons.storefront_outlined, _goToVendor),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _goToSearch,
                        child: Container(
                          height: 46,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: navyDeep.withOpacity(0.25), blurRadius: 18, offset: const Offset(0, 8)),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded, size: 19, color: primaryBlue),
                              const SizedBox(width: 10),
                              Text(
                                'Rechercher un produit, une boutique…',
                                style: TextStyle(fontSize: 12.5, color: mutedText, fontWeight: FontWeight.w500),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: goldSoft.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.tune_rounded, size: 14, color: navy),
                              ),
                            ],
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
    );
  }

  Widget _headerIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }

  // ============================================================
  // RACCOURCIS RAPIDES — remplace les anciens boutons d'appbar
  // ============================================================
  Widget _buildQuickAccessRow() {
    final items = [
      {'icon': Icons.shopping_cart_rounded, 'label': 'Panier', 'action': _goToCart},
      {'icon': Icons.favorite_rounded, 'label': 'Wishlist', 'action': _goToWishlist},
      {'icon': Icons.chat_bubble_rounded, 'label': 'Messages', 'action': _goToMessages},
      {'icon': Icons.storefront_rounded, 'label': 'Ma boutique', 'action': _goToVendor},
    ];
    return Row(
      children: items.map((item) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: item == items.last ? 0 : 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: item['action'] as VoidCallback,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: cardWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: hairline),
                  boxShadow: [
                    BoxShadow(color: navyDeep.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(item['icon'] as IconData, size: 18, color: navy),
                    const SizedBox(height: 5),
                    Text(
                      item['label'] as String,
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: darkText),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // BANNIÈRE — cadre or, indicateurs institutionnels
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
                onTap: _goToFlashSales,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: gold.withOpacity(0.35), width: 1.4),
                    boxShadow: [
                      BoxShadow(color: navyDeep.withOpacity(0.12), blurRadius: 18, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(19),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _networkImage(banner['image_url']),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(12, 20, 12, 10),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Color(0xCC0A1F44)],
                              ),
                            ),
                            child: const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Offre en vedette',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(banners.length, (i) {
            final active = i == _currentBannerIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? gold : hairline,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ============================================================
  // ✅ SUPERMARCHÉS — liste institutionnelle avec anneau or
  // ============================================================
  Widget _buildSupermarketsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Épiceries partenaires', onSeeAll: _goToSearch, subtitle: 'Livraison à domicile'),
        const SizedBox(height: 12),
        SizedBox(
          height: 104,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _supermarkets.length,
            itemBuilder: (context, index) {
              final s = _supermarkets[index];
              final initials = (s['name'] as String)
                  .split(' ')
                  .map((w) => w.isNotEmpty ? w[0] : '')
                  .take(2)
                  .join()
                  .toUpperCase();

              return GestureDetector(
                onTap: () => context.push('/market/search?shop=${Uri.encodeComponent(s['name'] as String)}'),
                child: Container(
                  width: 178,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardWhite,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: hairline),
                    boxShadow: [
                      BoxShadow(color: navyDeep.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: navyDeep,
                          shape: BoxShape.circle,
                          border: Border.all(color: gold, width: 1.6),
                        ),
                        child: Text(
                          initials,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s['name'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: darkText),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              s['tagline'] as String,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 9, color: mutedText, height: 1.25),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.timer_outlined, size: 10.5, color: navy),
                                const SizedBox(width: 3),
                                Text(
                                  s['time'] as String,
                                  style: const TextStyle(fontSize: 9, color: navy, fontWeight: FontWeight.w700),
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
  // ✅ CATÉGORIES — icônes circulaires cerclées d'or
  // ============================================================
  Widget _buildCategorySection() {
    final categories = [
      {'icon': Icons.checkroom_rounded, 'label': 'Mode', 'id': 'fashion'},
      {'icon': Icons.phone_android_rounded, 'label': 'Électronique', 'id': 'electronics'},
      {'icon': Icons.chair_rounded, 'label': 'Maison', 'id': 'home'},
      {'icon': Icons.build_rounded, 'label': 'Services', 'id': 'services'},
      {'icon': Icons.directions_car_rounded, 'label': 'Véhicules', 'id': 'vehicles'},
      {'icon': Icons.house_rounded, 'label': 'Immobilier', 'id': 'realestate'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Catégories'),
        const SizedBox(height: 12),
        SizedBox(
          height: 84,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return Padding(
                padding: const EdgeInsets.only(right: 14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () => context.push('/market/category/${cat['id']}'),
                  child: Column(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ivory,
                          shape: BoxShape.circle,
                          border: Border.all(color: gold.withOpacity(0.6), width: 1.4),
                        ),
                        child: Icon(cat['icon'] as IconData, size: 21, color: navy),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cat['label'] as String,
                        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: darkText),
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
  // FLASH SALE — ruban or, chronomètre institutionnel
  // ============================================================
  Widget _buildFlashSaleSection(List<dynamic> flashSales) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [navyDeep, navy]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: gold.withOpacity(0.18), borderRadius: BorderRadius.circular(9)),
                child: const Icon(Icons.bolt_rounded, color: gold, size: 16),
              ),
              const SizedBox(width: 8),
              const Text('Offres Flash', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Colors.white)),
              const Spacer(),
              FlashSaleTimer(endTime: DateTime.now().add(const Duration(hours: 2, minutes: 45))),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 186,
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
        _sectionHeader('Recommandé pour vous', onSeeAll: () => context.push('/market/buy')),
        const SizedBox(height: 12),
        SizedBox(
          height: 186,
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
  // CARTE PRODUIT HORIZONTALE — style institutionnel
  // ============================================================
  Widget _buildProductHorizontalCard(Map<String, dynamic> product, {bool isFlash = false}) {
    final currency = product['currency'] ?? 'FC';
    final symbol = currency == 'USD' ? '\$' : 'FC';
    final price = (product['price'] as num).toInt();

    return GestureDetector(
      onTap: () => context.push('/market/product/${product['id']}'),
      child: Container(
        width: 136,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: hairline),
          boxShadow: [
            BoxShadow(color: navyDeep.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _networkImage(product['image_url']),
                    if (isFlash)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: navyDeep,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: gold, width: 1),
                          ),
                          child: const Text('FLASH', style: TextStyle(color: gold, fontSize: 7.5, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
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
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: darkText),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$price $symbol',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: navy),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 10, color: mutedText),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          product['city'] ?? 'Abidjan',
                          style: const TextStyle(fontSize: 9, color: mutedText),
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
  // GRILLE PRODUITS
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
          color: cardWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: hairline),
          boxShadow: [
            BoxShadow(color: navyDeep.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _networkImage(product['image_url']),
                    if (hasDiscount)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: gold,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '-${((1 - price / originalPrice) * 100).round()}%',
                            style: const TextStyle(color: navyDeep, fontSize: 8, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: navyDeep.withOpacity(0.12), blurRadius: 6)],
                        ),
                        child: const Icon(Icons.bookmark_border_rounded, size: 13, color: navy),
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
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: darkText),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${price.toInt()} $symbol',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: navy),
                      ),
                      if (hasDiscount)
                        Padding(
                          padding: const EdgeInsets.only(left: 5),
                          child: Text(
                            '${originalPrice.toInt()} $symbol',
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              fontSize: 9.5,
                              color: mutedText,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 9.5, color: mutedText),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          product['city'] ?? 'Abidjan',
                          style: const TextStyle(fontSize: 8.5, color: mutedText),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.store_rounded, size: 9.5, color: mutedText),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          product['shop']?['name'] ?? 'Vendeur',
                          style: const TextStyle(fontSize: 8.5, color: mutedText),
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

  Widget _sectionHeader(String title, {VoidCallback? onSeeAll, String? subtitle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: darkText)),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 10, color: mutedText, fontWeight: FontWeight.w500)),
            ],
          ],
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
            child: const Text('Voir tout', style: TextStyle(color: navy, fontWeight: FontWeight.w800, fontSize: 12)),
          ),
      ],
    );
  }

  // ============================================================
  // NAVBAR FLOTTANTE — pilule navy, indicateur or
  // ============================================================
  Widget _buildFloatingNavBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        decoration: BoxDecoration(
          color: navyDeep,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: navyDeep.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 12)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_rounded, 'Accueil', true, () {}),
                _buildNavItem(Icons.favorite_rounded, 'Wishlist', false, _goToWishlist),
                _buildNavItem(Icons.shopping_cart_rounded, 'Panier', false, _goToCart),
                _buildNavItem(Icons.chat_bubble_rounded, 'Chat', false, _goToMessages),
                _buildNavItem(Icons.person_rounded, 'Profil', false, _goToProfile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isSelected ? gold : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? navyDeep : Colors.white70, size: 19),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 8.5,
                color: isSelected ? gold : Colors.white54,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
