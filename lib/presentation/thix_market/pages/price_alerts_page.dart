import 'package:flutter/material.dart';

import '../widgets/products/price_alert.dart';

class PriceAlertsPage extends StatelessWidget {
  const PriceAlertsPage({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: PriceAlert(
              productId: 'demo-product',
              productTitle: 'Produit de démonstration',
              currentPrice: 0,
            ),
          ),
        ),
      );
}
