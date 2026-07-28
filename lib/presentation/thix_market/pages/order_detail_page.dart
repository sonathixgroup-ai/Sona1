// lib/presentation/thix_market/pages/order_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// ============================================================
// CHARTE GRAPHIQUE THIX MARKET
// ============================================================
class _MarketColors {
  static const Color red = Color(0xFFD81E2C);
  static const Color gold = Color(0xFFF0A93B);
  static const Color lightBg = Color(0xFFF7F7FA);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF1A1A1A);
  static const Color mutedText = Color(0xFF8A8A8F);
  static const Color cardBorder = Color(0xFFF0F0F0);
  static const Color successGreen = Color(0xFF00B074);
  static const Color creamBg = Color(0xFFFCEFDA);
}

// ============================================================
// PROVIDER RIVERPOD (Chargement de la commande)
// ============================================================
final orderDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, orderId) async {
  final supabase = Supabase.instance.client;

  // 1. Charger la commande principale
  final orderResponse = await supabase
      .from('orders')
      .select()
      .eq('id', orderId)
      .single();

  final orderData = Map<String, dynamic>.from(orderResponse);

  // 2. Charger les articles (items) de cette commande
  try {
    final itemsResponse = await supabase
        .from('order_items')
        .select()
        .eq('order_id', orderId);
    orderData['items'] = itemsResponse;
  } catch (e) {
    debugPrint('Erreur chargement items: $e');
    orderData['items'] = [];
  }

  // 3. Charger l'adresse si un address_id est présent
  if (orderData['address_id'] != null) {
    try {
      final addressResponse = await supabase
          .from('addresses')
          .select()
          .eq('id', orderData['address_id'])
          .maybeSingle();
      orderData['address'] = addressResponse;
    } catch (e) {
      debugPrint('Erreur chargement adresse: $e');
    }
  }

  // 4. Charger la boutique si un shop_id est présent
  if (orderData['shop_id'] != null) {
    try {
      final shopResponse = await supabase
          .from('shops')
          .select('name, logo_url')
          .eq('id', orderData['shop_id'])
          .maybeSingle();
      orderData['shop'] = shopResponse;
    } catch (e) {
      debugPrint('Erreur chargement boutique: $e');
    }
  }

  return orderData;
});

// ============================================================
// PAGE DETAIL COMMANDE
// ============================================================
class OrderDetailPage extends ConsumerWidget {
  final String orderId;

