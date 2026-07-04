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

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  Future<void> _loadMethods() async {
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _methods = [
        {'id': 'card', 'name': 'Carte bancaire', 'icon': Icons.credit_card, 'color': 0xFF2563EB},
        {'id': 'mobile_money', 'name': 'Mobile Money (Orange/MTN)', 'icon': Icons.phone_android, 'color': 0xFFE5592F},
        {'id': 'thix_money', 'name': 'THIX Money', 'icon': Icons.account_balance_wallet, 'color': 0xFF10B981},
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
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
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isSelected ? const Color(0xFFE5592F) : Colors.grey[200]!, width: isSelected ? 2 : 1),
                ),
                child: RadioListTile<Map<String, dynamic>>(
                  value: method,
                  groupValue: widget.provider.selectedPaymentMethod,
                  onChanged: (value) => widget.provider.selectPaymentMethod(value!),
                  title: Row(
                    children: [
                      Icon(method['icon'], color: Color(method['color'])),
                      const SizedBox(width: 8),
                      Text(method['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  activeColor: const Color(0xFFE5592F),
                  contentPadding: EdgeInsets.zero,
                ),
              );
            },
          ),
        ),
        _buildBottomButton(),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: widget.provider.selectedPaymentMethod != null
            ? () => widget.provider.selectPaymentMethod(widget.provider.selectedPaymentMethod!)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE5592F),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Continuer'),
      ),
    );
  }
}
