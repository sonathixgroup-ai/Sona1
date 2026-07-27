import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import '../providers/market_providers.dart';
import '../widgets/products/product_card.dart';
import '../checkout/checkout_page.dart';

// CHARTE
class _MarketColors {
  static const redDark = Color(0xFF5C0E12);
  static const red = Color(0xFFD81E2C);
  static const gold = Color(0xFFF0A93B);
  static const lightBg = Color(0xFFF7F7FA);
  static const pureWhite = Color(0xFFFFFFFF);
  static const darkText = Color(0xFF1A1A1A);
  static const mutedText = Color(0xFF8A8A8F);
  static const cardBorder = Color(0xFFF0F0F0);
  static const successGreen = Color(0xFF00B074);
}

final productDetailProvider = FutureProvider.family<Map<String,dynamic>, String>((ref, productId) async {
  final db = ref.read(supabaseClientProvider);
  final prod = await db.from('products').select().eq('id', productId).maybeSingle();
  if(prod==null) throw Exception('Produit introuvable');
  Map<String,dynamic> shop = {};
  if(prod['shop_id']!=null){
    final s = await db.from('shops').select().eq('id', prod['shop_id']).maybeSingle();
    if(s!=null) shop = s;
  }
  List<Map<String,dynamic>> reviews = [];
  try{
    final r = await db.from('reviews').select('*, user:users(name, avatar)').eq('product_id', productId).order('created_at', ascending: false).limit(20);
    reviews = List<Map<String,dynamic>>.from(r);
  }catch(_){}
  double rating = 0;
  if(reviews.isNotEmpty){
    double sum = 0;
    for(final rev in reviews){ sum += (rev['rating'] as num).toDouble(); }
    rating = sum / reviews.length;
  }
  return {...prod, 'shop': shop, 'reviews': reviews, 'reviews_count': reviews.length, 'rating': rating};
});

final similarProductsProvider = FutureProvider.family<List<Map<String,dynamic>>, Map<String,String>>((ref, params) async {
  final db = ref.read(supabaseClientProvider);
  final res = await db.from('products').select('*, shop:shops(name, city)').eq('category', params['category']!).neq('id', params['id']!).limit(10);
  return List<Map<String,dynamic>>.from(res);
});

final isFavoriteProvider = FutureProvider.family<bool, String>((ref, productId) async {
  final db = ref.read(supabaseClientProvider);
  final uid = db.auth.currentUser?.id;
  if(uid==null) return false;
  final res = await db.from('wishlist').select().match({'user_id': uid, 'product_id': productId}).maybeSingle();
  return res!=null;
});

