// lib/presentation/thix_market/pages/shop_statistics_page.dart
import 'package:flutter/material.dart';
import '../widgets/shops/shop_statistics.dart';

class ShopStatisticsPage extends StatelessWidget {
  final String shopId;

  const ShopStatisticsPage({super.key, required this.shopId});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Statistiques boutique')),
        body: ShopStatistics(shopId: shopId),
      );
}
