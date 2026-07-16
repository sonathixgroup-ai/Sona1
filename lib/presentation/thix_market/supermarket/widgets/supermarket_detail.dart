// lib/presentation/thix_market/supermarket/supermarket_detail.dart
// UI exacte capture milieu: Header vert, Search, Offer 30%, Categories, Fresh Products
// Prod: CachedNetworkImage, pagination, realtime stock

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'providers/supermarket_provider.dart';

class SupermarketDetail extends StatefulWidget {
  final String shopId;
  const SupermarketDetail({super.key, required this.shopId});
  @override State<SupermarketDetail> createState()=>_SupermarketDetailState();
}

class _SupermarketDetailState extends State<SupermarketDetail> {
  @override void initState(){ super.initState(); Future.microtask(()=> context.read<SupermarketProvider>().loadShopDetail(widget.shopId)); }

  @override Widget build(BuildContext context){
    final prov = context.watch<SupermarketProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F5),
      body: CustomScrollView(
        slivers: [
          // HEADER VERT GRADIENT comme capture
          SliverAppBar(
            expandedHeight: 165, pinned: true, backgroundColor: const Color(0xFF5AB16C),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: LinearGradient(colors:[Color(0xFF7BC67E), Color(0xFF4AA85F)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                child: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(16,12,16,0), child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
                  Row(children:[ const CircleAvatar(radius:16, backgroundImage: NetworkImage('https://i.pravatar.cc/100')), const SizedBox(width:8), Column(crossAxisAlignment:CrossAxisAlignment.start, children:[ Text('Morning, Hannah', style: TextStyle(color: Colors.white.withOpacity(.9), fontSize:12)), const Text('What would you buy today?', style: TextStyle(color: Colors.white, fontWeight:FontWeight.w800, fontSize:13))]), const Spacer(), Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.shopping_bag_outlined, size:18, color: Color(0xFF4AA85F)))])]),
                  const SizedBox(height:14),
                  // Bannière offre 30% comme capture
                  Container(
                    height: 88, padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow:[BoxShadow(color: Colors.black.withOpacity(.08), blurRadius:10)]),
                    child: Row(children:[
                      Expanded(child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[ const Text('Enjoy The Special', style: TextStyle(fontWeight:FontWeight.w900, fontSize:14)), const Text('Offer Up To 30%', style: TextStyle(fontWeight:FontWeight.w900, fontSize:14, color:Color(0xFF2E7D32))), const SizedBox(height:4), Text('From 14th June, 2025', style: TextStyle(color: Colors.grey[600], fontSize:10)), Container(margin: const EdgeInsets.only(top:6), height:3, width:60, decoration: BoxDecoration(color: const Color(0xFF4AA85F), borderRadius: BorderRadius.circular(10)))])),
                      Image.network('https://cdn-icons-png.flaticon.com/512/3081/3081840.png', width:68, errorBuilder:(_,__,___)=> const Icon(Icons.shopping_basket, size:40, color: Colors.orange)),
                    ]),
                  ),
                ]))),
              ),
            ),
          ),
          // SEARCH + CATEGORIES + PRODUCTS
          SliverToBoxAdapter(
            child: prov.isLoadingDetail? const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())) : Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
              const SizedBox(height:12),
              // Search bar
              Padding(padding: const EdgeInsets.symmetric(horizontal:16), child: Container(height:44, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFEFEFEF))), child: Row(children:[ const SizedBox(width:12), const Icon(Icons.search, color: Colors.grey, size:20), const SizedBox(width:8), const Expanded(child: Text('Search vegetables, fruits and more', style: TextStyle(color: Colors.grey, fontSize:12))), Container(margin: const EdgeInsets.only(right:8), padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.tune, size:16))]))),
              const SizedBox(height:18),
              // Categories titre
              Padding(padding: const EdgeInsets.symmetric(horizontal:16), child: Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[ const Text('Categories', style: TextStyle(fontWeight:FontWeight.w900, fontSize:15)), Text('See all', style: TextStyle(color: Colors.grey[500], fontSize:12, fontWeight:FontWeight.w600))])),
              const SizedBox(height:12),
              SizedBox(height:72, child: ListView.separated(padding: const EdgeInsets.symmetric(horizontal:16), scrollDirection: Axis.horizontal, itemCount: prov.aisles.length, separatorBuilder:(_,__)=> const SizedBox(width:14), itemBuilder:(_,i){
                final a=prov.aisles[i]; final active=prov.selectedAisle==a['name'];
                return GestureDetector(onTap: ()=> prov.setAisle(a['name']), child: Column(children:[ Container(width:52,height:52, decoration: BoxDecoration(color: active? const Color(0xFF4AA85F) : const Color(0xFFF1F5F0), shape: BoxShape.circle, border: Border.all(color: active? const Color(0xFF4AA85F) : Colors.transparent)), child: Icon(_iconFor(a['name']), color: active? Colors.white : const Color(0xFF6B8A6E), size:22)), const SizedBox(height:6), Text(a['name'], style: TextStyle(fontSize:11, fontWeight: active? FontWeight.w800 : FontWeight.w600, color: active? const Color(0xFF2E7D32) : Colors.black87))]));
              })),
              const SizedBox(height:18),
              Padding(padding: const EdgeInsets.symmetric(horizontal:16), child: Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[ const Text('Fresh Products', style: TextStyle(fontWeight:FontWeight.w900, fontSize:15)), Text('See all', style: TextStyle(color: Colors.grey[500], fontSize:12))])),
              const SizedBox(height:12),
              // Grille produits Fresh
              Padding(padding: const EdgeInsets.symmetric(horizontal:12), child: GridView.builder(shrinkWrap:true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2, childAspectRatio:.72, crossAxisSpacing:10, mainAxisSpacing:10), itemCount: prov.filteredProducts.length, itemBuilder:(_,i){
                final p=prov.filteredProducts[i]; final qty=prov.cartQty[p['id']]??0;
                return _ProductCardFresh(product:p, qty:qty, onAdd:()=> prov.add(p['id'],1), onRemove:()=> prov.add(p['id'],-1), onTap:()=> context.pushNamed('supermarketProduct', pathParameters:{'productId':p['id']}, extra:p));
              })),
              const SizedBox(height:100),
            ]),
          ),
        ],
      ),
      // Bottom nav comme capture
      bottomNavigationBar: BottomNavigationBar(selectedItemColor: const Color(0xFF4AA85F), unselectedItemColor: Colors.grey, showUnselectedLabels:true, type: BottomNavigationBarType.fixed, items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label:'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.local_offer_outlined), label:'Promo'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_basket), label:''), // centre vert
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label:'Message'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label:'Account'),
      ]),
      floatingActionButton: FloatingActionButton(onPressed:()=> context.pushNamed('supermarketCart', pathParameters:{'shopId':widget.shopId}), backgroundColor: const Color(0xFF4AA85F), child: Badge(label: Text('${context.watch<SupermarketProvider>().totalItems}'), child: const Icon(Icons.shopping_bag, color: Colors.white))),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
  IconData _iconFor(String n){ final l=n.toLowerCase(); if(l.contains('fruit')) return Icons.apple_rounded; if(l.contains('frais')||l.contains('fresh')) return Icons.eco_rounded; if(l.contains('snack')) return Icons.cookie_rounded; if(l.contains('grocery')) return Icons.shopping_cart_rounded; return Icons.category_rounded; }
}

