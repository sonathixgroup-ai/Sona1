// lib/presentation/thix_market/vendor/vendor_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/shop_provider.dart';
import '../providers/market_providers.dart';

// ============================================================
// PROVIDERS (réels via shop_id)
// ============================================================
final vendorOrdersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = ref.read(supabaseClientProvider);
  final uid = db.auth.currentUser?.id;
  if (uid == null) return [];

  final shopsRes = await db.from('shops').select('id').eq('owner_id', uid);
  final shops = List<Map<String, dynamic>>.from(shopsRes);
  if (shops.isEmpty) return [];

  final shopIds = shops.map((s) => s['id']).toList();

  final res = await db
      .from('orders')
      .select('id, total, status, payment_status, created_at, currency')
      .inFilter('shop_id', shopIds)
      .order('created_at', ascending: false)
      .limit(50);

  return List<Map<String, dynamic>>.from(res);
});

final vendorProductsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = ref.read(supabaseClientProvider);
  final uid = db.auth.currentUser?.id;
  if (uid == null) return [];

  final shopsRes = await db.from('shops').select('id').eq('owner_id', uid);
  final shops = List<Map<String, dynamic>>.from(shopsRes);
  if (shops.isEmpty) return [];

  final shopIds = shops.map((s) => s['id']).toList();

  final res = await db
      .from('products')
      .select('id, title, price, status, stock')
      .inFilter('shop_id', shopIds)
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(res);
});

// ============================================================
// PAGE
// ============================================================
class VendorDashboard extends ConsumerStatefulWidget {
  const VendorDashboard({super.key});

  @override
  ConsumerState<VendorDashboard> createState() => _VendorDashboardState();
}

