// lib/presentation/thix_market/vendor/vendor_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/shop_provider.dart';
import '../providers/market_providers.dart';

// ============================================================
// PROVIDERS PROD (Corrigés pour utiliser shop_id au lieu de seller_id)
// ============================================================
final vendorOrdersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = ref.read(supabaseClientProvider);
  final uid = db.auth.currentUser?.id;
  if (uid == null) return [];

  // 1. On récupère d'abord les boutiques de l'utilisateur connecté
  final shopsRes = await db.from('shops').select('id').eq('owner_id', uid);
  final shops = List<Map<String, dynamic>>.from(shopsRes);
  if (shops.isEmpty) return [];

  final shopIds = shops.map((s) => s['id']).toList();

  // 2. On récupère les commandes liées aux boutiques du vendeur (via shop_id)
  final res = await db.from('orders')
      .select('id, total, status, created_at')
      .inFilter('shop_id', shopIds)
      .order('created_at', ascending: false)
      .limit(50);
      
  return List<Map<String, dynamic>>.from(res);
});

final vendorAnnouncementsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = ref.read(supabaseClientProvider);
  final uid = db.auth.currentUser?.id;
  if (uid == null) return [];
  final res = await db.from('products').select('id').eq('owner_id', uid);
  return List<Map<String, dynamic>>.from(res);
});

class VendorDashboard extends ConsumerStatefulWidget {
  const VendorDashboard({super.key});
  @override ConsumerState<VendorDashboard> createState() => _VendorDashboardState();
}

