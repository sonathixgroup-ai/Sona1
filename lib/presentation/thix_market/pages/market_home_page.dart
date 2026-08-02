// lib/presentation/thix_market/pages/market_home_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/market_colors.dart';
import '../l10n/market_strings.dart';
import '../providers/market_providers.dart';
import '../widgets/products/product_card.dart';
import '../widgets/market/flash_sale_timer.dart';

class MarketHomePage extends ConsumerStatefulWidget {
  const MarketHomePage({super.key});
  @override
  ConsumerState<MarketHomePage> createState() => _MarketHomePageState();
}

class _MarketHomePageState extends ConsumerState<MarketHomePage> {
  final ScrollController _scroll = ScrollController();
  final PageController _bannerCtrl = PageController(viewportFraction: 0.94);
  Timer? _bannerTimer;
  bool _bannerReady = false;
  int _currentBanner = 0;
  int _selectedNav = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 700) {
      ref.read(forYouProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _bannerCtrl.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  void _safeNavigate(String name, String path) {
    try {
      context.pushNamed(name);
    } catch (_) {
      try {
        context.push(path);
      } catch (_) {}
    }
  }

  // --------------------------------------------------------
  // HERO BANNER — produits marqués "Hero Banner" (is_featured)
  // dans le formulaire de publication. Auto-scroll toutes les 4s.
  // --------------------------------------------------------
  void _startBannerAuto(int count) {
    if (_bannerReady) return;
    if (count <= 1) return;
    _bannerReady = true;
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_bannerCtrl.hasClients) return;
      _currentBanner = (_currentBanner + 1) % count;
      _bannerCtrl.animateToPage(_currentBanner, duration: const Duration(milliseconds: 700), curve: Curves.easeOutCubic);
      if (mounted) setState(() {});
    });
  }

  String? _bannerTargetId(Map<String, dynamic>? b) {
    if (b == null) return null;
    final candidates = [b['product_id'], b['target_product_id'], b['id']];
    for (final c in candidates) {
      if (c != null && c.toString().trim().isNotEmpty) return c.toString();
    }
    return null;
  }

  String? _extractImage(Map<String, dynamic>? data) {
    if (data == null) return null;
    if (data['image_url'] != null && data['image_url'].toString().isNotEmpty) return data['image_url'].toString();
    if (data['banner_url'] != null && data['banner_url'].toString().isNotEmpty) return data['banner_url'].toString();
    if (data['images'] is List && (data['images'] as List).isNotEmpty) return (data['images'] as List).first.toString();
    return null;
  }

  String _greetingName(MarketStrings t) {
    final user = Supabase.instance.client.auth.currentUser;
    final full = user?.userMetadata?['full_name'] ?? user?.userMetadata?['name'];
    if (full != null && (full as String).trim().isNotEmpty) return full.trim().split(' ').first;
    final email = user?.email;
    if (email != null && email.contains('@')) return email.split('@').first;
    return t.client;
  }

  void _showComing(String feature) {
    final t = context.mkt;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.comingSoon(feature)), backgroundColor: MarketColors.gold));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.mkt;
    final bannersAsync = ref.watch(bannersProvider); // produits is_featured == true
    final flashAsync = ref.watch(flashSalesProvider);
    final forYouAsync = ref.watch(forYouProvider);
    final all = ref.watch(allMarketProductsProvider);
    final hasMore = ref.read(forYouProvider.notifier).hasMore;

    bannersAsync.whenData((b) => WidgetsBinding.instance.addPostFrameCallback((_) => _startBannerAuto(b.length)));

    return Scaffold(
      backgroundColor: MarketColors.lightBg,
      body: RefreshIndicator(
        color: MarketColors.red,
        onRefresh: () async {
          ref.invalidate(bannersProvider);
          ref.invalidate(flashSalesProvider);
          ref.invalidate(featuredShopsProvider);
          await ref.read(forYouProvider.notifier).refresh();
        },
        child: CustomScrollView(
          controller: _scroll,
          slivers: [
            SliverToBoxAdapter(child: _buildTopBar(t)),
            SliverToBoxAdapter(child: _buildHero(bannersAsync, t)),
            const SliverToBoxAdapter(child: SizedBox(height: 6)),
            SliverToBoxAdapter(child: _buildFeaturedStrip(bannersAsync, t)),
            const SliverToBoxAdapter(child: SizedBox(height: 18)),
            SliverToBoxAdapter(child: _buildTrustBadges(t)),
            SliverToBoxAdapter(child: _buildSearchBar(t)),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(child: _buildSupermarketSection(t)),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(child: _buildPromoBannersRow(t)),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(child: _buildB2BTools(t)),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(child: _buildFlashTicker(flashAsync, t)),
            SliverToBoxAdapter(child: _buildFlashSaleSection(flashAsync, t)),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(child: _buildSectionHeader(t.allProducts, () {})),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            _buildGrid(forYouAsync, all, hasMore, t),
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(t),
    );
  }

  Widget _buildTopBar(MarketStrings t) {
    return Container(
      color: MarketColors.white,
      padding: const EdgeInsets.fromLTRB(16, 54, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.white, Color(0xFFFFF6F6)]),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: MarketColors.cardBorder),
                ),
                child: const Icon(Icons.shopping_bag_rounded, color: MarketColors.red, size: 22)),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              RichText(
                  text: const TextSpan(children: [
                TextSpan(text: 'THIX ', style: TextStyle(color: MarketColors.red, fontWeight: FontWeight.w900, fontSize: 19)),
                TextSpan(text: 'MARKET', style: TextStyle(color: MarketColors.gold, fontWeight: FontWeight.w900, fontSize: 19)),
              ])),
              Text(t.appTagline, style: const TextStyle(color: MarketColors.mutedText, fontSize: 11.5)),
            ]),
          ]),
          Row(children: [
            InkWell(
                onTap: () => context.push('/market/notifications'),
                child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: MarketColors.cardBorder)),
                    child: const Icon(Icons.notifications_none_rounded, size: 20))),
            const SizedBox(width: 10),
            InkWell(
                onTap: () => context.push('/user/dashboard'),
                child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [MarketColors.red, MarketColors.redDark]), shape: BoxShape.circle),
                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 20))),
          ]),
        ],
      ),
    );
  }

  Widget _buildHero(AsyncValue<List<Map<String, dynamic>>> async, MarketStrings t) {
    return async.when(
      loading: () => const SizedBox(height: 230, child: Center(child: CircularProgressIndicator(color: MarketColors.red))),
      error: (_, __) => _buildHeroContent([null], t),
      data: (b) => _buildHeroContent(b, t),
    );
  }

  Widget _buildHeroContent(List<dynamic> banners, MarketStrings t) {
    final slides = banners.isEmpty ? [null] : banners;
    return Column(children: [
      SizedBox(
        height: 230,
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n is ScrollStartNotification) {
              _bannerTimer?.cancel();
              _bannerReady = false;
            } else if (n is ScrollEndNotification) {
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) _startBannerAuto(slides.length);
              });
            }
            return false;
          },
          child: PageView.builder(
            controller: _bannerCtrl,
            itemCount: slides.length,
            onPageChanged: (i) => setState(() => _currentBanner = i),
            itemBuilder: (_, index) {
              final b = slides[index] as Map<String, dynamic>?;
              final imageUrl = _extractImage(b);
              final title = b?['title'] ?? t.defaultHeroTitle;
              final subtitle = b?['description'] ?? b?['subtitle'] ?? t.defaultHeroSubtitle;
              final targetId = _bannerTargetId(b);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () {
                    if (targetId != null && targetId.isNotEmpty) {
                      context.push('/market/product/$targetId');
                    } else {
                      context.push('/market/flash-sales');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(22, 22, 16, 22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [MarketColors.redDark, MarketColors.red],
                      ),
                      image: imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(imageUrl),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.55), BlendMode.darken),
                            )
                          : null,
                      boxShadow: [BoxShadow(color: MarketColors.red.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Stack(children: [
                      if (imageUrl == null)
                        const Positioned(
                            right: -10,
                            bottom: -10,
                            child: Opacity(opacity: 0.18, child: Icon(Icons.shopping_cart_rounded, size: 140, color: Colors.white))),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (index == 0 && imageUrl == null)
                            Text('${t.greeting}, ${_greetingName(t)} 👋', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1.2)),
                          const SizedBox(height: 8),
                          SizedBox(width: 210, child: Text(subtitle, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [MarketColors.gold, Color(0xFFC9862B)]),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(targetId != null ? Icons.visibility_rounded : Icons.search_rounded, size: 16, color: MarketColors.redDark),
                              const SizedBox(width: 8),
                              Text(targetId != null ? t.viewOffer : t.exploreMarket, style: const TextStyle(color: MarketColors.redDark, fontWeight: FontWeight.w800, fontSize: 12.5)),
                            ]),
                          ),
                        ],
                      ),
                    ]),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      const SizedBox(height: 10),
      Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(slides.length, (i) {
            final a = i == _currentBanner;
            return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 6,
                width: a ? 18 : 6,
                decoration: BoxDecoration(color: a ? MarketColors.red : Colors.grey.shade300, borderRadius: BorderRadius.circular(10)));
          })),
    ]);
  }

  // --------------------------------------------------------
  // BANDE "PRODUITS EN VEDETTE" — les mêmes produits que le
  // hero banner (is_featured), affichés en auto-scroll continu.
  // --------------------------------------------------------
  Widget _buildFeaturedStrip(AsyncValue<List<Map<String, dynamic>>> async, MarketStrings t) {
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) {
        final products = list.whereType<Map<String, dynamic>>().toList();
        if (products.isEmpty) return const SizedBox.shrink();
        return _AutoScrollProductStrip(products: products, badgeType: _StripBadge.featured, title: t.featuredProducts, icon: Icons.star_rounded);
      },
    );
  }

  Widget _buildTrustBadges(MarketStrings t) {
    return Container(
      color: MarketColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _trustItem(Icons.lock_outline_rounded, t.securePayment),
          _trustItem(Icons.verified_user_outlined, t.verifiedSellers),
          _trustItem(Icons.local_shipping_outlined, t.reliableDelivery),
          _trustItem(Icons.headset_mic_outlined, t.support247),
        ],
      ),
    );
  }

  Widget _trustItem(IconData icon, String label) {
    return Row(children: [
      Icon(icon, size: 15, color: MarketColors.red),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _buildSearchBar(MarketStrings t) {
    return Container(
      color: MarketColors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Row(children: [
        Expanded(
            child: GestureDetector(
                onTap: () => context.push('/market/search'),
                child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: MarketColors.cardBorder, width: 1.4)),
                    child: Row(children: [
                      const Icon(Icons.search_rounded, size: 20, color: MarketColors.red),
                      const SizedBox(width: 10),
                      Expanded(child: Text(t.searchHint, style: const TextStyle(fontSize: 12.5, color: MarketColors.mutedText))),
                    ])))),
        const SizedBox(width: 10),
        InkWell(
            onTap: () => context.push('/market/search'),
            child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [MarketColors.red, MarketColors.redDark]),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(child: Text(t.search, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5))))),
      ]),
    );
  }

  Widget _buildSupermarketSection(MarketStrings t) {
    final shopsAsync = ref.watch(featuredShopsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(t.homeSupermarkets, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          GestureDetector(onTap: () => _safeNavigate('marketShops', '/market/shops'), child: Text(t.seeAll, style: const TextStyle(color: MarketColors.red, fontSize: 12, fontWeight: FontWeight.w800))),
        ]),
        const SizedBox(height: 16),
        shopsAsync.when(
          loading: () => const SizedBox(height: 64, child: Center(child: CircularProgressIndicator(color: MarketColors.red))),
          error: (_, __) => const SizedBox.shrink(),
          data: (shops) {
            if (shops.isEmpty) return Text(t.noSupermarket, style: const TextStyle(color: MarketColors.mutedText, fontSize: 12));
            return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: shops.take(4).map((s) {
                  return GestureDetector(
                      onTap: () => context.push('/market/shop/${s['id']}'),
                      child: Column(children: [
                        Container(
                            height: 64,
                            width: 64,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(colors: [MarketColors.red, MarketColors.redDark]),
                                image: s['logo_url'] != null ? DecorationImage(image: NetworkImage(s['logo_url']), fit: BoxFit.cover) : null),
                            child: s['logo_url'] == null ? const Icon(Icons.storefront_rounded, color: Colors.white, size: 28) : null),
                        const SizedBox(height: 8),
                        Text((s['name'] ?? 'Shop').toString(), style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                      ]));
                }).toList());
          },
        ),
      ]),
    );
  }

  Widget _buildPromoBannersRow(MarketStrings t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Expanded(
            child: GestureDetector(
                onTap: () => _safeNavigate('marketFlashSales', '/market/flash-sales'),
                child: Container(
                    height: 150,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [MarketColors.redDark, MarketColors.red]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: MarketColors.red.withOpacity(0.2), blurRadius: 14, offset: const Offset(0, 8))]),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(t.exclusiveOffers, style: const TextStyle(color: MarketColors.gold, fontWeight: FontWeight.w800, fontSize: 10)),
                      const SizedBox(height: 6),
                      Text(t.upTo50, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 19)),
                      Text(t.onPremiumSelection, style: const TextStyle(color: Colors.white70, fontSize: 10.5)),
                      const Spacer(),
                      Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(gradient: const LinearGradient(colors: [MarketColors.gold, Color(0xFFC9862B)]), borderRadius: BorderRadius.circular(10)),
                          child: Text(t.discover, style: const TextStyle(color: MarketColors.redDark, fontWeight: FontWeight.w800, fontSize: 11))),
                    ])))),
        const SizedBox(width: 12),
        Expanded(
            child: GestureDetector(
                onTap: () => _safeNavigate('vendorDashboard', '/market/vendor/dashboard'),
                child: Container(
                    height: 150,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [MarketColors.creamBg, Colors.white]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 8))]),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(t.sellWithThix, style: const TextStyle(color: Color(0xFFC9862B), fontWeight: FontWeight.w800, fontSize: 10)),
                      const SizedBox(height: 6),
                      Text(t.growBusiness, style: const TextStyle(color: MarketColors.darkText, fontWeight: FontWeight.w900, fontSize: 15, height: 1.15)),
                      const Spacer(),
                      Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(gradient: const LinearGradient(colors: [MarketColors.gold, Color(0xFFC9862B)]), borderRadius: BorderRadius.circular(10)),
                          child: Text(t.start, style: const TextStyle(color: MarketColors.redDark, fontWeight: FontWeight.w800, fontSize: 11))),
                    ])))),
      ]),
    );
  }

  Widget _buildB2BTools(MarketStrings t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: MarketColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _b2bItem(Icons.compare_arrows_rounded, t.compare, () => _safeNavigate('marketProductComparator', '/market/compare')),
            _b2bItem(Icons.notifications_active_rounded, t.priceAlert, () => _safeNavigate('marketPriceAlerts', '/market/price-alerts')),
            _b2bItem(Icons.request_quote_rounded, t.b2bQuote, () => _showComing(t.b2bQuote)),
            _b2bItem(Icons.favorite_rounded, t.wishlist, () => _safeNavigate('marketWishlist', '/market/wishlist')),
          ],
        ),
      ),
    );
  }

  Widget _b2bItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(children: [Icon(icon, color: MarketColors.red, size: 24), const SizedBox(height: 6), Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800))])));
  }

  Widget _buildFlashTicker(AsyncValue<List<Map<String, dynamic>>> async, MarketStrings t) {
    return async.maybeWhen(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        DateTime? timerEnd;
        for (final p in list) {
          if (p['expires_at'] != null) {
            final dt = DateTime.tryParse(p['expires_at'].toString());
            if (dt != null && dt.isAfter(DateTime.now())) {
              if (timerEnd == null || dt.isBefore(timerEnd)) timerEnd = dt;
            }
          }
        }
        timerEnd ??= DateTime.now().add(const Duration(hours: 2, minutes: 45));

        return Container(
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [MarketColors.redDark, MarketColors.red])),
          padding: const EdgeInsets.symmetric(vertical: 8),
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: FlashSaleTimer(endTime: timerEnd),
                ),
              ),
              Expanded(child: ClipRect(child: _MarqueeText(text: t.flashSaleBannerText))),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildFlashSaleSection(AsyncValue<List<Map<String, dynamic>>> async, MarketStrings t) {
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return _AutoScrollProductStrip(products: list, badgeType: _StripBadge.flash, title: t.flashOffers, icon: Icons.bolt_rounded, liveLabel: t.live);
      },
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onTap) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        ]));
  }

  Widget _buildGrid(AsyncValue<List<Map<String, dynamic>>> forYouAsync, List<Map<String, dynamic>> all, bool hasMore, MarketStrings t) {
    return forYouAsync.when(
      loading: () => const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(60), child: Center(child: CircularProgressIndicator(color: MarketColors.red)))),
      error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('${t.error}: $e'))),
      data: (_) => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.62),
          delegate: SliverChildBuilderDelegate((_, i) {
            if (i >= all.length) return const Center(child: CircularProgressIndicator(color: MarketColors.red));
            return ProductCard(product: all[i]);
          }, childCount: all.length + (hasMore ? 1 : 0)),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(MarketStrings t) {
    return Container(
      color: MarketColors.white,
      padding: const EdgeInsets.only(top: 6),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _navItem(Icons.home_rounded, t.home, 0),
                _navItem(Icons.receipt_long_rounded, t.orders, 1),
                const SizedBox(width: 60),
                _navItem(Icons.favorite_rounded, t.wishlist, 3),
                _navItem(Icons.notifications_active_rounded, t.alerts, 4),
              ]),
              Positioned(
                  top: -20,
                  child: GestureDetector(
                      onTap: () => context.push('/market/cart'),
                      child: Container(
                          width: 60,
                          height: 60,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [MarketColors.red, MarketColors.redDark]),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [BoxShadow(color: MarketColors.red.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 6))]),
                          child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 26)))),
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
        HapticFeedback.lightImpact();
        setState(() => _selectedNav = index);
        if (index == 0) _scroll.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
        if (index == 1) context.push('/market/orders');
        if (index == 3) context.push('/market/wishlist');
        if (index == 4) context.push('/market/price-alerts');
      },
      child: Container(
          width: 65,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: sel ? MarketColors.red : MarketColors.mutedText, size: 24),
            const SizedBox(height: 2),
            Text(label, maxLines: 1, style: TextStyle(fontSize: 10, color: sel ? MarketColors.red : MarketColors.mutedText, fontWeight: sel ? FontWeight.w800 : FontWeight.w500)),
          ])),
    );
  }
}

