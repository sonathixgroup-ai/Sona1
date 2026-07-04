import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'checkout_provider.dart';
import '../../cart/cart_provider.dart';
import 'order_confirmation_page.dart';

class OrderSummaryWidget extends StatelessWidget {
  final CheckoutProvider provider;

  const OrderSummaryWidget({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final subtotal = cartProvider.subtotal;
    final shippingCost = provider.selectedShippingMethod?['price'] ?? 0;
    final total = subtotal + shippingCost;
    final items = cartProvider.cartItems.map((item) {
      final product = item['product'];
      return {
        'product_id': product['id'],
        'quantity': item['quantity'],
        'price': (product['discount_price'] ?? product['price']).toDouble(),
        'product_name': product['title'],
        'image_url': (product['images'] as List?)?.firstOrNull,
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
                // Adresse
                _buildSection('Adresse de livraison', [
                  Text(provider.selectedAddress?['full_name'] ?? ''),
                  Text(provider.selectedAddress?['address_line'] ?? ''),
                  Text('${provider.selectedAddress?['city']}, ${provider.selectedAddress?['postal_code']}'),
                  Text('Tél: ${provider.selectedAddress?['phone']}'),
                ]),
                const SizedBox(height: 16),
                // Mode de livraison
                _buildSection('Mode de livraison', [
                  Text('${provider.selectedShippingMethod?['name']} - ${provider.selectedShippingMethod?['price']} FCFA'),
                  Text('Livraison sous ${provider.selectedShippingMethod?['days']}'),
                ]),
                const SizedBox(height: 16),
                // Moyen de paiement
                _buildSection('Moyen de paiement', [
                  Text(provider.selectedPaymentMethod?['name'] ?? ''),
                ]),
                const SizedBox(height: 16),
                // Articles
                const Text('Articles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ...items.map((item) => ListTile(
                  leading: item['image_url'] != null
                      ? Image.network(item['image_url'], width: 40, height: 40, fit: BoxFit.cover)
                      : const Icon(Icons.image),
                  title: Text(item['product_name']),
                  subtitle: Text('Quantité: ${item['quantity']}'),
                  trailing: Text('${(item['price'] * item['quantity']).toInt()} FCFA'),
                )),
                const Divider(height: 24),
                // Prix total
                _buildPriceRow('Sous-total', subtotal),
                _buildPriceRow('Livraison', shippingCost),
                const Divider(),
                _buildPriceRow('Total', total, isTotal: true),
              ],
            ),
          ),
        ),
        _buildBottomButton(context, total, items, cartProvider),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 16 : 14)),
          Text(
            '${value.toInt()} FCFA',
            style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 18 : 14, color: isTotal ? const Color(0xFFE5592F) : null),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context, double total, List<Map<String, dynamic>> items, CartProvider cartProvider) {
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
                MaterialPageRoute(builder: (_) => OrderConfirmationPage(order: order)),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE5592F),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: provider.isProcessing
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Confirmer et payer', style: TextStyle(fontSize: 16)),
      ),
    );
  }
}
