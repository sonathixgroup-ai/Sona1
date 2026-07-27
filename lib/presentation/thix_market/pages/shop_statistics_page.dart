import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/market_providers.dart';

// ============================================================
// CHARTE THIX — Navy / Or
// ============================================================
const _navyDeep = Color(0xFF0A1F44);
const _navy = Color(0xFF123B7A);
const _gold = Color(0xFFE3B23C);
const _bg = Color(0xFFF6F7FB);
const _white = Colors.white;
const _muted = Color(0xFF8A8FA3);
const _hair = Color(0xFFE7EAF3);

// ============================================================
// MODEL
// ============================================================
class ShopStats {
  final int revenue;
  final int orders;
  final int products;
  final int followers;
  final double rating;
  final List<Map<String, dynamic>> salesByDay; // [{day, total}]
  final List<Map<String, dynamic>> topProducts;
  ShopStats({required this.revenue, required this.orders, required this.products, required this.followers, required this.rating, required this.salesByDay, required this.topProducts});
}

// ============================================================
// PROVIDER STATS
// ============================================================
final shopStatsProvider = FutureProvider.family<ShopStats, String>((ref, shopId) async {
  final db = ref.read(supabaseClientProvider);

  // 1. Produits de la boutique
  final productsRes = await db.from('products').select('id, title, image_url, price, sold_count').eq('shop_id', shopId);
  final products = List<Map<String,dynamic>>.from(productsRes);

  // 2. Commandes liées aux produits de la boutique
  final productIds = products.map((p)=> p['id']).toList();
  int revenue = 0;
  int orders = 0;
  List<Map<String,dynamic>> salesByDay = [];

  if (productIds.isNotEmpty) {
    // total commandes + revenu
    final ordersRes = await db.from('order_items').select('quantity, price, created_at').inFilter('product_id', productIds);
    final orderItems = List<Map<String,dynamic>>.from(ordersRes);
    orders = orderItems.length;
    revenue = orderItems.fold(0, (sum, e)=> sum + ((e['price'] as num?)?.toInt()??0) * ((e['quantity'] as num?)?.toInt()??1));

    // group by day last 7 jours (client side pour éviter RPC)
    final Map<String,int> byDay = {};
    for (var i=6; i>=0; i--) {
      final d = DateTime.now().subtract(Duration(days: i));
      final key = '${d.day}/${d.month}';
      byDay[key]=0;
    }
    for (final o in orderItems) {
      final dt = DateTime.tryParse(o['created_at']??'')?? DateTime.now();
      final key = '${dt.day}/${dt.month}';
      if (byDay.containsKey(key)) byDay[key] = byDay[key]! + ((o['price'] as num?)?.toInt()??0);
    }
    salesByDay = byDay.entries.map((e)=> {'day': e.key, 'total': e.value}).toList();
  } else {
    salesByDay = List.generate(7, (i){
      final d = DateTime.now().subtract(Duration(days: 6-i));
      return {'day': '${d.day}/${d.month}', 'total': 0};
    });
  }

  // 3. Followers
  final followersRes = await db.from('shop_followers').select('id').eq('shop_id', shopId).count();
  final followers = followersRes.count;

  // 4. Rating boutique
  final shopRes = await db.from('shops').select('rating').eq('id', shopId).maybeSingle();
  final rating = (shopRes?['rating'] as num?)?.toDouble()?? 0.0;

  // 5. Top produits triés par sold_count
  products.sort((a,b)=> ((b['sold_count'] as num?)?.toInt()??0).compareTo((a['sold_count'] as num?)?.toInt()??0));
  final top = products.take(5).toList();

  return ShopStats(revenue: revenue, orders: orders, products: products.length, followers: followers, rating: rating, salesByDay: salesByDay, topProducts: top);
});

class ShopStatisticsPage extends ConsumerWidget {
  final String shopId;
  const ShopStatisticsPage({super.key, required this.shopId});

