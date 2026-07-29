// lib/presentation/thix_market/pages/market_home_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/market_colors.dart';
import '../providers/market_providers.dart';
import '../widgets/products/wishlist_button.dart';
import '../widgets/market/flash_sale_timer.dart';

class MarketHomePage extends ConsumerStatefulWidget {
  const MarketHomePage({super.key});
  @override 
  ConsumerState<MarketHomePage> createState() => _MarketHomePageState();
}

class _MarketHomePageState extends ConsumerState<MarketHomePage> {
  final ScrollController _scroll = ScrollController();
  final PageController _bannerCtrl = PageController(viewportFraction: 0.94);
  final ScrollController _flashScrollCtrl = ScrollController();
  Timer? _timer;
  int _currentBanner = 0;
  int _selectedNav = 0;

  @override 
  void initState(){
    super.initState();
    _scroll.addListener(_onScroll);
  }
  
  void _onScroll(){
    if(_scroll.position.pixels > _scroll.position.maxScrollExtent - 700){
      ref.read(forYouProvider.notifier).loadMore();
    }
  }
  
  @override 
  void dispose(){ 
    _scroll.dispose(); 
    _bannerCtrl.dispose(); 
    _flashScrollCtrl.dispose();
    _timer?.cancel(); 
    super.dispose(); 
  }

  void _safeNavigate(String name, String path){
    try{ context.pushNamed(name); }catch(_){ try{ context.push(path); }catch(_){} }
  }

