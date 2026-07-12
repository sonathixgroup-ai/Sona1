import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../providers/market_provider.dart';
import '../providers/shop_provider.dart';
import '../widgets/market/flash_sale_timer.dart';

class MarketHomePage extends StatefulWidget {
  const MarketHomePage({super.key});
  @override
  State<MarketHomePage> createState() => _MarketHomePageState();
}

class _MarketHomePageState extends State<MarketHomePage> {
  final ScrollController _scrollController = ScrollController();
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;
  int _currentBanner = 0;

  // ============================================================
  // CHARTE GRAPHITE - International Standard
  // ============================================================
  static const Color graphite900 = Color(0xFF0E0E10);
  static const Color graphite800 = Color(0xFF18181B);
  static const Color graphite700 = Color(0xFF27272A);
  static const Color graphite600 = Color(0xFF3F3F46);
  static const Color graphite500 = Color(0xFF71717A);
  static const Color graphite300 = Color(0xFFD4D4D8);
  static const Color graphite100 = Color(0xFFF4F4F5);
  static const Color graphite50 = Color(0xFFFAFAFA);
  static const Color accent = Color(0xFFFFFFFF); // CTA principal
  static const Color accent2 = Color(0xFFE9FF70); // lime international
  static const Color success = Color(0xFF22C55E);
  static const Color danger = Color(0xFFEF4444);

  static const List<Map<String, dynamic>> _supermarkets = [
    {'name': 'Kin Frais', 'tagline': 'Frais • 35 min', 'initial': 'KF', 'color': Color(0xFF18181B)},
    {'name': 'AlimentPlus', 'tagline': 'Épicerie • 40 min', 'initial': 'AP', 'color': Color(0xFF27272A)},
    {'name': 'ÉpiCash', 'tagline': 'Prix bas • 30 min', 'initial': 'EC', 'color': Color(0xFF3F3F46)},
    {'name': 'MaxiMarché', 'tagline': 'Familial • 45 min', 'initial': 'MM', 'color': Color(0xFF18181B)},
    {'name': 'SuperGo', 'tagline': 'Express • 25 min', 'initial': 'SG', 'color': Color(0xFF27272A)},
  ];

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