  @override Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(shopStatsProvider(shopId));

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _navyDeep,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Statistiques boutique', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded, size: 20), onPressed: ()=> ref.invalidate(shopStatsProvider(shopId)))],
      ),
      body: async.when(
        loading: ()=> const Center(child: CircularProgressIndicator(color: _gold)),
        error: (e,_ )=> Center(child: Text('Erreur $e')),
        data: (s)=> RefreshIndicator(
          color: _gold,
          onRefresh: () async => ref.invalidate(shopStatsProvider(shopId)),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // METRICS GRID
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _metricCard('Revenu total', '${_formatMoney(s.revenue)} FCFA', Icons.payments_rounded, _navyDeep),
                  _metricCard('Commandes', '${s.orders}', Icons.receipt_long_rounded, _navy),
                  _metricCard('Produits', '${s.products}', Icons.inventory_2_rounded, _navy),
                  _metricCard('Abonnés', _formatNumber(s.followers), Icons.favorite_rounded, const Color(0xFFD64545), sub: '${s.rating.toStringAsFixed(1)} ★'),
                ],
              ),
              const SizedBox(height: 20),

              // SALES CHART
              _sectionTitle('Ventes 7 derniers jours'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.fromLTRB(16,16,16,8),
                decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _hair)),
                child: SizedBox(height: 160, child: _SalesBarChart(data: s.salesByDay)),
              ),
              const SizedBox(height: 20),

              _sectionTitle('Top produits'),
              const SizedBox(height: 10),
              if(s.topProducts.isEmpty)
                Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _hair)), child: const Center(child: Text('Aucune vente', style: TextStyle(color: _muted)))),
              else
               ...s.topProducts.map((p)=> Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _hair)),
                  child: ListTile(
                    leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: (p['image_url'] as String?)==null? Container(width: 44,height: 44,color: _bg,child: const Icon(Icons.image, color: _muted)) : Image.network(p['image_url'], width: 44,height: 44, fit: BoxFit.cover, errorBuilder: (_,__,___)=> Container(width:44,height:44,color:_bg,child: const Icon(Icons.broken_image_outlined)))),
                    title: Text(p['title']??'Produit', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    subtitle: Text('${p['sold_count']??0} vendus • ${p['price']??0} FCFA', style: const TextStyle(fontSize: 11.5, color: _muted)),
                    trailing: const Icon(Icons.trending_up_rounded, color: _gold, size: 18),
                  ),
                )),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color, {String? sub}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _hair), boxShadow: [BoxShadow(color: _navyDeep.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0,4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 14, color: color)), const Spacer(), if(sub!=null) Text(sub, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color))]),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1A1D29))),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: _muted, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _sectionTitle(String t)=> Text(t, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF1A1D29)));

  String _formatMoney(int n){
    if(n>=1000000) return '${(n/1000000).toStringAsFixed(1)}M';
    if(n>=1000) return '${(n/1000).toStringAsFixed(0)}k';
    return n.toString();
  }
  String _formatNumber(int n){
    if(n>=1000000) return '${(n/1000000).toStringAsFixed(1)}M';
    if(n>=1000) return '${(n/1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

class _SalesBarChart extends StatelessWidget {
  final List<Map<String,dynamic>> data;
  const _SalesBarChart({required this.data});

  @override Widget build(BuildContext context) {
    final maxVal = data.map((e)=> e['total'] as int).fold(0, (a,b)=> a>b? a:b);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((d){
        final total = d['total'] as int;
        final h = maxVal==0? 0.15 : (total / maxVal).clamp(0.15, 1.0);
        return Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(children: [
            Expanded(child: Align(alignment: Alignment.bottomCenter, child: Container(height: 120*h, decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_navy, _navyDeep]), borderRadius: BorderRadius.circular(8))))),
            const SizedBox(height: 6),
            Text(d['day'], style: const TextStyle(fontSize: 10, color: _muted, fontWeight: FontWeight.w600)),
          ]),
        ));
      }).toList(),
    );
  }
}
