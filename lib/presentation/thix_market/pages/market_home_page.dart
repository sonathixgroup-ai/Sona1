// lib/presentation/thix_market/pages/market_home_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/market_provider.dart';
import '../providers/shop_provider.dart';
import '../widgets/market/flash_sale_timer.dart';
import '../widgets/products/wishlist_button.dart'; 

// ============================================================
// CHARTE GRAPHIQUE THIX MARKET — ROUGE & OR 
// ============================================================
class _MarketColors {
  static const Color redDark = Color(0xFF5C0E12);
  static const Color red = Color(0xFFD81E2C);
  static const Color redSoft = Color(0xFFE63946);
  static const Color gold = Color(0xFFF0A93B);
  static const Color goldSoft = Color(0xFFFCE7C4);
  static const Color creamBg = Color(0xFFFCEFDA);
  static const Color lightBg = Color(0xFFF7F7FA);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF1A1A1A);
  static const Color mutedText = Color(0xFF8A8A8F);
  static const Color cardBorder = Color(0xFFF0F0F0);
  static const Color successGreen = Color(0xFF00B074);
}

class MarketHomePage extends StatefulWidget {
  const MarketHomePage({super.key});

  @override
  State<MarketHomePage> createState() => _MarketHomePageState();
}

class _MarketHomePageState extends State<MarketHomePage> {
  final ScrollController _scrollController = ScrollController();
  final PageController _bannerController = PageController(viewportFraction: 0.94);
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

  // ============================================================
  // NAVIGATION SÉCURISÉE
  // ============================================================
  void _goToVendor() => context.pushNamed('vendorDashboard');
  void _goToCart() => context.pushNamed('marketCart');
  void _goToWishlist() => context.pushNamed('marketWishlist');
  void _goToOrders() => context.pushNamed('marketOrders'); // Ouvre l'historique des commandes
  void _goToPriceAlerts() => context.pushNamed('marketPriceAlerts');
  void _goToActivity() => context.pushNamed('marketActivity');
  void _goToPriceComparator() => context.pushNamed('marketProductComparator');
  void _goToSearch() => context.pushNamed('marketSearch');
  void _goToUserDashboard() => context.push('/user/dashboard'); 

  void _onNavTap(int index) {
    setState(() => _selectedNavIndex = index);
    HapticFeedback.lightImpact();
    switch (index) {
      case 0: // Accueil
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
        break;
      case 1: // Commandes (A gauche, remplace Activité)
        _goToOrders();
        break;
      case 2: // Panier
        _goToCart();
        break;
      case 3: // Wishlist (A droite)
        _goToWishlist();
        break;
      case 4: // Alertes Prix
        _goToPriceAlerts();
        break;
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================
  Widget _networkImage(String? url, {BoxFit fit = BoxFit.cover}) {
    if (url == null || url.trim().isEmpty) {
      return Container(
        color: _MarketColors.lightBg,
        alignment: Alignment.center,
        child: const Icon(Icons.image_outlined, color: _MarketColors.mutedText),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (_, __) => Container(
        color: _MarketColors.lightBg,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _MarketColors.red)),
      ),
      errorWidget: (_, __, ___) => Container(
        color: _MarketColors.lightBg,
        child: const Icon(Icons.image_not_supported_outlined, color: _MarketColors.mutedText),
      ),
    );
  }

  void _startBannerAutoplay(int count) {
    if (count <= 1) return;
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_bannerController.hasClients) {
        final nextPage = (_currentBannerIndex + 1) % count;
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

  String _shopName(Map<String, dynamic> product) {
    return (product['shop_name'] ??
            product['shops']?['name'] ??
            product['shop']?['name'] ??
            'Boutique THIX') as String;
  }

  String _location(Map<String, dynamic> product) {
    return (product['location'] ??
            product['city'] ??
            product['ville'] ??
            product['shops']?['city'] ??
            'RDC') as String;
  }

  String _greetingName(MarketProvider marketProvider) {
    final user = Supabase.instance.client.auth.currentUser;
    final fullName = user?.userMetadata?['full_name'] ?? user?.userMetadata?['name'];
    if (fullName != null && (fullName as String).trim().isNotEmpty) {
      return fullName.trim().split(' ').first;
    }
    final email = user?.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }
    return 'Client';
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
      if (banners.isNotEmpty && _bannerTimer == null) _startBannerAutoplay(banners.length);
    });

