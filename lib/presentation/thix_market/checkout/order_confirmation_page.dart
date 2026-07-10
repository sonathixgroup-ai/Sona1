// lib/presentation/thix_market/checkout/order_confirmation_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OrderConfirmationPage extends StatelessWidget {
  final Map<String, dynamic> order;
  final String? currencySymbol;

  const OrderConfirmationPage({
    super.key,
    required this.order,
    this.currencySymbol,
  });

  // ─── Palette THIX ID ────────────────────────────────────────────
  static const Color thixOrange = Color(0xFFE5592F);
  static const Color softOrange = Color(0xFFFFF0EC);
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
        centerTitle: true,
        automaticallyImplyLeading: false, // Empêche le retour en arrière accidentel
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: darkText),
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            // ─── Icône de succès avec Animation ───────────────────
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: success.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded, size: 80, color: success),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            
            const Text(
              'Merci pour votre commande !',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: darkText),
            ),
            const SizedBox(height: 8),
            Text(
              'Commande #$orderId',
              style: const TextStyle(fontSize: 16, color: mutedText, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 32),

            // ─── Récapitulatif ──────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Récapitulatif',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: darkText),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Total', '$total $symbol', isTotal: true),
                  _buildInfoRow('Livraison', shippingMethod),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Statut paiement', style: TextStyle(color: mutedText, fontWeight: FontWeight.w500)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1, thickness: 1),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.mark_email_read_rounded, color: thixOrange, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Un email de confirmation contenant tous les détails vous a été envoyé.',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // ─── Boutons d'action ──────────────────────────────────
            // Bouton principal : Suivre la commande
            if (orderId != 'N/A')
              ElevatedButton.icon(
                onPressed: () => context.push('/market/tracking/$orderId'),
                icon: const Icon(Icons.local_shipping_rounded),
                label: const Text('Suivre ma commande', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: thixOrange,
                  foregroundColor: pureWhite,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Bouton secondaire : Retour à l'accueil
            OutlinedButton(
              onPressed: () => context.go('/'),
              style: OutlinedButton.styleFrom(
                foregroundColor: darkText,
                side: BorderSide(color: Colors.grey[300]!, width: 2),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Retour à l\'accueil', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? darkText : mutedText,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w700,
              color: isTotal ? thixOrange : darkText,
              fontSize: isTotal ? 18 : 15,
            ),
          ),
        ],
      ),
    );
  }
}
