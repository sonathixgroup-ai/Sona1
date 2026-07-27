import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'checkout_provider.dart';

class PaymentMethodSelector extends ConsumerWidget {
  const PaymentMethodSelector({super.key});

  static const thixOrange = Color(0xFFE5592F);
  static const pureWhite = Color(0xFFFFFFFF);
  static const darkText = Color(0xFF10192E);
  static const mutedText = Color(0xFF7386A8);

  static const _methods = [
    {
      'id': 'mobile_money',
      'name': 'Mobile Money',
      'desc': 'M-Pesa, Airtel, Orange, Africell',
      'icon': Icons.phone_android_rounded,
      'color': 0xFF2D6CDF
    },
    {
      'id': 'cash',
      'name': 'Paiement à la livraison',
      'desc': 'Payez en espèces à la réception',
      'icon': Icons.payments_rounded,
      'color': 0xFF2ECC71
    },
    {
      'id': 'thix_money',
      'name': 'THIX Money',
      'desc': 'Utilisez votre portefeuille numérique',
      'icon': Icons.account_balance_wallet_rounded,
      'color': 0xFFE5592F
    },
    {
      'id': 'card',
      'name': 'Carte bancaire',
      'desc': 'Visa, Mastercard',
      'icon': Icons.credit_card_rounded,
      'color': 0xFF0A1F44
    },
  ];

  @override Widget build(BuildContext context, WidgetRef ref){
    final state = ref.watch(checkoutProvider);
    final notifier = ref.read(checkoutProvider.notifier);

    return Column(children: [
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _methods.length,
        itemBuilder: (context, index){
          final method = _methods[index];
          final isSelected = state.selectedPayment!=null && state.selectedPayment!['id']==method['id'];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isSelected? thixOrange : Colors.grey.shade200, width: isSelected? 2 : 1)),
            child: InkWell(
              onTap: ()=> notifier.selectPaymentMethod(method),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: RadioListTile<Map<String,dynamic>>(
                  value: method,
                  groupValue: state.selectedPayment,
                  onChanged: (v){ if(v!=null) notifier.selectPaymentMethod(v); },
                  activeColor: thixOrange,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: Row(children: [
                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Color(method['color'] as int).withOpacity(0.1), shape: BoxShape.circle), child: Icon(method['icon'] as IconData, color: Color(method['color'] as int), size: 24)),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(method['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w800, color: darkText, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(method['desc'].toString(), style: const TextStyle(color: mutedText, fontSize: 12, fontWeight: FontWeight.w500)),
                    ])),
                  ]),
                  secondary: isSelected? const Icon(Icons.check_circle_rounded, color: thixOrange) : const SizedBox.shrink(),
                ),
              ),
            ),
          );
        },
      )),
      Container(
        padding: const EdgeInsets.fromLTRB(16,12,16,24),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0,-4))]),
        child: SafeArea(top: false, child: SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
          onPressed: state.selectedPayment==null? null : (){ notifier.selectPaymentMethod(state.selectedPayment!); },
          style: ElevatedButton.styleFrom(backgroundColor: thixOrange, foregroundColor: pureWhite, disabledBackgroundColor: Colors.grey.shade200, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
          child: const Text('Continuer', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ))),
      ),
    ]);
  }
}