enum _StripBadge { flash, featured, none }

/// Bande horizontale à défilement continu, réutilisée pour "Offres flash"
/// et "Produits en vedette". Gère son propre Timer/ScrollController et
/// se met en pause automatiquement au toucher.
class _AutoScrollProductStrip extends StatefulWidget {
  final List<Map<String, dynamic>> products;
  final _StripBadge badgeType;
  final String title;
  final IconData icon;
  final String? liveLabel;

  const _AutoScrollProductStrip({
    required this.products,
    required this.badgeType,
    required this.title,
    required this.icon,
    this.liveLabel,
  });

  @override
  State<_AutoScrollProductStrip> createState() => _AutoScrollProductStripState();
}

class _AutoScrollProductStripState extends State<_AutoScrollProductStrip> {
  final ScrollController _ctrl = ScrollController();
  Timer? _timer;
  bool _paused = false;
  static const double _step = 1.1;
  static const Duration _tick = Duration(milliseconds: 16);

  bool get _active => widget.products.length > 4;

  @override
  void initState() {
    super.initState();
    if (_active) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _start());
    }
  }

  void _start() {
    _timer = Timer.periodic(_tick, (_) {
      if (!_ctrl.hasClients || _paused) return;
      final maxExt = _ctrl.position.maxScrollExtent;
      final next = _ctrl.offset + _step;
      _ctrl.jumpTo(next >= maxExt ? 0 : next);
    });
  }

  void _pause() => _paused = true;
  void _resumeAfterDelay() => Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _paused = false;
      });

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Icon(widget.icon, color: MarketColors.gold, size: 22),
          const SizedBox(width: 6),
          Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          if (_active && widget.liveLabel != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: MarketColors.gold.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: Text(widget.liveLabel!, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: MarketColors.gold)),
            ),
          ],
        ]),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 245,
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (!_active) return false;
            if (n is ScrollStartNotification) {
              _pause();
            } else if (n is ScrollEndNotification) {
              _resumeAfterDelay();
            }
            return false;
          },
          child: ListView.separated(
            controller: _ctrl,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => ProductCard(
              product: widget.products[i],
              variant: ProductCardVariant.horizontal,
              isFlashSale: widget.badgeType == _StripBadge.flash,
              isFeatured: widget.badgeType == _StripBadge.featured,
            ),
          ),
        ),
      ),
    ]);
  }
}

class _MarqueeText extends StatefulWidget {
  final String text;
  const _MarqueeText({required this.text});
  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText> {
  late final ScrollController _ctrl;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ctrl = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  void _start() {
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!_ctrl.hasClients) return;
      final maxScroll = _ctrl.position.maxScrollExtent;
      final current = _ctrl.offset;
      _ctrl.jumpTo(current >= maxScroll ? 0 : current + 2.0);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: ListView.builder(
        controller: _ctrl,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(widget.text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
        ),
      ),
    );
  }
}