class _VendorDashboardState extends ConsumerState<VendorDashboard> {
  static const primary = Color(0xFF1A73E8);
  static const bg = Color(0xFFF6F7FB);

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.invalidate(myShopsProvider);
      ref.invalidate(vendorOrdersProvider);
      ref.invalidate(vendorProductsProvider);
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(myShopsProvider);
    ref.invalidate(vendorOrdersProvider);
    ref.invalidate(vendorProductsProvider);
    await Future.wait([
      ref.read(myShopsProvider.future),
      ref.read(vendorOrdersProvider.future),
      ref.read(vendorProductsProvider.future),
    ]);
  }

  String _statusLabel(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'pending':
        return 'En attente';
      case 'processing':
        return 'En cours';
      case 'shipped':
        return 'Expédiée';
      case 'delivered':
        return 'Livrée';
      case 'cancelled':
        return 'Annulée';
      default:
        return status ?? '-';
    }
  }

  Color _statusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return primary;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopsAsync = ref.watch(myShopsProvider);
    final ordersAsync = ref.watch(vendorOrdersProvider);
    final productsAsync = ref.watch(vendorProductsProvider);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text(
          'Espace vendeur',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
          ),
        ],
      ),
      body: shopsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: primary)),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (shops) {
          final hasShop = shops.isNotEmpty;
          final shop = hasShop ? shops.first : null;

          return ordersAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator(color: primary)),
            error: (e, _) => Center(child: Text('Erreur commandes : $e')),
            data: (orders) {
              final products = productsAsync.valueOrNull ?? [];
              final pending =
                  orders.where((o) => o['status'] == 'pending').length;
              final processing =
                  orders.where((o) => o['status'] == 'processing').length;
              final rating = (shop?['rating'] as num?)?.toDouble() ?? 0.0;

              return RefreshIndicator(
                color: primary,
                onRefresh: _refresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      hasShop
                          ? _shopHeader(shop!, context)
                          : _noShopHeader(context),
                      const SizedBox(height: 20),
                      if (hasShop) ...[
                        _kpiGrid(
                          ordersCount: orders.length,
                          pending: pending,
                          processing: processing,
                          productsCount: products.length,
                          rating: rating,
                        ),
                        const SizedBox(height: 24),
                      ],
                      _actionGrid(context, hasShop, shop),
                      const SizedBox(height: 24),
                      if (hasShop) _recentOrders(orders, context),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ----------------------------------------------------------
  // HEADER SANS BOUTIQUE
  // ----------------------------------------------------------
  Widget _noShopHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.storefront_rounded, size: 40, color: primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Créez votre boutique',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pour vendre sur THIX Market, créez d\'abord votre boutique.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => context.pushNamed('marketCreateShop'),
              icon: const Icon(Icons.add_business_rounded),
              label: const Text(
                'Créer une boutique',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // HEADER BOUTIQUE
  // ----------------------------------------------------------
  Widget _shopHeader(Map<String, dynamic> shop, BuildContext context) {
    final logo = shop['logo_url']?.toString() ?? '';
    final name = shop['name']?.toString() ?? 'Ma boutique';
    final city = shop['city']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            backgroundImage:
                logo.isNotEmpty ? NetworkImage(logo) : null,
            child: logo.isEmpty
                ? const Icon(Icons.store, color: primary, size: 28)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (city.isNotEmpty)
                  Text(
                    city,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Colors.white),
            onPressed: () => context.pushNamed(
              'marketManageShop',
              pathParameters: {'shopId': shop['id'].toString()},
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // KPI (données réelles uniquement)
  // ----------------------------------------------------------
  Widget _kpiGrid({
    required int ordersCount,
    required int pending,
    required int processing,
    required int productsCount,
    required double rating,
  }) {
    final kpis = [
      {
        'label': 'Commandes',
        'value': '$ordersCount',
        'icon': Icons.shopping_bag_outlined,
        'color': primary,
      },
      {
        'label': 'En attente',
        'value': '$pending',
        'icon': Icons.pending_actions_rounded,
        'color': Colors.orange,
      },
      {
        'label': 'Produits',
        'value': '$productsCount',
        'icon': Icons.inventory_2_outlined,
        'color': Colors.teal,
      },
      {
        'label': 'Note',
        'value': rating > 0 ? rating.toStringAsFixed(1) : '-',
        'icon': Icons.star_rounded,
        'color': Colors.amber.shade700,
      },
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: kpis.map((kpi) {
        final color = kpi['color'] as Color;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(kpi['icon'] as IconData, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      kpi['value'] as String,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      kpi['label'] as String,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ----------------------------------------------------------
  // ACTIONS RAPIDES
  // ----------------------------------------------------------
  Widget _actionGrid(
    BuildContext context,
    bool hasShop,
    Map<String, dynamic>? shop,
  ) {
    final shopId = shop?['id']?.toString();

    final actions = <Map<String, dynamic>>[
      {
        'icon': Icons.inventory_2_outlined,
        'label': 'Produits',
        'onTap': () => context.pushNamed('marketSell'),
        'needShop': true,
      },
      {
        'icon': Icons.shopping_bag_outlined,
        'label': 'Commandes',
        'onTap': () {
          // Page dédiée si disponible, sinon sell avec tab
          try {
            context.push('/market/vendor/orders');
          } catch (_) {
            context.pushNamed('marketSell', queryParameters: {'tab': 'orders'});
          }
        },
        'needShop': true,
      },
      {
        'icon': Icons.add_box_outlined,
        'label': 'Annonce',
        'onTap': () => context.pushNamed('marketPublishAnnouncement'),
        'needShop': true,
      },
      {
        'icon': Icons.live_tv_outlined,
        'label': 'Live',
        'onTap': () => context.pushNamed('marketCreateLive'),
        'needShop': true,
      },
      {
        'icon': Icons.bar_chart_rounded,
        'label': 'Stats',
        'onTap': () {
          if (shopId != null) {
            context.push('/market/shop/$shopId/stats');
          }
        },
        'needShop': true,
      },
      {
        'icon': Icons.local_shipping_outlined,
        'label': 'Livraisons',
        'onTap': () => context.pushNamed('deliveryManagement'),
        'needShop': true,
      },
      {
        'icon': Icons.storefront_outlined,
        'label': 'Boutique',
        'onTap': () {
          if (shopId != null) {
            context.pushNamed(
              'marketManageShop',
              pathParameters: {'shopId': shopId},
            );
          } else {
            context.pushNamed('marketCreateShop');
          }
        },
        'needShop': false,
      },
      {
        'icon': Icons.settings_outlined,
        'label': 'Réglages',
        'onTap': () {
          if (shopId != null) {
            context.pushNamed(
              'marketManageShop',
              pathParameters: {'shopId': shopId},
            );
          }
        },
        'needShop': true,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions rapides',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.95,
          children: actions.map((a) {
            return InkWell(
              onTap: () {
                final needShop = a['needShop'] == true;
                if (needShop && !hasShop) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Créez d\'abord une boutique'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                (a['onTap'] as VoidCallback)();
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      a['icon'] as IconData,
                      size: 26,
                      color: primary,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      a['label'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // DERNIÈRES COMMANDES (réelles)
  // ----------------------------------------------------------
  Widget _recentOrders(
    List<Map<String, dynamic>> orders,
    BuildContext context,
  ) {
    final recent = orders.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Dernières commandes',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            TextButton(
              onPressed: () {
                try {
                  context.push('/market/vendor/orders');
                } catch (_) {
                  context.pushNamed(
                    'marketSell',
                    queryParameters: {'tab': 'orders'},
                  );
                }
              },
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (recent.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text(
                'Aucune commande pour le moment',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recent.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (c, i) {
                final o = recent[i];
                final id = o['id']?.toString() ?? '';
                final shortId =
                    id.length > 8 ? id.substring(0, 8) : id;
                final total = (o['total'] as num?)?.toInt() ?? 0;
                final currency = o['currency']?.toString() ?? 'FC';
                final status = o['status']?.toString() ?? '';
                final color = _statusColor(status);

                return ListTile(
                  onTap: () {
                    if (id.isNotEmpty) {
                      context.push('/market/order/$id');
                    }
                  },
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.15),
                    radius: 18,
                    child: Icon(
                      status == 'pending'
                          ? Icons.hourglass_top_rounded
                          : Icons.receipt_long_rounded,
                      color: color,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    'Commande #$shortId',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '$total $currency',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
