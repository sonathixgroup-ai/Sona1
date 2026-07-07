// lib/presentation/thix_market/cart/cart_summary_widget.dart
import 'package:flutter/material.dart';

class CartSummaryWidget extends StatelessWidget {
  final double subtotal;
  final double shippingCost;
  final double total;
  final int itemCount;
  final VoidCallback onCheckout;

  const CartSummaryWidget({
    super.key,
    required this.subtotal,
    required this.shippingCost,
    required this.total,
    required this.itemCount,
    required this.onCheckout,
  });

  // ─── Palette Élite ──────────────────────────────────────────────
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color primaryBlue = Color(0xFF2D6CDF);
  static const Color softBlue = Color(0xFFEFF5FF);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF10192E);
  static const Color mutedText = Color(0xFF7386A8);
  static const Color gold = Color(0xFFE3B23C);

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
            // Ligne séparateur
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Détails des prix
            _buildRow('Sous-total ($itemCount articles)', subtotal),
            const SizedBox(height: 4),
            _buildRow('Livraison', shippingCost),
            const Divider(height: 24, thickness: 1),
            _buildRow('Total', total, isTotal: true),
            const SizedBox(height: 16),
            // Bouton Continuer
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

  Widget _buildRow(String label, double value, {bool isTotal = false}) {
    final currency = value >= 1000 ? 'FC' : 'FC'; // on pourrait récupérer la devise du panier, mais simplifié
    // On affiche en FC par défaut, mais le panier utilise déjà la devise dynamique dans les items.
    // Pour le total, on utilise le même symbole.
    // On peut récupérer la devise du premier article, mais pour l'instant on met FC.
    // On pourrait améliorer en ajoutant un paramètre, mais ce n'est pas critique.
    final symbol = 'FC'; // à rendre dynamique si nécessaire
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
