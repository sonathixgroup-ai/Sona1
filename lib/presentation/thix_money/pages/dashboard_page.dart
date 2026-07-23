// lib/presentation/thix_money/pages/dashboard_page.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/nav.dart';
import '../providers/wallet_provider.dart';
import '../services/wallet_service.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});
  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  bool _soldeVisible = true;
  static const navyDeep = Color(0xFF0A1F44);
  static const navy = Color(0xFF123B7A);
  static const primaryBlue = Color(0xFF2D6CDF);
  static const gold = Color(0xFFE3B23C);
  static const ivory = Color(0xFFF6F7FB);

  Future<String> _getUserName() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return 'THIX';
    final res = await Supabase.instance.client.from('profiles').select('first_name, full_name').eq('id', user.id).maybeSingle();
    if (res == null) return user.email?.split('@').first?? 'THIX';
    return (res['first_name']?? res['full_name']?? 'THIX').toString().split(' ').first;
  }

  final List<_ThixService> _services = const [
    _ThixService('Crédit\ninstantané', Icons.bolt_rounded, [Color(0xFF2D6CDF), Color(0xFF123B7A)], AppRoutes.thixMoneyLoans),
    _ThixService('Assurance', Icons.shield_rounded, [Color(0xFF1FA97F), Color(0xFF0E6B4E)], null),
    _ThixService('Épargne\nplanifiée', Icons.savings_rounded, [Color(0xFFE3B23C), Color(0xFFB8862A)], AppRoutes.thixMoneySavings),
    _ThixService('Change', Icons.swap_horiz_rounded, [Color(0xFF9B59B6), Color(0xFF5E3370)], null),
    _ThixService('Marchand', Icons.storefront_rounded, [Color(0xFFE0743C), Color(0xFF9C4A22)], AppRoutes.thixMarket),
    _ThixService('Don &\nContributions', Icons.volunteer_activism_rounded, [Color(0xFFE0507A), Color(0xFF9C2E4E)], null),
    _ThixService('Ma Tontine', Icons.groups_rounded, [Color(0xFF2DA6DF), Color(0xFF12557A)], AppRoutes.thixMoneyTontines),
    _ThixService('Éducation', Icons.school_rounded, [Color(0xFF3CB4E3), Color(0xFF1D6F8C)], AppRoutes.education),
    _ThixService('Virement\ninternational', Icons.public_rounded, [Color(0xFF123B7A), Color(0xFF0A1F44)], AppRoutes.thixMoneySend),
    _ThixService('Microfinance', Icons.account_balance_rounded, [Color(0xFF4CAF50), Color(0xFF2E6B30)], AppRoutes.thixMoneyLoans),
    _ThixService('Investissement', Icons.trending_up_rounded, [Color(0xFFE3B23C), Color(0xFF8A6420)], AppRoutes.thixMoneyInvestments),
    _ThixService('Planification', Icons.calendar_month_rounded, [Color(0xFF2D6CDF), Color(0xFF1A3D8C)], AppRoutes.thixMoneySavings),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ivory,
      extendBody: true,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(walletStreamProvider),
        child: CustomScrollView(slivers: [
          _header(),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -38),
              child: Column(children: [
                _soldeCard(),
                const SizedBox(height: 12),
                _top4Actions(),
                const SizedBox(height: 14),
                _sectionHeader('Services financiers'),
                _servicesGrid(),
                const SizedBox(height: 12),
                _promo(),
                const SizedBox(height: 12),
                _sectionHeader('Transactions récentes'),
                _transactions(),
                const SizedBox(height: 90),
              ]),
            ),
          ),
        ]),
      ),
      bottomNavigationBar: _navBar(),
    );
  }

  // HEADER COMPACT + NOM DYNAMIQUE
  Widget _header() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 44, 16, 62),
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [navyDeep, navy]), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28))),
        child: FutureBuilder<String>(
          future: _getUserName(),
          builder: (context, snap) {
            final name = snap.data?? '...';
            final initial = name.isNotEmpty? name[0].toUpperCase() : 'T';
            return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Container(width: 38, height: 38, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [gold, Color(0xFFB8862A)]), border: Border.all(color: Colors.white24, width: 1)), child: Center(child: Text(initial, style: const TextStyle(color: navyDeep, fontWeight: FontWeight.w800, fontSize: 16)))),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Bonjour, $name 👋', style: const TextStyle(color: Colors.white70, fontSize: 11.5)), const SizedBox(height: 1), const Text('THIX MONEY', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800))]),
              ]),
              Row(children: [
                _hIcon(Icons.qr_code_scanner_rounded, () => context.push(AppRoutes.thixMoneyScanner)),
                const SizedBox(width: 8),
                _hIcon(Icons.notifications_none_rounded, () {}, dot: true),
              ]),
            ]);
          },
        ),
      ),
    );
  }

  Widget _hIcon(IconData i, VoidCallback tap, {bool dot = false}) => InkWell(onTap: tap, borderRadius: BorderRadius.circular(20), child: Stack(clipBehavior: Clip.none, children: [Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), shape: BoxShape.circle, border: Border.all(color: Colors.white24)), child: Icon(i, color: Colors.white, size: 18)), if (dot) Positioned(top: 0, right: 0, child: Container(width: 8, height: 8, decoration: BoxDecoration(color: gold, shape: BoxShape.circle, border: Border.all(color: navyDeep, width: 1))))]));

  // SOLDE BIEN PLACE - COMPACT
  Widget _soldeCard() {
    final walletAsync = ref.watch(walletStreamProvider);
    return walletAsync.when(
      loading: () => Container(margin: const EdgeInsets.symmetric(horizontal: 16), height: 120, decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(colors: [primaryBlue, navy])), child: const Center(child: CircularProgressIndicator(color: Colors.white))),
      error: (e, _) => Container(margin: const EdgeInsets.symmetric(horizontal: 16), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)), child: Text('Erreur $e', style: const TextStyle(fontSize: 11))),
      data: (w) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [primaryBlue, Color(0xFF1A3A8F)]), boxShadow: [BoxShadow(color: navy.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Solde disponible', style: TextStyle(color: Colors.white70, fontSize: 11)), InkWell(onTap: () => setState(() => _soldeVisible =!_soldeVisible), child: Icon(_soldeVisible? Icons.visibility_rounded : Icons.visibility_off_rounded, color: Colors.white70, size: 16))]),
          const SizedBox(height: 4),
          Text(_soldeVisible? '${w.soldeCdf} FC' : '••••• FC', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
          Text(_soldeVisible? '≈ ${w.soldeUsd} USD • ${w.thixId}' : '≈ ••• USD', style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ]),
      ),
    );
  }

  // 4 SERVICES EN HAUT COMME DEMANDE - FORME HOMEPAGE
  Widget _top4Actions() {
    final items = [
      {'label': 'Envoyer', 'icon': Icons.arrow_upward_rounded, 'route': AppRoutes.thixMoneySend},
      {'label': 'Recharger', 'icon': Icons.add_rounded, 'route': AppRoutes.thixMoneyRecharge},
      {'label': 'Scanner', 'icon': Icons.qr_code_scanner_rounded, 'route': AppRoutes.thixMoneyScanner},
      {'label': 'Retrait', 'icon': Icons.account_balance_wallet_rounded, 'route': AppRoutes.thixMoneyRetrait},
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: items.map((a) => InkWell(onTap: () => context.push(a['route'] as String), borderRadius: BorderRadius.circular(18), child: Column(children: [
        Container(width: 52, height: 52, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))]), child: Icon(a['icon'] as IconData, color: navy, size: 22)),
        const SizedBox(height: 5),
        Text(a['label'] as String, style: const TextStyle(fontSize: 10.5, color: navyDeep, fontWeight: FontWeight.w600)),
      ]))).toList()),
    );
  }

  Widget _sectionHeader(String t) => Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(t, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: navyDeep)), Text('Voir tout', style: TextStyle(fontSize: 11, color: primaryBlue, fontWeight: FontWeight.w600))]));

  Widget _servicesGrid() => GridView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: _services.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 8, childAspectRatio: 0.82),
    itemBuilder: (context, i) {
      final s = _services[i];
      return InkWell(onTap: () => s.route!= null? context.push(s.route!) : null, borderRadius: BorderRadius.circular(14), child: Column(children: [
        Container(width: 46, height: 46, decoration: BoxDecoration(gradient: LinearGradient(colors: s.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: s.gradient.last.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3))]), child: Icon(s.icon, color: Colors.white, size: 20)),
        const SizedBox(height: 4),
        Text(s.label, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontSize: 8.8, color: navyDeep, fontWeight: FontWeight.w600, height: 1.1)),
      ]));
    },
  );

  Widget _promo() => Container(margin: const EdgeInsets.symmetric(horizontal: 16), padding: const EdgeInsets.all(14), decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), gradient: const LinearGradient(colors: [gold, Color(0xFFB8862A)])), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Crédit instantané', style: TextStyle(color: navyDeep, fontSize: 13, fontWeight: FontWeight.w800)), const SizedBox(height: 2), Text('Jusqu\'à 500 000 FC en 5 minutes, sans dossier', style: TextStyle(color: navyDeep.withOpacity(0.7), fontSize: 10.5))])), const Icon(Icons.arrow_forward_rounded, color: navyDeep, size: 18)]));

  Widget _transactions() {
    return FutureBuilder<String>(future: ref.read(walletServiceProvider).getVerifiedThixId(), builder: (context, thixSnap) {
      if (!thixSnap.hasData) return const SizedBox(height: 30, child: Center(child: CircularProgressIndicator()));
      return FutureBuilder(future: Supabase.instance.client.from('thix_transactions').select().eq('thix_id', thixSnap.data!).order('created_at', ascending: false).limit(3), builder: (context, snap) {
        final list = (snap.data as List?)?? [];
        if (list.isEmpty) return Container(margin: const EdgeInsets.symmetric(horizontal: 16), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: const Text('Aucune transaction', style: TextStyle(fontSize: 11, color: Colors.grey)));
        return Container(margin: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]), child: Column(children: list.map<Widget>((t) {
          final entrant = t['type'] == 'RECHARGE';
          return Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: entrant? const Color(0xFFE7F6EE) : const Color(0xFFEFF3FB), borderRadius: BorderRadius.circular(10)), child: Icon(entrant? Icons.arrow_downward_rounded : Icons.receipt_long_rounded, color: entrant? const Color(0xFF1FA97F) : primaryBlue, size: 16)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t['type']?? '', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: navyDeep)), Text(t['ref_transa']?? '', style: const TextStyle(fontSize: 9, color: Colors.black45))])),
            Text('${entrant? '+' : '-'}${t['montant']} ${t['devise']}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: entrant? const Color(0xFF1FA97F) : navyDeep)),
          ]));
        }).toList()));
      });
    });
  }

  Widget _navBar() => Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 14), child: ClipRRect(borderRadius: BorderRadius.circular(22), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(height: 56, decoration: BoxDecoration(color: navyDeep.withOpacity(0.94), borderRadius: BorderRadius.circular(22)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
    IconButton(icon: const Icon(Icons.home_rounded, color: gold, size: 20), onPressed: () {}),
    IconButton(icon: const Icon(Icons.pie_chart_rounded, color: Colors.white54, size: 20), onPressed: () {}),
    Container(width: 42, height: 42, decoration: BoxDecoration(gradient: const LinearGradient(colors: [gold, Color(0xFFB8862A)]), shape: BoxShape.circle), child: IconButton(icon: const Icon(Icons.qr_code_scanner_rounded, color: navyDeep, size: 18), onPressed: () => context.push(AppRoutes.thixMoneyScanner))),
    IconButton(icon: const Icon(Icons.groups_rounded, color: Colors.white54, size: 20), onPressed: () {}),
    IconButton(icon: const Icon(Icons.person_rounded, color: Colors.white54, size: 20), onPressed: () {}),
  ])))));
}

class _ThixService {
  final String label; final IconData icon; final List<Color> gradient; final String? route;
  const _ThixService(this.label, this.icon, this.gradient, this.route);
}