  void _startAutoplay(int count) {
    _bannerTimer?.cancel();
    if (count <= 1) return;
    _bannerTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!_bannerController.hasClients) return;
      _currentBanner = (_currentBanner + 1) % count;
      _bannerController.animateToPage(_currentBanner, duration: const Duration(milliseconds: 650), curve: Curves.easeInOutCubicEmphasized);
      setState(() {});
    });
  }

  void _goToVendor() => context.push('/market/vendor/dashboard');
  void _goToCart() => context.push('/market/cart');
  void _goToWishlist() => context.push('/market/buy');

  Widget _netImg(String? url) {
    if (url == null || url.isEmpty) return Container(color: graphite700, child: const Icon(Icons.image, color: graphite500));
    return CachedNetworkImage(
      imageUrl: url, fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: graphite700),
      errorWidget: (_, __, ___) => Container(color: graphite700, child: const Icon(Icons.broken_image_outlined, color: graphite500)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final market = context.watch<MarketProvider>();
    final banners = market.promoBanners;

    if (banners.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoplay(banners.length));
    }

    final allById = <String, dynamic>{};
    for (final p in [...market.flashSales,...market.recommendedProducts,...market.forYouProducts]) {
      allById[p['id'].toString()] = p;
    }
    final allProducts = allById.values.toList();

    return Scaffold(
      backgroundColor: graphite50,
      body: RefreshIndicator(
        color: graphite900,
        onRefresh: () => market.refresh(),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            _buildGraphiteAppBar(),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 14),
                  if (banners.isNotEmpty) _buildBannerInternational(banners),
                  const SizedBox(height: 20),
                  _buildSupermarketsInternational(),
                  const SizedBox(height: 20),
                  _buildCategoriesInternational(),
                  const SizedBox(height: 20),
                  if (market.flashSales.isNotEmpty) _buildFlashInternational(market.flashSales),
                  if (market.recommendedProducts.isNotEmpty) _buildSectionHorizontal('Recommandé pour vous', market.recommendedProducts, onSeeAll: () => context.push('/market/buy')),
                  if (allProducts.isNotEmpty)...[
                    Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 10), child: _sectionHeader('Marketplace • Tous les produits', action: 'Voir tout', onTap: () => context.push('/market/buy'))),
                    _productGridInternational(allProducts),
                  ],
                  const SizedBox(height: 110),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavGraphite(),
    );
  }

  // ============================================================
  // APP BAR GRAPHITE
  // ============================================================
  Widget _buildGraphiteAppBar() {
    return SliverAppBar(
      pinned: true, floating: true, elevation: 0, backgroundColor: graphite900, toolbarHeight: 64,
      title: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: graphite800, borderRadius: BorderRadius.circular(10), border: Border.all(color: graphite700)), child: const Icon(Icons.storefront_rounded, size: 18, color: Colors.white)),
        const SizedBox(width: 10),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('THIX MARKET', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.6)),
          Text('Livraison • Kinshasa', style: TextStyle(fontSize: 10, color: graphite500, fontWeight: FontWeight.w500)),
        ]),
        const Spacer(),
        _appBarIcon(Icons.notifications_none_rounded, () => context.push('/market/notifications'), hasDot: true),
        const SizedBox(width: 8),
        _appBarIcon(Icons.store_rounded, _goToVendor),
      ]),
    );
  }

  Widget _appBarIcon(IconData icon, VoidCallback tap, {bool hasDot = false}) {
    return InkWell(
      onTap: tap, borderRadius: BorderRadius.circular(10),
      child: Stack(clipBehavior: Clip.none, children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: graphite800, borderRadius: BorderRadius.circular(10), border: Border.all(color: graphite700)), child: Icon(icon, size: 18, color: Colors.white)),
        if (hasDot) Positioned(top: -2, right: -2, child: Container(width: 9, height: 9, decoration: BoxDecoration(color: accent2, shape: BoxShape.circle, border: Border.all(color: graphite900, width: 1.5)))),
      ]),
    );
  }

  // ============================================================
  // SEARCH - INTERNATIONAL STANDARD
  // ============================================================
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: InkWell(
        onTap: () => context.push('/market/search'),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: graphite300)),
          child: Row(children: [
            const Icon(Icons.search_rounded, color: graphite500, size: 20),
            const SizedBox(width: 10),
            const Expanded(child: Text('Rechercher produits, marques, boutiques', style: TextStyle(color: graphite500, fontSize: 13.5))),
            Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: graphite900, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.tune_rounded, size: 14, color: Colors.white)),
          ]),
        ),
      ),
    );
  }

  // ============================================================
  // BANNER INTERNATIONAL - Rectangulaire, full bleed, 6s autoplay
  // ============================================================
  Widget _buildBannerInternational(List banners) {
    return Column(children: [
      SizedBox(
        height: 176,
        child: PageView.builder(
          controller: _bannerController,
          onPageChanged: (i) => setState(() => _currentBanner = i),
          itemCount: banners.length,
          itemBuilder: (context, i) {
            final b = banners[i];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: graphite800),
              clipBehavior: Clip.hardEdge,
              child: Stack(fit: StackFit.expand, children: [
                _netImg(b['image_url']),
                Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [graphite900.withOpacity(0.85), Colors.transparent, Colors.transparent]))),
                Positioned(
                  left: 16, bottom: 16, right: 16,
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: accent2, borderRadius: BorderRadius.circular(20)), child: const Text('NOUVEAU', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: graphite900))),
                      const SizedBox(height: 6),
                      Text(b['title']?? 'Offre Spéciale Marketplace', maxLines: 1, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                    ])),
                    InkWell(onTap: () => context.push('/market/flash-sales'), child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: const Text('Acheter', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: graphite900)))),
                  ]),
                ),
              ]),
            );
          },
        ),
      ),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(banners.length, (i) => AnimatedContainer(duration: const Duration(milliseconds: 300), width: i == _currentBanner? 20 : 6, height: 6, margin: const EdgeInsets.symmetric(horizontal: 3), decoration: BoxDecoration(color: i == _currentBanner? graphite900 : graphite300, borderRadius: BorderRadius.circular(10))))),
    ]);
  }

  // ============================================================
  // SUPERMARCHÉS - INTERNATIONAL CARD
  // ============================================================
  Widget _buildSupermarketsInternational() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _sectionHeader('Supermarchés à domicile', action: 'Voir tout', onTap: () => context.push('/market/search'))),
      const SizedBox(height: 10),
      SizedBox(
        height: 98,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16), scrollDirection: Axis.horizontal, itemCount: _supermarkets.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, i) {
            final s = _supermarkets[i];
            return InkWell(
              onTap: () => context.push('/market/search?shop=${Uri.encodeComponent(s['name'])}'), borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 180, padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: graphite300)),
                child: Row(children: [
                  Container(width: 44, height: 44, alignment: Alignment.center, decoration: BoxDecoration(color: s['color'] as Color, borderRadius: BorderRadius.circular(12)), child: Text(s['initial'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13))),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(s['name'], maxLines: 1, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: graphite900)),
                    const SizedBox(height: 2), Text(s['tagline'], style: const TextStyle(fontSize: 10, color: graphite500)),
                    const SizedBox(height: 4), Row(children: [Container(width: 6, height: 6, decoration: const BoxDecoration(color: success, shape: BoxShape.circle)), const SizedBox(width: 4), const Text('Ouvert', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: success))]),
                  ])),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }

  // ============================================================
  // CATEGORIES - CHIPS GRAPHITE
  // ============================================================
  Widget _buildCategoriesInternational() {
    final cats = [
      {'label': 'Mode', 'id': 'fashion', 'icon': Icons.checkroom_outlined},
      {'label': 'Tech', 'id': 'electronics', 'icon': Icons.phone_iphone_outlined},
      {'label': 'Maison', 'id': 'home', 'icon': Icons.chair_outlined},
      {'label': 'Services', 'id': 'services', 'icon': Icons.handyman_outlined},
      {'label': 'Auto', 'id': 'vehicles', 'icon': Icons.directions_car_outlined},
      {'label': 'Immo', 'id': 'realestate', 'icon': Icons.home_work_outlined},
    ];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16), scrollDirection: Axis.horizontal, itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (c, i) {
          final cat = cats[i];
          final isFirst = i == 0;
          return InkWell(
            onTap: () => context.push('/market/category/${cat['id']}'), borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: isFirst? graphite900 : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: isFirst? graphite900 : graphite300)),
              child: Row(children: [Icon(cat['icon'] as IconData, size: 16, color: isFirst? Colors.white : graphite700), const SizedBox(width: 6), Text(cat['label'] as String, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: isFirst? Colors.white : graphite900))]),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // FLASH SALE - GRAPHITE
  // ============================================================
  Widget _buildFlashInternational(List flash) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: graphite900, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: danger, borderRadius: BorderRadius.circular(6)), child: const Text('FLASH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10))),
          const SizedBox(width: 8), const Text('Offres Flash', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
          const Spacer(), FlashSaleTimer(endTime: DateTime.now().add(const Duration(hours: 2, minutes: 45))),
        ]),
        const SizedBox(height: 14),
        SizedBox(height: 196, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: flash.take(6).length, separatorBuilder: (_, __) => const SizedBox(width: 10), itemBuilder: (c, i) => _productCardGraphite(flash[i], isDark: true, isFlash: true))),
      ]),
    );
  }

  Widget _buildSectionHorizontal(String title, List products, {VoidCallback? onSeeAll}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 10), child: _sectionHeader(title, action: 'Voir tout', onTap: onSeeAll)),
      SizedBox(height: 210, child: ListView.separated(padding: const EdgeInsets.symmetric(horizontal: 16), scrollDirection: Axis.horizontal, itemCount: products.take(8).length, separatorBuilder: (_, __) => const SizedBox(width: 10), itemBuilder: (c, i) => _productCardGraphite(products[i]))),
    ]);
  }

  // ============================================================
  // PRODUCT CARD - INTERNATIONAL STANDARD
  // ============================================================
  Widget _productCardGraphite(Map product, {bool isDark = false, bool isFlash = false}) {
    final price = (product['price'] as num).toInt();
    final currency = product['currency']?? 'FC';
    final symbol = currency == 'USD'? '\$' : 'FC';
    return InkWell(
      onTap: () => context.push('/market/product/${product['id']}'), borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 148,
        decoration: BoxDecoration(color: isDark? graphite800 : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark? graphite700 : graphite300)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: Stack(fit: StackFit.expand, children: [
            _netImg(product['image_url']),
            if (isFlash) Positioned(top: 8, left: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), decoration: BoxDecoration(color: danger, borderRadius: BorderRadius.circular(6)), child: const Text('-30%', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)))),
            Positioned(top: 8, right: 8, child: Container(width: 28, height: 28, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)]), child: const Icon(Icons.favorite_border_rounded, size: 14, color: graphite900))),
          ]))),
          Padding(padding: const EdgeInsets.all(9), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(product['title']?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: isDark? Colors.white : graphite900)),
            const SizedBox(height: 4),
            Text('$price $symbol', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: isDark? Colors.white : graphite900)),
            const SizedBox(height: 3),
            Row(children: [const Icon(Icons.location_on_outlined, size: 10, color: graphite500), const SizedBox(width: 2), Expanded(child: Text(product['city']?? 'Kinshasa', maxLines: 1, style: const TextStyle(fontSize: 9.5, color: graphite500)))]),
          ])),
        ]),
      ),
    );
  }

  Widget _productGridInternational(List products) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.68),
        itemCount: products.length > 10? 10 : products.length,
        itemBuilder: (c, i) {
          final p = products[i];
          final price = (p['price'] as num).toInt();
          final symbol = (p['currency']?? 'FC') == 'USD'? '\$' : 'FC';
          return InkWell(
            onTap: () => context.push('/market/product/${p['id']}'), borderRadius: BorderRadius.circular(18),
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: graphite300)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(18)), child: Stack(fit: StackFit.expand, children: [_netImg(p['image_url']), Positioned(top: 8, left: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: graphite900, borderRadius: BorderRadius.circular(20)), child: const Text('LIVRAISON', style: TextStyle(color: accent2, fontSize: 8, fontWeight: FontWeight.w800))))]))),
                Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p['title']?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: graphite900)),
                  const SizedBox(height: 4), Text('$price $symbol', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: graphite900)),
                  const SizedBox(height: 4), Row(children: [const Icon(Icons.store_outlined, size: 11, color: graphite500), const SizedBox(width: 3), Expanded(child: Text(p['shop']?['name']?? 'Vendeur vérifié', maxLines: 1, style: const TextStyle(fontSize: 10, color: graphite500)))]),
                ])),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title, {String? action, VoidCallback? onTap}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: graphite900)),
      if (action!= null) InkWell(onTap: onTap, child: Text(action, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: graphite500))),
    ]);
  }

  Widget _buildBottomNavGraphite() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(color: graphite900, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8))]),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _navItemGraphite(Icons.home_rounded, 'Accueil', true, () {}),
            _navItemGraphite(Icons.favorite_border_rounded, 'Wishlist', false, _goToWishlist),
            _navItemGraphite(Icons.shopping_bag_outlined, 'Panier', false, _goToCart),
            _navItemGraphite(Icons.chat_bubble_outline_rounded, 'Chat', false, () => context.push('/market/messages')),
            _navItemGraphite(Icons.person_outline_rounded, 'Profil', false, () => context.push('/market/activity')),
          ]),
        ),
      ),
    );
  }

  Widget _navItemGraphite(IconData icon, String label, bool sel, VoidCallback tap) {
    return InkWell(
      onTap: tap, borderRadius: BorderRadius.circular(12),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 20, color: sel? accent2 : graphite500),
        const SizedBox(height: 3), Text(label, style: TextStyle(fontSize: 9.5, fontWeight: sel? FontWeight.w800 : FontWeight.w500, color: sel? Colors.white : graphite500)),
      ])),
    );
  }
}