    return Scaffold(
      backgroundColor: _MarketColors.lightBg,
      body: RefreshIndicator(
        color: _MarketColors.red,
        onRefresh: () => marketProvider.refresh(),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(child: _buildTopBar()),
            SliverToBoxAdapter(child: _buildHeroBannerCarousel(banners, marketProvider)),
            SliverToBoxAdapter(child: _buildTrustBadges()),
            SliverToBoxAdapter(child: _buildSearchBar()),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            
            // LA SECTION SUPERMARCHÉS (BANDE NOIRE + 4 LOGOS)
            SliverToBoxAdapter(child: _buildSupermarketSection()),
            
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(child: _buildPromoBannersRow()),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(child: _buildB2BTools()),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            
            if (marketProvider.flashSales.isNotEmpty) ...[
              SliverToBoxAdapter(child: _buildFlashSaleSection(marketProvider.flashSales)),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
            if (allProducts.isNotEmpty)
              SliverToBoxAdapter(child: _buildSectionHeader('Tous les produits', () {})),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            if (allProducts.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.62,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildProductCard(allProducts[index]),
                    childCount: allProducts.length,
                  ),
                ),
              )
            else
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: Text('Aucun produit disponible pour le moment',
                        style: TextStyle(color: _MarketColors.mutedText, fontSize: 13)),
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
  // TOP BAR
  // ============================================================
  Widget _buildTopBar() {
    return Container(
      color: _MarketColors.pureWhite,
      padding: const EdgeInsets.fromLTRB(16, 54, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _MarketColors.pureWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _MarketColors.cardBorder),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: const Icon(Icons.shopping_bag_rounded, color: _MarketColors.red, size: 22),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(text: 'THIX ', style: TextStyle(color: _MarketColors.red, fontWeight: FontWeight.w900, fontSize: 19)),
                        TextSpan(text: 'MARKET', style: TextStyle(color: _MarketColors.gold, fontWeight: FontWeight.w900, fontSize: 19)),
                      ],
                    ),
                  ),
                  const Text('Achetez. Vendez. Évoluez.',
                      style: TextStyle(color: _MarketColors.mutedText, fontSize: 11.5, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
          Row(
            children: [
              _headerIconButton(Icons.notifications_none_rounded, () => context.push('/market/notifications'), outline: true),
              const SizedBox(width: 10),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _goToUserDashboard,
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: _MarketColors.red, shape: BoxShape.circle),
                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerIconButton(IconData icon, VoidCallback onTap, {bool outline = false}) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _MarketColors.pureWhite,
          shape: BoxShape.circle,
          border: Border.all(color: _MarketColors.cardBorder, width: 1.4),
        ),
        child: Icon(icon, color: _MarketColors.darkText, size: 20),
      ),
    );
  }

  // ============================================================
  // HERO BANNER
  // ============================================================
  Widget _buildHeroBannerCarousel(List<dynamic> banners, MarketProvider marketProvider) {
    final slides = banners.isNotEmpty ? banners : const [null];

    return Column(
      children: [
        SizedBox(
          height: 230,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: slides.length,
            onPageChanged: (i) => setState(() => _currentBannerIndex = i),
            itemBuilder: (context, index) {
              final banner = slides[index];
              final isFirst = index == 0;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () => banner != null ? context.push('/market/flash-sales') : _goToSearch(),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(22, 22, 16, 22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_MarketColors.redDark, _MarketColors.red],
                      ),
                      boxShadow: [BoxShadow(color: _MarketColors.red.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 10))],
                      image: banner != null && banner['image_url'] != null
                          ? DecorationImage(
                              image: NetworkImage(banner['image_url']),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.25), BlendMode.darken),
                            )
                          : null,
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -10,
                          bottom: -10,
                          child: Opacity(
                            opacity: 0.18,
                            child: Icon(Icons.shopping_cart_rounded, size: 140, color: Colors.white),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isFirst)
                              Text('Bonjour, ${_greetingName(marketProvider)} 👋',
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, height: 1.2, color: Colors.white),
                                children: [
                                  TextSpan(text: banner?['title'] ?? 'Votre marketplace\n'),
                                  TextSpan(text: banner != null ? '' : 'premium', style: const TextStyle(color: _MarketColors.gold)),
                                  if (banner == null) const TextSpan(text: ' et sécurisée'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 210,
                              child: Text(
                                banner?['subtitle'] ?? 'Des milliers de produits, des vendeurs vérifiés, une expérience unique.',
                                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500, height: 1.3),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              decoration: BoxDecoration(color: _MarketColors.gold, borderRadius: BorderRadius.circular(14)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.search_rounded, size: 16, color: _MarketColors.redDark),
                                  SizedBox(width: 8),
                                  Text('Explorer le marché', style: TextStyle(color: _MarketColors.redDark, fontWeight: FontWeight.w800, fontSize: 12.5)),
                                  SizedBox(width: 6),
                                  Icon(Icons.arrow_forward_rounded, size: 14, color: _MarketColors.redDark),
                                ],
                              ),
                            ),
                          ],
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
          children: List.generate(slides.length, (i) {
            final active = i == _currentBannerIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 6,
              width: active ? 18 : 6,
              decoration: BoxDecoration(
                color: active ? _MarketColors.red : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTrustBadges() {
    final badges = [
      {'icon': Icons.lock_outline_rounded, 'label': 'Paiement sécurisé'},
      {'icon': Icons.verified_user_outlined, 'label': 'Vendeurs vérifiés'},
      {'icon': Icons.local_shipping_outlined, 'label': 'Livraison fiable'},
      {'icon': Icons.headset_mic_outlined, 'label': 'Support 24/7'},
    ];
    return Container(
      color: _MarketColors.pureWhite,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: badges.map((b) {
          return Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(b['icon'] as IconData, size: 15, color: _MarketColors.red),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(b['label'] as String,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: _MarketColors.darkText)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: _MarketColors.pureWhite,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _goToSearch,
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _MarketColors.pureWhite,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _MarketColors.cardBorder, width: 1.4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search_rounded, size: 20, color: _MarketColors.red),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text('Rechercher un produit, une marque...',
                          style: TextStyle(fontSize: 12.5, color: _MarketColors.mutedText, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: _goToSearch,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: _MarketColors.red, borderRadius: BorderRadius.circular(24)),
              child: const Text('Rechercher', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5)),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION SUPERMARCHÉS : BANDE NOIRE + 4 LOGOS FICTIFS
  // ============================================================
  Widget _buildSupermarketSection() {
    final mockSupermarkets = [
      {'name': 'Kin Marché', 'color': Colors.red.shade50, 'icon': Icons.shopping_basket_rounded, 'iconColor': Colors.red},
      {'name': 'Super U', 'color': Colors.blue.shade50, 'icon': Icons.storefront_rounded, 'iconColor': Colors.blue},
      {'name': 'Shoprite', 'color': Colors.green.shade50, 'icon': Icons.local_mall_rounded, 'iconColor': Colors.green},
      {'name': 'Carrefour', 'color': Colors.orange.shade50, 'icon': Icons.shopping_cart_rounded, 'iconColor': Colors.orange},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // La bande noire
          GestureDetector(
            onTap: () => context.pushNamed('marketShops'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _MarketColors.darkText,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _MarketColors.pureWhite.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.shopping_cart_checkout_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Supermarchés', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                        const SizedBox(height: 4),
                        const Text('Faites vos courses au supermarché à domicile.', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Les 4 logos fictifs en dessous
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: mockSupermarkets.map((store) {
              return Expanded(
                child: GestureDetector(
                  onTap: () => context.pushNamed('marketShops'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Column(
                      children: [
                        Container(
                          height: 54,
                          decoration: BoxDecoration(
                            color: store['color'] as Color,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
                          ),
                          alignment: Alignment.center,
                          child: Icon(store['icon'] as IconData, color: store['iconColor'] as Color, size: 26),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          store['name'] as String,
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: _MarketColors.darkText),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DEUX BANNIÈRES PROMO (Offres exclusives / Vendez avec Thix)
  // ============================================================
  Widget _buildPromoBannersRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/market/flash-sales'),
              child: Container(
                height: 150,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_MarketColors.redDark, _MarketColors.red]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('OFFRES EXCLUSIVES', style: TextStyle(color: _MarketColors.gold, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.5)),
                    const SizedBox(height: 6),
                    const Text('Jusqu\'à -50%', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 19, height: 1.1)),
                    const Text('sur une sélection premium', style: TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: _MarketColors.gold, borderRadius: BorderRadius.circular(10)),
                      child: const Text('Découvrir', style: TextStyle(color: _MarketColors.redDark, fontWeight: FontWeight.w800, fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _goToVendor,
              child: Container(
                height: 150,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: _MarketColors.creamBg, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('VENDEZ AVEC THIX', style: TextStyle(color: Color(0xFFC9862B), fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.5)),
                    const SizedBox(height: 6),
                    const Text('Développez votre\nbusiness aujourd\'hui', style: TextStyle(color: _MarketColors.darkText, fontWeight: FontWeight.w900, fontSize: 15, height: 1.15)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: _MarketColors.gold, borderRadius: BorderRadius.circular(10)),
                      child: const Text('Commencer', style: TextStyle(color: _MarketColors.redDark, fontWeight: FontWeight.w800, fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildB2BTools() {
    final tools = [
      {'icon': Icons.compare_arrows_rounded, 'label': 'Comparer', 'action': _goToPriceComparator},
      {'icon': Icons.notifications_active_rounded, 'label': 'Alerte Prix', 'action': _goToPriceAlerts},
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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: tools.map((t) {
            return InkWell(
              onTap: t['action'] as VoidCallback,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  children: [
                    Icon(t['icon'] as IconData, color: _MarketColors.red, size: 24),
                    const SizedBox(height: 6),
                    Text(t['label'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _MarketColors.darkText)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFlashSaleSection(List<dynamic> flashSales) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.bolt_rounded, color: _MarketColors.gold, size: 22),
              const SizedBox(width: 6),
              const Text('Offres flash', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: _MarketColors.darkText)),
              const Spacer(),
              FlashSaleTimer(endTime: DateTime.now().add(const Duration(hours: 2, minutes: 45))),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 245,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: flashSales.take(8).length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _buildProductHorizontalCard(flashSales[index], isFlash: true),
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
                Text('Voir tout', style: TextStyle(color: _MarketColors.red, fontSize: 12, fontWeight: FontWeight.w800)),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios_rounded, size: 10, color: _MarketColors.red),
              ],
            ),
          ),
        ],
      ),
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
        width: 155,
        decoration: BoxDecoration(
          color: _MarketColors.pureWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isFlash ? _MarketColors.red.withOpacity(0.25) : _MarketColors.cardBorder, width: 1),
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
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: _networkImage(product['image_url']),
                  ),
                  if (isFlash)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: _MarketColors.red, borderRadius: BorderRadius.circular(8)),
                        child: Text('-${product['discount_percent'] ?? 0}%', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: WishlistButton(
                        productId: product['id'].toString(),
                        size: 20,
                        activeColor: _MarketColors.red,
                        inactiveColor: _MarketColors.mutedText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 5,
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
                    if (product['rating'] != null)
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 13, color: _MarketColors.gold),
                          const SizedBox(width: 2),
                          Text('${product['rating']}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _MarketColors.darkText)),
                          if (product['reviews_count'] != null)
                            Text(' (${product['reviews_count']})', style: const TextStyle(fontSize: 9, color: _MarketColors.mutedText)),
                        ],
                      ),
                    Row(
                      children: [
                        const Icon(Icons.storefront_rounded, size: 11, color: _MarketColors.mutedText),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(_shopName(product), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, color: _MarketColors.mutedText, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isFlash && product['original_price'] != null)
                          Text('${(product['original_price'] as num).toInt()} $symbol', style: const TextStyle(fontSize: 10, color: _MarketColors.mutedText, decoration: TextDecoration.lineThrough)),
                        Text('$price $symbol', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: _MarketColors.red)),
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
  // CARTE PRODUIT VERTICALE 
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
                        decoration: BoxDecoration(color: _MarketColors.red, borderRadius: BorderRadius.circular(8)),
                        child: Text('-${((1 - price / originalPrice) * 100).round()}%', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: WishlistButton(
                        productId: product['id'].toString(),
                        size: 20,
                        activeColor: _MarketColors.red,
                        inactiveColor: _MarketColors.mutedText,
                      ),
                    ),
                  ),
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
                    Text(
                      product['title'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _MarketColors.darkText, height: 1.2),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.storefront_rounded, size: 11, color: _MarketColors.mutedText),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(_shopName(product), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, color: _MarketColors.mutedText, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 11, color: _MarketColors.mutedText),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(_location(product), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, color: _MarketColors.mutedText, fontWeight: FontWeight.w600)),
                        ),
                      ],
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
                              Text('${price.toInt()} $symbol', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: _MarketColors.red)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: _MarketColors.creamBg, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.add_shopping_cart_rounded, size: 16, color: _MarketColors.red),
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
  // BOTTOM NAV BAR (CORRIGÉE : Panier, Commandes, Wishlist)
  // ============================================================
  Widget _buildBottomNavBar() {
    return Container(
      color: _MarketColors.pureWhite,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem(Icons.home_rounded, 'Accueil', 0),
                  // Remplacement de Activité par Commandes
                  _navItem(Icons.receipt_long_rounded, 'Commandes', 1), 
                  const SizedBox(width: 56), 
                  _navItem(Icons.favorite_rounded, 'Wishlist', 3), 
                  _navItem(Icons.notifications_active_rounded, 'Alertes', 4), 
                ],
              ),
              // Bouton Panier Central (Forcé pour réagir au clic direct)
              Positioned(
                top: -18,
                child: GestureDetector(
                  onTap: _goToCart, // ✅ Appelle directement la fonction du panier
                  behavior: HitTestBehavior.opaque, // ✅ Assure que le clic est toujours détecté
                  child: Container(
                    width: 58,
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _MarketColors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [BoxShadow(color: _MarketColors.red.withOpacity(0.4), blurRadius: 14, offset: const Offset(0, 6))],
                    ),
                    child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 24),
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
    final isSelected = _selectedNavIndex == index;
    return InkWell(
      onTap: () => _onNavTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? _MarketColors.red : _MarketColors.mutedText, size: 22),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 9.5, color: isSelected ? _MarketColors.red : _MarketColors.mutedText, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500)),
        ],
      ),
    );
  }
}