  const OrderDetailPage({
    super.key, 
    required this.orderId
  });

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '—';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return _MarketColors.gold;
      case 'processing': return Colors.blue;
      case 'shipped': return Colors.purple;
      case 'delivered': return _MarketColors.successGreen;
      case 'cancelled': return _MarketColors.red;
      default: return _MarketColors.mutedText;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending': return 'En attente';
      case 'processing': return 'En préparation';
      case 'shipped': return 'Expédiée';
      case 'delivered': return 'Livrée';
      case 'cancelled': return 'Annulée';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Écoute de l'état de la commande
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: _MarketColors.lightBg,
      appBar: AppBar(
        title: const Text(
          'Détail de la commande',
          style: TextStyle(
            color: _MarketColors.darkText,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        backgroundColor: _MarketColors.pureWhite,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _MarketColors.darkText, size: 20),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _MarketColors.cardBorder, height: 1),
        ),
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: _MarketColors.red)),
        error: (error, stack) => _buildErrorState(context, ref, error.toString()),
        data: (order) => _buildContent(context, ref, order),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: _MarketColors.creamBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline_rounded, size: 64, color: _MarketColors.gold),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Impossible de charger les détails : $error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _MarketColors.darkText,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(orderDetailProvider(orderId)),
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            label: const Text('Réessayer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _MarketColors.red,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, Map<String, dynamic> order) {
    final items = List<Map<String, dynamic>>.from(order['items'] ?? []);
    final address = order['address'] as Map?;
    final shop = order['shop'] as Map?;
    final status = order['status'] ?? 'pending';
    final total = (order['total'] as num?)?.toDouble() ?? 0;
    final currency = order['currency'] ?? 'FC'; 
    final createdAt = _formatDate(order['created_at']);
    final paymentStatus = order['payment_status'] ?? 'pending';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête : statut et date
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _MarketColors.pureWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _MarketColors.cardBorder),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Commande #${order['id'].toString().substring(0, 8)}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: _MarketColors.darkText),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 12, color: _MarketColors.mutedText),
                        const SizedBox(width: 4),
                        Text(
                          createdAt,
                          style: const TextStyle(color: _MarketColors.mutedText, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                      color: _statusColor(status),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Boutique
          if (shop != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _MarketColors.pureWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _MarketColors.cardBorder),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: _MarketColors.lightBg,
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: shop['logo_url'] != null
                        ? Image.network(
                            shop['logo_url'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.storefront_rounded, size: 20, color: _MarketColors.mutedText),
                          )
                        : const Icon(Icons.storefront_rounded, size: 20, color: _MarketColors.mutedText),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Vendu par', style: TextStyle(fontSize: 10, color: _MarketColors.mutedText, fontWeight: FontWeight.w600)),
                        Text(
                          shop['name'] ?? 'Boutique',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _MarketColors.darkText),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _MarketColors.mutedText),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Articles
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _MarketColors.pureWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _MarketColors.cardBorder),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Articles commandés',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: _MarketColors.darkText),
                ),
                const SizedBox(height: 16),
                
                ...items.map((item) => _buildItemTile(item, currency)),
                
                const Divider(height: 32, color: _MarketColors.cardBorder),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total payé',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _MarketColors.darkText),
                    ),
                    Text(
                      '${total.toInt()} $currency',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: _MarketColors.red),
                    ),
                  ],
                ),
                if (paymentStatus == 'paid')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _MarketColors.successGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.check_circle_rounded, size: 12, color: _MarketColors.successGreen),
                              SizedBox(width: 4),
                              Text('Paiement validé', style: TextStyle(color: _MarketColors.successGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Adresse de livraison
          if (address != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _MarketColors.pureWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _MarketColors.cardBorder),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.location_on_rounded, size: 18, color: _MarketColors.gold),
                      SizedBox(width: 8),
                      Text(
                        'Adresse de livraison',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: _MarketColors.darkText),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    address['full_name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: _MarketColors.darkText, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(address['address_line'] ?? '', style: const TextStyle(color: _MarketColors.mutedText, fontSize: 12)),
                  Text('${address['city'] ?? ''}, ${address['postal_code'] ?? ''}', style: const TextStyle(color: _MarketColors.mutedText, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone_rounded, size: 12, color: _MarketColors.mutedText),
                      const SizedBox(width: 4),
                      Text(address['phone'] ?? '', style: const TextStyle(color: _MarketColors.mutedText, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // Actions
          if (status == 'pending' || status == 'processing')
            Column(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showCancelConfirmDialog(context, ref),
                  icon: const Icon(Icons.cancel_outlined, color: _MarketColors.red, size: 18),
                  label: const Text('Annuler la commande', style: TextStyle(color: _MarketColors.red, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    side: const BorderSide(color: _MarketColors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
            
          ElevatedButton.icon(
            onPressed: () => context.push('/market/orders'),
            icon: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 18),
            label: const Text('Retour à mes commandes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _MarketColors.darkText, 
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile(Map<String, dynamic> item, String currency) {
    final name = item['product_name'] ?? 'Produit';
    final quantity = item['quantity'] ?? 1;
    final price = (item['price'] as num?)?.toDouble() ?? 0;
    final imageUrl = item['product_image'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 56,
              height: 56,
              color: _MarketColors.lightBg,
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _MarketColors.red));
                      },
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported_outlined, color: _MarketColors.mutedText),
                    )
                  : const Icon(Icons.image_outlined, color: _MarketColors.mutedText),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: _MarketColors.darkText, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Qté: $quantity  •  ${price.toInt()} $currency/u',
                  style: const TextStyle(color: _MarketColors.mutedText, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(price * quantity).toInt()} $currency',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: _MarketColors.darkText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Annuler la commande', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler cette commande ? Cette action est irréversible.',
          style: TextStyle(fontSize: 14, color: _MarketColors.darkText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Non, garder', style: TextStyle(color: _MarketColors.mutedText, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // Ferme la dialog
              
              try {
                await Supabase.instance.client
                    .from('orders')
                    .update({'status': 'cancelled'})
                    .eq('id', orderId);
                    
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Commande annulée avec succès'),
                      backgroundColor: _MarketColors.successGreen,
                    ),
                  );
                }
                
                // Rafraîchir les données via Riverpod
                ref.invalidate(orderDetailProvider(orderId));
                
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erreur lors de l’annulation'),
                      backgroundColor: _MarketColors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _MarketColors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text('Oui, annuler', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
