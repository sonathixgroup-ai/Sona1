// lib/presentation/thix_market/vendor/vendor_orders_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../providers/market_providers.dart';

// ============================================================
// PROVIDER
// ============================================================
final vendorAllOrdersProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String?>((ref, statusFilter) async {
  final db = ref.read(supabaseClientProvider);
  final uid = db.auth.currentUser?.id;
  if (uid == null) return [];

  final shopsRes = await db.from('shops').select('id').eq('owner_id', uid);
  final shops = List<Map<String, dynamic>>.from(shopsRes);
  if (shops.isEmpty) return [];

  final shopIds = shops.map((s) => s['id']).toList();

  var query = db
      .from('orders')
      .select(
        'id, total, status, payment_status, payout_status, payment_method, '
        'currency, created_at, user_id, receipt_code, refund_requested, '
        'refund_reason, received_at, shipping_method',
      )
      .inFilter('shop_id', shopIds)
      .order('created_at', ascending: false);

  if (statusFilter != null &&
      statusFilter.isNotEmpty &&
      statusFilter != 'all') {
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
  bool _busy = false;

  static const primary = Color(0xFF1A73E8);
  static const bg = Color(0xFFF6F7FB);
  static const dark = Color(0xFF10192E);
  static const muted = Color(0xFF7386A8);
  static const red = Color(0xFFD81E2C);
  static const green = Color(0xFF00B074);
  static const gold = Color(0xFFF0A93B);

  final _statusTabs = const [
    {'key': 'all', 'label': 'Toutes'},
    {'key': 'pending', 'label': 'En attente'},
    {'key': 'processing', 'label': 'Préparation'},
    {'key': 'shipped', 'label': 'Expédiées'},
    {'key': 'delivered', 'label': 'Livrées'},
    {'key': 'cancelled', 'label': 'Annulées'},
  ];

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return gold;
      case 'processing':
      case 'confirmed':
        return const Color(0xFF8B5CF6);
      case 'shipped':
        return primary;
      case 'delivered':
        return green;
      case 'cancelled':
        return red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'En attente';
      case 'confirmed':
        return 'Confirmée';
      case 'processing':
        return 'Préparation';
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

  String _cur(dynamic c) {
    final v = (c ?? 'CDF').toString().toUpperCase();
    if (v == 'XOF' || v == 'FCFA' || v == 'FC' || v == 'CDF') return 'FC';
    if (v == 'USD' || v == '\$') return '\$';
    return v;
  }

  String _money(num amount, String cur) {
    if (cur == '\\( ') return ' \){amount.toStringAsFixed(2)} $cur';
    return '${amount.toInt()} $cur';
  }

  Future<void> _updateStatus(String orderId, String newStatus) async {
    setState(() => _busy = true);
    try {
      final db = ref.read(supabaseClientProvider);
      final payload = <String, dynamic>{
        'status': newStatus,
      };

      // Expédition → générer / garder le code QR, argent toujours bloqué
      if (newStatus == 'shipped') {
        payload['receipt_code'] = orderId;
        payload['payout_status'] = 'held';
      }

      // Livré manuellement (si besoin) → libère le paiement
      if (newStatus == 'delivered') {
        payload['received_at'] = DateTime.now().toIso8601String();
        payload['payout_status'] = 'released';
        payload['payment_status'] = 'paid';
      }

      // Annulation → remboursement
      if (newStatus == 'cancelled') {
        payload['payout_status'] = 'refunded';
      }

      await db.from('orders').update(payload).eq('id', orderId);

      ref.invalidate(vendorAllOrdersProvider(_filter));
      ref.invalidate(vendorAllOrdersProvider(null));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut → ${_statusLabel(newStatus)}'),
            backgroundColor: green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showQrSheet(Map<String, dynamic> order) {
    final orderId = order['id'].toString();
    final code = (order['receipt_code'] ?? orderId).toString();
    final short = orderId.length > 8 ? orderId.substring(0, 8).toUpperCase() : orderId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Code de livraison',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              const SizedBox(height: 6),
              Text(
                'Commande #$short',
                style: const TextStyle(color: muted, fontSize: 13),
              ),
              const SizedBox(height: 8),
              const Text(
                'Présentez ce QR au client pour confirmer la réception.\nL\'argent ne sera versé qu\'après le scan.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: muted, height: 1.4),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: BarcodeWidget(
                  barcode: Barcode.qrCode(),
                  data: code,
                  width: 200,
                  height: 200,
                  drawText: false,
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                code,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: dark,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Code copié'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Copier'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 46),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Fermer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showActions(Map<String, dynamic> order) {
    final status = (order['status'] ?? 'pending').toString();
    final orderId = order['id'].toString();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Actions commande',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: 8),

              if (status == 'pending') ...[
                _actionTile(
                  icon: Icons.inventory_2_outlined,
                  label: 'Passer en préparation',
                  color: const Color(0xFF8B5CF6),
                  onTap: () {
                    Navigator.pop(ctx);
                    _updateStatus(orderId, 'processing');
                  },
                ),
              ],

              if (status == 'pending' || status == 'processing' || status == 'confirmed') ...[
                _actionTile(
                  icon: Icons.local_shipping_outlined,
                  label: 'Marquer comme expédiée',
                  color: primary,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _updateStatus(orderId, 'shipped');
                    // Afficher le QR après expédition
                    final refreshed = {...order, 'status': 'shipped', 'receipt_code': orderId};
                    if (mounted) _showQrSheet(refreshed);
                  },
                ),
              ],

              if (status == 'shipped') ...[
                _actionTile(
                  icon: Icons.qr_code_2_rounded,
                  label: 'Afficher le QR de livraison',
                  color: primary,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showQrSheet(order);
                  },
                ),
              ],

              if (status != 'delivered' && status != 'cancelled') ...[
                _actionTile(
                  icon: Icons.cancel_outlined,
                  label: 'Annuler la commande',
                  color: red,
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmCancel(orderId);
                  },
                ),
              ],

              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Fermer'),
                onTap: () => Navigator.pop(ctx),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
      onTap: onTap,
    );
  }

  Future<void> _confirmCancel(String orderId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler cette commande ?'),
        content: const Text(
          'Le client sera notifié et le paiement ne sera pas versé.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: red),
            child: const Text('Oui, annuler', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) await _updateStatus(orderId, 'cancelled');
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(vendorAllOrdersProvider(_filter));

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Commandes vendeur',
          style: TextStyle(
            color: dark,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: dark),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(vendorAllOrdersProvider(_filter));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 10, top: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: _statusTabs.map((t) {
                  final sel = _filter == t['key'];
                  return GestureDetector(
                    onTap: () => setState(() => _filter = t['key']!),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: sel ? primary : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        t['label']!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: sel ? Colors.white : muted,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          Expanded(
            child: async.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: primary),
              ),
              error: (e, _) => Center(child: Text('Erreur : $e')),
              data: (orders) {
                if (orders.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucune commande',
                      style: TextStyle(color: muted),
                    ),
                  );
                }
                return RefreshIndicator(
                  color: primary,
                  onRefresh: () async {
                    ref.invalidate(vendorAllOrdersProvider(_filter));
                    await ref.read(vendorAllOrdersProvider(_filter).future);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _orderCard(orders[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderCard(Map<String, dynamic> o) {
    final id = o['id']?.toString() ?? '';
    final short = id.length > 8 ? id.substring(0, 8).toUpperCase() : id;
    final status = (o['status'] ?? 'pending').toString();
    final color = _statusColor(status);
    final total = (o['total'] as num?) ?? 0;
    final cur = _cur(o['currency']);
    final date = DateTime.tryParse(o['created_at']?.toString() ?? '');
    final payout = (o['payout_status'] ?? 'held').toString();
    final refund = o['refund_requested'] == true;
    final paymentStatus = (o['payment_status'] ?? '').toString();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showActions(o),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: refund ? gold.withOpacity(0.5) : Colors.grey.shade200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Commande #$short',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: dark,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Montant + date
              Row(
                children: [
                  Text(
                    _money(total, cur),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: dark,
                    ),
                  ),
                  const Spacer(),
                  if (date != null)
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(date),
                      style: const TextStyle(fontSize: 11, color: muted),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Badges payout / payment / refund
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _badge(
                    payout == 'released'
                        ? 'Payé vendeur'
                        : payout == 'refunded'
                            ? 'Remboursé'
                            : 'Fonds bloqués',
                    payout == 'released'
                        ? green
                        : payout == 'refunded'
                            ? red
                            : gold,
                  ),
                  if (paymentStatus.isNotEmpty)
                    _badge(
                      paymentStatus == 'paid'
                          ? 'Client payé'
                          : paymentStatus == 'pending_delivery'
                              ? 'Cash livraison'
                              : paymentStatus,
                      paymentStatus == 'paid' ? green : muted,
                    ),
                  if (refund)
                    _badge('Réclamation', red),
                ],
              ),

              if (refund && o['refund_reason'] != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Motif : ${o['refund_reason']}',
                  style: const TextStyle(fontSize: 12, color: red),
                ),
              ],

              const SizedBox(height: 10),

              // Boutons rapides
              Row(
                children: [
                  if (status == 'shipped')
                    TextButton.icon(
                      onPressed: () => _showQrSheet(o),
                      icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                      label: const Text('QR livraison'),
                    ),
                  const Spacer(),
                  Text(
                    'Gérer ›',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: primary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
