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
  static const ink = Color(0xFF080E1F);
  static const deepNavy = Color(0xFF0A1931);
  static const royal = Color(0xFF2D5BFF);
  static const gold = Color(0xFFC5A46A);
  static const bg = Color(0xFFF6F7FB);
  static const cardBorder = Color(0xFFEFF2F8);

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
          SliverToBoxAdapter(child: _header()),
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), child: _balanceWrapper())),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _top4(),
                const SizedBox(height: 32),
                _sectionTitle('Opérations rapides', 'Gérez'),
                const SizedBox(height: 16),
                _grid(), // FIX ICI
                const SizedBox(height: 28),
                _promoCard(),
                const SizedBox(height: 28),
                _sectionTitle('Activité récente', 'Tout voir'),
                const SizedBox(height: 14),
                _tx(),
                const SizedBox(height: 130),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _nav(),
    );
  }

  Widget _balanceWrapper() => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: deepNavy.withOpacity(0.12), blurRadius: 32, offset: const Offset(0, 16)),
          ],
        ),
        child: const BalanceCard(),
      );

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 8),
        child: FutureBuilder<Map<String, String>>(
          future: _getProfile(),
          builder: (c, s) {
            final name = s.data?['name']?? '';
            final initial = s.data?['initial']?? 'T';
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [gold, gold.withOpacity(0.2)])),
                    child: Container(
                      width: 46, height: 46,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                      child: Center(child: Text(initial, style: const TextStyle(color: deepNavy, fontWeight: FontWeight.w900, fontSize: 18))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name.isEmpty? 'Bonjour' : 'Bonjour, $name', style: const TextStyle(color: ink, fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: deepNavy.withOpacity(0.06), borderRadius: BorderRadius.circular(20)),
                      child: const Text('PRIVATE MEMBER', style: TextStyle(color: deepNavy, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                    ),
                  ]),
                ]),
                Row(children: [
                  _hIcon(Icons.qr_code_scanner, () => context.push(AppRoutes.thixMoneyScanner)),
                  const SizedBox(width: 10),
                  _hIcon(Icons.notifications_none_rounded, () {}, dot: true),
                ]),
              ],
            );
          },
        ),
      );

  Widget _hIcon(IconData i, VoidCallback t, {bool dot = false}) => GestureDetector(
        onTap: t,
        child: Stack(clipBehavior: Clip.none, children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: cardBorder)),
            child: Icon(i, color: ink, size: 20),
          ),
          if (dot) Positioned(top: -2, right: -2, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: const Color(0xFFFF3B5C), shape: BoxShape.circle, border: Border.all(color: bg, width: 2.5)))),
        ]),
      );

  // TOP 4 - ESPACE CORRIGÉ
  Widget _top4() {
    final items = [
      {'l': 'Recharger', 'i': Icons.add_rounded, 'c': royal, 'r': AppRoutes.thixMoneyRecharge},
      {'l': 'Envoyer', 'i': Icons.arrow_outward_rounded, 'c': deepNavy, 'r': AppRoutes.thixMoneySend},
      {'l': 'Historique', 'i': Icons.receipt_long_rounded, 'c': ink, 'r': AppRoutes.thixMoneyLoans},
      {'l': 'Scanner', 'i': Icons.qr_code_rounded, 'c': gold, 'r': AppRoutes.thixMoneyScanner},
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: items.map((a) {
          final color = a['c'] as Color;
          return Column(
            children: [
              GestureDetector(
                onTap: () => context.push(a['r'] as String),
                child: Container(
                  width: 62, height: 62,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: color, boxShadow: [BoxShadow(color: color.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 8))]),
                  child: Icon(a['i'] as IconData, color: Colors.white, size: 26),
                ),
              ),
              const SizedBox(height: 12), // <-- DISTANCE FIXÉE ICI
              Text(a['l'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ink)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _sectionTitle(String t, String action) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ink)),
          Text(action, style: TextStyle(fontSize: 12.5, color: ink.withOpacity(0.4), fontWeight: FontWeight.w600)),
        ]),
      );

  // GRILLE CORRIGÉE - PLUS DE RESPIRATION
  Widget _grid() {
    final services = [
      {'l': 'Crédit\nexpress', 'c': royal, 'i': Icons.bolt_rounded, 'r': AppRoutes.thixMoneyLoans},
      {'l': 'Assurance', 'c': const Color(0xFF0E9F6E), 'i': Icons.verified_user_rounded, 'r': ''},
      {'l': 'Épargne', 'c': gold, 'i': Icons.savings_rounded, 'r': AppRoutes.thixMoneySavings},
      {'l': 'Change', 'c': const Color(0xFF7C3AED), 'i': Icons.swap_horiz_rounded, 'r': ''},
      {'l': 'Marchand', 'c': const Color(0xFFEA580C), 'i': Icons.storefront_rounded, 'r': ''},
      {'l': 'Dons', 'c': const Color(0xFFE11D48), 'i': Icons.favorite_rounded, 'r': ''},
      {'l': 'Tontine', 'c': const Color(0xFF0EA5E9), 'i': Icons.groups_rounded, 'r': AppRoutes.thixMoneyTontines},
      {'l': 'Éducation', 'c': const Color(0xFF0891B2), 'i': Icons.school_rounded, 'r': ''},
      {'l': 'Virement\nmondial', 'c': deepNavy, 'i': Icons.public_rounded, 'r': ''},
      {'l': 'Micro\nfinance', 'c': const Color(0xFF16A34A), 'i': Icons.account_balance_rounded, 'r': ''},
      {'l': 'Investir', 'c': const Color(0xFFCA8A04), 'i': Icons.trending_up_rounded, 'r': AppRoutes.thixMoneyInvestments},
      {'l': 'Planning', 'c': ink, 'i': Icons.calendar_month_rounded, 'r': ''},
    ];

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 12,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 14, // +2
        crossAxisSpacing: 12,
        childAspectRatio: 0.72, // FIX: plus haut = plus de place pour le texte
      ),
      itemBuilder: (_, i) {
        final s = services[i];
        final color = s['c'] as Color;
        return GestureDetector(
          onTap: () => (s['r'] as String).isNotEmpty? context.push(s['r'] as String) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6), // PADDING INTERNE
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: cardBorder)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(13)),
                  child: Icon(s['i'] as IconData, color: color, size: 22),
                ),
                const SizedBox(height: 12), // DISTANCE ICONE -> TEXTE
                Expanded(
                  child: Text(s['l'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ink, height: 1.25, letterSpacing: -0.1)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _promoCard() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(colors: [Color(0xFF080E1F), Color(0xFF162A5A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('DISPONIBLE MAINTENANT', style: TextStyle(color: gold, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
            const SizedBox(height: 8),
            const Text('Crédit Instantané', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('Jusqu\'à 500 000 FCFA par IA.', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12.5)),
          ])),
          Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.arrow_outward_rounded, size: 22, color: ink)),
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
              if (list.isEmpty) return Container(margin: const EdgeInsets.symmetric(horizontal: 20), padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: const Center(child: Text('Aucune activité récente', style: TextStyle(fontSize: 13, color: Colors.black38))));
              return Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(children: list.map<Widget>((t) {
                bool isDeposit = (t['type'] == 'reception' || t['type'] == 'Deposit');
                return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: cardBorder)), child: Row(children: [
                  Container(width: 44, height: 44, decoration: BoxDecoration(color: isDeposit? const Color(0xFF0E9F6E).withOpacity(0.1) : deepNavy.withOpacity(0.06), borderRadius: BorderRadius.circular(12)), child: Icon(isDeposit? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, size: 20, color: isDeposit? const Color(0xFF0E9F6E) : deepNavy)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text((t['type']?? 'Transaction').toString().toUpperCase(), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: ink)),
                    const SizedBox(height: 4),
                    Text(t['ref_transa']?? 'THIX • Transfert', style: TextStyle(fontSize: 11, color: ink.withOpacity(0.4))),
                  ])),
                  Text('${isDeposit? '+' : '-'} ${t['montant']} ${t['devise']}', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: isDeposit? const Color(0xFF0E9F6E) : ink)),
                ]));
              }).toList()));
            },
          );
        },
      );

  Widget _nav() => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(height: 72, decoration: BoxDecoration(color: Colors.white.withOpacity(0.92), border: Border.all(color: Colors.white)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                const _NavIcon(icon: Icons.home_rounded, isActive: true),
                const _NavIcon(icon: Icons.bar_chart_rounded),
                Transform.translate(offset: const Offset(0, -18), child: GestureDetector(onTap: () => context.push(AppRoutes.thixMoneyScanner), child: Container(width: 60, height: 60, decoration: BoxDecoration(color: ink, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)), child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 26)))),
                const _NavIcon(icon: Icons.account_balance_wallet_rounded),
                const _NavIcon(icon: Icons.person_rounded),
              ])),
            ),
          ),
        ),
      );
}

class _NavIcon extends StatelessWidget {
  final IconData icon; final bool isActive; const _NavIcon({required this.icon, this.isActive = false});
  @override
  Widget build(BuildContext context) => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(icon, color: isActive? const Color(0xFF080E1F) : const Color(0xFF080E1F).withOpacity(0.25), size: 26),
    if (isActive) Container(margin: const EdgeInsets.only(top: 4), width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFF080E1F), shape: BoxShape.circle)),
  ]);
}
