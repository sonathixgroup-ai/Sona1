// lib/presentation/thix_money/pages/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/nav.dart';
import '../providers/wallet_provider.dart';
import '../services/wallet_service.dart';

// ============================================================
// PALETTE — Charte THIX ID
// ============================================================
class _Palette {
  static const navyDeep = Color(0xFF0A1F44);
  static const navy = Color(0xFF123B7A);
  static const blue = Color(0xFF2D6CDF);
  static const gold = Color(0xFFE3B23C);
  static const goldDark = Color(0xFFB8862A);
  static const ivory = Color(0xFFF6F7FB);
}

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});
  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  bool _soldeVisible = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.ivory,
      extendBody: true,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(walletStreamProvider),
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _PremiumHeader()),
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -60),
                child: Column(
                  children: [
                    _PremiumBalanceCard(
                      soldeVisible: _soldeVisible,
                      onToggle: () => setState(() => _soldeVisible = !_soldeVisible),
                    ),
                    const SizedBox(height: 18),
                    const _QuickActions(),
                    const SizedBox(height: 26),
                    const _SummaryCards(),
                    const SizedBox(height: 10),
                    const _SectionHeader(title: 'Services financiers', actionLabel: 'Voir tout'),
                    const SizedBox(height: 14),
                    const _PremiumServiceGrid(),
                    const SizedBox(height: 22),
                    const _PromoBanner(),
                    const SizedBox(height: 10),
                    const _SectionHeader(title: 'Dernières transactions', actionLabel: 'Voir tout'),
                    const SizedBox(height: 12),
                    const _LastTransactions(),
                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _FloatingNavBar(),
    );
  }
}

