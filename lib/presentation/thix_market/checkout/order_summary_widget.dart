// lib/presentation/thix_market/checkout/order_summary_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../cart/cart_provider.dart';
import 'checkout_provider.dart';
import 'order_confirmation_page.dart';
import '../../../services/market_payment_service.dart'; // <-- Ton service de paiement par Edge Function

class OrderSummaryWidget extends ConsumerWidget {
  const OrderSummaryWidget({super.key});

  static const thixOrange = Color(0xFFE5592F);
  static const pureWhite = Color(0xFFFFFFFF);
  static const darkText = Color(0xFF10192E);
  static const mutedText = Color(0xFF7386A8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartNotifier = ref.read(cartProvider.notifier);
    final cartState = ref.watch(cartProvider);
    final checkout = ref.watch(checkoutProvider);
    final checkoutNotifier = ref.read(checkoutProvider.notifier);

    final subtotalSymbol = cartNotifier.currencySymbol;
    final total = cartNotifier.subtotal;
    final shippingLabel = checkout.selectedShipping != null ? (checkout.selectedShipping!['price_label'] ?? 'À déterminer').toString() : 'À déterminer';
    final shippingName = checkout.selectedShipping != null ? (checkout.selectedShipping!['name'] ?? 'Livraison').toString() : 'Livraison';

    final items = cartState.items.map((item) {
      final product = item['product'] as Map?;
      double price = 0;
      try {
        price = cartNotifier.getItemRealPrice(item);
      } catch (_) {}
      return {
        'product_id': product != null ? product['id'] : item['product_id'],
        'quantity': item['quantity'],
        'price': price,
        'product_name': product != null && product['title'] != null ? product['title'].toString() : 'Produit',
        'image_url': product != null ? (product['images'] is List && (product['images'] as List).isNotEmpty ? (product['images'] as List).first.toString() : product['image_url']?.toString()) : null,
      };
    }).toList();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _section('Adresse de livraison', [
                  Text(checkout.selectedAddress != null ? (checkout.selectedAddress!['full_name'] ?? '').toString() : '', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(checkout.selectedAddress != null ? (checkout.selectedAddress!['address_line'] ?? '').toString() : ''),
                  Text(checkout.selectedAddress != null ? '${checkout.selectedAddress!['commune'] ?? ''}, ${checkout.selectedAddress!['city'] ?? ''}' : ''),
                  if (checkout.selectedAddress != null && checkout.selectedAddress!['landmark'] != null && checkout.selectedAddress!['landmark'].toString().isNotEmpty)
                    Text('Repère: ${checkout.selectedAddress!['landmark']}', style: const TextStyle(fontStyle: FontStyle.italic)),
                  Text('Tél: ${checkout.selectedAddress != null ? checkout.selectedAddress!['phone'] ?? '' : ''}'),
                ]),
                const SizedBox(height: 16),
                _section('Mode de livraison', [
                  Text(shippingName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('Frais : $shippingLabel', style: const TextStyle(color: thixOrange, fontWeight: FontWeight.w500)),
                ]),
                const SizedBox(height: 16),
                _section('Moyen de paiement', [
                  Text(checkout.selectedPayment != null ? (checkout.selectedPayment!['name'] ?? '').toString() : '', style: const TextStyle(fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 16),
                const Text('Articles', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: darkText)),
                const SizedBox(height: 8),
                ...items.map((item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: item['image_url'] != null
                            ? Image.network(item['image_url'].toString(), width: 50, height: 50, fit: BoxFit.cover)
                            : Container(width: 50, height: 50, color: Colors.grey.shade200, child: const Icon(Icons.image_rounded, color: mutedText)),
                      ),
                      title: Text(item['product_name'].toString(), style: const TextStyle(fontWeight: FontWeight.w600, color: darkText, fontSize: 14)),
                      subtitle: Text('Qté: ${item['quantity']}', style: const TextStyle(color: mutedText, fontSize: 12)),
                      trailing: Text('${((item['price'] as num) * (item['quantity'] as num)).toInt()} $subtotalSymbol', style: const TextStyle(fontWeight: FontWeight.w800, color: darkText)),
                    )),
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                _priceRow('Sous-total', '${total.toInt()} $subtotalSymbol'),
                _priceRow('Livraison', shippingLabel, isHighlight: true),
                const Divider(height: 24),
                _priceRow('Total à payer (hors livraison)', '${total.toInt()} $subtotalSymbol', isTotal: true),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: checkout.isProcessing
                ? null
                : () async {
                    try {
                      // 1. Enregistrement initial de la commande en base de données
                      final order = await checkoutNotifier.processOrder(total: total, items: items);
                      final orderId = order['id']?.toString() ?? '';

                      // 2. Initialisation et traitement du paiement sécurisé via Edge Function Supabase
                      final paymentService = MarketPaymentService(Supabase.instance.client);
                      final paymentMethodId = checkout.selectedPayment?['id'] ?? 'cash';
                      
                      final paymentSuccess = await paymentService.processOrderPayment(
                        orderId: orderId,
                        amount: total,
                        currency: subtotalSymbol == '\$' ? 'USD' : 'FC',
                        paymentMethod: paymentMethodId,
                        phoneNumber: checkout.selectedAddress?['phone']?.toString(),
                      );

                      if (paymentSuccess && context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderConfirmationPage(order: order, currencySymbol: subtotalSymbol),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: thixOrange,
              foregroundColor: pureWhite,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: checkout.isProcessing
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Confirmer la commande', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _section(String title, List<Widget> children) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: darkText, fontSize: 15)),
            const SizedBox(height: 12),
            ...children.map((c) => Padding(padding: const EdgeInsets.only(bottom: 4), child: c)),
          ],
        ),
      );

  Widget _priceRow(String label, String value, {bool isTotal = false, bool isHighlight = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500, fontSize: isTotal ? 16 : 14, color: isTotal ? darkText : mutedText)),
            Text(value, style: TextStyle(fontWeight: isTotal ? FontWeight.w800 : (isHighlight ? FontWeight.w600 : FontWeight.w700), fontSize: isTotal ? 18 : 14, color: isTotal ? darkText : (isHighlight ? thixOrange : darkText))),
          ],
        ),
      );
}
