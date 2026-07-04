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
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFFE5592F) : Colors.grey[200]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: RadioListTile<Map<String, dynamic>>(
                  value: method,
                  groupValue: widget.provider.selectedShippingMethod,
                  onChanged: (value) => widget.provider.selectShippingMethod(value!),
                  title: Text(method['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${method['days']} · ${method['price']} FCFA'),
                  activeColor: const Color(0xFFE5592F),
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
              backgroundColor: const Color(0xFFE5592F),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Continuer'),
          ),
        ),
      ],
    );
  }
}
