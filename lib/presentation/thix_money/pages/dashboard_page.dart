// lib/presentation/thix_money/pages/dashboard_page.dart
import 'package:flutter/material.dart';
import '../widgets/balance_card.dart';
import '../widgets/quick_actions.dart';
import '../widgets/wallet_stats.dart';
import '../widgets/service_grid.dart';
import '../widgets/promo_banners.dart';
import '../widgets/tontine_strip.dart';
import '../widgets/section_title.dart';
import 'package:go_router/go_router.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const BalanceCard(),
            const QuickActions(),
            const SizedBox(height: 16),
            const WalletStats(),
            SectionTitle(title: 'Services financiers', onViewAll: () {}),
            const ServiceGrid(),
            const SizedBox(height: 16),
            const PromoBanners(),
            const SizedBox(height: 16),
            SectionTitle(title: 'Mes tontines', onViewAll: () => context.push('/thix-money/tontines')),
            const TontineStrip(),
            const SizedBox(height: 100),
          ]),
        ),
      ),
    );
  }
}
