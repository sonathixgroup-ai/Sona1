// lib/presentation/thix_market/pages/market_home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../providers/market_provider.dart';

class MarketHomePage extends StatefulWidget {
  const MarketHomePage({super.key});

  @override
  State<MarketHomePage> createState() => _MarketHomePageState();
}

class _MarketHomePageState extends State<MarketHomePage> {
  // ============================================================
  // CHARTE THIX MARKET — Institutionnel Bleu / Blanc
  // ============================================================
  static const Color navyDeep = Color(0xFF0E2A52);
  static const Color navy = Color(0xFF123B7A);
  static const Color blue = Color(0xFF2D6CDF);
  static const Color blueSoft = Color(0xFFE7EEFC);
  static const Color bgApp = Color(0xFFF6F9FF);
  static const Color gold = Color(0xFFC9962C);
  static const Color textMuted = Color(0xFF6C7A96);
  static const Color textDark = Color(0xFF10192E);

  final List<Map<String, String>> _categories = const [
    {'id': 'fashion', 'name': 'Mode', 'icon': 'checkroom'},
    {'id': 'electronics', 'name': 'Électro.', 'icon': 'devices'},
    {'id': 'home', 'name': 'Maison', 'icon': 'chair'},
    {'id': 'vehicles', 'name': 'Véhicules', 'icon': 'directions_car'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketProvider>().loadIfStale();
    });
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'checkroom':
        return Icons.checkroom_rounded;
      case 'devices':
        return Icons.devices_other_rounded;
      case 'chair':
        return Icons.chair_rounded;
      case 'directions_car':
        return Icons.directions_car_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final market = context.watch<MarketProvider>();