// ============================================================
// HEADER
// ============================================================
class _PremiumHeader extends ConsumerWidget {
  const _PremiumHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final displayName = (user?.userMetadata?['full_name'] as String?) ?? 'Utilisateur';
    final initiale = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'T';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 90),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_Palette.navyDeep, _Palette.navy],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [_Palette.gold, _Palette.goldDark]),
                  border: Border.all(color: Colors.white24, width: 1.5),
                ),
                child: Center(
                  child: Text(initiale,
                      style: const TextStyle(color: _Palette.navyDeep, fontWeight: FontWeight.w800, fontSize: 18)),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bonjour, $displayName 👋',
                      style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                  const SizedBox(height: 2),
                  const Text('THIX MONEY',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                ],
              ),
            ],
          ),
          Row(
            children: [
              _headerIconButton(
                icon: Icons.qr_code_scanner_rounded,
                onTap: () => context.push(AppRoutes.thixMoneyScanner),
              ),
              const SizedBox(width: 10),
              _headerIconButton(icon: Icons.notifications_none_rounded, dot: true, onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerIconButton({required IconData icon, required VoidCallback onTap, bool dot = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          if (dot)
            Positioned(
              top: -1,
              right: -1,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _Palette.gold,
                  shape: BoxShape.circle,
                  border: Border.all(color: _Palette.navyDeep, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// CARTE SOLDE — connectée au wallet réel
// ============================================================
class _PremiumBalanceCard extends ConsumerWidget {
  final bool soldeVisible;
  final VoidCallback onToggle;
  const _PremiumBalanceCard({required this.soldeVisible, required this.onToggle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletStreamProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_Palette.blue, _Palette.navy],
        ),
        boxShadow: [
          BoxShadow(color: _Palette.navy.withOpacity(0.35), blurRadius: 22, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Solde disponible', style: TextStyle(color: Colors.white70, fontSize: 13)),
              GestureDetector(
                onTap: onToggle,
                child: Icon(soldeVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                    color: Colors.white70, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          walletAsync.when(
            data: (wallet) {
              final montant = wallet?.balance ?? 0;
              final devise = wallet?.devise ?? 'FC';
              return Text(
                soldeVisible ? '${_formatMontant(montant)} $devise' : '••••••• $devise',
                style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              );
            },
            loading: () => const SizedBox(
              height: 30,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              ),
            ),
            error: (e, _) => const Text('Erreur de chargement', style: TextStyle(color: Colors.white70, fontSize: 14)),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _pilule(icon: Icons.arrow_upward_rounded, label: 'Envoyer', onTap: () => context.push(AppRoutes.thixMoneySend)),
              const SizedBox(width: 10),
              _pilule(icon: Icons.arrow_downward_rounded, label: 'Recevoir', onTap: () => context.push(AppRoutes.thixMoneyRecharge)),
              const SizedBox(width: 10),
              _pilule(icon: Icons.add_rounded, label: 'Recharger', onTap: () => context.push(AppRoutes.thixMoneyRecharge)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatMontant(num montant) {
    final s = montant.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i != 0 && (s.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  Widget _pilule({required IconData icon, required String label, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: _Palette.gold, size: 18),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ACTIONS RAPIDES
// ============================================================
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.qr_code_scanner_rounded, 'Scanner', AppRoutes.thixMoneyScanner),
      (Icons.people_alt_rounded, 'Contacts', AppRoutes.thixMoneySend),
      (Icons.receipt_long_rounded, 'Historique', AppRoutes.thixMoneyLoans),
      (Icons.money_rounded, 'Retrait', AppRoutes.thixMoneyRetrait),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: actions.map((a) {
          return GestureDetector(
            onTap: () => context.push(a.$3),
            child: Column(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Icon(a.$1, color: _Palette.navy, size: 24),
                ),
                const SizedBox(height: 6),
                Text(a.$2, style: const TextStyle(fontSize: 11.5, color: _Palette.navyDeep, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================
// SUMMARY CARDS (Épargne / Invest / Crédits / Tontines)
// ============================================================
class _SummaryCards extends ConsumerWidget {
  const _SummaryCards();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.7,
        children: [
          _sumCard(context, title: 'Épargne', value: '0 FC', icon: Icons.savings_rounded, color: _Palette.gold, route: AppRoutes.thixMoneySavings),
          _sumCard(context, title: 'Investissement', value: '0 actifs', icon: Icons.trending_up_rounded, color: _Palette.blue, route: AppRoutes.thixMoneyInvestments),
          _sumCard(context, title: 'Crédits', value: '0 FC', icon: Icons.credit_card_rounded, color: _Palette.navy, route: AppRoutes.thixMoneyLoans),
          _sumCard(context, title: 'Tontines', value: '0 actives', icon: Icons.groups_rounded, color: const Color(0xFF2DA6DF), route: AppRoutes.thixMoneyTontines),
        ],
      ),
    );
  }

  Widget _sumCard(BuildContext context, {required String title, required String value, required IconData icon, required Color color, required String route}) {
    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 16, color: color),
            ),
            const Spacer(),
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.black45)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: _Palette.navyDeep)),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SECTION HEADER générique
// ============================================================
class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  const _SectionHeader({required this.title, required this.actionLabel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: _Palette.navyDeep)),
          Text(actionLabel, style: const TextStyle(fontSize: 12.5, color: _Palette.blue, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ============================================================
// GRILLE DES 12 SERVICES
// ============================================================
class _PremiumServiceGrid extends StatelessWidget {
  const _PremiumServiceGrid();

  @override
  Widget build(BuildContext context) {
    // Les routes en erreur ont été remplacées par ''
    final services = [
      _ServiceItem('Crédit\ninstantané', Icons.flash_on_rounded, [const Color(0xFF2D6CDF), const Color(0xFF123B7A)], AppRoutes.thixMoneyLoans),
      _ServiceItem('Assurance', Icons.security_rounded, [const Color(0xFF1FA97F), const Color(0xFF0E6B4E)], AppRoutes.thixMoneyInsurance),
      _ServiceItem('Épargne\nplanifiée', Icons.savings_rounded, [_Palette.gold, _Palette.goldDark], AppRoutes.thixMoneySavings),
      _ServiceItem('Change', Icons.currency_exchange_rounded, [const Color(0xFF9B59B6), const Color(0xFF5E3370)], AppRoutes.thixMoneyExchange),
      _ServiceItem('Marchand', Icons.storefront_rounded, [const Color(0xFFE0743C), const Color(0xFF9C4A22)], AppRoutes.thixMoneyMerchant),
      _ServiceItem('Don &\nContributions', Icons.volunteer_activism_rounded, [const Color(0xFFE0507A), const Color(0xFF9C2E4E)], AppRoutes.thixMoneyDonations),
      _ServiceItem('Ma Tontine', Icons.groups_rounded, [const Color(0xFF2DA6DF), const Color(0xFF12557A)], AppRoutes.thixMoneyTontines),
      _ServiceItem('Éducation', Icons.school_rounded, [const Color(0xFF3CB4E3), const Color(0xFF1D6F8C)], ''), // Suspendu
      _ServiceItem('Virement\ninternational', Icons.public_rounded, [_Palette.navy, _Palette.navyDeep], ''), // Suspendu
      _ServiceItem('Microfinance', Icons.account_balance_rounded, [const Color(0xFF4CAF50), const Color(0xFF2E6B30)], ''), // Suspendu
      _ServiceItem('Investissement', Icons.trending_up_rounded, [_Palette.gold, const Color(0xFF8A6420)], AppRoutes.thixMoneyInvestments),
      _ServiceItem('Planification', Icons.calendar_month_rounded, [_Palette.blue, const Color(0xFF1A3D8C)], ''), // Suspendu
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: services.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 10,
          childAspectRatio: 0.72,
        ),
        itemBuilder: (context, index) {
          final s = services[index];
          return GestureDetector(
            onTap: () {
              // Vérification ajoutée ici : on ne redirige que si la route n'est pas vide
              if (s.route.isNotEmpty) {
                context.push(s.route);
              }
            },
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: s.gradient),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: s.gradient.last.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: Icon(s.icon, color: Colors.white, size: 24),
                ),
                const SizedBox(height: 6),
                Text(
                  s.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 10.5, color: _Palette.navyDeep, fontWeight: FontWeight.w600, height: 1.15),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ServiceItem {
  final String label;
  final IconData icon;
  final List<Color> gradient;
  final String route;
  const _ServiceItem(this.label, this.icon, this.gradient, this.route);
}

// ============================================================
// BANNIÈRE PROMO
// ============================================================
class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(colors: [_Palette.gold, _Palette.goldDark]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Crédit instantané',
              style: TextStyle(color: _Palette.navyDeep, fontSize: 16.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text("Jusqu'à 500 000 FC en 5 minutes, sans dossier",
              style: TextStyle(color: _Palette.navyDeep.withOpacity(0.75), fontSize: 12.5, height: 1.3)),
        ],
      ),
    );
  }
}

// ============================================================
// TRANSACTIONS — logique Supabase inchangée, style restylé
// ============================================================
class _LastTransactions extends ConsumerWidget {
  const _LastTransactions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletService = ref.read(walletServiceProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: FutureBuilder<String>(
        future: walletService.getVerifiedThixId(),
        builder: (context, thixSnap) {
          if (!thixSnap.hasData) {
            return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
          }
          final thixId = thixSnap.data!;
          return FutureBuilder(
            future: Supabase.instance.client
                .from('thix_transactions')
                .select()
                .eq('thix_id', thixId)
                .order('created_at', ascending: false)
                .limit(4),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
              }
              final list = (snap.data as List?) ?? [];
              if (list.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
                  child: const Center(
                    child: Text('Aucune transaction', style: TextStyle(color: Colors.black45, fontSize: 12.5)),
                  ),
                );
              }
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: list.map<Widget>((e) {
                    final montant = e['montant'];
                    final entrant = (montant is num) ? montant >= 0 : (e['type'] == 'reception');
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: entrant ? const Color(0xFFE7F6EE) : const Color(0xFFEFF3FB),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              entrant ? Icons.arrow_downward_rounded : Icons.receipt_long_rounded,
                              color: entrant ? const Color(0xFF1FA97F) : _Palette.blue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e['type'] ?? '',
                                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: _Palette.navyDeep)),
                                const SizedBox(height: 2),
                                Text(e['ref_transa'] ?? '',
                                    style: const TextStyle(fontSize: 11.5, color: Colors.black45)),
                              ],
                            ),
                          ),
                          Text(
                            '${e['montant']} ${e['devise'] ?? ''}',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: entrant ? const Color(0xFF1FA97F) : _Palette.navyDeep,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================
// BOTTOM NAV FLOTTANTE
// ============================================================
class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
      child: Container(
        height: 66,
        decoration: BoxDecoration(
          color: _Palette.navyDeep.withOpacity(0.95),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: _Palette.navyDeep.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navIcon(Icons.home_rounded, active: true, onTap: () {}),
            _navIcon(Icons.pie_chart_rounded, onTap: () {}),
            GestureDetector(
              onTap: () => context.push(AppRoutes.thixMoneyScanner),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_Palette.gold, _Palette.goldDark]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _Palette.gold.withOpacity(0.5), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: const Icon(Icons.qr_code_scanner_rounded, color: _Palette.navyDeep, size: 22),
              ),
            ),
            _navIcon(Icons.groups_rounded, onTap: () => context.push(AppRoutes.thixMoneyTontines)),
            _navIcon(Icons.person_rounded, onTap: () {}),
          ],
        ),
      ),
    );
  }

  Widget _navIcon(IconData icon, {bool active = false, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: active ? _Palette.gold : Colors.white54, size: 22),
          const SizedBox(height: 4),
          Container(
            width: active ? 5 : 0,
            height: 5,
            decoration: const BoxDecoration(color: _Palette.gold, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}
