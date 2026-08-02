// lib/presentation/market/payment_method_selector.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'checkout_provider.dart';
import '../../../services/market_payment_service.dart';

class PaymentMethodSelector extends ConsumerStatefulWidget {
  const PaymentMethodSelector({super.key});

  @override
  ConsumerState<PaymentMethodSelector> createState() => _PaymentMethodSelectorState();
}

class _PaymentMethodSelectorState extends ConsumerState<PaymentMethodSelector> {
  static const Color primaryBlue = Color(0xFF0B3D91);
  static const Color lightBg = Color(0xFFF6F8FB);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF10192E);
  static const Color mutedText = Color(0xFF7386A8);
  static const Color cardBorder = Color(0xFFEEF1F7);

  final TextEditingController _phoneController = TextEditingController();
  String? _selectedOperator;
  bool _isProcessing = false;

  String _t(BuildContext context, String fr, String en) {
    final lang = Localizations.localeOf(context).languageCode;
    return lang == 'fr' ? fr : en;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(checkoutProvider);
    final notifier = ref.read(checkoutProvider.notifier);
    final isMobileMoneySelected = state.selectedPayment != null && state.selectedPayment!['id'] == 'mobile_money';

    final List<Map<String, dynamic>> mainMethods = [
      {
        'id': 'mobile_money',
        'name': _t(context, 'Mobile Money (RDC)', 'Mobile Money (DRC)'),
        'desc': 'Vodacom, Airtel, Orange, Africell',
        'icon': Icons.phone_android_rounded,
        'color': 0xFF2D6CDF,
      },
      {
        'id': 'cash',
        'name': _t(context, 'Paiement à la livraison', 'Cash on Delivery'),
        'desc': _t(context, 'Règlement en espèces à la réception', 'Pay in cash upon receipt'),
        'icon': Icons.payments_rounded,
        'color': 0xFF00B074,
      },
      {
        'id': 'thix_money',
        'name': 'THIX Money Wallet',
        'desc': _t(context, 'Paiement instantané sécurisé', 'Secure instant payment'),
        'icon': Icons.account_balance_wallet_rounded,
        'color': 0xFFE5592F,
      },
      {
        'id': 'card',
        'name': _t(context, 'Carte Bancaire Internationale', 'International Credit Card'),
        'desc': 'Visa, Mastercard',
        'icon': Icons.credit_card_rounded,
        'color': 0xFF0A1F44,
      },
    ];

    final List<Map<String, dynamic>> mobileOperators = [
      {'id': 'vodacom', 'name': 'Vodacom (M-Pesa)', 'color': 0xFFE60000},
      {'id': 'airtel', 'name': 'Airtel Money', 'color': 0xFFED1C24},
      {'id': 'orange', 'name': 'Orange Money', 'color': 0xFFFF7900},
      {'id': 'africell', 'name': 'Africell (AfriMoney)', 'color': 0xFF662D91},
    ];

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                _t(context, 'Choisissez votre mode de paiement', 'Choose your payment method'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: darkText),
              ),
              const SizedBox(height: 12),

              ...mainMethods.map((method) {
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
                      Row(
                        children: [
                          const Icon(Icons.signal_cellular_alt_rounded, size: 16, color: primaryBlue),
                          const SizedBox(width: 8),
                          Text(
                            _t(context, 'Sélectionnez votre opérateur (RDC)', 'Select your operator (DRC)'),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: primaryBlue),
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
                        itemCount: mobileOperators.length,
                        itemBuilder: (context, i) {
                          final op = mobileOperators[i];
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
                                  Container(width: 10, height: 10, decoration: BoxDecoration(color: opColor, shape: BoxShape.circle)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      op['name'] as String,
                                      style: TextStyle(fontSize: 11.5, fontWeight: isOpSelected ? FontWeight.w900 : FontWeight.w700, color: darkText),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isOpSelected) Icon(Icons.check_circle_rounded, size: 16, color: opColor),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _t(context, 'Numéro de téléphone Mobile Money', 'Mobile Money Phone Number'),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: darkText),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: 'Ex: +243XXXXXXXXX',
                          filled: true,
                          fillColor: pureWhite,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cardBorder)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cardBorder)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Bouton de Paiement Final via Edge Function Supabase
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
                onPressed: (state.selectedPayment == null || (isMobileMoneySelected && (_selectedOperator == null || _phoneController.text.trim().isEmpty)) || _isProcessing)
                    ? null
                    : () async {
                        setState(() => _isProcessing = true);
                        try {
                          final paymentService = MarketPaymentService(Supabase.instance.client);
                          
                          // Appel de l'Edge Function Supabase pour traiter le paiement
                          await paymentService.processOrderPayment(
                            orderId: state.orderId ?? '',
                            amount: state.totalAmount,
                            currency: state.currency,
                            paymentMethod: state.selectedPayment!['id'],
                            phoneNumber: _phoneController.text.trim(),
                            operator: _selectedOperator,
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(_t(context, 'Paiement effectué avec succès !', 'Payment successful!'))),
                            );
                            // Redirection vers la page de succès ou confirmation finale
                            // context.go('/market/order-success');
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isProcessing = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: pureWhite,
                  disabledBackgroundColor: Colors.grey.shade200,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isProcessing
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_t(context, 'Payer maintenant', 'Pay Now'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
