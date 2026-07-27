import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/market_providers.dart';
import '../cart/cart_provider.dart';

// CHARTE
class _MarketColors {
  static const red = Color(0xFFD81E2C);
  static const gold = Color(0xFFF0A93B);
  static const lightBg = Color(0xFFF7F7FA);
  static const pureWhite = Color(0xFFFFFFFF);
  static const darkText = Color(0xFF1A1A1A);
  static const mutedText = Color(0xFF8A8A8F);
  static const cardBorder = Color(0xFFF0F0F0);
  static const creamBg = Color(0xFFFCEFDA);
}

// PROVIDERS PROD
class ComparatorNotifier extends StateNotifier<List<String>> {
  ComparatorNotifier(): super([]);
  void add(String id){ if(!state.contains(id)) state = [...state, id]; }
  void remove(String id)=> state = state.where((e)=> e!=id).toList();
  void clear()=> state = [];
  bool contains(String id)=> state.contains(id);
}
final comparatorIdsProvider = StateNotifierProvider<ComparatorNotifier, List<String>>((ref)=> ComparatorNotifier());

final comparatorProductsProvider = FutureProvider<List<Map<String,dynamic>>>((ref) async {
  final ids = ref.watch(comparatorIdsProvider);
  if(ids.isEmpty) return [];
  final db = ref.read(supabaseClientProvider);
  final res = await db.from('products').select('*, shop:shops(name)').inFilter('id', ids);
  return List<Map<String,dynamic>>.from(res);
});

class ProductComparatorPage extends ConsumerWidget {
  const ProductComparatorPage({super.key});

  @override Widget build(BuildContext context, WidgetRef ref){
    final ids = ref.watch(comparatorIdsProvider);
    final productsAsync = ref.watch(comparatorProductsProvider);

    return Scaffold(
      backgroundColor: _MarketColors.lightBg,
      appBar: AppBar(
        backgroundColor: _MarketColors.pureWhite,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _MarketColors.darkText),
        title: const Text('Comparateur B2B', style: TextStyle(color: _MarketColors.darkText, fontWeight: FontWeight.w900, fontSize: 18)),
        actions: [
          if(ids.isNotEmpty) TextButton(onPressed: ()=> ref.read(comparatorIdsProvider.notifier).clear(), child: const Text('Vider', style: TextStyle(color: _MarketColors.red))),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: _MarketColors.cardBorder, height: 1)),
      ),
      body: productsAsync.when(
        loading: ()=> const Center(child: CircularProgressIndicator(color: _MarketColors.red)),
        error: (e,_ )=> Center(child: Text('Erreur $e')),
        data: (products){
          if(products.length<2) return _empty(context, products);
          return _table(context, ref, products);
        },
      ),
    );
  }

  Widget _empty(BuildContext context, List<Map<String,dynamic>> products){
    final hasOne = products.length==1;
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(24), decoration: const BoxDecoration(color: _MarketColors.creamBg, shape: BoxShape.circle), child: const Icon(Icons.compare_arrows_rounded, size: 64, color: _MarketColors.gold)),
      const SizedBox(height: 24),
      Text(hasOne? 'Ajoutez un autre produit' : 'Comparateur vide', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _MarketColors.darkText)),
      const SizedBox(height: 8),
      Text(hasOne? 'Il vous faut au moins 2 produits.' : 'Sélectionnez des produits et cliquez sur comparer.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: _MarketColors.mutedText, height: 1.4)),
      const SizedBox(height: 32),
      ElevatedButton(onPressed: ()=> context.go('/market/home'), style: ElevatedButton.styleFrom(backgroundColor: _MarketColors.red, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), elevation: 0), child: const Text('Explorer le marché', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
    ])));
  }

  Widget _table(BuildContext context, WidgetRef ref, List<Map<String,dynamic>> products){
    final features = [
      {'label': 'Prix', 'key': 'price'},
      {'label': 'Marque', 'key': 'brand'},
      {'label': 'Évaluation', 'key': 'rating'},
      {'label': 'État', 'key': 'condition'},
      {'label': 'Livraison', 'key': 'delivery'},
      {'label': 'Stock', 'key': 'stock'},
    ];
    return SingleChildScrollView(child: Column(children: [
      Container(color: _MarketColors.pureWhite, padding: const EdgeInsets.symmetric(vertical: 20), child: Row(children: [
        const SizedBox(width: 80),
       ...products.map((p)=> Expanded(child: _header(context, ref, p))),
      ])),
      const Divider(height: 1, color: _MarketColors.cardBorder),
     ...features.map((f)=> _row(f, products)),
      const SizedBox(height: 30),
    ]));
  }

  Widget _header(BuildContext context, WidgetRef ref, Map<String,dynamic> product){
    String img = '';
    if(product['image_url']!=null) img = product['image_url'].toString();
    String title = product['title']!=null? product['title'].toString() : 'Produit';
    String id = product['id'].toString();
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Column(children: [
      Stack(alignment: Alignment.topRight, children: [
        ClipRRect(borderRadius: BorderRadius.circular(12), child: Container(width: double.infinity, height: 100, color: _MarketColors.lightBg, child: img.isEmpty? const Icon(Icons.image_not_supported_outlined, color: _MarketColors.mutedText) : CachedNetworkImage(imageUrl: img, fit: BoxFit.contain, placeholder: (a,b)=> const Center(child: CircularProgressIndicator(strokeWidth: 2)), errorWidget: (a,b,c)=> const Icon(Icons.image_not_supported_outlined)))),
        GestureDetector(onTap: ()=> ref.read(comparatorIdsProvider.notifier).remove(id), child: Container(margin: const EdgeInsets.all(4), padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]), child: const Icon(Icons.close_rounded, size: 14, color: _MarketColors.red))),
      ]),
      const SizedBox(height: 12),
      Text(title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, height: 1.2)),
      const SizedBox(height: 12),
      ElevatedButton(onPressed: () async {
        final db = ref.read(supabaseClientProvider);
        final uid = db.auth.currentUser?.id;
        if(uid==null){ context.push('/login'); return; }
        try{
          await db.from('cart').insert({'user_id': uid, 'product_id': id, 'quantity': 1});
          ref.invalidate(cartProvider);
          if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ajouté au panier!')));
        }catch(e){ debugPrint('$e'); }
      }, style: ElevatedButton.styleFrom(backgroundColor: _MarketColors.red, minimumSize: const Size(double.infinity, 32), padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0), child: const Icon(Icons.shopping_cart_checkout_rounded, color: Colors.white, size: 16)),
    ]));
  }

  Widget _row(Map<String,String> feature, List<Map<String,dynamic>> products){
    return Container(decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _MarketColors.cardBorder))), padding: const EdgeInsets.symmetric(vertical: 16), child: Row(children: [
      SizedBox(width: 80, child: Padding(padding: const EdgeInsets.only(left: 12), child: Text(feature['label']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _MarketColors.mutedText)))),
     ...products.map((p){
        final key = feature['key']!;
        String val = '-';
        if(p[key]!=null) val = p[key].toString();
        if(key=='price') val = '${p[key]??0} ${p['currency']??'FC'}';
        if(key=='rating') val = p[key]!=null? '⭐ $val' : '-';
        return Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(val, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: key=='price'? FontWeight.w900 : FontWeight.w600, color: key=='price'? _MarketColors.red : _MarketColors.darkText))));
      }),
    ]));
  }
}
