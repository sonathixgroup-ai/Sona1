// lib/presentation/thix_market/pages/product_detall_page.dart
import 'package:flutter/material.dart';
import '../pages/product_detall.dart';

class ProductDetallPage extends StatelessWidget {
  final String productId;

  const ProductDetallPage({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    // Le widget ProductDetail gère déjà son propre Scaffold
    return ProductDetail(productId: productId);
  }
}
