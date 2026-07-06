// lib/presentation/thix_market/vendor/vendor_dashboard.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/shop_provider.dart';
import '../providers/sell_provider.dart';

class VendorDashboard extends StatefulWidget {
  const VendorDashboard({super.key});

  @override
  State<VendorDashboard> createState() => _VendorDashboardState();
}

class _VendorDashboardState extends State<VendorDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShopProvider>().loadMyShops();
      context.read<SellProvider>().loadOrders();
      context.read<SellProvider>().loadMyAnnouncements();
    });
  }

  @override
  Widget build(BuildContext context) {
    final shopProvider = context.watch<ShopProvider>();
    final sellProvider = context.watch<SellProvider>();

    final hasShop = shopProvider.myShops.isNotEmpty;
    final shop = hasShop ? shopProvider.myShops.first : null;
    final orders = sellProvider.orders;
    final pendingOrders = orders.where((o) => o['status'] == 'pending').toList();
    final totalProducts = sellProvider.announcements.length;
    final totalSales = orders.length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Espace vendeur'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              shopProvider.loadMyShops();
              sellProvider.loadOrders();
              sellProvider.loadMyAnnouncements();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            shopProvider.loadMyShops(),
            sellProvider.loadOrders(),
            sellProvider.loadMyAnnouncements(),
          ]);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête boutique
              _buildShopHeader(shop, hasShop, context),
              const SizedBox(height: 24),

              // KPIs
              _buildKpiGrid(totalSales, pendingOrders.length, totalProducts, shop?['rating'] ?? 0),
              const SizedBox(height: 24),

              // Grille des actions
              _buildActionGrid(context, hasShop),
              const SizedBox(height: 24),

              // Dernières commandes
              _buildRecentOrders(orders),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShopHeader(Map<String, dynamic>? shop, bool hasShop, BuildContext context) {
    if (!hasShop) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
        ),
        child: Row(
          children: [
            const Icon(Icons.store, size: 40, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Vous n’avez pas encore de boutique',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  const Text('Créez votre boutique pour commencer à vendre',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => context.push('/market/shop/create'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A73E8)),
                    child: const Text('Créer une boutique'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: shop['logo_url'] != null
                ? NetworkImage(shop['logo_url'])
                : null,
            child: shop['logo_url'] == null
                ? const Icon(Icons.store, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shop['name'] ?? 'Ma boutique',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${shop['city'] ?? 'Ville non renseignée'}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => context.push('/market/shop/${shop['id']}/manage'),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(int totalSales, int pendingOrders, int totalProducts, double rating) {
    final kpis = [
      {'label': 'Ventes', 'value': '$totalSales', 'icon': Icons.trending_up, 'color': Colors.green},
      {'label': 'Commandes en attente', 'value': '$pendingOrders', 'icon': Icons.pending, 'color': Colors.orange},
      {'label': 'Produits', 'value': '$totalProducts', 'icon': Icons.inventory_2, 'color': Colors.blue},
      {'label': 'Note moyenne', 'value': rating.toStringAsFixed(1), 'icon': Icons.star, 'color': Colors.amber},
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (kpi['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(kpi['icon'] as IconData, color: kpi['color'] as Color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(kpi['value'] as String,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(kpi['label'] as String,
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionGrid(BuildContext context, bool hasShop) {
    final actions = [
      {'icon': Icons.store, 'label': 'Ma boutique', 'route': '/market/shops'},
      {'icon': Icons.inventory_2, 'label': 'Produits', 'route': '/market/sell'},
      {'icon': Icons.shopping_bag, 'label': 'Commandes', 'route': '/market/sell?tab=orders'},
      {'icon': Icons.announcement, 'label': 'Publier une annonce', 'route': '/market/announcement/publish'},
      {'icon': Icons.live_tv, 'label': 'Lives', 'route': '/market/live/create'},
      {'icon': Icons.bar_chart, 'label': 'Statistiques', 'route': '/market/sell?tab=stats'},
      {'icon': Icons.local_shipping, 'label': 'Livraisons', 'route': '/market/deliveries'},
      {'icon': Icons.settings, 'label': 'Paramètres', 'route': '/market/settings'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Actions rapides', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.2,
          children: actions.map((action) {
            return InkWell(
              onTap: () => context.push(action['route'] as String),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(action['icon'] as IconData, size: 28, color: const Color(0xFF1A73E8)),
                    const SizedBox(height: 4),
                    Text(action['label'] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecentOrders(List<Map<String, dynamic>> orders) {
    final recent = orders.take(5).toList();
    if (recent.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text('Aucune commande récente', style: TextStyle(color: Colors.grey))),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Dernières commandes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            TextButton(
              onPressed: () => context.push('/market/sell?tab=orders'),
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recent.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final order = recent[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: order['status'] == 'pending' ? Colors.orange : Colors.green,
                radius: 12,
                child: Icon(
                  order['status'] == 'pending' ? Icons.pending : Icons.check,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              title: Text('Commande #${order['id']}'),
              subtitle: Text('${order['total']?.toInt() ?? 0} FCFA - ${order['date'] ?? ''}'),
              trailing: Text(order['status'] ?? '', style: const TextStyle(fontSize: 12)),
            );
          },
        ),
      ],
    );
  }
}
