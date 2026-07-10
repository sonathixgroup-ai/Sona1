// lib/presentation/thix_market/checkout/order_summary_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thix_id/presentation/thix_market/cart/cart_provider.dart';
import 'checkout_provider.dart';
import 'order_confirmation_page.dart';

class OrderSummaryWidget extends StatelessWidget {
  final CheckoutProvider provider;

  const OrderSummaryWidget({super.key, required this.provider});

  // ─── Palette THIX ID ────────────────────────────────────────────
  static const Color thixOrange = Color(0xFFE5592F);
  static const Color softBlue = Color(0xFFEFF5FF);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF10192E);
  static const Color mutedText = Color(0xFF7386A8);

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // Devises et Montants
    final subtotalSymbol = cartProvider.currencySymbol;
    final total = cartProvider.subtotal; // On n'ajoute plus de frais de livraison ici
    
    final shippingLabel = provider.selectedShippingMethod?['price_label'] ?? 'À déterminer';
    final shippingName = provider.selectedShippingMethod?['name'] ?? 'Livraison';

    // Items
    final items = cartProvider.cartItems.map((item) {
      final product = item['product'];
      return {
        'product_id': product['id'],
        'quantity': item['quantity'],
        'price': (product['discount_price'] ?? product['price']).toDouble(),
        'product_name': product['title'],
        'image_url': (product['images'] is List && (product['images'] as List).isNotEmpty)
            ? (product['images'] as List).first
            : product['image_url'],
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
                // ─── Adresse ────────────────────────────────────
                _buildSection('Adresse de livraison', [
                  Text(provider.selectedAddress?['full_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('${provider.selectedAddress?['address_line']}'),
                  Text('${provider.selectedAddress?['commune']}, ${provider.selectedAddress?['city']}'),
                  if (provider.selectedAddress?['landmark'] != null && provider.selectedAddress!['landmark'].toString().isNotEmpty)
                    Text('Repère: ${provider.selectedAddress?['landmark']}', style: const TextStyle(fontStyle: FontStyle.italic)),
                  Text('Tél: ${provider.selectedAddress?['phone']}'),
                  if (provider.selectedAddress?['alt_phone'] != null && provider.selectedAddress!['alt_phone'].toString().isNotEmpty)
                    Text('Tél alt: ${provider.selectedAddress?['alt_phone']}'),
                ]),
                const SizedBox(height: 16),

                // ─── Mode de livraison ─────────────────────────
                _buildSection('Mode de livraison', [
                  Text(shippingName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('Frais : $shippingLabel', style: const TextStyle(color: thixOrange, fontWeight: FontWeight.w500)),
                ]),
                const SizedBox(height: 16),

                // ─── Moyen de paiement ─────────────────────────
                _buildSection('Moyen de paiement', [
                  Text(provider.selectedPaymentMethod?['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 16),

                // ─── Articles ──────────────────────────────────
                const Text('Articles', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: darkText)),
                const SizedBox(height: 8),
                ...items.map((item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: item['image_url'] != null
                        ? Image.network(item['image_url'], width: 50, height: 50, fit: BoxFit.cover)
                        : Container(width: 50, height: 50, color: Colors.grey[200], child: const Icon(Icons.image_rounded, color: mutedText)),
                  ),
                  title: Text(item['product_name'], style: const TextStyle(fontWeight: FontWeight.w600, color: darkText, fontSize: 14)),
                  subtitle: Text('Qté: ${item['quantity']}', style: TextStyle(color: mutedText, fontSize: 12)),
                  trailing: Text(
                    '${(item['price'] * item['quantity']).toInt()} $subtotalSymbol',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: darkText),
                  ),
                )),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(),
                ),

                // ─── Prix ──────────────────────────────────────
                _buildPriceRow('Sous-total', '${total.toInt()} $subtotalSymbol'),
                _buildPriceRow('Livraison', shippingLabel, isHighlight: true),
                const Divider(height: 24),
                _buildPriceRow('Total à payer (hors livraison)', '${total.toInt()} $subtotalSymbol', isTotal: true),
              ],
            ),
          ),
        ),

        // ─── Bouton ────────────────────────────────────────────
        _buildBottomButton(context, total, items, cartProvider, subtotalSymbol),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: darkText, fontSize: 15)),
          const SizedBox(height: 12),
          ...children.map((child) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: child,
          )),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false, bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? darkText : mutedText,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.w800 : (isHighlight ? FontWeight.w600 : FontWeight.w700),
              fontSize: isTotal ? 18 : 14,
              color: isTotal ? darkText : (isHighlight ? thixOrange : darkText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(
    BuildContext context,
    double total,
    List<Map<String, dynamic>> items,
    CartProvider cartProvider,
    String currencySymbol,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: provider.isProcessing ? null : () async {
          try {
            final order = await provider.processOrder(
              cartProvider: cartProvider,
              total: total, // On envoie le total sans frais de port
              items: items,
            );
            if (context.mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderConfirmationPage(
                    order: order,
                    currencySymbol: currencySymbol,
                  ),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
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
        child: provider.isProcessing
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Confirmer la commande', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
    );
  }
}
