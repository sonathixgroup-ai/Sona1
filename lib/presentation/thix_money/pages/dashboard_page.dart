// lib/presentation/thix_money/pages/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/balance_card.dart';
import '../widgets/quick_actions.dart';
import '../widgets/wallet_stats.dart';
import '../widgets/service_grid.dart';
import '../widgets/promo_banners.dart';
import '../widgets/tontine_strip.dart';
import '../widgets/section_title.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_item.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txState = ref.watch(transactionProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        title: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF1A3FFF), borderRadius: BorderRadius.circular(10)), child: const Text('T', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
          const SizedBox(width: 8),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('THIX MONEY', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)), Text('Votre argent, votre liberté', style: TextStyle(fontSize: 10, color: Colors.grey))])
        ]),
        actions: [IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}), const CircleAvatar(radius: 16, backgroundImage: NetworkImage('https://i.pravatar.cc/150')), const SizedBox(width: 12)],
      ),
      body: RefreshIndicator(
        onRefresh: () async { ref.read(transactionProvider.notifier).refresh(); },
        child: CustomScrollView(slivers: [
          const SliverToBoxAdapter(child: BalanceCard()),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          const SliverToBoxAdapter(child: QuickActions()),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          const SliverToBoxAdapter(child: WalletStats()),
          SliverToBoxAdapter(child: SectionTitle(title: 'Dernières transactions', onViewAll: () => context.push('/thix-money/history'))),
          SliverList.builder(
            itemCount: txState.items.take(3).length,
            itemBuilder: (_, i) => TransactionItem(tx: txState.items[i]),
          ),
          SliverToBoxAdapter(child: SectionTitle(title: 'Services financiers', onViewAll: () {})),
          const SliverToBoxAdapter(child: ServiceGrid()),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          const SliverToBoxAdapter(child: PromoBanners()),
          SliverToBoxAdapter(child: SectionTitle(title: 'Mes tontines', onViewAll: () => context.push('/thix-money/tontines'))),
          const SliverToBoxAdapter(child: TontineStrip()),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ]),
      ),
    );
  }
}