  void _startAuto(int count, int flashCount){
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_){
      // 1. Auto-scroll du Hero Banner
      if(count > 1 && _bannerCtrl.hasClients) {
        _currentBanner = (_currentBanner + 1) % count;
        _bannerCtrl.animateToPage(_currentBanner, duration: const Duration(milliseconds: 700), curve: Curves.easeOutCubic);
        if(mounted) setState((){});
      }
      
      // 2. Auto-scroll des produits Flash Sales UNIQUEMENT SI > 4 produits
      if (flashCount > 4 && _flashScrollCtrl.hasClients) {
        double maxExt = _flashScrollCtrl.position.maxScrollExtent;
        double current = _flashScrollCtrl.offset;
        double next = current + 167; // 155 (carte) + 12 (espacement)
        
        if (next > maxExt) {
          _flashScrollCtrl.animateTo(0, duration: const Duration(milliseconds: 800), curve: Curves.easeInOut);
        } else {
          _flashScrollCtrl.animateTo(next, duration: const Duration(milliseconds: 800), curve: Curves.easeInOut);
        }
      }
    });
  }

  String _shopName(Map<String,dynamic> p) => (p['shop_name']?? p['shops']?['name']?? 'Boutique THIX').toString();
  String _location(Map<String,dynamic> p) => (p['city']?? p['location']?? 'RDC').toString();
  
  String _currencySymbol(Map<String, dynamic> p) {
    final cur = (p['currency'] ?? 'CDF').toString().toUpperCase();
    if (cur == 'USD' || cur == '\$') return '\$';
    return 'FC';
  }

  String _greetingName(){
    final user = Supabase.instance.client.auth.currentUser;
    final full = user?.userMetadata?['full_name']?? user?.userMetadata?['name'];
    if(full!=null && (full as String).trim().isNotEmpty) return full.trim().split(' ').first;
    final email = user?.email;
    if(email!=null && email.contains('@')) return email.split('@').first;
    return 'Client';
  }
  
  double _price(dynamic v){ if(v is num) return v.toDouble(); return double.tryParse(v?.toString()??'')??0; }
  
  String? _extractImage(Map<String, dynamic>? data) {
    if (data == null) return null;
    if (data['image_url'] != null && data['image_url'].toString().isNotEmpty) return data['image_url'].toString();
    if (data['banner_url'] != null && data['banner_url'].toString().isNotEmpty) return data['banner_url'].toString();
    if (data['images'] is List && (data['images'] as List).isNotEmpty) return (data['images'] as List)[0].toString();
    return null;
  }

  Widget _img(String? url){ 
    if(url==null||url.isEmpty) {
      return Container(color: MarketColors.lightBg, child: const Icon(Icons.image_outlined, color: MarketColors.mutedText)); 
    } 
    return Image.network(url, fit: BoxFit.cover, errorBuilder: (_,__,___)=> Container(color: MarketColors.lightBg, child: const Icon(Icons.image_not_supported_outlined, color: MarketColors.mutedText))); 
  }

  void _showComing(String f){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$f : Bientôt disponible!'), backgroundColor: MarketColors.gold)); }

  @override 
  Widget build(BuildContext context){
    final bannersAsync = ref.watch(bannersProvider);
    final flashAsync = ref.watch(flashSalesProvider);
    final forYouAsync = ref.watch(forYouProvider);
    final all = ref.watch(allMarketProductsProvider);
    final hasMore = ref.read(forYouProvider.notifier).hasMore;

    // Synchronisation de l'auto-scroll avec la taille des listes
    bannersAsync.whenData((b)=> flashAsync.whenData((f)=> WidgetsBinding.instance.addPostFrameCallback((_)=> _startAuto(b.length, f.length))));

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
            SliverToBoxAdapter(child: _buildTopBar()),
            SliverToBoxAdapter(child: _buildHero(bannersAsync)),
            SliverToBoxAdapter(child: _buildTrustBadges()),
            SliverToBoxAdapter(child: _buildSearchBar()),
            const SliverToBoxAdapter(child: SizedBox(height:24)),
            SliverToBoxAdapter(child: _buildSupermarketSection()),
            const SliverToBoxAdapter(child: SizedBox(height:24)),
            SliverToBoxAdapter(child: _buildPromoBannersRow()),
            const SliverToBoxAdapter(child: SizedBox(height:20)),
            SliverToBoxAdapter(child: _buildB2BTools()),
            const SliverToBoxAdapter(child: SizedBox(height:20)),
            
            // BANDEAU DÉFILANT ROUGE AVEC MINUTEUR AU DÉBUT
            SliverToBoxAdapter(child: flashAsync.maybeWhen(
              data: (list) {
                if (list.isEmpty) return const SizedBox.shrink();
                
                DateTime? timerEnd;
                for (var p in list) {
                  if (p['expires_at'] != null) {
                    final dt = DateTime.tryParse(p['expires_at'].toString());
                    if (dt != null && dt.isAfter(DateTime.now())) {
                      if (timerEnd == null || dt.isBefore(timerEnd)) timerEnd = dt;
                    }
                  }
                }
                timerEnd ??= DateTime.now().add(const Duration(hours: 2, minutes: 45));

                return Container(
                  color: MarketColors.red, // Fond rouge
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      // Minuteur au début à gauche
                      Padding(
                        padding: const EdgeInsets.only(left: 12, right: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                          child: FlashSaleTimer(endTime: timerEnd),
                        ),
                      ),
                      // Texte défilant blanc en gras
                      const Expanded(
                        child: ClipRect(
                          child: _MarqueeWidget(text: "⚡ VENTE FLASH EN COURS • JUSQU'À -50% SUR UNE SÉLECTION DE PRODUITS • PROFITEZ-EN VITE ⚡"),
                        ),
                      ),
                    ],
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            )),

            SliverToBoxAdapter(child: _buildFlashSaleSection(flashAsync)),
            const SliverToBoxAdapter(child: SizedBox(height:24)),
            SliverToBoxAdapter(child: _buildSectionHeader('Tous les produits', (){})),
            const SliverToBoxAdapter(child: SizedBox(height:12)),
            _buildGrid(forYouAsync, all, hasMore),
            const SliverToBoxAdapter(child: SizedBox(height:110)),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildTopBar(){
    return Container(
      color: MarketColors.white,
      padding: const EdgeInsets.fromLTRB(16,54,16,16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(width:44,height:44, decoration: BoxDecoration(color: MarketColors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: MarketColors.cardBorder)), child: const Icon(Icons.shopping_bag_rounded, color: MarketColors.red, size:22)),
            const SizedBox(width:10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [RichText(text: const TextSpan(children: [TextSpan(text:'THIX ', style: TextStyle(color: MarketColors.red, fontWeight: FontWeight.w900, fontSize:19)), TextSpan(text:'MARKET', style: TextStyle(color: MarketColors.gold, fontWeight: FontWeight.w900, fontSize:19))])), const Text('Achetez. Vendez. Évoluez.', style: TextStyle(color: MarketColors.mutedText, fontSize:11.5))]),
          ]),
          Row(children: [
            InkWell(onTap: ()=> context.push('/market/notifications'), child: Container(width:40,height:40, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: MarketColors.cardBorder)), child: const Icon(Icons.notifications_none_rounded, size:20))),
            const SizedBox(width:10),
            InkWell(onTap: ()=> context.push('/user/dashboard'), child: Container(width:40,height:40, decoration: const BoxDecoration(color: MarketColors.red, shape: BoxShape.circle), child: const Icon(Icons.person_rounded, color: Colors.white, size:20))),
          ]),
        ],
      ),
    );
  }

  Widget _buildHero(AsyncValue<List<Map<String,dynamic>>> async){
    return async.when(
      loading: ()=> const SizedBox(height:230, child: Center(child: CircularProgressIndicator(color: MarketColors.red))),
      error: (_,__)=> _buildHeroContent([null]),
      data: (b)=> _buildHeroContent(b),
    );
  }

  Widget _buildHeroContent(List<dynamic> banners){
    final slides = banners.isEmpty ? [null] : banners;
    return Column(children: [
      SizedBox(
        height: 230,
        child: PageView.builder(
          controller: _bannerCtrl,
          itemCount: slides.length,
          onPageChanged: (i)=> setState(()=> _currentBanner=i),
          itemBuilder: (_, index){
            final b = slides[index] as Map<String,dynamic>?;
            final imageUrl = _extractImage(b);
            final title = b?['title'] ?? 'Votre marketplace\npremium et sécurisée';
            final subtitle = b?['description'] ?? b?['subtitle'] ?? 'Des milliers de produits, des vendeurs vérifiés, une expérience unique.';
            final productId = b?['id'] ?? b?['target_url'];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal:6),
              child: GestureDetector(
                onTap: () {
                  if (productId != null && productId.toString().isNotEmpty) {
                    context.push('/market/product/$productId');
                  } else {
                    context.push('/market/flash-sales');
                  }
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(22,22,16,22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: MarketColors.redDark,
                    image: imageUrl != null 
                        ? DecorationImage(
                            image: NetworkImage(imageUrl), 
                            fit: BoxFit.cover, 
                            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.55), BlendMode.darken)
                          )
                        : null,
                    gradient: imageUrl == null ? const LinearGradient(colors: [MarketColors.redDark, MarketColors.red]) : null,
                  ),
                  child: Stack(children: [
                    if (imageUrl == null)
                      const Positioned(right:-10,bottom:-10, child: Opacity(opacity:0.18, child: Icon(Icons.shopping_cart_rounded, size:140, color: Colors.white))),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      mainAxisAlignment: MainAxisAlignment.center, 
                      children: [
                        if(index==0 && imageUrl == null) 
                          Text('Bonjour, ${_greetingName()} 👋', style: const TextStyle(color: Colors.white, fontSize:13, fontWeight: FontWeight.w600)),
                        const SizedBox(height:8),
                        Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize:22, fontWeight: FontWeight.w900, height:1.2)),
                        const SizedBox(height:8),
                        SizedBox(width:210, child: Text(subtitle, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize:12))),
                        const SizedBox(height:16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal:18,vertical:12), 
                          decoration: BoxDecoration(color: MarketColors.gold, borderRadius: BorderRadius.circular(14)), 
                          child: Row(
                            mainAxisSize: MainAxisSize.min, 
                            children: [
                              Icon(productId != null ? Icons.visibility_rounded : Icons.search_rounded, size:16, color: MarketColors.redDark), 
                              const SizedBox(width:8), 
                              Text(productId != null ? 'Voir l\'offre' : 'Explorer le marché', style: const TextStyle(color: MarketColors.redDark, fontWeight: FontWeight.w800, fontSize:12.5))
                            ]
                          )
                        ),
                      ]
                    ),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height:10),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(slides.length, (i){ final a=i==_currentBanner; return AnimatedContainer(duration: const Duration(milliseconds:250), margin: const EdgeInsets.symmetric(horizontal:3), height:6, width:a?18:6, decoration: BoxDecoration(color: a?MarketColors.red:Colors.grey.shade300, borderRadius: BorderRadius.circular(10))); })),
    ]);
  }

  Widget _buildTrustBadges(){
    return Container(
      color: MarketColors.white,
      padding: const EdgeInsets.symmetric(horizontal:12,vertical:14),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Row(children: [Icon(Icons.lock_outline_rounded, size:15, color: MarketColors.red), SizedBox(width:5), Text('Paiement sécurisé', style: TextStyle(fontSize:10.5, fontWeight: FontWeight.w600))]),
          Row(children: [Icon(Icons.verified_user_outlined, size:15, color: MarketColors.red), SizedBox(width:5), Text('Vendeurs vérifiés', style: TextStyle(fontSize:10.5, fontWeight: FontWeight.w600))]),
          Row(children: [Icon(Icons.local_shipping_outlined, size:15, color: MarketColors.red), SizedBox(width:5), Text('Livraison fiable', style: TextStyle(fontSize:10.5, fontWeight: FontWeight.w600))]),
          Row(children: [Icon(Icons.headset_mic_outlined, size:15, color: MarketColors.red), SizedBox(width:5), Text('Support 24/7', style: TextStyle(fontSize:10.5, fontWeight: FontWeight.w600))]),
        ],
      ),
    );
  }

  Widget _buildSearchBar(){
    return Container(
      color: MarketColors.white,
      padding: const EdgeInsets.fromLTRB(16,4,16,16),
      child: Row(children: [
        Expanded(child: GestureDetector(onTap: ()=> context.push('/market/search'), child: Container(height:48, padding: const EdgeInsets.symmetric(horizontal:16), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: MarketColors.cardBorder, width:1.4)), child: const Row(children: [Icon(Icons.search_rounded, size:20, color: MarketColors.red), SizedBox(width:10), Expanded(child: Text('Rechercher un produit, une marque...', style: TextStyle(fontSize:12.5, color: MarketColors.mutedText)))])))),
        const SizedBox(width:10),
        InkWell(onTap: ()=> context.push('/market/search'), child: Container(height:48, padding: const EdgeInsets.symmetric(horizontal:20), decoration: BoxDecoration(color: MarketColors.red, borderRadius: BorderRadius.circular(24)), child: const Center(child: Text('Rechercher', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize:12.5))))),
      ]),
    );
  }

  Widget _buildSupermarketSection(){
    final shopsAsync = ref.watch(featuredShopsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal:16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Supermarchés à domicile', style: TextStyle(fontWeight: FontWeight.w900, fontSize:16)), GestureDetector(onTap: ()=> _safeNavigate('marketShops','/market/shops'), child: const Text('Tout voir', style: TextStyle(color: MarketColors.red, fontSize:12, fontWeight: FontWeight.w800)))]),
        const SizedBox(height:16),
        shopsAsync.when(
          loading: ()=> const SizedBox(height:64, child: Center(child: CircularProgressIndicator(color: MarketColors.red))),
          error: (_,__)=> const SizedBox.shrink(),
          data: (shops){
            if(shops.isEmpty) return const Text('Aucun supermarché', style: TextStyle(color: MarketColors.mutedText, fontSize:12));
            return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: shops.take(4).map((s){
              return GestureDetector(onTap: ()=> context.push('/market/shop/${s['id']}'), child: Column(children: [Container(height:64,width:64, decoration: BoxDecoration(shape: BoxShape.circle, color: MarketColors.red, image: s['logo_url']!=null? DecorationImage(image: NetworkImage(s['logo_url']), fit: BoxFit.cover):null), child: s['logo_url']==null? const Icon(Icons.storefront_rounded, color: Colors.white, size:28):null), const SizedBox(height:8), Text((s['name']??'Shop').toString(), style: const TextStyle(fontSize:11.5, fontWeight: FontWeight.w700))]));
            }).toList());
          },
        ),
      ]),
    );
  }

  Widget _buildPromoBannersRow(){
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal:16),
      child: Row(children: [
        Expanded(child: GestureDetector(onTap: ()=> _safeNavigate('marketFlashSales','/market/flash-sales'), child: Container(height:150, padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: const LinearGradient(colors: [MarketColors.redDark, MarketColors.red]), borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('OFFRES EXCLUSIVES', style: TextStyle(color: MarketColors.gold, fontWeight: FontWeight.w800, fontSize:10)), const SizedBox(height:6), const Text('Jusqu\'à -50%', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize:19)), const Text('sur une sélection premium', style: TextStyle(color: Colors.white70, fontSize:10.5)), const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal:12,vertical:8), decoration: BoxDecoration(color: MarketColors.gold, borderRadius: BorderRadius.circular(10)), child: const Text('Découvrir', style: TextStyle(color: MarketColors.redDark, fontWeight: FontWeight.w800, fontSize:11)))])))),
        const SizedBox(width:12),
        Expanded(child: GestureDetector(onTap: ()=> _safeNavigate('vendorDashboard','/market/vendor/dashboard'), child: Container(height:150, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: MarketColors.creamBg, borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('VENDEZ AVEC THIX', style: TextStyle(color: Color(0xFFC9862B), fontWeight: FontWeight.w800, fontSize:10)), const SizedBox(height:6), const Text('Développez votre\nbusiness aujourd\'hui', style: TextStyle(color: MarketColors.darkText, fontWeight: FontWeight.w900, fontSize:15, height:1.15)), const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal:12,vertical:8), decoration: BoxDecoration(color: MarketColors.gold, borderRadius: BorderRadius.circular(10)), child: const Text('Commencer', style: TextStyle(color: MarketColors.redDark, fontWeight: FontWeight.w800, fontSize:11)))])))),
      ]),
    );
  }

  Widget _buildB2BTools(){
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal:16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical:14,horizontal:8),
        decoration: BoxDecoration(color: MarketColors.white, borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _b2bItem(Icons.compare_arrows_rounded, 'Comparer', ()=> _safeNavigate('marketProductComparator','/market/compare')),
            _b2bItem(Icons.notifications_active_rounded, 'Alerte Prix', ()=> _safeNavigate('marketPriceAlerts','/market/price-alerts')),
            _b2bItem(Icons.request_quote_rounded, 'Devis B2B', ()=> _showComing('Devis B2B')),
            _b2bItem(Icons.favorite_rounded, 'Wishlist', ()=> _safeNavigate('marketWishlist','/market/wishlist')),
          ],
        ),
      ),
    );
  }

  Widget _b2bItem(IconData icon, String label, VoidCallback onTap){
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Padding(padding: const EdgeInsets.all(4), child: Column(children: [Icon(icon, color: MarketColors.red, size:24), const SizedBox(height:6), Text(label, style: const TextStyle(fontSize:10, fontWeight: FontWeight.w800))])) );
  }

  Widget _buildFlashSaleSection(AsyncValue<List<Map<String,dynamic>>> async){
    return async.when(
      loading: ()=> const SizedBox.shrink(),
      error: (_,__)=> const SizedBox.shrink(),
      data: (list){
        if(list.isEmpty) return const SizedBox.shrink();

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal:16), 
            child: Row(children: [
              const Icon(Icons.bolt_rounded, color: MarketColors.gold, size:22), 
              const SizedBox(width:6), 
              const Text('Offres flash', style: TextStyle(fontWeight: FontWeight.w900, fontSize:18)), 
            ])
          ),
          const SizedBox(height:12),
          SizedBox(
            height:245, 
            child: ListView.separated(
              controller: _flashScrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal:16), 
              scrollDirection: Axis.horizontal, 
              itemCount: list.length, 
              separatorBuilder: (_,__)=> const SizedBox(width:12), 
              itemBuilder: (_,i)=> _buildProductHorizontalCard(list[i])
            )
          ),
        ]);
      },
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onTap){
    return Padding(padding: const EdgeInsets.symmetric(horizontal:16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize:16)), GestureDetector(onTap: onTap, child: const Row(children: [Text('Voir tout', style: TextStyle(color: MarketColors.red, fontSize:12, fontWeight: FontWeight.w800)), SizedBox(width:4), Icon(Icons.arrow_forward_ios_rounded, size:10, color: MarketColors.red)]))]));
  }

  Widget _buildProductHorizontalCard(Map<String,dynamic> p){
    final price = _price(p['price']);
    final currencySymbol = _currencySymbol(p);
    final imageUrl = _extractImage(p);
    
    return GestureDetector(
      onTap: ()=> context.push('/market/product/${p['id']}'),
      child: Container(
        width: 155,
        decoration: BoxDecoration(color: MarketColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFD81E2C).withValues(alpha:0.25))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex:5, child: Stack(fit: StackFit.expand, children: [ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: _img(imageUrl)), Positioned(top:8,left:8, child: Container(padding: const EdgeInsets.symmetric(horizontal:8,vertical:4), decoration: BoxDecoration(color: MarketColors.red, borderRadius: BorderRadius.circular(8)), child: Text('-${p['discount_percent']??0}%', style: const TextStyle(color: Colors.white, fontSize:10, fontWeight: FontWeight.w900)))), Positioned(top:4,right:4, child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: WishlistButton(productId: p['id'].toString(), size:20)))])),
          Expanded(flex:5, child: Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p['title']??'', maxLines:2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize:12, fontWeight: FontWeight.w700, height:1.2)),
            const Spacer(),
            Row(children: [const Icon(Icons.storefront_rounded, size:11, color: MarketColors.mutedText), const SizedBox(width:3), Expanded(child: Text(_shopName(p), maxLines:1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize:9.5, color: MarketColors.mutedText)))]),
            Text('${price.toInt()} $currencySymbol', style: const TextStyle(fontWeight: FontWeight.w900, fontSize:15, color: MarketColors.red)),
          ]))),
        ]),
      ),
    );
  }

  Widget _buildGrid(AsyncValue<List<Map<String,dynamic>>> forYouAsync, List<Map<String,dynamic>> all, bool hasMore){
    return forYouAsync.when(
      loading: ()=> const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(60), child: Center(child: CircularProgressIndicator(color: MarketColors.red)))),
      error: (e,_ )=> SliverToBoxAdapter(child: Center(child: Text('Erreur $e'))),
      data: (_)=> SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal:16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2, crossAxisSpacing:12, mainAxisSpacing:12, childAspectRatio:0.62),
          delegate: SliverChildBuilderDelegate((_,i){ if(i>=all.length) return const Center(child: CircularProgressIndicator(color: MarketColors.red)); return _buildProductCard(all[i]); }, childCount: all.length + (hasMore?1:0)),
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String,dynamic> p){
    final price = _price(p['discount_price']??p['price']);
    final orig = _price(p['price']);
    final hasDisc = p['discount_price']!=null && price<orig;
    final currencySymbol = _currencySymbol(p);
    final imageUrl = _extractImage(p);

    return GestureDetector(
      onTap: ()=> context.push('/market/product/${p['id']}'),
      child: Container(
        decoration: BoxDecoration(color: MarketColors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: MarketColors.cardBorder)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex:5, child: Stack(fit: StackFit.expand, children: [
            ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(18)), child: _img(imageUrl)),
            if(hasDisc) Positioned(top:8,left:8, child: Container(padding: const EdgeInsets.symmetric(horizontal:6,vertical:4), decoration: BoxDecoration(color: MarketColors.red, borderRadius: BorderRadius.circular(8)), child: Text('-${((1-price/orig)*100).round()}%', style: const TextStyle(color: Colors.white, fontSize:10, fontWeight: FontWeight.w900)))),
            Positioned(top:6,right:6, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: WishlistButton(productId: p['id'].toString(), size:20))),
          ])),
          Expanded(
            flex:5,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p['title']??'', maxLines:2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize:12, fontWeight: FontWeight.w700, height:1.2)),
                const SizedBox(height:3),
                Row(children: [const Icon(Icons.storefront_rounded, size:11, color: MarketColors.mutedText), const SizedBox(width:3), Expanded(child: Text(_shopName(p), maxLines:1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize:9.5, color: MarketColors.mutedText)))]),
                Row(children: [const Icon(Icons.location_on_outlined, size:11, color: MarketColors.mutedText), const SizedBox(width:3), Expanded(child: Text(_location(p), maxLines:1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize:9.5, color: MarketColors.mutedText)))]),
                const Spacer(),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if(hasDisc) Text('${orig.toInt()} $currencySymbol', style: const TextStyle(decoration: TextDecoration.lineThrough, fontSize:10, color: MarketColors.mutedText)), Text('${price.toInt()} $currencySymbol', style: const TextStyle(fontWeight: FontWeight.w900, fontSize:14, color: MarketColors.red))]),
                  Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: MarketColors.creamBg, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.add_shopping_cart_rounded, size:16, color: MarketColors.red)),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildBottomNavBar(){
    return Container(
      color: MarketColors.white,
      padding: const EdgeInsets.only(top:6),
      child: SafeArea(
        top:false,
        child: SizedBox(
          height:64,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_navItem(Icons.home_rounded,'Accueil',0), _navItem(Icons.receipt_long_rounded,'Commandes',1), const SizedBox(width:60), _navItem(Icons.favorite_rounded,'Wishlist',3), _navItem(Icons.notifications_active_rounded,'Alertes',4)]),
              Positioned(top:-20, child: GestureDetector(onTap: ()=> context.push('/market/cart'), child: Container(width:60,height:60, alignment: Alignment.center, decoration: BoxDecoration(color: MarketColors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width:4)), child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size:26)))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index){
    final sel = _selectedNav==index;
    return GestureDetector(
      onTap: (){
        HapticFeedback.lightImpact();
        setState(()=> _selectedNav=index);
        if(index==0) _scroll.animateTo(0, duration: const Duration(milliseconds:400), curve: Curves.easeOut);
        if(index==1) context.push('/market/orders');
        if(index==3) context.push('/market/wishlist');
        if(index==4) context.push('/market/price-alerts');
      },
      child: Container(width:65, padding: const EdgeInsets.symmetric(vertical:4), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: sel?MarketColors.red:MarketColors.mutedText, size:24), const SizedBox(height:2), Text(label, maxLines:1, style: TextStyle(fontSize:10, color: sel?MarketColors.red:MarketColors.mutedText, fontWeight: sel?FontWeight.w800:FontWeight.w500))])),
    );
  }
}

