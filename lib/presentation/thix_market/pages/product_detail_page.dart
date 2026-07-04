import 'package:flutter/material.dart';

import '../widgets/products/product_detail.dart';

class ProductDetailPage extends StatelessWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  Widget build(BuildContext context) => ProductDetail(productId: productId);
}
