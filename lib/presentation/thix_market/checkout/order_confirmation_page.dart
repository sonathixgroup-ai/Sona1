import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'checkout_provider.dart';

class OrderConfirmationPage extends ConsumerWidget {
  final Map<String,dynamic> order;
  final String? currencySymbol;
  const OrderConfirmationPage({super.key, required this.order, this.currencySymbol});

  static const thixOrange = Color(0xFFE5592F);
  static const pureWhite = Color(0xFFFFFFFF);
  static const darkText = Color(0xFF10192E);
  static const mutedText = Color(0xFF7386A8);
  static const success = Color(0xFF2ECC71);

  @override Widget build(BuildContext context, WidgetRef ref){
    final symbol = currencySymbol?? 'FC';
    final total = (order['total'] as num?)?.toInt()??0;
    final orderId = order['id']?.toString()?? 'N/A';
    final shippingMethod = order['shipping_method']?.toString()?? 'Standard';
    final paymentStatus = order['payment_status']?.toString()?? 'pending';
    final statusLabel = paymentStatus=='paid'? 'Payé' : (paymentStatus=='pending_delivery'? 'À la livraison' : 'En attente');
    final statusColor = paymentStatus=='paid'? success : (paymentStatus=='pending_delivery'? thixOrange : Colors.orange);

    void goHome(){
      ref.read(checkoutProvider.notifier).reset();
      context.go('/');
    }

    return Scaffold(
      backgroundColor: pureWhite,
      appBar: AppBar(
        title: const Text('Commande confirmée', style: TextStyle(fontWeight: FontWeight.w900, color: darkText, fontSize: 18)),
        backgroundColor: pureWhite,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [IconButton(icon: const Icon(Icons.close_rounded, color: darkText), onPressed: goHome)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, scale, child)=> Transform.scale(scale: scale, child: Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: success.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.check_circle_rounded, size: 80, color: success))),
          ),
          const SizedBox(height: 20),
          const Text('Merci pour votre commande !', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: darkText)),
          const SizedBox(height: 6),
          SelectableText('Commande #$orderId', style: const TextStyle(fontSize: 14, color: mutedText, fontWeight: FontWeight.w600)),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFFF7F8FC), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Récapitulatif', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: darkText)),
              const SizedBox(height: 16),
              _row('Total', '$total $symbol', isTotal: true),
              _row('Livraison', shippingMethod),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Statut paiement', style: TextStyle(color: mutedText, fontWeight: FontWeight.w600, fontSize: 13)),
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text(statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 11))),
              ]),
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
              Row(children: [const Icon(Icons.mark_email_read_rounded, color: thixOrange, size: 20), const SizedBox(width: 12), Expanded(child: Text('Un email de confirmation vous a été envoyé avec le suivi.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4)))]),
            ]),
          ),
          const SizedBox(height: 32),
          if(orderId!='N/A') SizedBox(width: double.infinity, height: 56, child: ElevatedButton.icon(onPressed: ()=> context.push('/market/tracking/$orderId'), icon: const Icon(Icons.local_shipping_rounded), label: const Text('Suivre ma commande', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)), style: ElevatedButton.styleFrom(backgroundColor: thixOrange, foregroundColor: pureWhite, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0))),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, height: 56, child: OutlinedButton(onPressed: goHome, style: OutlinedButton.styleFrom(foregroundColor: darkText, side: BorderSide(color: Colors.grey.shade300, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text('Retour à l\'accueil', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)))),
        ]),
      ),
    );
  }

  Widget _row(String label, String value, {bool isTotal=false})=> Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(label, style: TextStyle(color: isTotal? darkText : mutedText, fontWeight: isTotal? FontWeight.w800 : FontWeight.w500, fontSize: isTotal? 15 : 13)),
    Text(value, style: TextStyle(fontWeight: isTotal? FontWeight.w900 : FontWeight.w700, color: isTotal? thixOrange : darkText, fontSize: isTotal? 18 : 14)),
  ]));
}
