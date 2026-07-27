import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/shop_provider.dart';

class ShopDetailPage extends ConsumerStatefulWidget {
  final String shopId;
  const ShopDetailPage({super.key, required this.shopId});
  @override ConsumerState<ShopDetailPage> createState() => _ShopDetailPageState();
}

class _ShopDetailPageState extends ConsumerState<ShopDetailPage> {
  static const navy = Color(0xFF1B2A4A);
  static const navyDeep = Color(0xFF10192E);
  static const gold = Color(0xFFC9962C);
  static const bgApp = Color(0xFFF6F7FB);
  static const textMuted = Color(0xFF8A8FA3);
  static const textDark = Color(0xFF1A1D29);
  static const danger = Color(0xFFE53935);

  @override void initState() {
    super.initState();
    Future.microtask(()=> ref.read(currentShopProvider.notifier).load(widget.shopId));
  }

  @override Widget build(BuildContext context) {
    final async = ref.watch(currentShopProvider);

    return async.when(
      loading: ()=> Scaffold(backgroundColor: bgApp, appBar: AppBar(title: const Text('Boutique'), backgroundColor: Colors.white, elevation: 0), body: const Center(child: CircularProgressIndicator(color: gold))),
      error: (e,_ )=> Scaffold(backgroundColor: bgApp, appBar: AppBar(title: const Text('Boutique'), backgroundColor: Colors.white), body: Center(child: Text('Erreur $e'))),
      data: (shop){
        if(shop==null){
          return Scaffold(
            backgroundColor: bgApp,
            appBar: AppBar(title: const Text('Boutique'), backgroundColor: Colors.white, elevation: 0),
            body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.store, size: 72, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              const Text('Boutique introuvable', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: textDark)),
              const SizedBox(height: 8),
              const Text('Cette boutique n\'existe pas ou a été supprimée', style: TextStyle(color: textMuted, fontSize: 13)),
              const SizedBox(height: 22),
              ElevatedButton(onPressed: ()=> context.pop(), style: ElevatedButton.styleFrom(backgroundColor: gold, foregroundColor: navyDeep, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12)), child: const Text('Retour', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
            ])),
          );
        }

        final products = List<Map<String,dynamic>>.from(shop['products']?? []);
        final isActive = shop['status']=='active';
        final isVerified = shop['is_verified']==true;
        final isLive = shop['is_live']==true || shop['live_status']=='live';
        final isFollowed = shop['is_followed']==true;
        final logo = shop['logo_url'] as String?;

