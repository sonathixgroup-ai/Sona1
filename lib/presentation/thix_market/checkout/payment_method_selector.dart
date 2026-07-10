// lib/presentation/thix_market/checkout/payment_method_selector.dart
import 'package:flutter/material.dart';
import 'checkout_provider.dart';

class PaymentMethodSelector extends StatefulWidget {
  final CheckoutProvider provider;

  const PaymentMethodSelector({super.key, required this.provider});

  @override
  State<PaymentMethodSelector> createState() => _PaymentMethodSelectorState();
}

class _PaymentMethodSelectorState extends State<PaymentMethodSelector> {
  List<Map<String, dynamic>> _methods = [];
  bool _isLoading = true;

  // ─── Palette THIX ID ────────────────────────────────────────────
  static const Color thixOrange = Color(0xFFE5592F);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF10192E);
  static const Color mutedText = Color(0xFF7386A8);

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  Future<void> _loadMethods() async {
    // Simulation d'un court temps de chargement
    await Future.delayed(const Duration(milliseconds: 300));
    
    setState(() {
      _methods = [
        {
          'id': 'mobile_money', 
          'name': 'Mobile Money', 
          'desc': 'M-Pesa, Airtel, Orange, Africell',
          'icon': Icons.phone_android_rounded, 
          'color': 0xFF2D6CDF // Bleu
        },
        {
          'id': 'cash', 
          'name': 'Paiement à la livraison', 
          'desc': 'Payez en espèces à la réception',
          'icon': Icons.payments_rounded, 
          'color': 0xFF2ECC71 // Vert
        },
        {
          'id': 'thix_money', 
          'name': 'THIX Money', 
          'desc': 'Utilisez votre portefeuille numérique',
          'icon': Icons.account_balance_wallet_rounded, 
          'color': 0xFFE5592F // Orange THIX
        },
        {
          'id': 'card', 
          'name': 'Carte bancaire', 
          'desc': 'Visa, Mastercard',
          'icon': Icons.credit_card_rounded, 
          'color': 0xFF0A1F44 // Navy
        },
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: thixOrange));
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _methods.length,
            itemBuilder: (context, index) {
              final method = _methods[index];
              final isSelected = widget.provider.selectedPaymentMethod?['id'] == method['id'];
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isSelected ? thixOrange : Colors.grey[200]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: InkWell(
                  onTap: () => widget.provider.selectPaymentMethod(method),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: RadioListTile<Map<String, dynamic>>(
                      value: method,
                      groupValue: widget.provider.selectedPaymentMethod,
                      onChanged: (value) => widget.provider.selectPaymentMethod(value!),
                      activeColor: thixOrange,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      title: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Color(method['color']).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(method['icon'], color: Color(method['color']), size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  method['name'],
                                  style: const TextStyle(fontWeight: FontWeight.w800, color: darkText, fontSize: 15),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  method['desc'],
                                  style: TextStyle(color: mutedText, fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      secondary: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: thixOrange)
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        // Bouton de validation
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: widget.provider.selectedPaymentMethod == null
                ? null
                : () => widget.provider.selectPaymentMethod(widget.provider.selectedPaymentMethod!),
            style: ElevatedButton.styleFrom(
              backgroundColor: thixOrange,
              foregroundColor: pureWhite,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Continuer',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}
