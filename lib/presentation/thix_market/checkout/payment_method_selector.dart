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

  // ─── Palette Élite ──────────────────────────────────────────────
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color primaryBlue = Color(0xFF2D6CDF);
  static const Color softBlue = Color(0xFFEFF5FF);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF10192E);
  static const Color mutedText = Color(0xFF7386A8);
  static const Color gold = Color(0xFFE3B23C);

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  Future<void> _loadMethods() async {
    // Simuler un chargement
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _methods = [
        {'id': 'card', 'name': 'Carte bancaire', 'icon': Icons.credit_card_rounded, 'color': 0xFF2563EB},
        {'id': 'mobile_money', 'name': 'Mobile Money (Orange/MTN)', 'icon': Icons.phone_android_rounded, 'color': 0xFFE5592F},
        {'id': 'thix_money', 'name': 'THIX Money', 'icon': Icons.account_balance_wallet_rounded, 'color': 0xFF10B981},
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryBlue));
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
                    color: isSelected ? primaryBlue : Colors.grey[200]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: RadioListTile<Map<String, dynamic>>(
                  value: method,
                  groupValue: widget.provider.selectedPaymentMethod,
                  onChanged: (value) => widget.provider.selectPaymentMethod(value!),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(method['color']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(method['icon'], color: Color(method['color'])),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          method['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: darkText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  activeColor: primaryBlue,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  secondary: isSelected
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.check_rounded, size: 16, color: primaryBlue),
                              SizedBox(width: 4),
                              Text(
                                'Sélectionné',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  color: primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        )
                      : null,
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: widget.provider.selectedPaymentMethod == null
                ? null
                : () => widget.provider.selectPaymentMethod(widget.provider.selectedPaymentMethod!),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: pureWhite,
              minimumSize: const Size(double.infinity, 52),
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