        return Scaffold(
          backgroundColor: bgApp,
          appBar: AppBar(
            title: Text(shop['name']??'Boutique', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19, color: textDark)),
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.white,
            actions: [
              IconButton(icon: Icon(isFollowed? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isFollowed? danger : textMuted), onPressed: ()=> ref.read(currentShopProvider.notifier).toggleFollow(shop['id'])),
              IconButton(icon: const Icon(Icons.share_rounded, color: textMuted), onPressed: ()=> ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Partage à venir')))),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: isLive? Border.all(color: danger.withValues(alpha: 0.4), width: 1.4) : null, boxShadow: [BoxShadow(color: navy.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0,6))]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if(isLive) Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: danger, borderRadius: BorderRadius.circular(6)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.fiber_manual_record, size: 8, color: Colors.white), SizedBox(width: 4), Text('EN DIRECT MAINTENANT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.4))])),
                  Row(children: [
                    Stack(children: [
                      Container(
                        width: 70,height: 70,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: bgApp, border: Border.all(color: isLive? danger.withValues(alpha: 0.5) : Colors.grey.shade200, width: isLive?1.5:1)),
                        child: logo==null || logo.isEmpty? const Icon(Icons.store_rounded, size: 32, color: textMuted) : ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(logo, fit: BoxFit.cover, errorBuilder: (_,__,___)=> const Icon(Icons.store_rounded, size: 32, color: textMuted))),
                      ),
                      if(isVerified) Positioned(bottom: -2,right: -2, child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.verified_rounded, size: 18, color: navy))),
                      if(!isActive) Positioned(top: 0,right: 0, child: Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: BoxDecoration(color: danger, borderRadius: BorderRadius.circular(6)), child: const Text('Inactif', style: TextStyle(color: Colors.white, fontSize: 8.5)))),
                    ]),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [Expanded(child: Text(shop['name']??'Boutique', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textDark), maxLines: 1, overflow: TextOverflow.ellipsis)), if(isVerified) const Icon(Icons.verified_rounded, size: 18, color: navy)]),
                      const SizedBox(height: 4),
                      if(shop['city']!=null) Row(children: [const Icon(Icons.location_on_rounded, size: 14, color: textMuted), const SizedBox(width: 4), Text(shop['city'], style: const TextStyle(color: textMuted, fontSize: 13))]),
                      const SizedBox(height: 6),
                      Row(children: [const Icon(Icons.shopping_bag_outlined, size: 14, color: textMuted), const SizedBox(width: 4), Text('${products.length} produits', style: const TextStyle(color: textMuted, fontSize: 12)), const SizedBox(width: 14), const Icon(Icons.favorite_rounded, size: 14, color: textMuted), const SizedBox(width: 4), Text(_formatNumber((shop['followers'] as num?)?.toInt()??0), style: const TextStyle(color: textMuted, fontSize: 12))]),
                    ])),
                  ]),
                  if(shop['description']!=null && (shop['description'] as String).isNotEmpty)...[const SizedBox(height: 10), Text(shop['description'], style: const TextStyle(color: textMuted, fontSize: 13, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis)],
                ]),
              ),
              const SizedBox(height: 16),
              Row(children: [const Text('Produits de la boutique', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: textDark)), const Spacer(), TextButton(onPressed: ()=> context.push('/market/search?shop=${shop['id']}'), style: TextButton.styleFrom(padding: EdgeInsets.zero), child: const Row(children: [Text('Voir tout', style: TextStyle(color: gold, fontWeight: FontWeight.w700, fontSize: 11.5)), Icon(Icons.chevron_right_rounded, size: 15, color: gold)]))]),
              const SizedBox(height: 8),
              if(products.isEmpty)
                Container(padding: const EdgeInsets.all(32), alignment: Alignment.center, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: navy.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0,4))]), child: Column(children: [Icon(Icons.inventory_2_rounded, size: 48, color: Colors.grey.shade300), const SizedBox(height: 8), const Text('Aucun produit disponible', style: TextStyle(color: textMuted, fontSize: 13))])),
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.7),
                  itemCount: products.length>6?6:products.length,
                  itemBuilder: (_, index){
                    final p = products[index];
                    final img = (p['image_url'] as String?) ?? (p['images'] is List && (p['images'] as List).isNotEmpty? p['images'][0] : null);
                    final currency = p['currency']??'FC';
                    final hasDiscount = p['discount_price']!=null && (p['discount_price'] as num) < (p['price'] as num);
                    final price = ((hasDiscount? p['discount_price'] : p['price']) as num).toDouble();
                    return GestureDetector(
                      onTap: ()=> context.push('/market/product/${p['id']}'),
                      child: Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: navy.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0,6))]),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: img==null? Container(color: bgApp, child: const Icon(Icons.image_rounded, color: Colors.grey)) : Image.network(img, fit: BoxFit.cover, width: double.infinity, errorBuilder: (_,__,___)=> Container(color: bgApp, child: const Icon(Icons.image_rounded, color: Colors.grey))))),
                          Padding(padding: const EdgeInsets.all(8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(p['title']??'', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5, color: textDark)),
                            const SizedBox(height: 2),
                            Row(children: [Text('${price.toInt()} $currency', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: navy)), if(hasDiscount) Padding(padding: const EdgeInsets.only(left: 4), child: Text('${(p['price'] as num).toInt()} $currency', style: const TextStyle(decoration: TextDecoration.lineThrough, fontSize: 9, color: textMuted)))]),
                          ])),
                        ]),
                      ),
                    );
                  },
                ),
              if(products.length>6)...[const SizedBox(height: 8), Center(child: TextButton(onPressed: ()=> context.push('/market/search?shop=${shop['id']}'), child: Text('Voir les ${products.length} produits', style: const TextStyle(color: gold, fontWeight: FontWeight.w600))))],
              const SizedBox(height: 20),
            ]),
          ),
        );
      },
    );
  }

  String _formatNumber(int num){
    if(num>=1000000) return '${(num/1000000).toStringAsFixed(1)}M';
    if(num>=1000) return '${(num/1000).toStringAsFixed(1)}k';
    return num.toString();
  }
}
