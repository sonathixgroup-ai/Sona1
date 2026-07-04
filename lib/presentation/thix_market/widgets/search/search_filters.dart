import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearchFilters extends StatefulWidget {
  final Function(Map<String, dynamic> filters) onApply;
  final Map<String, dynamic>? initialFilters;

  const SearchFilters({
    super.key,
    required this.onApply,
    this.initialFilters,
  });

  @override
  State<SearchFilters> createState() => _SearchFiltersState();
}

class _SearchFiltersState extends State<SearchFilters> {
  RangeValues _priceRange = const RangeValues(0, 1000000);
  RangeValues _distanceRange = const RangeValues(0, 50);
  double _minRating = 0;
  String? _selectedCondition;
  String? _selectedShipping;
  List<String> _selectedPaymentMethods = [];
  bool _hasFreeShipping = false;
  bool _onlyVerifiedSellers = false;

  final List<Map<String, dynamic>> _conditions = [
    {'id': 'new', 'name': 'Neuf', 'icon': Icons.fiber_new},
    {'id': 'like_new', 'name': 'Comme neuf', 'icon': Icons.star},
    {'id': 'good', 'name': 'Bon état', 'icon': Icons.thumb_up},
    {'id': 'fair', 'name': 'État correct', 'icon': Icons.hourglass_empty},
  ];

  final List<Map<String, dynamic>> _shippingOptions = [
    {'id': 'delivery', 'name': 'Livraison', 'icon': Icons.local_shipping},
    {'id': 'pickup', 'name': 'Retrait', 'icon': Icons.store},
    {'id': 'both', 'name': 'Les deux', 'icon': Icons.swap_horiz},
  ];

  final List<Map<String, dynamic>> _paymentMethods = [
    {'id': 'thix_money', 'name': 'THIX Money', 'icon': Icons.account_balance_wallet},
    {'id': 'card', 'name': 'Carte bancaire', 'icon': Icons.credit_card},
    {'id': 'mobile_money', 'name': 'Mobile Money', 'icon': Icons.phone_android},
    {'id': 'cash', 'name': 'Espèces', 'icon': Icons.money},
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialFilters();
  }

  void _loadInitialFilters() {
    if (widget.initialFilters != null) {
      setState(() {
        _priceRange = RangeValues(
          widget.initialFilters!['min_price']?.toDouble() ?? 0,
          widget.initialFilters!['max_price']?.toDouble() ?? 1000000,
        );
        _distanceRange = RangeValues(
          widget.initialFilters!['min_distance']?.toDouble() ?? 0,
          widget.initialFilters!['max_distance']?.toDouble() ?? 50,
        );
        _minRating = widget.initialFilters!['min_rating']?.toDouble() ?? 0;
        _selectedCondition = widget.initialFilters!['condition'];
        _selectedShipping = widget.initialFilters!['shipping_type'];
        _selectedPaymentMethods = List<String>.from(widget.initialFilters!['payment_methods'] ?? []);
        _hasFreeShipping = widget.initialFilters!['free_shipping'] ?? false;
        _onlyVerifiedSellers = widget.initialFilters!['verified_sellers'] ?? false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filtres avancés',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: _resetFilters,
                child: const Text('Réinitialiser'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Prix
          const Text(
            'Prix (FCFA)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 1000000,
            divisions: 100,
            labels: RangeLabels(
              '${_priceRange.start.toInt()} FCFA',
              '${_priceRange.end.toInt()} FCFA',
            ),
            activeColor: const Color(0xFFE5592F),
            onChanged: (values) {
              setState(() => _priceRange = values);
            },
          ),
          const SizedBox(height: 16),

          // Distance (si géolocalisation activée)
          const Text(
            'Distance (km)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          RangeSlider(
            values: _distanceRange,
            min: 0,
            max: 50,
            divisions: 50,
            labels: RangeLabels(
              '${_distanceRange.start.toInt()} km',
              '${_distanceRange.end.toInt()} km',
            ),
            activeColor: const Color(0xFFE5592F),
            onChanged: (values) {
              setState(() => _distanceRange = values);
            },
          ),
          const SizedBox(height: 16),

          // Note minimale
          const Text(
            'Note minimum',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _minRating,
                  min: 0,
                  max: 5,
                  divisions: 10,
                  activeColor: const Color(0xFFE5592F),
                  label: _minRating.toString(),
                  onChanged: (value) {
                    setState(() => _minRating = value);
                  },
                ),
              ),
              SizedBox(
                width: 60,
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    Text(
                      _minRating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // État
          const Text(
            'État',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _conditions.map((condition) {
              final isSelected = _selectedCondition == condition['id'];
              return FilterChip(
                label: Text(condition['name']),
                avatar: Icon(condition['icon'], size: 16),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCondition = selected ? condition['id'] : null;
                  });
                },
                selectedColor: const Color(0xFFE5592F).withOpacity(0.1),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Options de livraison
          const Text(
            'Option de livraison',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _shippingOptions.map((option) {
              final isSelected = _selectedShipping == option['id'];
              return FilterChip(
                label: Text(option['name']),
                avatar: Icon(option['icon'], size: 16),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedShipping = selected ? option['id'] : null;
                  });
                },
                selectedColor: const Color(0xFFE5592F).withOpacity(0.1),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Modes de paiement
          const Text(
            'Modes de paiement acceptés',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _paymentMethods.map((method) {
              final isSelected = _selectedPaymentMethods.contains(method['id']);
              return FilterChip(
                label: Text(method['name']),
                avatar: Icon(method['icon'], size: 16),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedPaymentMethods.add(method['id']);
                    } else {
                      _selectedPaymentMethods.remove(method['id']);
                    }
                  });
                },
                selectedColor: const Color(0xFFE5592F).withOpacity(0.1),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Options supplémentaires
          SwitchListTile(
            title: const Text('Livraison gratuite uniquement'),
            value: _hasFreeShipping,
            onChanged: (value) {
              setState(() => _hasFreeShipping = value);
            },
            activeColor: const Color(0xFFE5592F),
          ),
          SwitchListTile(
            title: const Text('Vendeurs vérifiés uniquement'),
            value: _onlyVerifiedSellers,
            onChanged: (value) {
              setState(() => _onlyVerifiedSellers = value);
            },
            activeColor: const Color(0xFFE5592F),
          ),
          const SizedBox(height: 20),

          // Boutons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_getFilters());
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5592F),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Appliquer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getFilters() {
    return {
      'min_price': _priceRange.start.toInt(),
      'max_price': _priceRange.end.toInt(),
      'min_distance': _distanceRange.start.toInt(),
      'max_distance': _distanceRange.end.toInt(),
      'min_rating': _minRating,
      'condition': _selectedCondition,
      'shipping_type': _selectedShipping,
      'payment_methods': _selectedPaymentMethods,
      'free_shipping': _hasFreeShipping,
      'verified_sellers': _onlyVerifiedSellers,
    };
  }

  void _resetFilters() {
    setState(() {
      _priceRange = const RangeValues(0, 1000000);
      _distanceRange = const RangeValues(0, 50);
      _minRating = 0;
      _selectedCondition = null;
      _selectedShipping = null;
      _selectedPaymentMethods = [];
      _hasFreeShipping = false;
      _onlyVerifiedSellers = false;
    });
  }
}
