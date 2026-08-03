// lib/presentation/thix_market/vendor/vendor_orders_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/market_providers.dart';

// ============================================================
// PROVIDER : commandes du vendeur
// ============================================================
final vendorAllOrdersProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String?>((ref, statusFilter) async {
  final db = ref.read(supabaseClientProvider);
  final uid = db.auth.currentUser?.id;
  if (uid == null) return [];

  // Boutiques du vendeur
  final shopsRes = await db.from('shops').select('id').eq('owner_id', uid);
  final shops = List<Map<String, dynamic>>.from(shopsRes);
  if (shops.isEmpty) return [];

  final shopIds = shops.map((s) => s['id']).toList();

  var query = db
      .from('orders')
      .select('id, total, status, payment_status, created_at, user_id, currency')
      .inFilter('shop_id', shopIds)
      .order('created_at', ascending: false);

  if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'all') {
    query = query.eq('status', statusFilter);
  }

  final res = await query.limit(100);
  return List<Map<String, dynamic>>.from(res);
});

// ============================================================
// PAGE
// ============================================================
class VendorOrdersPage extends ConsumerStatefulWidget {
  const VendorOrdersPage({super.key});

  @override
  ConsumerState<VendorOrdersPage> createState() => _VendorOrdersPageState();
}

class _VendorOrdersPageState extends ConsumerState<VendorOrdersPage> {
  String _filter = 'all';

  final _statusTabs = const [
    {'key': 'all', 'label': 'Toutes'},
    {'key': 'pending', 'label': 'En attente'},
    {'key': 'processing', 'label': 'En cours'},
    {'key': 'shipped', 'label': 'Expédiées'},
    {'key': 'delivered', 'label': 'Livrées'},
    {'key': 'cancelled', 'label': 'Annulées'},
  ];

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'processing':
        return const Color(0xFF3B82F6);
      case 'shipped':
        return const Color(0xFF8B5CF6);
      case 'delivered':
        return const Color(0xFF00B074);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
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
        return status;
    }
  }

  Future<void> _updateStatus(String orderId, String newStatus) async {
    try {
      final db = ref.read(supabaseClientProvider);
      await db.from('orders').update({
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      ref.invalidate(vendorAllOrdersProvider(_filter == 'all' ? null : _filter));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut mis à jour → ${_statusLabel(newStatus)}'),
            backgroundColor: const Color(0xFF00B074),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showStatusActions(Map<String, dynamic> order) {
    final current = (order['status'] ?? 'pending').toString().toLowerCase();
    final orderId = order['id'].toString();

    final actions = <Map<String, String>>[];

    if (current == 'pending') {
      actions.addAll([
        {'key': 'processing', 'label': 'Accepter / En cours'},
        {'key': 'cancelled', 'label': 'Annuler'},
      ]);
    } else if (current == 'processing') {
      actions.addAll([
        {'key': 'shipped', 'label': 'Marquer expédiée'},
        {'key': 'cancelled', 'label': 'Annuler'},
      ]);
    } else if (current == 'shipped') {
      actions.add({'key': 'delivered', 'label': 'Marquer livrée'});
    }

    if (actions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune action possible sur cette commande')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Commande #${orderId.substring(0, 8)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Statut actuel : ${_statusLabel(current)}',
                  style: TextStyle(color: _statusColor(current), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                ...actions.map((a) {
                  final isCancel = a['key'] == 'cancelled';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _updateStatus(orderId, a['key']!);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isCancel ? Colors.red.shade50 : const Color(0xFF1A73E8),
                          foregroundColor: isCancel ? Colors.red : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          a['label']!,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync =
        ref.watch(vendorAllOrdersProvider(_filter == 'all' ? null : _filter));

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text(
          'Mes commandes',
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
            onPressed: () {
              ref.invalidate(
                vendorAllOrdersProvider(_filter == 'all' ? null : _filter),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ===== FILTRES =====
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: _statusTabs.map((tab) {
                  final selected = _filter == tab['key'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(tab['label']!),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => _filter = tab['key']!);
                      },
                      selectedColor: const Color(0xFF1A73E8),
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      backgroundColor: Colors.grey.shade100,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1),

          // ===== LISTE =====
          Expanded(
            child: ordersAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF1A73E8)),
              ),
              error: (e, _) => Center(child: Text('Erreur : $e')),
              data: (orders) {
                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          _filter == 'all'
                              ? 'Aucune commande'
                              : 'Aucune commande ${_statusLabel(_filter).toLowerCase()}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: const Color(0xFF1A73E8),
                  onRefresh: () async {
                    ref.invalidate(
                      vendorAllOrdersProvider(_filter == 'all' ? null : _filter),
                    );
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final order = orders[i];
                      final id = order['id'].toString();
                      final shortId = id.length > 8 ? id.substring(0, 8) : id;
                      final status = (order['status'] ?? 'pending').toString();
                      final total = order['total'] ?? 0;
                      final currency = (order['currency'] ?? 'FC').toString();
                      final createdAt = order['created_at'] != null
                          ? DateTime.tryParse(order['created_at'].toString())
                          : null;
                      final dateStr = createdAt != null
                          ? DateFormat('dd/MM/yyyy HH:mm').format(createdAt.toLocal())
                          : '';

                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            // Ouvre le détail
                            context.push('/market/order/$id');
                          },
                          onLongPress: () => _showStatusActions(order),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFEEEEEE)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: _statusColor(status),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Commande #$shortId',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        dateStr,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$total $currency',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _statusColor(status).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _statusLabel(status),
                                        style: TextStyle(
                                          color: _statusColor(status),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () => _showStatusActions(order),
                                      child: const Icon(
                                        Icons.more_horiz_rounded,
                                        color: Colors.grey,
                                        size: 22,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
