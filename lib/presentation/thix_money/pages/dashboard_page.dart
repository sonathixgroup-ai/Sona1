// lib/presentation/thix_money/pages/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/nav.dart';
import '../widgets/balance_card.dart';
import '../widgets/service_grid.dart';
import '../providers/wallet_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});
  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(title: const Text('THIX MONEY', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: const Text('Votre argent, votre liberté', style: TextStyle(fontSize: 11)), backgroundColor: Colors.white, elevation: 0),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(walletStreamProvider),
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: BalanceCard()),
          SliverToBoxAdapter(child: _QuickActions()),
          SliverToBoxAdapter(child: _SummaryCards()),
          const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Dernières transactions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text('Voir tout >', style: TextStyle(color: Colors.blue, fontSize: 12))]))),
          SliverToBoxAdapter(child: _LastTransactions()),
          const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, 8), child: Text('Services financiers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))),
          SliverToBoxAdapter(child: ServiceGrid()),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ]),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _Action(icon: Icons.send, label: 'Envoyer', color: Color(0xFFE3F2FD), iconColor: Colors.blue, onTap: () => context.push(AppRoutes.thixMoneySend)),
        _Action(icon: Icons.add, label: 'Recharger', color: Color(0xFFE8F5E9), iconColor: Colors.green, onTap: () => context.push(AppRoutes.thixMoneyRecharge)),
        _Action(icon: Icons.qr_code_scanner, label: 'Scanner', color: Color(0xFFEDE7F6), iconColor: Colors.deepPurple, onTap: () => context.push(AppRoutes.thixMoneyScanner)),
        _Action(icon: Icons.money, label: 'Retrait', color: Color(0xFFFFF3E0), iconColor: Colors.orange, onTap: () => context.push(AppRoutes.thixMoneyRetrait)),
      ]),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon; final String label; final Color color; final Color iconColor; final VoidCallback onTap;
  const _Action({required this.icon, required this.label, required this.color, required this.iconColor, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Column(children: [Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: iconColor)), const SizedBox(height: 6), Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))]));
}

class _SummaryCards extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.6, children: [
        _SumCard(title: 'Épargne', value: '0 FC', icon: Icons.savings, onTap: () => context.push(AppRoutes.thixMoneySavings)),
        _SumCard(title: 'Invest', value: '0 actifs', icon: Icons.trending_up, onTap: () => context.push(AppRoutes.thixMoneyInvestments)),
        _SumCard(title: 'Crédits', value: '0 FC', icon: Icons.credit_card, onTap: () => context.push(AppRoutes.thixMoneyLoans)),
        _SumCard(title: 'Tontines', value: '0 actives', icon: Icons.groups, onTap: () => context.push(AppRoutes.thixMoneyTontines)),
      ]),
    );
  }
}

class _SumCard extends StatelessWidget {
  final String title; final String value; final IconData icon; final VoidCallback onTap;
  const _SumCard({required this.title, required this.value, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 18, color: Colors.grey), const Spacer(), Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))]))); 
}

class _LastTransactions extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(future: Future(() async {
      final thixId = await ref.read(ref.read(walletServiceProvider).getVerifiedThixId());
      return await Supabase.instance.client.from('thix_transactions').select().eq('thix_id', thixId).order('created_at', ascending: false).limit(3);
    }), builder: (_, snap) {
      if (!snap.hasData) return const SizedBox(height: 40, child: Center(child: CircularProgressIndicator()));
      final list = snap.data as List;
      if (list.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('Aucune transaction', style: TextStyle(color: Colors.grey, fontSize: 12)));
      return Column(children: list.map((e) => ListTile(leading: const CircleAvatar(child: Icon(Icons.receipt, size: 14)), title: Text(e['type'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), subtitle: Text(e['ref_transa'], style: const TextStyle(fontSize: 10)), trailing: Text('${e['montant']} ${e['devise']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))).toList());
    });
  }
}
