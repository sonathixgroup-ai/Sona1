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
import '../widgets/service_grid.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});
  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  // Palette "Grandeur Fintech" : Luxueuse, institutionnelle et moderne
  static const premiumDark = Color(0xFF0F172A);
  static const premiumBlue = Color(0xFF1E3A8A);
  static const premiumGold = Color(0xFFD4AF37);
  static const bgScaffold = Color(0xFFF4F6F9);
  static const surfaceWhite = Colors.white;

  Future<Map<String, String>> _getProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return {'name': '', 'initial': 'T'};
    final r = await Supabase.instance.client
        .from('profiles')
        .select('first_name, full_name')
        .eq('id', user.id)
        .maybeSingle();
    final full = (r?['first_name'] ?? r?['full_name'] ?? user.email?.split('@').first ?? 'THIX').toString();
    final first = full.split(' ').first;
    return {'name': first, 'initial': first.isNotEmpty ? first[0].toUpperCase() : 'T'};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgScaffold,
      extendBody: true,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(child: _header()),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 16),
              child: const BalanceCard(),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _quickActionsBand(), // Bande premium — Envoyer/Recharger/Scanner/Retrait
                const SizedBox(height: 22),

                _sectionTitle('Services Financiers', showAction: false),
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: ServiceGrid(),
                ),

                const SizedBox(height: 22),
                _promoCardPremium(),

                const SizedBox(height: 22),
                _sectionTitle('Opérations Récentes', showAction: true),
                const SizedBox(height: 10),
                _transactionsList(),

                const SizedBox(height: 110),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _premiumNav(),
    );
  }

  // ==========================================
  // HEADER
  // ==========================================
  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 56, 20, 14),
        child: FutureBuilder<Map<String, String>>(
          future: _getProfile(),
          builder: (c, s) {
            final name = s.data?['name'] ?? '';
            final initial = s.data?['initial'] ?? 'T';
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: surfaceWhite,
                        border: Border.all(color: premiumGold.withOpacity(0.5), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: premiumDark.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: Center(
                        child: Text(initial,
                            style: const TextStyle(color: premiumDark, fontWeight: FontWeight.w800, fontSize: 19)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isEmpty ? 'Bienvenue' : 'Bonjour, $name',
                          style: const TextStyle(color: premiumDark, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: premiumBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                          child: const Text('Compte Personnel',
                              style: TextStyle(color: premiumBlue, fontSize: 10.5, fontWeight: FontWeight.w700)),
                        )
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    _actionPill(Icons.qr_code_scanner_rounded, () => context.push(AppRoutes.thixMoneyScanner)),
                    const SizedBox(width: 8),
                    _actionPill(Icons.notifications_outlined, () {}, dot: true),
                  ],
                ),
              ],
            );
          },
        ),
      );

  Widget _actionPill(IconData i, VoidCallback t, {bool dot = false}) => InkWell(
        onTap: t,
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: surfaceWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withOpacity(0.03)),
                boxShadow: [BoxShadow(color: premiumDark.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Icon(i, color: premiumDark, size: 21),
            ),
            if (dot)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE11D48),
                    shape: BoxShape.circle,
                    border: Border.all(color: surfaceWhite, width: 2),
                  ),
                ),
              ),
          ],
        ),
      );

  // ==========================================
  // BANDE ACTIONS RAPIDES — mise en évidence forte
  // Fond dégradé navy/or, distinct du reste (blanc/gris)
  // ==========================================
  Widget _quickActionsBand() {
    final items = [
      {'l': 'Envoyer', 'i': Icons.north_east_rounded, 'r': AppRoutes.thixMoneySend},
      {'l': 'Recharger', 'i': Icons.add_card_rounded, 'r': AppRoutes.thixMoneyRecharge},
      {'l': 'Scanner', 'i': Icons.qr_code_scanner_rounded, 'r': AppRoutes.thixMoneyScanner},
      {'l': 'Retrait', 'i': Icons.south_west_rounded, 'r': null},
    ];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [premiumDark, premiumBlue],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: premiumBlue.withOpacity(0.28), blurRadius: 22, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((a) {
          final route = a['r'] as String?;
          return InkWell(
            onTap: () {
              if (route != null && route.isNotEmpty) {
                context.push(route);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${a['l']} sera bientôt disponible !'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: premiumDark,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: premiumGold.withOpacity(0.35), width: 1),
                  ),
                  child: Icon(a['i'] as IconData, color: premiumGold, size: 23),
                ),
                const SizedBox(height: 8),
                Text(
                  a['l'] as String,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.2),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _sectionTitle(String t, {bool showAction = false}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(t, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: premiumDark, letterSpacing: -0.4)),
            if (showAction)
              Text('Voir tout', style: TextStyle(fontSize: 13, color: premiumBlue, fontWeight: FontWeight.w700)),
          ],
        ),
      );

  // ==========================================
  // CARTE PROMO "BLACK METAL"
  // ==========================================
  Widget _promoCardPremium() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: premiumDark,
          boxShadow: [BoxShadow(color: premiumDark.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.stars_rounded, color: premiumGold, size: 16),
                      const SizedBox(width: 6),
                      const Text('THIX PRESTIGE',
                          style: TextStyle(color: premiumGold, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('Ligne de Crédit',
                      style: TextStyle(color: surfaceWhite, fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  const SizedBox(height: 6),
                  Text('Accédez jusqu\'à 500 000 FC instantanément.\nSans paperasse.',
                      style: TextStyle(color: surfaceWhite.withOpacity(0.7), fontSize: 12, height: 1.4)),
                ],
              ),
            ),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: premiumGold,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: premiumGold.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.arrow_forward_rounded, size: 23, color: premiumDark),
            ),
          ],
        ),
      );

  // ==========================================
  // TRANSACTIONS RÉCENTES
  // ==========================================
  Widget _transactionsList() => FutureBuilder<String>(
        future: ref.read(walletServiceProvider).getVerifiedThixId(),
        builder: (c, s) {
          if (!s.hasData) return const SizedBox();
          return FutureBuilder(
            future: Supabase.instance.client
                .from('thix_transactions')
                .select()
                .eq('thix_id', s.data!)
                .order('created_at', ascending: false)
                .limit(4),
            builder: (c, snap) {
              final list = (snap.data as List?) ?? [];
              if (list.isEmpty) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: surfaceWhite, borderRadius: BorderRadius.circular(20)),
                  child: const Center(child: Text('Aucune opération récente', style: TextStyle(fontSize: 13, color: Colors.grey))),
                );
              }

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: surfaceWhite,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: premiumDark.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Column(
                  children: list.asMap().entries.map((entry) {
                    int idx = entry.key;
                    var t = entry.value;
                    bool isDeposit = (t['type'] == 'reception' || t['type'] == 'Deposit');

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isDeposit ? const Color(0xFF10B981).withOpacity(0.1) : premiumDark.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isDeposit ? Icons.south_west_rounded : Icons.north_east_rounded,
                                  size: 19,
                                  color: isDeposit ? const Color(0xFF10B981) : premiumDark,
                                ),
                              ),
                              const SizedBox(width: 13),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(t['type'] ?? 'Opération',
                                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: premiumDark)),
                                    const SizedBox(height: 2),
                                    Text(t['ref_transa'] ?? 'Détails indisponibles', style: const TextStyle(fontSize: 11, color: Colors.black45)),
                                  ],
                                ),
                              ),
                              Text(
                                '${isDeposit ? '+' : '-'} ${t['montant']} ${t['devise']}',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  color: isDeposit ? const Color(0xFF10B981) : premiumDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (idx < list.length - 1) Divider(height: 1, color: Colors.black.withOpacity(0.04)),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      );

  // ==========================================
  // BOTTOM NAV
  // ==========================================
  Widget _premiumNav() => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: premiumDark,
              borderRadius: BorderRadius.circular(36),
              boxShadow: [BoxShadow(color: premiumDark.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const _NavIcon(icon: Icons.grid_view_rounded, isActive: true),
                const _NavIcon(icon: Icons.insert_chart_outlined),
                Transform.translate(
                  offset: const Offset(0, -12),
                  child: GestureDetector(
                    onTap: () => context.push(AppRoutes.thixMoneyScanner),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: premiumGold,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: premiumGold.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 6))],
                        border: Border.all(color: surfaceWhite, width: 3),
                      ),
                      child: const Icon(Icons.compare_arrows_rounded, color: premiumDark, size: 27),
                    ),
                  ),
                ),
                const _NavIcon(icon: Icons.account_balance_wallet_outlined),
                const _NavIcon(icon: Icons.person_outline_rounded),
              ],
            ),
          ),
        ),
      );
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  const _NavIcon({required this.icon, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: isActive ? Colors.white : Colors.white54, size: 25),
        if (isActive) ...[
          const SizedBox(height: 5),
          Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFFD4AF37), shape: BoxShape.circle)),
        ],
      ],
    );
  }
}