class ProductDetailPage extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailPage({super.key, required this.productId});
  @override ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  int qty = 1;
  String? variant;
  String? colorSel;
  bool adding = false;
  int imgIndex = 0;

  Future<void> toggleFav(bool currentlyFav) async {
    final db = ref.read(supabaseClientProvider);
    final uid = db.auth.currentUser?.id;
    if(uid==null){ ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez vous connecter'))); return; }
    try{
      if(!currentlyFav){
        await db.from('wishlist').insert({'user_id': uid, 'product_id': widget.productId});
      } else {
        await db.from('wishlist').delete().match({'user_id': uid, 'product_id': widget.productId});
      }
      ref.invalidate(isFavoriteProvider(widget.productId));
      ref.invalidate(favoritesProvider);
    }catch(e){ debugPrint('fav $e'); }
  }

  Future<void> addToCart() async {
    final db = ref.read(supabaseClientProvider);
    final uid = db.auth.currentUser?.id;
    if(uid==null){ ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez vous connecter'))); return; }
    setState(()=> adding=true);
    try{
      final existing = await db.from('cart').select().match({'user_id': uid, 'product_id': widget.productId}).maybeSingle();
      if(existing!=null){
        int cur = 0;
        if(existing['quantity']!=null) cur = (existing['quantity'] as num).toInt();
        await db.from('cart').update({'quantity': cur + qty}).eq('id', existing['id']);
      } else {
        await db.from('cart').insert({'user_id': uid, 'product_id': widget.productId, 'quantity': qty, 'variant': variant, 'color': colorSel});
      }
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ajouté au panier!'), backgroundColor: _MarketColors.successGreen));
      ref.invalidate(cartProvider);
    }catch(e){
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur $e'), backgroundColor: _MarketColors.red));
    }finally{ if(mounted) setState(()=> adding=false); }
  }

  Future<void> buyNow(int stock) async {
    if(stock<=0){ ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rupture de stock'))); return; }
    await addToCart();
    if(mounted){
      try{ context.push('/market/checkout'); }catch(_){ Navigator.push(context, MaterialPageRoute(builder: (_)=> const CheckoutPage())); }
    }
  }

  void openChat(Map<String,dynamic> product){
    final shop = product['shop'] as Map<String,dynamic>?;
    final shopId = product['shop_id'];
    if(shopId==null){ ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Boutique indisponible'))); return; }
    String name = 'Vendeur';
    String? avatar;
    if(shop!=null){ if(shop['name']!=null) name = shop['name'].toString(); if(shop['logo_url']!=null) avatar = shop['logo_url'].toString(); }
    context.push('/market/chat/$shopId', extra: {'title': name, 'userName': name, 'userAvatar': avatar});
  }

  @override Widget build(BuildContext context){
    final detailAsync = ref.watch(productDetailProvider(widget.productId));
    final favAsync = ref.watch(isFavoriteProvider(widget.productId));

    return detailAsync.when(
      loading: ()=> const Scaffold(backgroundColor: _MarketColors.pureWhite, body: Center(child: CircularProgressIndicator(color: _MarketColors.red))),
      error: (e,_ )=> Scaffold(appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: ()=> context.pop())), body: Center(child: Text('Erreur $e'))),
      data: (product){
        final imagesRaw = product['images'] as List?;
        List<String> images = [];
        if(imagesRaw!=null && imagesRaw.isNotEmpty) images = imagesRaw.map((e)=> e.toString()).toList();
        else if(product['image_url']!=null) images = [product['image_url'].toString()];
        else images = [''];
        bool hasDiscount = product['discount_price']!=null && (product['discount_price'] as num) < (product['price'] as num);
        String currency = product['currency']!=null? product['currency'].toString() : 'CDF';
        String symbol = currency=='USD'? '\$' : 'FC';
        int stock = 0;
        if(product['stock']!=null) stock = (product['stock'] as num).toInt();
        bool available = stock>0;
                List variants = [];
        if(product['variants'] is List) variants = product['variants'] as List;
        List colors = [];
        if(product['colors'] is List) colors = product['colors'] as List;
        List reviews = [];
        if(product['reviews'] is List) reviews = product['reviews'] as List;
        bool isFav = favAsync.valueOrNull?? false;

        return Scaffold(
          backgroundColor: _MarketColors.lightBg,
          body: CustomScrollView(slivers: [
            SliverAppBar(
              expandedHeight: 380,
              pinned: true,
              backgroundColor: _MarketColors.pureWhite,
              leading: Padding(padding: const EdgeInsets.all(8), child: _circleBtn(Icons.arrow_back_rounded, ()=> context.pop())),
              actions: [
                Padding(padding: const EdgeInsets.all(8), child: _circleBtn(isFav? Icons.favorite_rounded : Icons.favorite_border_rounded, ()=> toggleFav(isFav), color: isFav? _MarketColors.red : _MarketColors.darkText)),
                Padding(padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8), child: _circleBtn(Icons.share_rounded, (){})),
              ],
              flexibleSpace: FlexibleSpaceBar(background: Stack(children: [
                Container(color: _MarketColors.pureWhite),
                CarouselSlider(options: CarouselOptions(height: 400, viewportFraction: 1, enableInfiniteScroll: images.length>1, onPageChanged: (i,_ )=> setState(()=> imgIndex=i)), items: images.map((img)=> CachedNetworkImage(imageUrl: img, fit: BoxFit.contain, width: double.infinity, placeholder: (a,b)=> const Center(child: CircularProgressIndicator(color: _MarketColors.red)), errorWidget: (a,b,c)=> const Center(child: Icon(Icons.broken_image_rounded, size: 50, color: _MarketColors.mutedText)))).toList()),
                if(images.length>1) Positioned(bottom: 24, left: 0, right: 0, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: images.asMap().entries.map((e){ final active = imgIndex==e.key; return AnimatedContainer(duration: const Duration(milliseconds: 250), width: active? 24 : 8, height: 6, margin: const EdgeInsets.symmetric(horizontal: 4), decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: active? _MarketColors.red : _MarketColors.cardBorder)); }).toList())),
              ])),
            ),
            SliverToBoxAdapter(child: Transform.translate(offset: const Offset(0,-20), child: Container(decoration: const BoxDecoration(color: _MarketColors.lightBg, borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 8),
              _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(product['title']!=null? product['title'].toString() : '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _MarketColors.darkText, height: 1.2)),
                const SizedBox(height: 12),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('${(hasDiscount? product['discount_price'] : product['price']).toString()} $symbol', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: _MarketColors.red)),
                  if(hasDiscount) Padding(padding: const EdgeInsets.only(left: 10, bottom: 4), child: Text('${product['price'].toString()} $symbol', style: const TextStyle(fontSize: 14, decoration: TextDecoration.lineThrough, color: _MarketColors.mutedText, fontWeight: FontWeight.w700))),
                ]),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [
                    RatingBar.builder(initialRating: (product['rating'] as num).toDouble(), minRating: 1, direction: Axis.horizontal, allowHalfRating: true, itemCount: 5, itemSize: 16, ignoreGestures: true, itemBuilder: (a,b)=> const Icon(Icons.star_rounded, color: _MarketColors.gold), onRatingUpdate: (_){}),
                    const SizedBox(width: 8),
                    Text('${product['reviews_count']} avis', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ]),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: available? _MarketColors.successGreen.withOpacity(0.1) : _MarketColors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(available? 'En stock ($stock)' : 'Rupture', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: available? _MarketColors.successGreen : _MarketColors.red))),
                ]),
              ])),
              _card(child: Row(children: [
                const Text('Quantité', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                const Spacer(),
                Container(decoration: BoxDecoration(color: _MarketColors.lightBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: _MarketColors.cardBorder)), child: Row(mainAxisSize: MainAxisSize.min, children: [
                  _qtyBtn(Icons.remove_rounded, (){ if(qty>1) setState(()=> qty--); }),
                  SizedBox(width: 40, child: Center(child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.w900)))),
                  _qtyBtn(Icons.add_rounded, (){ if(qty<stock) setState(()=> qty++); }),
                ])),
              ])),
              if(variants.isNotEmpty || colors.isNotEmpty) _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if(variants.isNotEmpty) _buildVariants(variants),
                if(variants.isNotEmpty && colors.isNotEmpty) const SizedBox(height: 16),
                if(colors.isNotEmpty) _buildColors(colors),
              ])),
              _card(child: InkWell(onTap: ()=> context.push('/market/shop/${product['shop_id']}'), child: Row(children: [
                CircleAvatar(radius: 27, backgroundImage: (product['shop']?['logo_url']!=null)? CachedNetworkImageProvider(product['shop']['logo_url'].toString()) : null, backgroundColor: _MarketColors.lightBg, child: product['shop']?['logo_url']==null? const Icon(Icons.storefront_rounded) : null),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(product['shop']?['name']!=null? product['shop']['name'].toString() : 'Boutique Partenaire', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  const Text('Voir les articles', style: TextStyle(color: _MarketColors.mutedText, fontSize: 12, fontWeight: FontWeight.w600)),
                ])),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              ]))),
              _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                Text(product['description']!=null? product['description'].toString() : '', style: const TextStyle(height: 1.5, color: _MarketColors.mutedText, fontSize: 13, fontWeight: FontWeight.w500)),
              ])),
              if(reviews.isNotEmpty) _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Avis clients', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)), GestureDetector(onTap: ()=> _showAllReviews(reviews), child: const Text('Voir tout', style: TextStyle(color: _MarketColors.red, fontWeight: FontWeight.w800, fontSize: 13)))]),
                const SizedBox(height: 16),
               ...reviews.take(3).map((r)=> _reviewCard(r)),
              ])),
              Consumer(builder: (c, ref, _){
                final cat = product['category']!=null? product['category'].toString() : '';
                final simAsync = ref.watch(similarProductsProvider({'category': cat, 'id': widget.productId}));
                return simAsync.when(loading: ()=> const SizedBox(), error: (e,_ )=> const SizedBox(), data: (sim){
                  if(sim.isEmpty) return const SizedBox();
                  return Container(color: _MarketColors.pureWhite, padding: const EdgeInsets.symmetric(vertical: 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Vous pourriez aussi aimer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900))),
                    const SizedBox(height: 16),
                    SizedBox(height: 260, child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), scrollDirection: Axis.horizontal, itemCount: sim.length, itemBuilder: (ctx, idx){ final p = sim[idx]; return Container(width: 160, margin: const EdgeInsets.only(right: 12), child: ProductCard(product: p, onTap: (_)=> context.push('/market/product/${p['id']}'))); })),
                  ]));
                });
              }),
              const SizedBox(height: 110),
            ])))),
          ]),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(16,12,16,24),
            decoration: BoxDecoration(color: _MarketColors.pureWhite, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0,-5))]),
            child: SafeArea(top: false, child: Row(children: [
              Container(decoration: BoxDecoration(color: _MarketColors.lightBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _MarketColors.cardBorder)), child: IconButton(icon: const Icon(Icons.chat_bubble_outline_rounded), onPressed: ()=> openChat(product))),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton(onPressed: available &&!adding? addToCart : null, style: OutlinedButton.styleFrom(side: const BorderSide(color: _MarketColors.red, width: 2), foregroundColor: _MarketColors.red, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: adding? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: _MarketColors.red, strokeWidth: 2)) : const Icon(Icons.add_shopping_cart_rounded))),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: Container(decoration: BoxDecoration(gradient: const LinearGradient(colors: [_MarketColors.redDark, _MarketColors.red]), borderRadius: BorderRadius.circular(16)), child: ElevatedButton(onPressed: available &&!adding? ()=> buyNow(stock) : null, style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text('Acheter', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.white))))),
            ])),
          ),
        );
      },
    );
  }

  Widget _card({required Widget child})=> Container(margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: _MarketColors.pureWhite, borderRadius: BorderRadius.circular(20), border: Border.all(color: _MarketColors.cardBorder), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0,4))]), child: child);
  Widget _circleBtn(IconData icon, VoidCallback onTap, {Color color=_MarketColors.darkText})=> InkWell(borderRadius: BorderRadius.circular(20), onTap: onTap, child: Container(width: 40, height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: _MarketColors.pureWhite.withOpacity(0.9), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)]), child: Icon(icon, color: color, size: 20)));
  Widget _qtyBtn(IconData icon, VoidCallback onTap)=> InkWell(borderRadius: BorderRadius.circular(30), onTap: onTap, child: Container(width: 36, height: 36, alignment: Alignment.center, child: Icon(icon, size: 18)));
  Widget _buildVariants(List list)=> Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Taille / Modèle', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 12), Wrap(spacing: 10, runSpacing: 10, children: list.map((v){ final label = v is String? v : v['name'].toString(); final sel = variant==label; return _chip(label, sel, ()=> setState(()=> variant = sel? null : label)); }).toList())]);
  Widget _buildColors(List list)=> Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Couleurs', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 12), Wrap(spacing: 10, runSpacing: 10, children: list.map((c){ final label = c is String? c : c['name'].toString(); final sel = colorSel==label; return _chip(label, sel, ()=> setState(()=> colorSel = sel? null : label)); }).toList())]);
  Widget _chip(String label, bool sel, VoidCallback onTap)=> InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: sel? _MarketColors.red : _MarketColors.lightBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: sel? _MarketColors.red : _MarketColors.cardBorder)), child: Text(label, style: TextStyle(fontWeight: sel? FontWeight.w900 : FontWeight.w600, fontSize: 13, color: sel? Colors.white : _MarketColors.darkText))));
  Widget _reviewCard(Map<String,dynamic> review){
    final user = review['user'] as Map?;
    String name = 'Client vérifié';
    String? avatar;
    if(user!=null){ if(user['name']!=null) name = user['name'].toString(); if(user['avatar']!=null) avatar = user['avatar'].toString(); }
    double rating = 0;
    if(review['rating']!=null) rating = (review['rating'] as num).toDouble();
    String comment = review['comment']!=null? review['comment'].toString() : '';
    String date = '';
    if(review['created_at']!=null){ try{ date = DateFormat('dd/MM/yyyy').format(DateTime.parse(review['created_at'].toString())); }catch(_){} }
    return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: _MarketColors.lightBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _MarketColors.cardBorder)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        CircleAvatar(radius: 18, backgroundImage: avatar!=null? CachedNetworkImageProvider(avatar) : null, backgroundColor: _MarketColors.cardBorder, child: avatar==null? const Icon(Icons.person_rounded, size: 18, color: _MarketColors.mutedText) : null),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          const SizedBox(height: 4),
          RatingBar.builder(initialRating: rating, minRating: 1, direction: Axis.horizontal, allowHalfRating: true, itemCount: 5, itemSize: 12, ignoreGestures: true, itemBuilder: (a,b)=> const Icon(Icons.star_rounded, color: _MarketColors.gold), onRatingUpdate: (_){}),
        ])),
        Text(date, style: const TextStyle(fontSize: 11, color: _MarketColors.mutedText)),
      ]),
      if(comment.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(comment, style: const TextStyle(height: 1.5, fontSize: 13))),
    ]));
  }
  void _showAllReviews(List reviews){
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_)=> Container(decoration: const BoxDecoration(color: _MarketColors.pureWhite, borderRadius: BorderRadius.vertical(top: Radius.circular(24))), padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), child: DraggableScrollableSheet(initialChildSize: 0.9, minChildSize: 0.5, maxChildSize: 0.95, expand: false, builder: (c, ctrl){ return Column(children: [
      Padding(padding: const EdgeInsets.all(20), child: Row(children: [const Text('Tous les avis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), const Spacer(), InkWell(onTap: ()=> Navigator.pop(context), child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: _MarketColors.lightBg, shape: BoxShape.circle), child: const Icon(Icons.close_rounded, size: 18)))])),
      Expanded(child: ListView.builder(controller: ctrl, padding: const EdgeInsets.symmetric(horizontal: 20), itemCount: reviews.length, itemBuilder: (a,i)=> _reviewCard(reviews[i]))),
    ]); })));
  }
}
