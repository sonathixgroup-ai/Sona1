// lib/presentation/thix_market/checkout/shipping_method_selector.dart
import 'package:flutter/material.dart';
import 'checkout_provider.dart';

class ShippingMethodSelector extends StatefulWidget {
  final CheckoutProvider provider;

  const ShippingMethodSelector({super.key, required this.provider});

  @override
  State<ShippingMethodSelector> createState() => _ShippingMethodSelectorState();
}

class _ShippingMethodSelectorState extends State<ShippingMethodSelector> {
  late final List<Map<String, dynamic>> _methods;

  // ─── Palette THIX ID ────────────────────────────────────────────
  static const Color thixOrange = Color(0xFFE5592F);
  static const Color softBlue = Color(0xFFEFF5FF);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF10192E);
  static const Color mutedText = Color(0xFF7386A8);

  @override
  void initState() {
    super.initState();
    _methods = const [
      {
        'id': 'home_delivery', 
        'name': 'Livraison à domicile', 
        'price': 0, 
        'price_label': 'Fixé par le livreur', 
        'days': 'Le livreur vous contactera'
      },
      {
        'id': 'pickup', 
        'name': 'Point relais THIX', 
        'price': 0, 
        'price_label': 'Gratuit', 
        'days': 'Retrait en boutique'
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _methods.length,
            itemBuilder: (context, index) {
              final method = _methods[index];
              final isSelected = widget.provider.selectedShippingMethod?['id'] == method['id'];
              
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
                child: RadioListTile<Map<String, dynamic>>(
                  value: method,
                  groupValue: widget.provider.selectedShippingMethod,
                  onChanged: (value) => widget.provider.selectShippingMethod(value!),
                  activeColor: thixOrange,
                  title: Text(
                    method['name'],
                    style: const TextStyle(fontWeight: FontWeight.w700, color: darkText),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      method['days'],
                      style: TextStyle(color: mutedText, fontSize: 13),
                    ),
                  ),
                  secondary: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? thixOrange.withOpacity(0.1) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      method['price_label'],
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        color: isSelected ? thixOrange : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: widget.provider.selectedShippingMethod == null
                ? null
                : () => widget.provider.selectShippingMethod(widget.provider.selectedShippingMethod!),
            style: ElevatedButton.styleFrom(
              backgroundColor: thixOrange,
              foregroundColor: pureWhite,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