// Carte produit verte 10% comme capture milieu
class _ProductCardFresh extends StatelessWidget {
  final Map<String,dynamic> product; final int qty; final VoidCallback onAdd, onRemove, onTap;
  const _ProductCardFresh({required this.product, required this.qty, required this.onAdd, required this.onRemove, required this.onTap});
  @override Widget build(BuildContext context){
    final price=(product['price']??0) as int;
    return GestureDetector(onTap:onTap, child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEFF3EF))), child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
      Stack(children:[ ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: CachedNetworkImage(imageUrl: product['image_url']??'', height:110, width:double.infinity, fit:BoxFit.cover, placeholder:(_,__)=> Container(color: const Color(0xFFF5F5F5)), errorWidget:(_,__,___)=> const Icon(Icons.image))), Positioned(top:8,right:8, child: Container(padding: const EdgeInsets.symmetric(horizontal:6,vertical:2), decoration: BoxDecoration(color: const Color(0xFFD6F5DB), borderRadius: BorderRadius.circular(8)), child: const Text('10%', style: TextStyle(fontSize:10,fontWeight:FontWeight.w800,color: Color(0xFF2E7D32))))) ]),
      Padding(padding: const EdgeInsets.fromLTRB(10,8,10,8), child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
        Text(product['title']??'', maxLines:1, overflow:TextOverflow.ellipsis, style: const TextStyle(fontWeight:FontWeight.w700,fontSize:12.5)),
        const SizedBox(height:2),
        Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[
          Column(crossAxisAlignment:CrossAxisAlignment.start, children:[ Text('\$$price /bunch', style: const TextStyle(fontWeight:FontWeight.w800,fontSize:12,color: Color(0xFF2E7D32))), Text('${product['unit']??'1 Bunch'}', style: TextStyle(fontSize:10,color: Colors.grey[500]))]),
          qty==0? InkWell(onTap:onAdd, child: Container(width:26,height:26,decoration: const BoxDecoration(color: Color(0xFF4AA85F), shape: BoxShape.circle), child: const Icon(Icons.add, color: Colors.white, size:16))): Container(decoration: BoxDecoration(color: const Color(0xFFF0F7F0), borderRadius: BorderRadius.circular(20)), child: Row(children:[ InkWell(onTap:onRemove, child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.remove, size:14))), Padding(padding: const EdgeInsets.symmetric(horizontal:4), child: Text('$qty', style: const TextStyle(fontWeight:FontWeight.w800,fontSize:12))), InkWell(onTap:onAdd, child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.add, size:14)))])),
        ]),
      ]),
    ])));
  }
}
