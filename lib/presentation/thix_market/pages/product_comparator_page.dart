import 'package:flutter/material.dart';

import '../widgets/products/product_comparator.dart';

class ProductComparatorPage extends StatelessWidget {
  const ProductComparatorPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Comparateur')),
        body: const ProductComparator(),
      );
}
