// lib/presentation/thix_market/checkout/order_confirmation_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OrderConfirmationPage extends StatelessWidget {
  final Map<String, dynamic> order;
  final String? currencySymbol; // $ ou FC

  const OrderConfirmationPage({
    super.key,
    required this.order,
    this.currencySymbol,
  });

  // ─── Palette Élite ──────────────────────────────────────────────
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color primaryBlue = Color(0xFF2D6CDF);
  static const Color softBlue = Color(0xFFEFF5FF);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF10192E);
  static const Color mutedText = Color(0xFF7386A8);
  static const Color success = Color(0xFF2ECC71);

  @override
  Widget build(BuildContext context) {
    final symbol = currencySymbol ?? 'FC';
    final total = (order['total'] as num?)?.toInt() ?? 0;
    final orderId = order['id'] ?? 'N/A';
    final shippingMethod = order['shipping_method'] ?? 'Standard';
    final paymentStatus = order['payment_status'] ?? 'pending';
    final statusLabel = paymentStatus == 'paid' ? 'Payé' : 'En attente';
    final statusColor = paymentStatus == 'paid' ? success : Colors.orange;

    return Scaffold(
      backgroundColor: pureWhite,
      appBar: AppBar(
        title: const Text(
          'Commande confirmée',
          style: TextStyle(fontWeight: FontWeight.w800, color: darkText),
        ),
        backgroundColor: pureWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: darkText),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ─── Icône de succès ──────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_rounded, size: 72, color: success),
            ),
            const SizedBox(height: 16),
            const Text(
              'Merci pour votre commande !',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: darkText),
            ),
            const SizedBox(height: 6),
            Text(
              'Commande #$orderId',
              style: const TextStyle(fontSize: 16, color: mutedText),
            ),
            const SizedBox(height: 24),

            // ─── Récapitulatif ──────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: softBlue,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Récapitulatif',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: darkText),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Total', '$total $symbol', isTotal: true),
                  _buildInfoRow('Mode de livraison', shippingMethod),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Statut paiement', style: TextStyle(color: mutedText)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, thickness: 1),
                  const Text(
                    'Un email de confirmation vous a été envoyé.',
                    style: TextStyle(color: mutedText, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // ─── Bouton retour ──────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => context.go('/'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: pureWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Retour à l\'accueil',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? darkText : mutedText,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              fontSize: isTotal ? 15 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
              color: isTotal ? primaryBlue : darkText,
              fontSize: isTotal ? 17 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
