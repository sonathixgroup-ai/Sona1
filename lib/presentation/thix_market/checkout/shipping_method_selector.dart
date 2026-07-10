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

  // ─── Palette Élite ──────────────────────────────────────────────
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color primaryBlue = Color(0xFF2D6CDF);
  static const Color softBlue = Color(0xFFEFF5FF);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF10192E);
  static const Color mutedText = Color(0xFF7386A8);
  static const Color gold = Color(0xFFE3B23C);
  static const Color danger = Color(0xFFFF5B3D);

  @override
  void initState() {
    super.initState();
    _methods = const [
      {'id': 'express', 'name': 'Express', 'price': 5000, 'days': '24h'},
      {'id': 'standard', 'name': 'Standard', 'price': 2500, 'days': '2 à 3 jours'},
      {'id': 'pickup', 'name': 'Point relais', 'price': 0, 'days': 'Le jour même'},
    ];
  }

  @override
  Widget build(BuildContext context) {
    // La devise de livraison est toujours en FC (CDF)
    const shippingSymbol = 'FC';

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
                    color: isSelected ? primaryBlue : Colors.grey[200]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: RadioListTile<Map<String, dynamic>>(
                  value: method,
                  groupValue: widget.provider.selectedShippingMethod,
                  onChanged: (value) => widget.provider.selectShippingMethod(value!),
                  activeColor: primaryBlue,
                  title: Text(
                    method['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: darkText,
                    ),
                  ),
                  subtitle: Text(
                    '${method['days']} · ${method['price']} $shippingSymbol',
                    style: TextStyle(color: mutedText),
                  ),
                  secondary: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryBlue.withOpacity(0.1) : softBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      method['price'] == 0 ? 'GRATUIT' : '${method['price']} $shippingSymbol',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: isSelected ? primaryBlue : mutedText,
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
