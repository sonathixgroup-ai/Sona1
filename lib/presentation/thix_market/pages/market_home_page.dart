import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final ScrollController _scrollController = ScrollController();
  final PageController _bannerController = PageController(viewportFraction: 0.94);
  Timer? _bannerTimer;
  int _currentBannerIndex = 0;
  int _selectedNavIndex = 0;

  @override void initState() {
    super.initState();
    _scrollController.addListener((){
      if(_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 600){
        ref.read(forYouProvider.notifier).loadMore();
      }
    });
  }

  @override void dispose() {
    _scrollController.dispose();
    _bannerController.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  void _safeNavigate(String name, String path){
    try { context.pushNamed(name); } catch(_) { try { context.push(path); } catch(_) {} }
  }

  void _startBannerAutoplay(int count){
    _bannerTimer?.cancel();
    if(count<=1) return;
    _bannerTimer = Timer.periodic(const Duration(seconds:5), (_){
      if(!_bannerController.hasClients) return;
      _currentBannerIndex = (_currentBannerIndex+1)%count;
      _bannerController.animateToPage(_currentBannerIndex, duration: const Duration(milliseconds:700), curve: Curves.easeOutCubic);
      if(mounted) setState((){});
    });
  }

  double _parsePrice(dynamic v){
    if(v is num) return v.toDouble();
    return double.tryParse(v?.toString()??'')??0;
  }

  String _shopName(Map<String,dynamic> p) => (p['shop_name']??p['shops']?['name']??'Boutique THIX').toString();
  String _location(Map<String,dynamic> p) => (p['city']??p['location']??'RDC').toString();

  Widget _networkImage(String? url){
    if(url==null||url.trim().isEmpty){
      return Container(color: MarketColors.lightBg, child: const Icon(Icons.image_outlined, color: MarketColors.mutedText));
    }
    return Image.network(url, fit: BoxFit.cover, cacheWidth: 500, errorBuilder: (_,__,___)=> Container(color: MarketColors.lightBg, child: const Icon(Icons.broken_image_outlined, color: MarketColors.mutedText)), loadingBuilder: (c,child,prog)=> prog==null?child:Container(color: MarketColors.lightBg));
  }

  @override Widget build(BuildContext context) {
    final bannersAsync = ref.watch(bannersProvider);
    final flashAsync = ref.watch(flashSalesProvider);
    final forYouAsync = ref.watch(forYouProvider);
    final allProducts = ref.watch(allMarketProductsProvider);
    final hasMore = ref.read(forYouProvider.notifier).hasMore;

    bannersAsync.whenData((b)=> WidgetsBinding.instance.addPostFrameCallback((_)=> _startBannerAutoplay(b.length)));

    return Scaffold(
      backgroundColor: MarketColors.lightBg,
      body: RefreshIndicator(
        color: MarketColors.red,
        onRefresh: () async { ref.invalidate(bannersProvider); ref.invalidate(flashSalesProvider); await ref.read(forYouProvider.notifier).refresh(); },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(child: _buildTopBar()),
            SliverToBoxAdapter(child: bannersAsync.when(loading: ()=> const SizedBox(height:230, child: Center(child: CircularProgressIndicator())), error: (_,__)=> _buildHeroBannerCarousel([], true), data: (b)=> _buildHeroBannerCarousel(b, false))),
            SliverToBoxAdapter(child: _buildTrustBadges()),
            SliverToBoxAdapter(child: _buildSearchBar()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(child: _buildSupermarketSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(child: _buildPromoBannersRow()),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(child: _buildB2BTools()),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(child: flashAsync.when(loading: ()=> const SizedBox.shrink(), error: (_,__)=> const SizedBox.shrink(), data: (f)=> f.isEmpty? const SizedBox.shrink() : _buildFlashSaleSection(f))),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(child: _buildSectionHeader('Tous les produits', (){})),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            forYouAsync.when(
              loading: ()=> const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(60), child: Center(child: CircularProgressIndicator()))),
              error: (e,_ )=> SliverToBoxAdapter(child: Center(child: Text('Erreur $e'))),
              data: (_)=> SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal:16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2, crossAxisSpacing:12, mainAxisSpacing:12, childAspectRatio:0.62),
                  delegate: SliverChildBuilderDelegate((ctx,i){
                    if(i>=allProducts.length) return const Center(child: CircularProgressIndicator(strokeWidth:2));
                    return _buildProductCard(allProducts[i]);
                  }, childCount: allProducts.length + (hasMore?1:0)),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height:110)),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // ================= UI IDENTIQUE A TON DESIGN =================
  Widget _buildTopBar(){
    return Container(color: MarketColors.white, padding: const EdgeInsets.fromLTRB(16,54,16,16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(children: [Container(width:44,height:44, decoration: BoxDecoration(color: MarketColors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: MarketColors.cardBorder), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius:10, offset: const Offset(0,4))]), child: const Icon(Icons.shopping_bag_rounded, color: MarketColors.red, size:22)), const SizedBox(width:10), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [RichText(text: const TextSpan(children: [TextSpan(text:'THIX ', style: TextStyle(color: MarketColors.red, fontWeight: FontWeight.w900, fontSize:19)), TextSpan(text:'MARKET', style: TextStyle(color: MarketColors.gold, fontWeight: FontWeight.w900, fontSize:19))])), const Text('Achetez. Vendez. Évoluez.', style: TextStyle(color: MarketColors.mutedText, fontSize:11.5))])]),
      Row(children: [InkWell(onTap: ()=> context.push('/market/notifications'), child: Container(width:40,height:40, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: MarketColors.cardBorder)), child: const Icon(Icons.notifications_none_rounded, size:20))), const SizedBox(width:10), InkWell(onTap: ()=> context.push('/user/dashboard'), child: Container(width:40,height:40, decoration: const BoxDecoration(color: MarketColors.red, shape: BoxShape.circle), child: const Icon(Icons.person_rounded, color: Colors.white, size:20)))])
    ]));
  }

  Widget _buildHeroBannerCarousel(List<Map<String,dynamic>> banners, bool loading){
    final slides = banners.isEmpty? [null] : banners;
    return Column(children: [
      SizedBox(height:230, child: PageView.builder(controller: _bannerController, itemCount: slides.length, onPageChanged: (i)=> setState(()=> _currentBannerIndex=i), itemBuilder: (_,index){
        final b = slides[index] as Map<String,dynamic>?;
        return Padding(padding: const EdgeInsets.symmetric(horizontal:6), child: GestureDetector(onTap: ()=> context.push('/market/flash-sales'), child: Container(padding: const EdgeInsets.fromLTRB(22,22,16,22), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [MarketColors.redDark, MarketColors.red]), boxShadow: [BoxShadow(color: MarketColors.red.withValues(alpha:0.25), blurRadius:20, offset: const Offset(0,10))], image: b?['image_url']!=null? DecorationImage(image: NetworkImage(b!['image_url']), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withValues(alpha:0.25), BlendMode.darken)):null), child: Stack(children: [
          const Positioned(right:-10,bottom:-10,child: Opacity(opacity:0.18, child: Icon(Icons.shopping_cart_rounded, size:140, color: Colors.white))),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            RichText(text: TextSpan(style: const TextStyle(fontSize:22,fontWeight:FontWeight.w900,height:1.2,color:Colors.white), children: [TextSpan(text: b?['title']??'Votre marketplace\n'), const TextSpan(text:'premium', style: TextStyle(color: MarketColors.gold)), const TextSpan(text:' et sécurisée')])), const SizedBox(height:8), SizedBox(width:210, child: Text(b?['subtitle']??'Des milliers de produits, des vendeurs vérifiés, une expérience unique.', style: const TextStyle(color: Colors.white70, fontSize:12, height:1.3))), const SizedBox(height:16), Container(padding: const EdgeInsets.symmetric(horizontal:18,vertical:12), decoration: BoxDecoration(color: MarketColors.gold, borderRadius: BorderRadius.circular(14)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.search_rounded, size:16, color: MarketColors.redDark), SizedBox(width:8), Text('Explorer le marché', style: TextStyle(color: MarketColors.redDark, fontWeight: FontWeight.w800, fontSize:12.5)), SizedBox(width:6), Icon(Icons.arrow_forward_rounded, size:14, color: MarketColors.redDark)]))
          ])
        ]))));
      })),
      const SizedBox(height:10),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(slides.length, (i){ final active = i==_currentBannerIndex; return AnimatedContainer(duration: const Duration(milliseconds:250), margin: const EdgeInsets.symmetric(horizontal:3), height:6, width:active?18:6, decoration: BoxDecoration(color: active?MarketColors.red:Colors.grey.shade300, borderRadius: BorderRadius.circular(10))); }))
    ]);
  }

  Widget _buildTrustBadges(){
    final badges = [{'icon':Icons.lock_outline_rounded,'label':'Paiement sécurisé'},{'icon':Icons.verified_user_outlined,'label':'Vendeurs vérifiés'},{'icon':Icons.local_shipping_outlined,'label':'Livraison fiable'},{'icon':Icons.headset_mic_outlined,'label':'Support 24/7'}];
    return Container(color: MarketColors.white, padding: const EdgeInsets.symmetric(horizontal:12,vertical:14), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: badges.map((b)=> Flexible(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(b['icon'] as IconData, size:15, color: MarketColors.red), const SizedBox(width:5), Flexible(child: Text(b['label'] as String, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize:10.5, fontWeight: FontWeight.w600)))]))).toList()));
  }

  Widget _buildSearchBar(){
    return Container(color: MarketColors.white, padding: const EdgeInsets.fromLTRB(16,4,16,16), child: Row(children: [Expanded(child: GestureDetector(onTap: ()=> context.push('/market/search'), child: Container(height:48, padding: const EdgeInsets.symmetric(horizontal:16), decoration: BoxDecoration(color: MarketColors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: MarketColors.cardBorder, width:1.4)), child: const Row(children: [Icon(Icons.search_rounded, size:20, color: MarketColors.red), SizedBox(width:10), Expanded(child: Text('Rechercher un produit, une marque...', style: TextStyle(fontSize:12.5, color: MarketColors.mutedText)))])))), const SizedBox(width:10), InkWell(onTap: ()=> context.push('/market/search'), child: Container(height:48, padding: const EdgeInsets.symmetric(horizontal:20), decoration: BoxDecoration(color: MarketColors.red, borderRadius: BorderRadius.circular(24)), child: const Center(child: Text('Rechercher', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize:12.5)))) )]));
  }

  Widget _buildSupermarketSection(){
    final shopsAsync = ref.watch(featuredShopsProvider);
    return Padding(padding: const EdgeInsets.symmetric(horizontal:16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Supermarchés à domicile', style: TextStyle(fontWeight: FontWeight.w900, fontSize:16)), GestureDetector(onTap: ()=> _safeNavigate('marketShops','/market/shops'), child: const Text('Tout voir', style: TextStyle(color: MarketColors.red, fontSize:12, fontWeight: FontWeight.w800)))]),
      const SizedBox(height:16),
      shopsAsync.when(loading: ()=> const SizedBox(height:64, child: Center(child: CircularProgressIndicator())), error: (_,__)=> const SizedBox.shrink(), data: (shops){
        if(shops.isEmpty) return const Text('Aucun supermarché', style: TextStyle(color: MarketColors.mutedText, fontSize:12));
        return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: shops.take(4).map((s){ return GestureDetector(onTap: ()=> context.push('/market/shop/${s['id']}'), child: Column(children: [Container(height:64,width:64, decoration: BoxDecoration(shape: BoxShape.circle, color: MarketColors.red, image: s['logo_url']!=null? DecorationImage(image: NetworkImage(s['logo_url']), fit: BoxFit.cover):null), child: s['logo_url']==null? const Icon(Icons.storefront_rounded, color: Colors.white, size:28):null), const SizedBox(height:8), Text((s['name']??'Shop').toString(), style: const TextStyle(fontSize:11.5, fontWeight: FontWeight.w700))])) ;}).toList());
      })
    ]));
  }

  Widget _buildPromoBannersRow(){
    return Padding(padding: const EdgeInsets.symmetric(horizontal:16), child: Row(children: [
      Expanded(child: GestureDetector(onTap: ()=> _safeNavigate('marketFlashSales','/market/flash-sales'), child: Container(height:150, padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: const LinearGradient(colors: [MarketColors.redDark, MarketColors.red]), borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('OFFRES EXCLUSIVES', style: TextStyle(color: MarketColors.gold, fontWeight: FontWeight.w800, fontSize:10)), const SizedBox(height:6), const Text('Jusqu\'à -50%', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize:19)), const Text('sur une sélection premium', style: TextStyle(color: Colors.white70, fontSize:10.5)), const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal:12,vertical:8), decoration: BoxDecoration(color: MarketColors.gold, borderRadius: BorderRadius.circular(10)), child: const Text('Découvrir', style: TextStyle(color: MarketColors.redDark, fontWeight: FontWeight.w800, fontSize:11)))])))),
      const SizedBox(width:12),
      Expanded(child: GestureDetector(onTap: ()=> _safeNavigate('vendorDashboard','/market/vendor/dashboard'), child: Container(height:150, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: MarketColors.creamBg, borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('VENDEZ AVEC THIX', style: TextStyle(color: Color(0xFFC9862B), fontWeight: FontWeight.w800, fontSize:10)), const SizedBox(height:6), const Text('Développez votre\nbusiness aujourd\'hui', style: TextStyle(color: MarketColors.darkText, fontWeight: FontWeight.w900, fontSize:15, height:1.15)), const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal:12,vertical:8), decoration: BoxDecoration(color: MarketColors.gold, borderRadius: BorderRadius.circular(10)), child: const Text('Commencer', style: TextStyle(color: MarketColors.redDark, fontWeight: FontWeight.w800, fontSize:11)))])))),
    ]));
  }

  Widget _buildB2BTools(){
    final tools = [{'icon':Icons.compare_arrows_rounded,'label':'Comparer','path':'/market/compare'},{'icon':Icons.notifications_active_rounded,'label':'Alerte Prix','path':'/market/price-alerts'},{'icon':Icons.request_quote_rounded,'label':'Devis B2B','path':'/market/b2b'},{'icon':Icons.favorite_rounded,'label':'Wishlist','path':'/market/wishlist'}];
    return Padding(padding: const EdgeInsets.symmetric(horizontal:16), child: Container(padding: const EdgeInsets.symmetric(vertical:14,horizontal:8), decoration: BoxDecoration(color: MarketColors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius:15, offset: const Offset(0,8))]), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: tools.map((t)=> InkWell(onTap: ()=> context.push(t['path'] as String), child: Column(children: [Icon(t['icon'] as IconData, color: MarketColors.red, size:24), const SizedBox(height:6), Text(t['label'] as String, style: const TextStyle(fontSize:10, fontWeight: FontWeight.w800))]))).toList())));
  }

  Widget _buildFlashSaleSection(List<dynamic> flashSales){
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal:16), child: Row(children: [const Icon(Icons.bolt_rounded, color: MarketColors.gold, size:22), const SizedBox(width:6), const Text('Offres flash', style: TextStyle(fontWeight: FontWeight.w900, fontSize:18)), const Spacer(), FlashSaleTimer(endTime: DateTime.now().add(const Duration(hours:2, minutes:45)))])),
      const SizedBox(height:12),
      SizedBox(height:245, child: ListView.separated(padding: const EdgeInsets.symmetric(horizontal:16), scrollDirection: Axis.horizontal, itemCount: flashSales.length, separatorBuilder: (_,__)=> const SizedBox(width:12), itemBuilder: (_,i)=> _buildProductHorizontalCard(flashSales[i]))),
    ]);
  }

  Widget _buildSectionHeader(String title, VoidCallback onTap){
    return Padding(padding: const EdgeInsets.symmetric(horizontal:16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize:16)), GestureDetector(onTap: onTap, child: const Row(children: [Text('Voir tout', style: TextStyle(color: MarketColors.red, fontSize:12, fontWeight: FontWeight.w800)), SizedBox(width:4), Icon(Icons.arrow_forward_ios_rounded, size:10, color: MarketColors.red)]))]));
  }

  Widget _buildProductHorizontalCard(Map<String,dynamic> p){
    final price = _parsePrice(p['discount_price']??p['price']);
    return GestureDetector(onTap: ()=> context.push('/market/product/${p['id']}'), child: Container(width:155, decoration: BoxDecoration(color: MarketColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: MarketColors.red.withValues(alpha:0.25)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.03), blurRadius:10, offset: const Offset(0,4))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(flex:5, child: Stack(fit: StackFit.expand, children: [ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: _networkImage(p['image_url'])), Positioned(top:8,left:8, child: Container(padding: const EdgeInsets.symmetric(horizontal:8,vertical:4), decoration: BoxDecoration(color: MarketColors.red, borderRadius: BorderRadius.circular(8)), child: Text('-${p['discount_percent']??0}%', style: const TextStyle(color: Colors.white, fontSize:10, fontWeight: FontWeight.w900)))), Positioned(top:4,right:4, child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: WishlistButton(productId: p['id'].toString(), size:20)))])),
      Expanded(flex:5, child: Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p['title']??'', maxLines:2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize:12, fontWeight: FontWeight.w700, height:1.2)), const Spacer(), Row(children: [const Icon(Icons.storefront_rounded, size:11, color: MarketColors.mutedText), const SizedBox(width:3), Expanded(child: Text(_shopName(p), maxLines:1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize:9.5, color: MarketColors.mutedText)))]), Text('${price.toInt()} FC', style: const TextStyle(fontWeight: FontWeight.w900, fontSize:15, color: MarketColors.red))])))
    ])));
  }

  Widget _buildProductCard(Map<String,dynamic> p){
    final price = _parsePrice(p['discount_price']??p['price']);
    final orig = _parsePrice(p['price']);
    final hasDisc = p['discount_price']!=null && price<orig;
    return GestureDetector(onTap: ()=> context.push('/market/product/${p['id']}'), child: Container(decoration: BoxDecoration(color: MarketColors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: MarketColors.cardBorder), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.03), blurRadius:10, offset: const Offset(0,4))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(flex:5, child: Stack(fit: StackFit.expand, children: [ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(18)), child: _networkImage(p['image_url'])), if(hasDisc) Positioned(top:8,left:8, child: Container(padding: const EdgeInsets.symmetric(horizontal:6,vertical:4), decoration: BoxDecoration(color: MarketColors.red, borderRadius: BorderRadius.circular(8)), child: Text('-${((1-price/orig)*100).round()}%', style: const TextStyle(color: Colors.white, fontSize:10, fontWeight: FontWeight.w900)))), Positioned(top:6,right:6, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: WishlistButton(productId: p['id'].toString(), size:20)))])),
      Expanded(flex:5, child: Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p['title']??'', maxLines:2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize:12, fontWeight: FontWeight.w700, height:1.2)), const SizedBox(height:3), Row(children: [const Icon(Icons.storefront_rounded, size:11, color: MarketColors.mutedText), const SizedBox(width:3), Expanded(child: Text(_shopName(p), maxLines:1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize:9.5, color: MarketColors.mutedText)))]), Row(children: [const Icon(Icons.location_on_outlined, size:11, color: MarketColors.mutedText), const SizedBox(width:3), Expanded(child: Text(_location(p), maxLines:1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize:9.5, color: MarketColors.mutedText)))]), const Spacer(), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if(hasDisc) Text('${orig.toInt()} FC', style: const TextStyle(decoration: TextDecoration.lineThrough, fontSize:10, color: MarketColors.mutedText)), Text('${price.toInt()} FC', style: const TextStyle(fontWeight: FontWeight.w900, fontSize:14, color: MarketColors.red))]), Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: MarketColors.creamBg, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.add_shopping_cart_rounded, size:16, color: MarketColors.red))])]))),
    ])));
  }

  Widget _buildBottomNavBar(){
    return Container(color: MarketColors.white, padding: const EdgeInsets.only(top:6), child: SafeArea(top:false, child: SizedBox(height:64, child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _navItem(Icons.home_rounded,'Accueil',0), _navItem(Icons.receipt_long_rounded,'Commandes',1), const SizedBox(width:60), _navItem(Icons.favorite_rounded,'Wishlist',3), _navItem(Icons.notifications_active_rounded,'Alertes',4),
      ]),
      Positioned(top:-20, child: GestureDetector(onTap: ()=> context.push('/market/cart'), child: Container(width:60,height:60, alignment: Alignment.center, decoration: BoxDecoration(color: MarketColors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width:4), boxShadow: [BoxShadow(color: MarketColors.red.withValues(alpha:0.4), blurRadius:14, offset: const Offset(0,6))]), child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size:26))))
    ]))));
  }

  Widget _navItem(IconData icon, String label, int index){
    final sel = _selectedNavIndex==index;
    return GestureDetector(onTap: (){ setState(()=> _selectedNavIndex=index); HapticFeedback.lightImpact(); if(index==1) context.push('/market/orders'); if(index==3) context.push('/market/wishlist'); if(index==4) context.push('/market/price-alerts'); if(index==0) _scrollController.animateTo(0, duration: const Duration(milliseconds:400), curve: Curves.easeOut); }, child: Container(width:65, padding: const EdgeInsets.symmetric(vertical:4), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: sel?MarketColors.red:MarketColors.mutedText, size:24), const SizedBox(height:2), Text(label, maxLines:1, style: TextStyle(fontSize:10, color: sel?MarketColors.red:MarketColors.mutedText, fontWeight: sel?FontWeight.w800:FontWeight.w500))])) );
  }
}
