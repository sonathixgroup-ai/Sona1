// lib/presentation/market/payment_method_selector.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'checkout_provider.dart';

class PaymentMethodSelector extends ConsumerStatefulWidget {
  const PaymentMethodSelector({super.key});

  @override
  ConsumerState<PaymentMethodSelector> createState() => _PaymentMethodSelectorState();
}

class _PaymentMethodSelectorState extends ConsumerState<PaymentMethodSelector> {
  // Charte graphique unifiée B2B / Retail
  static const Color primaryBlue = Color(0xFF0B3D91);
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color lightBg = Color(0xFFF6F8FB);
  static const Color gold = Color(0xFFF7C948);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF10182B);
  static const Color mutedText = Color(0xFF6B7690);
  static const Color cardBorder = Color(0xFFEEF1F7);

  // Méthodes principales
  final List<Map<String, dynamic>> _mainMethods = [
    {
      'id': 'mobile_money',
      'name': 'Mobile Money (RDC)',
      'desc': 'Vodacom, Airtel, Orange, Africell',
      'icon': Icons.phone_android_rounded,
      'color': 0xFF2D6CDF,
    },
    {
      'id': 'cash',
      'name': 'Paiement à la livraison',
      'desc': 'Règlement en espèces à la réception',
      'icon': Icons.payments_rounded,
      'color': 0xFF00B074,
    },
    {
      'id': 'thix_money',
      'name': 'THIX Money Wallet',
      'desc': 'Paiement instantané sécurisé',
      'icon': Icons.account_balance_wallet_rounded,
      'color': 0xFFE5592F,
    },
    {
      'id': 'card',
      'name': 'Carte Bancaire Internationale',
      'desc': 'Visa, Mastercard',
      'icon': Icons.credit_card_rounded,
      'color': 0xFF0A1F44,
    },
  ];

  // Opérateurs Mobile Money extraits de la carte RDC (Vodacom, Airtel, Orange, Africell)
  final List<Map<String, dynamic>> _mobileOperators = [
    {
      'id': 'vodacom',
      'name': 'Vodacom (M-Pesa)',
      'color': 0xFFE60000, // Rouge Vodacom
      'badge': 'Populaire',
    },
    {
      'id': 'airtel',
      'name': 'Airtel Money',
      'color': 0xFFED1C24, // Rouge Airtel
    },
    {
      'id': 'orange',
      'name': 'Orange Money',
      'color': 0xFFFF7900, // Orange
    },
    {
      'id': 'africell',
      'name': 'Africell (AfriMoney)',
      'color': 0xFF662D91, // Violet / Orange Africell
    },
  ];

  String? _selectedOperator;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(checkoutProvider);
    final notifier = ref.read(checkoutProvider.notifier);
    final isMobileMoneySelected = state.selectedPayment != null && state.selectedPayment!['id'] == 'mobile_money';

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Choisissez votre mode de paiement',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: darkText),
              ),
              const SizedBox(height: 12),

              // Liste des méthodes principales
              ..._mainMethods.map((method) {
                final isSelected = state.selectedPayment != null && state.selectedPayment!['id'] == method['id'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: pureWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSelected ? primaryBlue : cardBorder, width: isSelected ? 2 : 1),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: InkWell(
                    onTap: () {
                      notifier.selectPaymentMethod(method);
                      if (method['id'] != 'mobile_money') {
                        setState(() => _selectedOperator = null);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(method['color'] as int).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(method['icon'] as IconData, color: Color(method['color'] as int), size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(method['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w800, color: darkText, fontSize: 15)),
                                const SizedBox(height: 4),
                                Text(method['desc'].toString(), style: const TextStyle(color: mutedText, fontSize: 12, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          Radio<Map<String, dynamic>>(
                            value: method,
                            groupValue: state.selectedPayment,
                            onChanged: (v) {
                              if (v != null) {
                                notifier.selectPaymentMethod(v);
                                if (v['id'] != 'mobile_money') setState(() => _selectedOperator = null);
                              }
                            },
                            activeColor: primaryBlue,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              // Sous-menu spécifique pour Mobile Money (Affichage des 4 opérateurs de la carte RDC)
              if (isMobileMoneySelected) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: lightBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryBlue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.signal_cellular_alt_rounded, size: 16, color: primaryBlue),
                          SizedBox(width: 8),
                          Text(
                            'Sélectionnez votre opérateur (RDC)',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: primaryBlue),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 2.8,
                        ),
                        itemCount: _mobileOperators.length,
                        itemBuilder: (context, i) {
                          final op = _mobileOperators[i];
                          final isOpSelected = _selectedOperator == op['id'];
                          final opColor = Color(op['color'] as int);

                          return InkWell(
                            onTap: () => setState(() => _selectedOperator = op['id']),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: isOpSelected ? opColor.withOpacity(0.12) : pureWhite,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isOpSelected ? opColor : cardBorder, width: isOpSelected ? 2 : 1),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(color: opColor, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      op['name'] as String,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: isOpSelected ? FontWeight.w900 : FontWeight.w700,
                                        color: darkText,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isOpSelected)
                                    Icon(Icons.check_circle_rounded, size: 16, color: opColor),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Bouton Continuer bas de page
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: BoxDecoration(
            color: pureWhite,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, -4))],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (state.selectedPayment == null || (isMobileMoneySelected && _selectedOperator == null))
                    ? null
                    : () {
                        // Action de validation du paiement
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Paiement sélectionné : ${state.selectedPayment!['name']}${_selectedOperator != null ? ' ($_selectedOperator)' : ''}'),
                            backgroundColor: successGreen,
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: pureWhite,
                  disabledBackgroundColor: Colors.grey.shade200,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Continuer vers le paiement', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static const Color successGreen = Color(0xFF00B074);
}
