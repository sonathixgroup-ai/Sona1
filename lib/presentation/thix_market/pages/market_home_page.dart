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
  // CHARTE THIX MARKET — Élite Institutionnel Bleu / Blanc
  // ============================================================
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color navy = Color(0xFF123B7A);
  static const Color primaryBlue = Color(0xFF2D6CDF);
  static const Color electricBlue = Color(0xFF4E8CFF);
  static const Color softBlue = Color(0xFFEFF5FF);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF10192E);
  static const Color mutedText = Color(0xFF7386A8);
  static const Color gold = Color(0xFFE3B23C);
  static const Color glow = Color(0xFF2D6CDF);
  static const Color green = Color(0xFF059669);

  // ✅ Supermarchés fictifs — logos générés par initiales + dégradé de couleur
  static const List<Map<String, dynamic>> _supermarkets = [
    {'name': 'Kin Frais', 'tagline': 'Produits frais & légumes', 'color': Color(0xFF2D6CDF), 'time': '35 min'},
    {'name': 'AlimentPlus', 'tagline': 'Épicerie complète', 'color': Color(0xFFE3B23C), 'time': '40 min'},
    {'name': 'ÉpiCash', 'tagline': 'Prix bas garantis', 'color': Color(0xFF059669), 'time': '30 min'},
    {'name': 'MaxiMarché', 'tagline': 'Supermarché familial', 'color': Color(0xFF7C4DFF), 'time': '45 min'},
    {'name': 'SuperGo', 'tagline': 'Livraison express', 'color': Color(0xFFE5484D), 'time': '25 min'},
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

  Widget _networkImage(String? url, {BoxFit fit = BoxFit.cover}) {
    if (url == null || url.trim().isEmpty) {
      return Container(color: softBlue, alignment: Alignment.center, child: Icon(Icons.image_outlined, color: mutedText));
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (_, __) => Container(color: softBlue, child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: primaryBlue))),
      errorWidget: (_, __, ___) => Container(color: softBlue, child: Icon(Icons.image_not_supported_outlined, color: mutedText)),
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
    final banners = marketProvider.promoBanners;

    // Démarrer l'autoplay dès que les bannières sont chargées
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (banners.isNotEmpty) _startBannerAutoplay(banners);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      body: RefreshIndicator(
        color: primaryBlue,
        onRefresh: () => marketProvider.refresh(),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),
                    // Bannières rectangulaires, agrandies
                    if (banners.isNotEmpty) ...[
                      _buildBannerCarousel(banners),
                      const SizedBox(height: 18),
                    ],
                    // ✅ Supermarchés — remplace la grille de catégories
                    _buildSupermarketsSection(),
                    const SizedBox(height: 14),
                    // ✅ Catégories — conservées, version compacte (chips fines)
                    _buildCategoryChipsSection(),
                    const SizedBox(height: 18),
                    if (marketProvider.flashSales.isNotEmpty) ...[
                      _buildFlashSaleSection(marketProvider.flashSales),
                      const SizedBox(height: 18),
                    ],
                    if (marketProvider.recommendedProducts.isNotEmpty) ...[
                      _buildRecommendedSection(marketProvider.recommendedProducts),
                      const SizedBox(height: 18),
                    ],
                    if (allProducts.isNotEmpty) ...[
                      _sectionHeader('Tous les produits', onSeeAll: () => context.push('/market/buy')),
                      const SizedBox(height: 8),
                      _productGrid(allProducts),
                    ],
                    const SizedBox(height: 100),
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
  // APP BAR — « THIX MARKET » au lieu de la localisation
  // ============================================================
  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      floating: true,
      elevation: 0,
      toolbarHeight: 72,
      backgroundColor: navyDeep,
      surfaceTintColor: navyDeep,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [navyDeep, navy, primaryBlue],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(26),
            bottomRight: Radius.circular(26),
          ),
          boxShadow: [
            BoxShadow(color: Color(0x332D6CDF), blurRadius: 22, offset: Offset(0, 10)),
          ],
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(9)),
            child: const Icon(Icons.storefront_rounded, size: 16, color: gold),
          ),
          const SizedBox(width: 7),
          const Text(
            'THIX MARKET',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          _buildIconButton(Icons.search_rounded, () => context.push('/market/search')),
          _buildIconButton(Icons.notifications_none_rounded, () => context.push('/market/notifications')),
          _buildIconButton(Icons.storefront_rounded, _goToVendor),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }

  // ============================================================
  // BANNIÈRE : rectangle, bord droit, plus haute, autoplay 6s
  // ============================================================
  Widget _buildBannerCarousel(List<dynamic> banners) {
    return SizedBox(
      height: 170,
      child: PageView.builder(
        controller: _bannerController,
        itemCount: banners.length,
        onPageChanged: (index) {
          setState(() => _currentBannerIndex = index);
        },
        itemBuilder: (context, index) {
          final banner = banners[index];
          return GestureDetector(
            onTap: () {
              context.push('/market/flash-sales');
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(0),
                boxShadow: [
                  BoxShadow(color: navyDeep.withOpacity(0.14), blurRadius: 20, offset: const Offset(0, 10)),
                ],
                image: DecorationImage(
                  image: NetworkImage(banner['image_url'] ?? ''),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // ✅ SUPERMARCHÉS — « Faites vos courses à domicile »
  // ============================================================
  Widget _buildSupermarketsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Supermarchés', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: darkText)),
                SizedBox(height: 2),
                Text('Faites vos courses à domicile', style: TextStyle(fontSize: 10.5, color: mutedText, fontWeight: FontWeight.w500)),
              ],
            ),
            TextButton(
              onPressed: () => context.push('/market/search'),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
              child: const Text('Voir tout', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 96,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _supermarkets.length,
            itemBuilder: (context, index) {
              final s = _supermarkets[index];
              final Color c = s['color'] as Color;
              final initials = (s['name'] as String)
                  .split(' ')
                  .map((w) => w.isNotEmpty ? w[0] : '')
                  .take(2)
                  .join()
                  .toUpperCase();

              return GestureDetector(
                onTap: () => context.push('/market/search?shop=${Uri.encodeComponent(s['name'] as String)}'),
                child: Container(
                  width: 172,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: pureWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: softBlue, width: 1),
                    boxShadow: [
                      BoxShadow(color: navyDeep.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [c, c.withOpacity(0.72)]),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [BoxShadow(color: c.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: Text(
                              initials,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                          ),
                          Positioned(
                            bottom: -2,
                            right: -2,
                            child: Container(
                              width: 11,
                              height: 11,
                              decoration: BoxDecoration(
                                color: green,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
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
                              style: const TextStyle(fontSize: 9, color: mutedText, height: 1.2),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: softBlue, borderRadius: BorderRadius.circular(20)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.delivery_dining_rounded, size: 10, color: primaryBlue),
                                  const SizedBox(width: 3),
                                  Text(
                                    s['time'] as String,
                                    style: const TextStyle(fontSize: 8.5, color: primaryBlue, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
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
  // ✅ CATÉGORIES — version compacte (chips), fonctionnalité conservée
  // ============================================================
  Widget _buildCategoryChipsSection() {
    final categories = [
      {'icon': Icons.checkroom_rounded, 'label': 'Mode', 'id': 'fashion'},
      {'icon': Icons.phone_android_rounded, 'label': 'Électronique', 'id': 'electronics'},
      {'icon': Icons.chair_rounded, 'label': 'Maison', 'id': 'home'},
      {'icon': Icons.build_rounded, 'label': 'Services', 'id': 'services'},
      {'icon': Icons.directions_car_rounded, 'label': 'Véhicules', 'id': 'vehicles'},
      {'icon': Icons.house_rounded, 'label': 'Immobilier', 'id': 'realestate'},
    ];

    return SizedBox(
      height: 34,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => context.push('/market/category/${cat['id']}'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: pureWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: softBlue, width: 1),
                  boxShadow: [
                    BoxShadow(color: navyDeep.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cat['icon'] as IconData, size: 13, color: navy),
                    const SizedBox(width: 5),
                    Text(
                      cat['label'] as String,
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: darkText),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
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
            const Text('Offres Flash', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: darkText)),
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
            const Text('Recommandé', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: darkText)),
            TextButton(
              onPressed: () => context.push('/market/buy'),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
              child: const Text('Voir tout', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w700, fontSize: 12)),
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
  // CARTE PRODUIT HORIZONTALE
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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: softBlue, width: 1),
          boxShadow: [
            BoxShadow(color: navyDeep.withOpacity(0.07), blurRadius: 14, offset: const Offset(0, 7)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _networkImage(product['image_url']),
                    if (isFlash)
                      Positioned(
                        top: 7,
                        left: 7,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFFF5B3D), Color(0xFFFF8A3D)]),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: const Color(0xFFFF5B3D).withOpacity(0.4), blurRadius: 7, offset: const Offset(0, 3))],
                          ),
                          child: const Text('FLASH', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
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
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: darkText),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$price $symbol',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: navyDeep),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 10, color: mutedText),
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
          color: pureWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: softBlue, width: 1),
          boxShadow: [
            BoxShadow(color: navyDeep.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 7)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _networkImage(product['image_url']),
                    if (hasDiscount)
                      Positioned(
                        top: 7,
                        left: 7,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFFF5B3D), Color(0xFFFF8A3D)]),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '-${((1 - price / originalPrice) * 100).round()}%',
                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 7,
                      right: 7,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: navyDeep.withOpacity(0.1), blurRadius: 5)],
                        ),
                        child: const Icon(Icons.bookmark_border_rounded, size: 13, color: navy),
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
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: darkText),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        '${price.toInt()} $symbol',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: navyDeep),
                      ),
                      if (hasDiscount)
                        Padding(
                          padding: const EdgeInsets.only(left: 5),
                          child: Text(
                            '${originalPrice.toInt()} $symbol',
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              fontSize: 9.5,
                              color: mutedText,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 9.5, color: mutedText),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          product['city'] ?? 'Abidjan',
                          style: TextStyle(fontSize: 8.5, color: mutedText),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.store_rounded, size: 9.5, color: mutedText),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          product['shop']?['name'] ?? 'Vendeur',
                          style: TextStyle(fontSize: 8.5, color: mutedText),
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
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: darkText)),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
            child: const Text('Voir tout', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
      ],
    );
  }

  // ============================================================
  // BOTTOM NAV BAR
  // ============================================================
  Widget _buildBottomNavBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      decoration: BoxDecoration(
        color: pureWhite,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(color: navyDeep.withOpacity(0.12), blurRadius: 22, offset: const Offset(0, 9)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, 'Accueil', true, () {}),
              _buildNavItem(Icons.favorite_border_rounded, 'Wishlist', false, _goToWishlist),
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
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: isSelected ? softBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isSelected ? primaryBlue : mutedText, size: 20),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                color: isSelected ? primaryBlue : mutedText,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
