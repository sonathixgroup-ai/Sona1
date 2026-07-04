// lib/presentation/thix_market/pages/product_detail_page.dart
import 'package:flutter/material.dart';
import '../widgets/products/product_detail.dart';

class ProductDetailPage extends StatelessWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    // Le widget ProductDetail gère déjà son propre Scaffold
    return ProductDetail(productId: productId);
  }
}