class _VendorDashboardState extends ConsumerState<VendorDashboard> {
  @override void initState() {
    super.initState();
    Future.microtask(() {
      ref.invalidate(myShopsProvider);
      ref.invalidate(vendorOrdersProvider);
      ref.invalidate(vendorAnnouncementsProvider);
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(myShopsProvider);
    ref.invalidate(vendorOrdersProvider);
    ref.invalidate(vendorAnnouncementsProvider);
    await Future.wait([
      ref.read(myShopsProvider.future),
      ref.read(vendorOrdersProvider.future),
      ref.read(vendorAnnouncementsProvider.future),
    ]);
  }

  @override Widget build(BuildContext context) {
    final shopsAsync = ref.watch(myShopsProvider);
    final ordersAsync = ref.watch(vendorOrdersProvider);
    final annAsync = ref.watch(vendorAnnouncementsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Espace vendeur', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _refresh),
        ],
      ),
      body: shopsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1A73E8))),
        error: (e, _) => Center(child: Text('Erreur $e')),
        data: (shops) {
          final hasShop = shops.isNotEmpty;
          final shop = hasShop ? shops.first : null;
          return ordersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1A73E8))),
            error: (e, _) => Center(child: Text('Erreur commandes $e')),
            data: (orders) {
              final announcements = annAsync.valueOrNull ?? [];
              final pending = orders.where((o) => o['status'] == 'pending').length;
              final rating = (shop?['rating'] as num?)?.toDouble() ?? 0.0;
              return RefreshIndicator(
                color: const Color(0xFF1A73E8),
                onRefresh: _refresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    hasShop ? _shopHeader(shop!, context) : _noShopHeader(context),
                    const SizedBox(height: 24),
                    _kpiGrid(orders.length, pending, announcements.length, rating),
                    const SizedBox(height: 24),
                    _actionGrid(context, hasShop),
                    const SizedBox(height: 24),
                    _recentOrders(orders, context),
                    const SizedBox(height: 80),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _noShopHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
      child: Row(children: [
        const Icon(Icons.store, size: 40, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Vous n’avez pas encore de boutique', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          const Text('Créez votre boutique pour commencer à vendre', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: () => context.pushNamed('marketCreateShop'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A73E8)), child: const Text('Créer une boutique', style: TextStyle(color: Colors.white))),
        ])),
      ]),
    );
  }

  Widget _shopHeader(Map<String, dynamic> shop, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)]), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        CircleAvatar(radius: 30, backgroundColor: Colors.white, backgroundImage: shop['logo_url'] != null && (shop['logo_url'] as String).isNotEmpty ? NetworkImage(shop['logo_url']) : null, child: shop['logo_url'] == null ? const Icon(Icons.store, color: Colors.white) : null),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(shop['name'] ?? 'Ma boutique', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(shop['city'] ?? 'Ville non renseignée', style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ])),
        IconButton(icon: const Icon(Icons.edit, color: Colors.white), onPressed: () => context.pushNamed('marketManageShop', pathParameters: {'shopId': shop['id'].toString()})),
      ]),
    );
  }

  Widget _kpiGrid(int totalSales, int pendingOrders, int totalProducts, double rating) {
    final kpis = [
      {'label': 'Ventes', 'value': '$totalSales', 'icon': Icons.trending_up, 'color': Colors.green},
      {'label': 'En attente', 'value': '$pendingOrders', 'icon': Icons.pending, 'color': Colors.orange},
      {'label': 'Produits', 'value': '$totalProducts', 'icon': Icons.inventory_2, 'color': Colors.blue},
      {'label': 'Note', 'value': rating.toStringAsFixed(1), 'icon': Icons.star, 'color': Colors.amber},
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: kpis.map((kpi) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: (kpi['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(kpi['icon'] as IconData, color: kpi['color'] as Color)),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(kpi['value'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(kpi['label'] as String, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ])),
          ]),
        );
      }).toList(),
    );
  }

  Widget _actionGrid(BuildContext context, bool hasShop) {
    final actions = [
      {'icon': Icons.store, 'label': 'Ma boutique', 'onTap': () => context.pushNamed('marketShops')},
      {'icon': Icons.inventory_2, 'label': 'Produits', 'onTap': () => context.pushNamed('marketSell')},
      {'icon': Icons.shopping_bag, 'label': 'Commandes', 'onTap': () => context.pushNamed('marketSell', queryParameters: {'tab': 'orders'})},
      {'icon': Icons.announcement, 'label': 'Annonce', 'onTap': () => context.pushNamed('marketPublishAnnouncement')},
      {'icon': Icons.live_tv, 'label': 'Lives', 'onTap': () => context.pushNamed('marketCreateLive')},
      {'icon': Icons.bar_chart, 'label': 'Stats', 'onTap': () {
        final shopId = ref.read(myShopsProvider).valueOrNull?.first?['id'];
        if(shopId != null) context.push('/market/shop/$shopId/stats');
      }},
      {'icon': Icons.local_shipping, 'label': 'Livraisons', 'onTap': () => context.pushNamed('deliveryManagement')},
      {'icon': Icons.settings, 'label': 'Paramètres', 'onTap': () => context.pushNamed('marketSettings')},
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Actions rapides', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 12),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.1,
        children: actions.map((a) {
          return InkWell(
            onTap: (){
              if(!hasShop && a['label'] != 'Ma boutique' && a['label'] != 'Paramètres'){
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez créer une boutique d\'abord.')));
                return;
              }
              (a['onTap'] as VoidCallback)();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(a['icon'] as IconData, size: 26, color: const Color(0xFF1A73E8)),
                const SizedBox(height: 4),
                Text(a['label'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
              ]),
            ),
          );
        }).toList(),
      ),
    ]);
  }

  Widget _recentOrders(List<Map<String, dynamic>> orders, BuildContext context){
    final recent = orders.take(5).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Dernières commandes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        TextButton(onPressed: ()=> context.pushNamed('marketSell', queryParameters: {'tab': 'orders'}), child: const Text('Voir tout')),
      ]),
      const SizedBox(height: 8),
      recent.isEmpty ? Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: const Center(child: Text('Aucune commande récente', style: TextStyle(color: Colors.grey)))) :
      ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recent.length,
        separatorBuilder: (_, __)=> const Divider(height: 1),
        itemBuilder: (c,i){
          final o = recent[i];
          final isPending = o['status'] == 'pending';
          return ListTile(
            leading: CircleAvatar(backgroundColor: isPending ? Colors.orange : Colors.green, radius: 12, child: Icon(isPending ? Icons.pending : Icons.check, color: Colors.white, size: 14)),
            title: Text('Commande #${o['id'].toString().substring(0,8)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: Text('${(o['total'] as num?)?.toInt() ?? 0} FCFA', style: const TextStyle(fontSize: 12)),
            trailing: Text(o['status'] ?? '', style: TextStyle(fontSize: 11, color: isPending ? Colors.orange : Colors.green, fontWeight: FontWeight.w600)),
          );
        },
      ),
    ]);
  }
}