    return Scaffold(
      backgroundColor: bgApp,
      body: RefreshIndicator(
        color: navyDeep,
        onRefresh: () => market.refresh(),
        child: CustomScrollView(
          slivers: [
            // ============================================================
            // HEADER INCURVÉ — signature THIX MARKET
            // ============================================================
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 34),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [navyDeep, navy, blue],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bonjour, ${market.userDisplayName}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/market/notifications'),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 20),
                              ),
                              if (market.unreadNotifications > 0)
                                Positioned(
                                  top: -2,
                                  right: -2,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: gold, shape: BoxShape.circle),
                                    child: Text(
                                      '${market.unreadNotifications}',
                                      style: const TextStyle(color: navyDeep, fontSize: 9, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => context.push('/market/search'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withOpacity(0.25)),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.search_rounded, color: Colors.white70, size: 18),
                            SizedBox(width: 10),
                            Text(
                              'Rechercher un produit, une boutique…',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ============================================================
            // CONTENU
            // ============================================================
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (market.isLoading && !market.hasData)
                    const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(child: CircularProgressIndicator(color: navyDeep)),
                    )
                  else ...[
                    // ---- Lives en cours ----
                    if (market.liveSessions.isNotEmpty) ...[
                      _sectionTitle('En direct', onSeeAll: () => context.push('/market/lives')),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 150,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: market.liveSessions.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, i) => _liveCard(market.liveSessions[i]),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ---- Bannière promo ----
                    if (market.promoBanners.isNotEmpty) ...[
                      _promoBanner(market.promoBanners.first),
                      const SizedBox(height: 24),
                    ],

                    // ---- Catégories ----
                    _sectionTitle('Catégories', onSeeAll: () => context.push('/market/categories')),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _categories.map((cat) => _categoryChip(cat)).toList(),
                    ),
                    const SizedBox(height: 24),

                    // ---- Vente Flash ----
                    if (market.flashSales.isNotEmpty) ...[
                      _sectionTitle('Vente Flash', onSeeAll: () => context.push('/market/flash-sale')),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 210,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: market.flashSales.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, i) => _productCard(market.flashSales[i]),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ---- Boutiques en vedette ----
                    if (market.featuredShops.isNotEmpty) ...[
                      _sectionTitle('Boutiques recommandées', onSeeAll: () => context.push('/market/shops')),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: market.featuredShops.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, i) => _shopChip(market.featuredShops[i]),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ---- Pour toi ----
                    if (market.forYouProducts.isNotEmpty) ...[
                      _sectionTitle('Pour toi'),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.68,
                        ),
                        itemCount: market.forYouProducts.length,
                        itemBuilder: (context, i) => _productCard(market.forYouProducts[i]),
                      ),
                    ],
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WIDGETS RÉUTILISABLES
  // ============================================================

  Widget _sectionTitle(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: textDark)),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: const Row(
              children: [
                Text('Voir tout', style: TextStyle(color: blue, fontWeight: FontWeight.w700, fontSize: 12)),
                Icon(Icons.chevron_right_rounded, size: 16, color: blue),
              ],
            ),
          ),
      ],
    );
  }

  Widget _promoBanner(Map<String, dynamic> banner) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [navyDeep, blue]),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(20)),
                  child: const Text('Offre limitée',
                      style: TextStyle(color: navyDeep, fontSize: 10, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 10),
                Text(
                  banner['title'] ?? 'Découvre THIX MARKET',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(Map<String, String> cat) {
    return GestureDetector(
      onTap: () => context.push('/market/category/${cat['id']}'),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(color: blueSoft, borderRadius: BorderRadius.circular(20)),
            child: Icon(_iconFor(cat['icon']!), color: navy, size: 24),
          ),
          const SizedBox(height: 8),
          Text(cat['name']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textDark)),
        ],
      ),
    );
  }

  Widget _liveCard(Map<String, dynamic> live) {
    final shop = live['shop'] as Map<String, dynamic>?;
    return GestureDetector(
      onTap: () => context.push('/market/live/${live['id']}'),
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: navyDeep,
          image: live['thumbnail_url'] != null
              ? DecorationImage(image: CachedNetworkImageProvider(live['thumbnail_url']), fit: BoxFit.cover)
              : null,
        ),
        child: Stack(
          children: [
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
                child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Text(
                shop?['name'] ?? 'Boutique',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shopChip(Map<String, dynamic> shop) {
    return GestureDetector(
      onTap: () => context.push('/market/shop/${shop['id']}'),
      child: Container(
        width: 88,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: blueSoft),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: blueSoft,
              backgroundImage:
                  shop['logo_url'] != null ? CachedNetworkImageProvider(shop['logo_url']) : null,
              child: shop['logo_url'] == null ? const Icon(Icons.store_rounded, color: navy, size: 18) : null,
            ),
            const SizedBox(height: 6),
            Text(
              shop['name'] ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: textDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productCard(Map<String, dynamic> product) {
    final imageUrl = product['image_url'] ??
        (product['images'] != null && (product['images'] as List).isNotEmpty ? product['images'][0] : null);
    final currency = product['currency'] ?? 'FC';
    final hasDiscount =
        product['discount_price'] != null && product['discount_price'] < product['price'];
    final price = (hasDiscount ? product['discount_price'] : product['price']).toDouble();

    return GestureDetector(
      onTap: () => context.push('/market/product/${product['id']}'),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: blueSoft),
          boxShadow: [BoxShadow(color: navyDeep.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                color: blueSoft,
                                child: Icon(Icons.image_rounded, color: navy.withOpacity(0.3)),
                              ),
                            )
                          : Container(
                              color: blueSoft,
                              child: Icon(Icons.image_rounded, color: navy.withOpacity(0.3)),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: navyDeep.withOpacity(0.08), blurRadius: 6)],
                      ),
                      child: const Icon(Icons.bookmark_border_rounded, size: 14, color: navy),
                    ),
                  ),
                ],
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
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5, color: textDark),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        '${price.toInt()} $currency',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: navyDeep),
                      ),
                      if (hasDiscount)
                        Padding(
                          padding: const EdgeInsets.only(left: 5),
                          child: Text(
                            '${(product['price']).toInt()} $currency',
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              fontSize: 9,
                              color: textMuted,
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
  }
}
