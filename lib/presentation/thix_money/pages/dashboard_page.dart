// lib/presentation/thix_money/pages/dashboard_page.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/nav.dart';
import '../providers/wallet_provider.dart';
import '../services/wallet_service.dart';
import '../widgets/balance_card.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});
  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  static const ink = Color(0xFF070F1E);
  static const navy = Color(0xFF0A1931);
  static const navySoft = Color(0xFF162B5E);
  static const gold = Color(0xFFC5A46A);
  static const bg = Color(0xFFF2F4F8);
  static const line = Color(0xFFE8ECF3);

  Future<Map<String, String>> _getProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return {'name': '', 'initial': 'T'};
    final r = await Supabase.instance.client.from('profiles').select('first_name, full_name').eq('id', user.id).maybeSingle();
    final full = (r?['first_name']?? r?['full_name']?? user.email?.split('@').first?? 'THIX').toString();
    final first = full.split(' ').first;
    return {'name': first, 'initial': first.isNotEmpty? first[0].toUpperCase() : 'T'};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      extendBody: true,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(child: _headerFyatuStyle()),
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 10, 20, 14), child: _heroBalance())),
          SliverToBoxAdapter(child: _depositWithdrawRow()),
          SliverToBoxAdapter(
            child: Column(children: [
              const SizedBox(height: 22),
              _quickLinksCard(), // INSPIRÉ FYATU MAIS DISPOSITION DIFFÉRENTE
              const SizedBox(height: 22),
              _promoCard(),
              const SizedBox(height: 22),
              _sectionHead('Transactions récentes', 'Voir tout'),
              const SizedBox(height: 12),
              _tx(),
              const SizedBox(height: 130),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: _nav(),
    );
  }

  // HEADER STYLE FYATU: Avatar + Nom + ID + Pill Business + Cloche
  Widget _headerFyatuStyle() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
        child: FutureBuilder<Map<String, String>>(
          future: _getProfile(),
          builder: (c, s) {
            final name = s.data?['name']?? 'Hellen';
            final initial = s.data?['initial']?? 'H';
            return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: ink.withOpacity(0.08), blurRadius: 12)]),
                  child: CircleAvatar(backgroundColor: navy, child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
                ),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: ink, letterSpacing: -0.2)),
                  const SizedBox(height: 2),
                  Text('F00${DateTime.now().millisecond} • THIX', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ink.withOpacity(0.4))),
                ]),
              ]),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: navy.withOpacity(0.2), blurRadius: 12)]),
                  child: Row(children: [Container(width: 6, height: 6, decoration: const BoxDecoration(color: gold, shape: BoxShape.circle)), const SizedBox(width: 6), const Text('Mon Business', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))]),
                ),
                const SizedBox(width: 10),
                _iconBell(),
              ]),
            ]);
          },
        ),
      );

  Widget _iconBell() => Stack(clipBehavior: Clip.none, children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: line)), child: const Icon(Icons.notifications_none_rounded, size: 20, color: ink)),
        Positioned(top: -2, right: -2, child: Container(width: 16, height: 16, decoration: BoxDecoration(color: const Color(0xFFFF3B30), shape: BoxShape.circle, border: Border.all(color: bg, width: 2)), child: const Center(child: Text('1', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900))))),
      ]);

  // HERO BALANCE - DIFFÉRENT DE FYATU: Pas de boutons dedans, design noir or avec pattern
  Widget _heroBalance() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(colors: [ink, navySoft], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: ink.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: Stack(children: [
        Positioned(right: -20, top: -20, child: Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, color: gold.withOpacity(0.08)))),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('SOLDE DISPONIBLE', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
            Icon(Icons.visibility_off_outlined, size: 18, color: Colors.white.withOpacity(0.5)),
          ]),
          const SizedBox(height: 14),
          const Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('\$1,109.99', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -1.2, height: 1)),
            SizedBox(width: 8),
            Padding(padding: EdgeInsets.only(bottom: 6), child: Text('USD', style: TextStyle(color: gold, fontSize: 13, fontWeight: FontWeight.w800))),
          ]),
        ]),
      ]),
    );
  }

  // DEPOSIT/WITHDRAW - DEHORS DE LA CARTE (INVERSE DE FYATU)
  Widget _depositWithdrawRow() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: [
          Expanded(child: _actionBtn(icon: Icons.arrow_downward_rounded, label: 'Déposer', dark: true, onTap: () => context.push(AppRoutes.thixMoneyRecharge))),
          const SizedBox(width: 12),
          Expanded(child: _actionBtn(icon: Icons.arrow_upward_rounded, label: 'Retirer', dark: false, onTap: () => context.push(AppRoutes.thixMoneySend))),
        ]),
      );

  Widget _actionBtn({required IconData icon, required String label, required bool dark, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(color: dark? navy : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: dark? Colors.transparent : line), boxShadow: [BoxShadow(color: ink.withOpacity(dark? 0.15 : 0.04), blurRadius: 16, offset: const Offset(0, 6))]),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 28, height: 28, decoration: BoxDecoration(color: dark? Colors.white.withOpacity(0.15) : navy.withOpacity(0.08), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: dark? Colors.white : navy)),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: dark? Colors.white : ink, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
        ]),
      ),
    );
  }

  // QUICK LINKS CARD - INSPIRÉ FYATU MAIS AVEC TA GRILLE 12 SERVICES + ESPACEMENT FIXÉ
  Widget _quickLinksCard() {
    final quick = [
      {'l': 'Envoyer', 'i': Icons.send_rounded, 'c': const Color(0xFF2D5BFF), 'r': AppRoutes.thixMoneySend},
      {'l': 'Crédit', 'i': Icons.bolt_rounded, 'c': const Color(0xFF2D5BFF), 'r': AppRoutes.thixMoneyLoans},
      {'l': 'eSIM', 'i': Icons.sim_card_rounded, 'c': const Color(0xFF7C3AED), 'r': ''},
      {'l': 'Airtime', 'i': Icons.phone_rounded, 'c': const Color(0xFF0E9F6E), 'r': ''},
      {'l': 'Comptes', 'i': Icons.account_balance_wallet_rounded, 'c': navy, 'r': ''},
      {'l': 'Transactions', 'i': Icons.receipt_long_rounded, 'c': const Color(0xFFEA580C), 'r': AppRoutes.thixMoneyLoans},
      {'l': 'Marchand', 'i': Icons.storefront_rounded, 'c': const Color(0xFFEA580C), 'r': AppRoutes.thixMarket},
      {'l': 'Support', 'i': Icons.headset_mic_rounded, 'c': ink, 'r': ''},
      {'l': 'Épargne', 'i': Icons.savings_rounded, 'c': gold, 'r': AppRoutes.thixMoneySavings},
      {'l': 'Tontine', 'i': Icons.groups_rounded, 'c': const Color(0xFF0EA5E9), 'r': AppRoutes.thixMoneyTontines},
      {'l': 'Investir', 'i': Icons.trending_up_rounded, 'c': const Color(0xFFCA8A04), 'r': AppRoutes.thixMoneyInvestments},
      {'l': 'Éducation', 'i': Icons.school_rounded, 'c': const Color(0xFF0891B2), 'r': AppRoutes.education},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: line), boxShadow: [BoxShadow(color: ink.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Accès rapides', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: ink, letterSpacing: -0.3)),
        const SizedBox(height: 18),
        GridView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: quick.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 20, crossAxisSpacing: 8, childAspectRatio: 0.78),
          itemBuilder: (_, i) {
            final s = quick[i];
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => (s['r'] as String).isNotEmpty? context.push(s['r'] as String) : null,
              child: Column(children: [
                Container(
                  width: 54, height: 54,
                  decoration: BoxDecoration(color: (s['c'] as Color).withOpacity(0.09), borderRadius: BorderRadius.circular(16), border: Border.all(color: (s['c'] as Color).withOpacity(0.1))),
                  child: Icon(s['i'] as IconData, color: s['c'] as Color, size: 24),
                ),
                const SizedBox(height: 10), // DISTANCE FIXÉE
                Text(s['l'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ink, height: 1.2)),
              ]),
            );
          },
        ),
      ]),
    );
  }

  Widget _sectionHead(String t, String a) => Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(t, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: ink)), Text(a, style: TextStyle(fontSize: 12, color: ink.withOpacity(0.4), fontWeight: FontWeight.w600))]));

  Widget _promoCard() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20), padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.white, border: Border.all(color: line)),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: gold.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.bolt_rounded, color: Color(0xFF9C7A3C))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Crédit instantané', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: ink)), const SizedBox(height: 2), Text('Jusqu\'à 500K FCFA en 5 min', style: TextStyle(fontSize: 11.5, color: ink.withOpacity(0.5)))])),
          Container(width: 32, height: 32, decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white)),
        ]),
      );

  Widget _tx() => FutureBuilder<String>(
        future: ref.read(walletServiceProvider).getVerifiedThixId(),
        builder: (c, s) {
          if (!s.hasData) return const SizedBox();
          return FutureBuilder(
            future: Supabase.instance.client.from('thix_transactions').select().eq('thix_id', s.data!).order('created_at', ascending: false).limit(3),
            builder: (c, snap) {
              final list = (snap.data as List?)?? [];
              if (list.isEmpty) return Container(margin: const EdgeInsets.symmetric(horizontal: 20), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: line)), child: const Center(child: Text('Aucune transaction', style: TextStyle(fontSize: 12, color: Colors.black38))));
              return Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(children: list.map<Widget>((t) {
                bool isDeposit = (t['type'] == 'reception' || t['type'] == 'Deposit');
                return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: line)), child: Row(children: [
                  Container(width: 40, height: 40, decoration: BoxDecoration(color: isDeposit? const Color(0xFF0E9F6E).withOpacity(0.1) : navy.withOpacity(0.06), borderRadius: BorderRadius.circular(10)), child: Icon(isDeposit? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, size: 18, color: isDeposit? const Color(0xFF0E9F6E) : navy)),
                  const SizedBox(width: 10),
                  Expanded(child: Text((t['type']?? 'Transaction').toString(), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: ink))),
                  Text('${t['montant']} ${t['devise']}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: ink)),
                ]));
              }).toList()));
            },
          );
        },
      );

  Widget _nav() => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: ink.withOpacity(0.1), blurRadius: 24)]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(height: 68, decoration: BoxDecoration(color: Colors.white.withOpacity(0.9)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  const _NavIcon(icon: Icons.home_rounded, isActive: true),
                  const _NavIcon(icon: Icons.bar_chart_rounded),
                  GestureDetector(onTap: () => context.push(AppRoutes.thixMoneyScanner), child: Container(width: 48, height: 48, decoration: const BoxDecoration(color: ink, shape: BoxShape.circle), child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 22))),
                  const _NavIcon(icon: Icons.wallet_rounded),
                  const _NavIcon(icon: Icons.person_rounded),
                ])),
              ),
            ),
          ),
        ),
      );
}

class _NavIcon extends StatelessWidget {
  final IconData icon; final bool isActive; const _NavIcon({required this.icon, this.isActive = false});
  @override
  Widget build(BuildContext context) => Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: isActive? const Color(0xFF070F1E) : const Color(0xFF070F1E).withOpacity(0.28), size: 24), if (isActive) Container(margin: const EdgeInsets.only(top: 4), width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFF070F1E), shape: BoxShape.circle))]);
}
