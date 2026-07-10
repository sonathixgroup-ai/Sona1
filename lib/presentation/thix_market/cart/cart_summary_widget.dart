// lib/presentation/thix_market/cart/cart_summary_widget.dart (nouvelle version)
import 'package:flutter/material.dart';

class CartSummaryWidget extends StatelessWidget {
  final double subtotal;
  final double shippingCost;
  final double total;
  final int itemCount;
  final String subtotalSymbol;
  final String shippingSymbol;
  final VoidCallback onCheckout;

  const CartSummaryWidget({
    super.key,
    required this.subtotal,
    required this.shippingCost,
    required this.total,
    required this.itemCount,
    required this.subtotalSymbol,
    required this.shippingSymbol,
    required this.onCheckout,
  });

  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color primaryBlue = Color(0xFF2D6CDF);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF10192E);
  static const Color mutedText = Color(0xFF7386A8);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pureWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: navyDeep.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            _buildRow('Sous-total ($itemCount articles)', subtotal, subtotalSymbol),
            const SizedBox(height: 4),
            _buildRow('Livraison', shippingCost, shippingSymbol),
            const Divider(height: 24, thickness: 1),
            _buildRow('Total', total, subtotalSymbol, isTotal: true),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: pureWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Continuer vers la validation',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, double value, String symbol, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: isTotal ? darkText : mutedText,
          ),
        ),
        Text(
          '${value.toInt()} $symbol',
          style: TextStyle(
            fontSize: isTotal ? 18 : 15,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
            color: isTotal ? primaryBlue : darkText,
          ),
        ),
      ],
    );
  }
}
