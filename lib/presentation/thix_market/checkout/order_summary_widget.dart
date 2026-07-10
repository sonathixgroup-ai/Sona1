// lib/presentation/thix_market/checkout/order_summary_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thix_id/presentation/thix_market/cart/cart_provider.dart';
import 'checkout_provider.dart';
import 'order_confirmation_page.dart';

class OrderSummaryWidget extends StatelessWidget {
  final CheckoutProvider provider;

  const OrderSummaryWidget({super.key, required this.provider});

  // ─── Palette Élite ──────────────────────────────────────────────
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color primaryBlue = Color(0xFF2D6CDF);
  static const Color softBlue = Color(0xFFEFF5FF);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF10192E);
  static const Color mutedText = Color(0xFF7386A8);
  static const Color gold = Color(0xFFE3B23C);
  static const Color danger = Color(0xFFFF5B3D);

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // Devises
    final subtotalSymbol = cartProvider.currencySymbol;
    final shippingSymbol = cartProvider.shippingSymbol; // toujours 'FC'

    // Montants
    final subtotal = cartProvider.subtotal;
    final shippingCost = provider.selectedShippingMethod?['price'] as double? ?? 0;
    final total = subtotal + shippingCost;

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
                  Text(provider.selectedAddress?['full_name'] ?? ''),
                  Text(provider.selectedAddress?['address_line'] ?? ''),
                  Text('${provider.selectedAddress?['city']}, ${provider.selectedAddress?['postal_code']}'),
                  Text('Tél: ${provider.selectedAddress?['phone']}'),
                ]),
                const SizedBox(height: 16),

                // ─── Mode de livraison ─────────────────────────
                _buildSection('Mode de livraison', [
                  Text('${provider.selectedShippingMethod?['name']} - ${(provider.selectedShippingMethod?['price'] ?? 0).toInt()} $shippingSymbol'),
                  Text('Livraison sous ${provider.selectedShippingMethod?['days']}'),
                ]),
                const SizedBox(height: 16),

                // ─── Moyen de paiement ─────────────────────────
                _buildSection('Moyen de paiement', [
                  Text(provider.selectedPaymentMethod?['name'] ?? ''),
                ]),
                const SizedBox(height: 16),

                // ─── Articles ──────────────────────────────────
                const Text('Articles', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: darkText)),
                const SizedBox(height: 8),
                ...items.map((item) => ListTile(
                  leading: item['image_url'] != null
                      ? Image.network(item['image_url'], width: 40, height: 40, fit: BoxFit.cover)
                      : const Icon(Icons.image_rounded, color: mutedText),
                  title: Text(item['product_name'], style: const TextStyle(fontWeight: FontWeight.w600, color: darkText)),
                  subtitle: Text('Quantité: ${item['quantity']}', style: TextStyle(color: mutedText)),
                  trailing: Text(
                    '${(item['price'] * item['quantity']).toInt()} $subtotalSymbol',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: primaryBlue),
                  ),
                )),
                const Divider(height: 24),

                // ─── Prix ──────────────────────────────────────
                _buildPriceRow('Sous-total', subtotal, subtotalSymbol),
                _buildPriceRow('Livraison', shippingCost, shippingSymbol),
                const Divider(),
                _buildPriceRow('Total', total, subtotalSymbol, isTotal: true),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: softBlue,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: darkText)),
          const SizedBox(height: 8),
          ...children.map((child) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: child,
          )),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double value, String symbol, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? darkText : mutedText,
            ),
          ),
          Text(
            '${value.toInt()} $symbol',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
              fontSize: isTotal ? 18 : 15,
              color: isTotal ? primaryBlue : darkText,
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
              total: total,
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
                SnackBar(
                  content: Text(e.toString()),
                  backgroundColor: danger,
                ),
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: pureWhite,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: provider.isProcessing
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text(
                'Confirmer et payer',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
      ),
    );
  }
}
