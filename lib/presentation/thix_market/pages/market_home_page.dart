import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/market_colors.dart';
import '../providers/market_providers.dart';
import '../widgets/products/wishlist_button.dart';
import '../widgets/market/flash_sale_timer.dart';

class MarketHomePage extends ConsumerStatefulWidget {
  const MarketHomePage({super.key});
  @override ConsumerState<MarketHomePage> createState() => _MarketHomePageState();
}

class _MarketHomePageState extends ConsumerState<MarketHomePage> {
  final ScrollController _scroll = ScrollController();
  final PageController _bannerCtrl = PageController(viewportFraction: 0.94);
  Timer? _timer;
  int _currentBanner = 0;
  int _selectedNav = 0;

  @override void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 600) {
      ref.read(forYouProvider.notifier).loadMore();
    }
  }

  @override void dispose() {
    _scroll.dispose();
    _bannerCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startAuto(int count) {
    _timer?.cancel();
    if (count <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_bannerCtrl.hasClients) return;
      _currentBanner = (_currentBanner + 1) % count;
      _bannerCtrl.animateToPage(
        _currentBanner,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
      );
    });
  }

  String _shopName(Map<String, dynamic> p) {
    return (p['shop_name']?? 'Boutique THIX').toString();
  }

  double _price(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString()?? '')?? 0;
  }

  Widget _img(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        color: MarketColors.lightBg,
        child: const Icon(Icons.image_outlined, color: MarketColors.mutedText),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      cacheWidth: 500,
      errorBuilder: (_, __, ___) => Container(
        color: MarketColors.lightBg,
        child: const Icon(Icons.broken_image_outlined),
      ),
    );
  }

  @override Widget build(BuildContext context) {
    final bannersAsync = ref.watch(bannersProvider);
    final flashAsync = ref.watch(flashSalesProvider);
    final forYouAsync = ref.watch(forYouProvider);
    final all = ref.watch(allMarketProductsProvider);

    bannersAsync.whenData((b) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startAuto(b.length));
    });

    return Scaffold(
      backgroundColor: MarketColors.lightBg,
      body: RefreshIndicator(
        color: MarketColors.red,
        onRefresh: () async {
          ref.invalidate(bannersProvider);
          ref.invalidate(flashSalesProvider);
          await ref.read(forYouProvider.notifier).refresh();
        },
        child: CustomScrollView(
          controller: _scroll,
          slivers: [
            SliverToBoxAdapter(child: _topBar()),
            SliverToBoxAdapter(child: _bannerSection(bannersAsync)),
            SliverToBoxAdapter(child: _trust()),
            SliverToBoxAdapter(child: _search()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(child: _shops()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(child: _promoRow()),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(child: _b2b()),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(child: _flashSection(flashAsync)),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(child: _header()),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            _grid(forYouAsync, all),
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _topBar() {
    return Container(
      color: MarketColors.white,
      padding: const EdgeInsets.fromLTRB(16, 54, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: MarketColors.cardBorder),
                ),
                child: const Icon(Icons.shopping_bag_rounded, color: MarketColors.red),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('THIX MARKET', style: TextStyle(fontWeight: FontWeight.w900)),
                  Text('Achetez. Vendez. Évoluez.', style: TextStyle(fontSize: 11, color: MarketColors.mutedText)),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => context.push('/market/notifications'),
          ),
        ],
      ),
    );
  }

  Widget _bannerSection(AsyncValue<List<Map<String, dynamic>>> async) {
    return async.when(
      loading: () => const SizedBox(height: 230, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
      data: (banners) {
        if (banners.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 230,
          child: PageView.builder(
            controller: _bannerCtrl,
            itemCount: banners.length,
            onPageChanged: (i) => _currentBanner = i,
            itemBuilder: (_, i) {
              final b = banners[i];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(colors: [MarketColors.redDark, MarketColors.red]),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(b['title']?? 'Marketplace premium', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                    const SizedBox(height: 8),
                    Text(b['subtitle']?? 'Vendeurs vérifiés', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _trust() {
    return Container(
      color: MarketColors.white,
      padding: const EdgeInsets.all(12),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text('Paiement sécurisé', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
          Text('Vendeurs vérifiés', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
          Text('Livraison fiable', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _search() {
    return Container(
      color: MarketColors.white,
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: () => context.push('/market/search'),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: MarketColors.cardBorder),
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: MarketColors.red, size: 20),
              SizedBox(width: 10),
              Text('Rechercher...', style: TextStyle(color: MarketColors.mutedText, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shops() {
    final shopsAsync = ref.watch(featuredShopsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Supermarchés', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              GestureDetector(
                onTap: () => context.push('/market/shops'),
                child: const Text('Tout voir', style: TextStyle(color: MarketColors.red, fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          shopsAsync.when(
            loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SizedBox.shrink(),
            data: (shops) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: shops.take(4).map((s) {
                return GestureDetector(
                  onTap: () => context.push('/market/shop/${s['id']}'),
                  child: Column(
                    children: [
                      Container(
                        height: 64,
                        width: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: MarketColors.red,
                          image: s['logo_url']!= null? DecorationImage(image: NetworkImage(s['logo_url']), fit: BoxFit.cover) : null,
                        ),
                        child: s['logo_url'] == null? const Icon(Icons.store, color: Colors.white) : null,
                      ),
                      const SizedBox(height: 8),
                      Text((s['name']?? 'Shop').toString(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _promoRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/market/flash-sales'),
              child: Container(
                height: 140,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [MarketColors.redDark, MarketColors.red]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('OFFRES', style: TextStyle(color: MarketColors.gold, fontSize: 10, fontWeight: FontWeight.w800)),
                    Text('Jusqu\'à -50%', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/market/vendor/dashboard'),
              child: Container(
                height: 140,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: MarketColors.creamBg, borderRadius: BorderRadius.circular(20)),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('VENDEZ', style: TextStyle(color: Color(0xFFC9862B), fontSize: 10, fontWeight: FontWeight.w800)),
                    Text('Votre business', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _b2b() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: MarketColors.white, borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _b2bItem(Icons.compare_arrows, 'Comparer', '/market/compare'),
            _b2bItem(Icons.notifications_active, 'Alerte', '/market/price-alerts'),
            _b2bItem(Icons.favorite, 'Wishlist', '/market/wishlist'),
          ],
        ),
      ),
    );
  }

  Widget _b2bItem(IconData icon, String label, String path) {
    return InkWell(
      onTap: () => context.push(path),
      child: Column(
        children: [
          Icon(icon, color: MarketColors.red, size: 22),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _flashSection(AsyncValue<List<Map<String, dynamic>>> async) {
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: MarketColors.gold),
                  const SizedBox(width: 6),
                  const Text('Offres flash', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const Spacer(),
                  FlashSaleTimer(endTime: DateTime.now().add(const Duration(hours: 2))),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 245,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => SizedBox(width: 155, child: _card(list[i])),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _header() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Text('Tous les produits', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
    );
  }

  Widget _grid(AsyncValue<List<Map<String, dynamic>>> forYouAsync, List<Map<String, dynamic>> all) {
    return forYouAsync.when(
      loading: () => const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(60), child: Center(child: CircularProgressIndicator()))),
      error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('Erreur $e'))),
      data: (_) => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.62),
          delegate: SliverChildBuilderDelegate(
            (_, i) {
              if (i >= all.length) return const Center(child: CircularProgressIndicator());
              return _card(all[i]);
            },
            childCount: all.length + (ref.read(forYouProvider.notifier).hasMore? 1 : 0),
          ),
        ),
      ),
    );
  }

  Widget _card(Map<String, dynamic> p) {
    final price = _price(p['discount_price']?? p['price']);
    final img = (p['image_url']?? (p['images'] is List && (p['images'] as List).isNotEmpty? (p['images'] as List).first : null)) as String?;
    return GestureDetector(
      onTap: () => context.push('/market/product/${p['id']}'),
      child: Container(
        decoration: BoxDecoration(color: MarketColors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: MarketColors.cardBorder)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(18)), child: _img(img)),
                  Positioned(top: 6, right: 6, child: Container(decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: WishlistButton(productId: p['id'].toString(), size: 20))),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['title']?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text('${price.toInt()} FC', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: MarketColors.red)),
                    Text(_shopName(p), maxLines: 1, style: const TextStyle(fontSize: 10, color: MarketColors.mutedText)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomNav() {
    return Container(
      color: MarketColors.white,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _navItem(Icons.home_rounded, 'Accueil', 0),
                  _navItem(Icons.receipt_long_rounded, 'Commandes', 1),
                  const SizedBox(width: 60),
                  _navItem(Icons.favorite_rounded, 'Wishlist', 3),
                  _navItem(Icons.notifications_active_rounded, 'Alertes', 4),
                ],
              ),
              Positioned(
                top: -20,
                child: GestureDetector(
                  onTap: () => context.push('/market/cart'),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: MarketColors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 26),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final sel = _selectedNav == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedNav = index);
        if (index == 0) {
          _scroll.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
        }
        if (index == 1) context.push('/market/orders');
        if (index == 3) context.push('/market/wishlist');
        if (index == 4) context.push('/market/price-alerts');
      },
      child: Container(
        width: 65,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: sel? MarketColors.red : MarketColors.mutedText, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 10,
                color: sel? MarketColors.red : MarketColors.mutedText,
                fontWeight: sel? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