class _MarqueeWidget extends StatefulWidget {
  final String text;
  const _MarqueeWidget({required this.text});
  @override _MarqueeWidgetState createState() => _MarqueeWidgetState();
}

class _MarqueeWidgetState extends State<_MarqueeWidget> {
  late ScrollController _marqueeScrollCtrl;
  late Timer _marqueeTimer;

  @override void initState() {
    super.initState();
    _marqueeScrollCtrl = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startMarquee());
  }

  void _startMarquee() {
    _marqueeTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (_marqueeScrollCtrl.hasClients) {
        double maxScroll = _marqueeScrollCtrl.position.maxScrollExtent;
        double currentScroll = _marqueeScrollCtrl.offset;
        if (currentScroll >= maxScroll) {
          _marqueeScrollCtrl.jumpTo(0);
        } else {
          _marqueeScrollCtrl.jumpTo(currentScroll + 2.0);
        }
      }
    });
  }

  @override void dispose() {
    _marqueeTimer.cancel();
    _marqueeScrollCtrl.dispose();
    super.dispose();
  }

  @override Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: ListView.builder(
        controller: _marqueeScrollCtrl,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              widget.text,
              style: const TextStyle(
                color: Colors.white, // Texte en blanc gras
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          );
        },
      ),
    );
  }
}
