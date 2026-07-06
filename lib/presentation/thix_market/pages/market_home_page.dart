import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../providers/market_provider.dart';
import '../providers/shop_provider.dart';
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

  static const Color navy = Color(0xFF1B2A4A);
  static const Color navyDeep = Color(0xFF10192E);
  static const Color gold = Color(0xFFC9962C);
  static const Color goldLight = Color(0xFFE8C98A);
  static const Color bgApp = Color(0xFFF6F7FB);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A1D29);
  static const Color textMuted = Color(0xFF8A8FA3);
  static const Color danger = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() => _isAppBarExpanded = _scrollController.offset < 90);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketProvider>().loadHomeData();
      context.read<ShopProvider>().loadMyShops(); // pour savoir si on a un shop
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _goToMyShop(MarketProvider marketProvider, ShopProvider shopProvider) {
    if (shopProvider.hasShop) {
      context.push('/market/shop/${shopProvider.myShopId}');
    } else {
      context.push('/market/shop/create');
    }
  }

  Widget _networkImage(String? url, {BoxFit fit = BoxFit.cover, double iconSize = 22, IconData icon = Icons.image_outlined}) {
    if (url == null || url.trim().isEmpty) {
      return Container(color: bgApp, alignment: Alignment.center, child: Icon(icon, color: textMuted, size: iconSize));
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (_, __) => Container(
        color: bgApp,
        alignment: Alignment.center,
        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: gold)),
      ),
      errorWidget: (_, __, ___) => Container(
        color: bgApp,
        alignment: Alignment.center,
        child: Icon(Icons.image_not_supported_outlined, color: textMuted, size: iconSize),
      ),
    );
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

    final marqueeProducts = marketProvider.flashSales.isNotEmpty
        ? marketProvider.flashSales
        : allProducts.take(10).toList();

    return Scaffold(
      backgroundColor: bgApp,
      body: RefreshIndicator(
        color: gold,
        onRefresh: () => marketProvider.refresh(),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            _buildAppBar(marketProvider, shopProvider),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _buildHeroWelcome(marketProvider),
                    const SizedBox(height: 12),
                    _buildTrustRow(),
                    const SizedBox(height: 16),
                    _buildSectionCard(const CategoryGrid()),
                    const SizedBox(height: 16),
                    _buildDualBanners(marketProvider, shopProvider),
                    const SizedBox(height: 16),
                    if (marqueeProducts.isNotEmpty) ...[
                      _sectionHeader(title: 'À ne pas manquer', icon: Icons.local_fire_department_rounded, iconColor: danger),
                      const SizedBox(height: 8),
                      _ProductMarquee(products: marqueeProducts, imageBuilder: _networkImage),
                      const SizedBox(height: 18),
                    ],
                    if (marketProvider.flashSales.isNotEmpty) ...[
                      _buildFlashSales(marketProvider.flashSales),
                      const SizedBox(height: 20),
                    ],
                    if (marketProvider.liveSessions.isNotEmpty) ...[
                      _buildLiveSessions(marketProvider.liveSessions),
                      const SizedBox(height: 20),
                    ],
                    if (allProducts.isNotEmpty) ...[
                      _sectionHeader(title: 'Tous les produits', icon: Icons.grid_view_rounded),
                      const SizedBox(height: 8),
                      _productGrid(allProducts),
                    ],
                    const SizedBox(height: 90),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(marketProvider, shopProvider),
    );
  }

  Widget _buildSectionCard(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: navy.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: child,
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================
  Widget _buildAppBar(MarketProvider marketProvider, ShopProvider shopProvider) {
    return SliverAppBar(
      expandedHeight: 68,
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
            Text('THIX', style: TextStyle(fontWeight: FontWeight.w800, color: navy, fontSize: 18)),
            Text(' Market', style: TextStyle(fontWeight: FontWeight.w600, color: gold, fontSize: 18)),
          ],
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: Colors.white,
          padding: const EdgeInsets.only(top: 44),
          child: Row(
            children: [
              const SizedBox(width: 14),
              RichText(
                text: const TextSpan(children: [
                  TextSpan(text: 'THIX', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 21, color: navy)),
                  TextSpan(text: ' Market', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 21, color: gold)),
                ]),
              ),
              const Spacer(),
              _buildIconButton(Icons.qr_code_scanner_rounded, () => context.push('/scan-qr')),
              Stack(
                children: [
                  _buildIconButton(Icons.notifications_none_rounded, () => context.push('/market/notifications')),
                  if (marketProvider.unreadNotifications > 0)
                    Positioned(
                      top: 4, right: 4,
                      child: Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(color: danger, shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
              _buildIconButton(Icons.storefront_rounded, () => _goToMyShop(marketProvider, shopProvider)),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bgApp, borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, size: 17, color: navy),
      ),
    );
  }

  // ============================================================
  // HERO
  // ============================================================
  Widget _buildHeroWelcome(MarketProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [navy, navyDeep], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: navy.withOpacity(0.3), blurRadius: 18, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bonjour, ${provider.userDisplayName} 👋', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, height: 1.25),
              children: [
                TextSpan(text: 'Votre marketplace ', style: TextStyle(color: Colors.white)),
                TextSpan(text: 'premium', style: TextStyle(color: gold)),
                TextSpan(text: ' et sécurisée', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Des milliers de produits, des vendeurs vérifiés.',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(right: 0),
            child: GestureDetector(
              onTap: () => context.push('/market/search'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: gold,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.search_rounded, size: 16, color: navyDeep),
                    SizedBox(width: 6),
                    Text('Explorer le marché', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: navyDeep)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustRow() {
    final items = [
      (Icons.lock_outline_rounded, 'Paiement\nsécurisé'),
      (Icons.verified_outlined, 'Vendeurs\nvérifiés'),
      (Icons.local_shipping_outlined, 'Livraison\nfiable'),
      (Icons.support_agent_rounded, 'Support\n24/7'),
    ];
    return Row(
      children: items.map((item) {
        return Expanded(
          child: Column(
            children: [
              Icon(item.$1, size: 18, color: navy),
              const SizedBox(height: 4),
              Text(item.$2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9.5, color: textMuted, height: 1.2)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _sectionHeader({required String title, IconData? icon, Color? iconColor, VoidCallback? onSeeAll, Widget? trailing}) {
    return Row(
      children: [
        if (icon != null) ...[Icon(icon, color: iconColor ?? navy, size: 16), const SizedBox(width: 5)],
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: textDark, letterSpacing: -0.2)),
        const Spacer(),
        if (trailing != null) trailing,
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Row(children: const [
              Text('Voir tout', style: TextStyle(color: gold, fontWeight: FontWeight.w700, fontSize: 11.5)),
              Icon(Icons.chevron_right_rounded, size: 15, color: gold),
            ]),
          ),
      ],
    );
  }

  // ============================================================
  // DOUBLE BANNIÈRE
  // ============================================================
  Widget _buildDualBanners(MarketProvider marketProvider, ShopProvider shopProvider) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => context.push('/market/promo'),
            child: Container(
              height: 110,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [navy, navyDeep], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('OFFRES EXCLUSIVES', style: TextStyle(color: gold, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                  Text('Jusqu\'à -50%', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                  Row(children: [
                    Text('Découvrir', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    Icon(Icons.chevron_right_rounded, color: Colors.white, size: 15),
                  ]),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => _goToMyShop(marketProvider, shopProvider),
            child: Container(
              height: 110,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [gold, goldLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    shopProvider.hasShop ? 'VOTRE BOUTIQUE' : 'VENDEZ AVEC THIX',
                    style: const TextStyle(color: navyDeep, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                  ),
                  Text(
                    shopProvider.hasShop ? 'Gérer mon shop' : 'Développez votre business',
                    style: const TextStyle(color: navyDeep, fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  Row(children: [
                    Text(shopProvider.hasShop ? 'Accéder' : 'Commencer', style: const TextStyle(color: navyDeep, fontSize: 11, fontWeight: FontWeight.w700)),
                    const Icon(Icons.chevron_right_rounded, color: navyDeep, size: 15),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ],
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
          title: 'Offres Flash', icon: Icons.flash_on_rounded, iconColor: danger,
          trailing: FlashSaleTimer(endTime: DateTime.now().add(const Duration(hours: 2, minutes: 45))),
        ),
        const SizedBox(height: 8),
        _productGrid(flashSales.take(8).toList(), isFlash: true),
      ],
    );
  }

  // ============================================================
  // LIVES
  // ============================================================
  Widget _buildLiveSessions(List<dynamic> lives) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(title: 'Lives en cours', icon: Icons.podcasts_rounded, iconColor: danger, onSeeAll: () => context.push('/market/live')),
        const SizedBox(height: 8),
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: lives.length,
            itemBuilder: (context, index) {
              final live = lives[index];
              return GestureDetector(
                onTap: () => context.push('/market/live/${live['id']}'),
                child: Container(
                  width: 130,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: cardBg,
                    boxShadow: [BoxShadow(color: navy.withOpacity(0.06), blurRadius: 13, offset: const Offset(0, 6))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                          child: Stack(fit: StackFit.expand, children: [
                            _networkImage(live['thumbnail'], icon: Icons.live_tv_rounded),
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.3)]),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 6, left: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: danger, borderRadius: BorderRadius.circular(5)),
                                child: const Row(children: [
                                  Icon(Icons.fiber_manual_record, size: 5, color: Colors.white),
                                  SizedBox(width: 3),
                                  Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                ]),
                              ),
                            ),
                            Positioned(
                              bottom: 6, right: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(5)),
                                child: Row(children: [
                                  const Icon(Icons.remove_red_eye_rounded, size: 9, color: Colors.white),
                                  const SizedBox(width: 2),
                                  Text('${live['viewers'] ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 9)),
                                ]),
                              ),
                            ),
                          ]),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(live['title'] ?? 'Live', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5, color: textDark)),
                            const SizedBox(height: 2),
                            Text(live['city'] ?? '', style: const TextStyle(fontSize: 9.5, color: textMuted)),
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
  // GRILLE PRODUITS
  // ============================================================
  Widget _productGrid(List<dynamic> products, {bool isFlash = false}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.7,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) => _buildProductGridItem(products[index], isFlash: isFlash),
    );
  }

  Widget _buildProductGridItem(Map<String, dynamic> product, {bool isFlash = false}) {
    final hasDiscount = product['discount_price'] != null && product['discount_price'] < product['price'];
    final price = (hasDiscount ? product['discount_price'] : product['price']).toDouble();
    final originalPrice = product['price'].toDouble();
    final currency = product['currency'] ?? 'FC';

    return GestureDetector(
      onTap: () => context.push('/market/product/${product['id']}'),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: navy.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(fit: StackFit.expand, children: [
                  _networkImage(product['image_url']),
                  if (hasDiscount)
                    Positioned(top: 6, left: 6, child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(color: danger, borderRadius: BorderRadius.circular(6)),
                      child: Text('-${((1 - price / originalPrice) * 100).round()}%', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    )),
                  if (isFlash)
                    Positioned(top: 6, right: 6, child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(6)),
                      child: const Text('FLASH', style: TextStyle(color: navyDeep, fontSize: 8, fontWeight: FontWeight.bold)),
                    )),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: textDark)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text('${price.toInt()} $currency', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: navy)),
                    if (hasDiscount) Padding(
                      padding: const EdgeInsets.only(left: 5),
                      child: Text('${originalPrice.toInt()}', style: const TextStyle(decoration: TextDecoration.lineThrough, fontSize: 9.5, color: textMuted)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.location_on_rounded, size: 11, color: textMuted),
                    const SizedBox(width: 2),
                    Expanded(child: Text(product['city'] ?? '', style: const TextStyle(fontSize: 9.5, color: textMuted), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM NAV
  // ============================================================
  Widget _buildBottomNavBar(MarketProvider marketProvider, ShopProvider shopProvider) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: navy.withOpacity(0.08), blurRadius: 14, offset: const Offset(0, -3))]),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, 'Accueil', true, () {}),
              _buildNavItem(Icons.category_rounded, 'Catégories', false, () => context.push('/market/search')),
              _buildNavItem(Icons.storefront_rounded, 'Mon Shop', false, () => _goToMyShop(marketProvider, shopProvider)),
              _buildNavItem(Icons.message_rounded, 'Messages', false, () => context.push('/market/messages')),
              _buildNavItem(Icons.person_rounded, 'Compte', false, () => context.push('/market/activity')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: isSelected ? navy : textMuted, size: 20),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 9.5, color: isSelected ? navy : textMuted, fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal)),
        ]),
      ),
    );
  }
}

// ============================================================
// PRODUCT MARQUEE
// ============================================================
class _ProductMarquee extends StatefulWidget {
  final List<dynamic> products;
  final Widget Function(String? url, {BoxFit fit, double iconSize, IconData icon}) imageBuilder;

  const _ProductMarquee({required this.products, required this.imageBuilder});

  @override
  State<_ProductMarquee> createState() => _ProductMarqueeState();
}

class _ProductMarqueeState extends State<_ProductMarquee> {
  final ScrollController _controller = ScrollController();
  Timer? _timer;
  static const double _itemWidth = 132;
  static const double _speed = 0.7;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() {
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_controller.hasClients) return;
      final max = _controller.position.maxScrollExtent;
      if (max <= 0) return;
      double next = _controller.offset + _speed;
      if (next >= max) next = 0;
      _controller.jumpTo(next);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) return const SizedBox.shrink();
    final loop = [...widget.products, ...widget.products, ...widget.products];

    return SizedBox(
      height: 168,
      child: ListView.builder(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: loop.length,
        itemBuilder: (context, index) {
          final product = loop[index];
          final price = product['price'];
          final currency = product['currency'] ?? 'FC';
          final discount = product['discount_price'];
          final hasDiscount = discount != null && price != null && discount < price;

          return Container(
            width: _itemWidth,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: const Color(0xFF1B2A4A).withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 5))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    child: Stack(fit: StackFit.expand, children: [
                      widget.imageBuilder(product['image_url']),
                      if (hasDiscount)
                        Positioned(
                          top: 5, left: 5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(5)),
                            child: Text(
                              '-${((1 - (discount / price)) * 100).round()}%',
                              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['title'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF1A1D29)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${((hasDiscount ? discount : price) ?? 0).toInt()} $currency',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF1B2A4A)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
