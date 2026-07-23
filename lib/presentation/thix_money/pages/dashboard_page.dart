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
  int _navIndex = 0;
  final PageController _promoController = PageController();
  int _promoIndex = 0;

  static const navyDeep = Color(0xFF0A1F44);
  static const navy = Color(0xFF123B7A);
  static const primaryBlue = Color(0xFF2D6CDF);
  static const gold = Color(0xFFE3B23C);
  static const ivory = Color(0xFFF6F7FB);

  final List<_ThixService> _services = const [
    _ThixService('Crédit\ninstantané', Icons.flash_on_rounded, [Color(0xFF2D6CDF), Color(0xFF123B7A)], AppRoutes.thixMoneyLoans),
    _ThixService('Assurance', Icons.security_rounded, [Color(0xFF1FA97F), Color(0xFF0E6B4E)], null),
    _ThixService('Épargne\nplanifiée', Icons.savings_rounded, [Color(0xFFE3B23C), Color(0xFFB8862A)], AppRoutes.thixMoneySavings),
    _ThixService('Change', Icons.currency_exchange_rounded, [Color(0xFF9B59B6), Color(0xFF5E3370)], null),
    _ThixService('Marchand', Icons.storefront_rounded, [Color(0xFFE0743C), Color(0xFF9C4A22)], AppRoutes.thixMarket),
    _ThixService('Don &\nContributions', Icons.volunteer_activism_rounded, [Color(0xFFE0507A), Color(0xFF9C2E4E)], null),
    _ThixService('Ma Tontine', Icons.groups_rounded, [Color(0xFF2DA6DF), Color(0xFF12557A)], AppRoutes.thixMoneyTontines),
    _ThixService('Éducation', Icons.school_rounded, [Color(0xFF3CB4E3), Color(0xFF1D6F8C)], AppRoutes.education),
    _ThixService('Virement\ninternational', Icons.public_rounded, [Color(0xFF123B7A), Color(0xFF0A1F44)], AppRoutes.thixMoneySend),
    _ThixService('Microfinance', Icons.account_balance_rounded, [Color(0xFF4CAF50), Color(0xFF2E6B30)], AppRoutes.thixMoneyLoans),
    _ThixService('Investissement', Icons.trending_up_rounded, [Color(0xFFE3B23C), Color(0xFF8A6420)], AppRoutes.thixMoneyInvestments),
    _ThixService('Planification', Icons.calendar_month_rounded, [Color(0xFF2D6CDF), Color(0xFF1A3D8C)], AppRoutes.thixMoneySavings),
  ];

  final _promos = const [
    {'titre': 'Crédit instantané', 'sous_titre': 'Jusqu\'à 500 000 FC en 5 minutes, sans dossier'},
    {'titre': 'Ma Tontine digitale', 'sous_titre': 'Gérez vos cotisations et retraits en toute transparence'},
    {'titre': 'Virement international', 'sous_titre': 'Envoyez de l\'argent en Afrique et en Europe en quelques secondes'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ivory,
      extendBody: true,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(walletStreamProvider),
        child: CustomScrollView(
          slivers: [
            _buildHeaderSliver(),
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -60),
                child: Column(
                  children: [
                    _buildSoldeCard(),
                    const SizedBox(height: 18),
                    _buildActionsRapides(),
                    const SizedBox(height: 26),
                    _buildServicesGrid(),
                    const SizedBox(height: 22),
                    _buildPromoBanner(),
                    const SizedBox(height: 22),
                    _buildTransactionsRecentes(),
                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildFloatingNavBar(),
    );
  }

  Widget _buildHeaderSliver() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 56, 20, 90),
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [navyDeep, navy]),
          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(width: 46, height: 46, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [gold, Color(0xFFB8862A)]), border: Border.all(color: Colors.white24, width: 1.5)), child: const Center(child: Text('N', style: TextStyle(color: navyDeep, fontWeight: FontWeight.w800, fontSize: 18)))),
            const SizedBox(width: 12),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Bonjour, Nathan 👋', style: TextStyle(color: Colors.white70, fontSize: 12.5)), SizedBox(height: 2), Text('THIX MONEY', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.5))]),
          ]),
          Row(children: [_headerIcon(Icons.qr_code_scanner_rounded), const SizedBox(width: 10), _headerIcon(Icons.notifications_none_rounded, dot: true)]),
        ]),
      ),
    );
  }

  Widget _headerIcon(IconData icon, {bool dot = false}) => Stack(clipBehavior: Clip.none, children: [Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: Colors.white.withOpacity(0.10), shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 1)), child: Icon(icon, color: Colors.white, size: 20)), if (dot) Positioned(top: -1, right: -1, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: gold, shape: BoxShape.circle, border: Border.all(color: navyDeep, width: 1.5))))]);

  Widget _buildSoldeCard() {
    final walletAsync = ref.watch(walletStreamProvider);
    return walletAsync.when(
      loading: () => Container(margin: const EdgeInsets.symmetric(horizontal: 20), height: 160, decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), gradient: const LinearGradient(colors: [primaryBlue, navy])), child: const Center(child: CircularProgressIndicator(color: Colors.white))),
      error: (e, _) => Container(margin: const EdgeInsets.symmetric(horizontal: 20), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26)), child: Text('Erreur: $e')),
      data: (w) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [primaryBlue, navy]), boxShadow: [BoxShadow(color: navy.withOpacity(0.35), blurRadius: 22, offset: const Offset(0, 12))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Solde disponible', style: TextStyle(color: Colors.white70, fontSize: 13)), GestureDetector(onTap: () => setState(() => _soldeVisible =!_soldeVisible), child: Icon(_soldeVisible? Icons.visibility_rounded : Icons.visibility_off_rounded, color: Colors.white70, size: 20))]),
            const SizedBox(height: 8),
            Text(_soldeVisible? '${w.soldeCdf} FC' : '••••••• FC', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text(_soldeVisible? '≈ ${w.soldeUsd} USD • ${w.thixId}' : '≈ ••• USD', style: const TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 18),
            Row(children: [
              _pilule(Icons.arrow_upward_rounded, 'Envoyer', () => context.push(AppRoutes.thixMoneySend)),
              const SizedBox(width: 10),
              _pilule(Icons.arrow_downward_rounded, 'Recevoir', () => context.push(AppRoutes.thixMoneyRecharge)),
              const SizedBox(width: 10),
              _pilule(Icons.add_rounded, 'Recharger', () => context.push(AppRoutes.thixMoneyRecharge)),
            ]),
          ]),
        );
      },
    );
  }

  Widget _pilule(IconData icon, String label, VoidCallback tap) => Expanded(child: InkWell(onTap: tap, borderRadius: BorderRadius.circular(16), child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white24, width: 1)), child: Column(children: [Icon(icon, color: gold, size: 18), const SizedBox(height: 4), Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))]))));

  Widget _buildActionsRapides() {
    final actions = [
      {'label': 'Scanner', 'icon': Icons.qr_code_scanner_rounded, 'route': AppRoutes.thixMoneyScanner},
      {'label': 'Contacts', 'icon': Icons.people_alt_rounded, 'route': AppRoutes.thixMoneySend},
      {'label': 'Historique', 'icon': Icons.receipt_long_rounded, 'route': AppRoutes.thixMoneySend},
      {'label': 'Cartes', 'icon': Icons.credit_card_rounded, 'route': AppRoutes.thixMoneySavings},
    ];
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: actions.map((a) => InkWell(onTap: () => context.push(a['route'] as String), child: Column(children: [Container(width: 54, height: 54, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))]), child: Icon(a['icon'] as IconData, color: navy, size: 24)), const SizedBox(height: 6), Text(a['label'] as String, style: const TextStyle(fontSize: 11.5, color: navyDeep, fontWeight: FontWeight.w600))]))).toList()));
  }

  Widget _buildServicesGrid() {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Services financiers', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: navyDeep)), Text('Voir tout', style: TextStyle(fontSize: 12.5, color: primaryBlue, fontWeight: FontWeight.w600))]),
      const SizedBox(height: 14),
      GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _services.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 16, crossAxisSpacing: 10, childAspectRatio: 0.72), itemBuilder: (context, index) {
        final s = _services[index];
        return GestureDetector(onTap: () => s.route!= null? context.push(s.route!) : null, child: Column(children: [Container(width: 56, height: 56, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: s.gradient), borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: s.gradient.last.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 5))]), child: Icon(s.icon, color: Colors.white, size: 24)), const SizedBox(height: 6), Text(s.label, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontSize: 10.5, color: navyDeep, fontWeight: FontWeight.w600, height: 1.15))]));
      }),
    ]));
  }

  Widget _buildPromoBanner() => Column(children: [
    SizedBox(height: 128, child: PageView.builder(controller: _promoController, itemCount: _promos.length, onPageChanged: (i) => setState(() => _promoIndex = i), itemBuilder: (context, index) {
      final promo = _promos[index];
      return Container(margin: const EdgeInsets.symmetric(horizontal: 20), padding: const EdgeInsets.all(20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(colors: [gold, Color(0xFFB8862A)])), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(promo['titre']!, style: const TextStyle(color: navyDeep, fontSize: 16.5, fontWeight: FontWeight.w800)), const SizedBox(height: 6), Text(promo['sous_titre']!, style: TextStyle(color: navyDeep.withOpacity(0.75), fontSize: 12.5, height: 1.3))] ));
    })),
    const SizedBox(height: 10),
    Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_promos.length, (i) => AnimatedContainer(duration: const Duration(milliseconds: 250), margin: const EdgeInsets.symmetric(horizontal: 3), width: i == _promoIndex? 18 : 6, height: 6, decoration: BoxDecoration(color: i == _promoIndex? primaryBlue : Colors.black12, borderRadius: BorderRadius.circular(4))))),
  ]);

  Widget _buildTransactionsRecentes() {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Transactions récentes', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: navyDeep)), Text('Tout voir', style: TextStyle(fontSize: 12.5, color: primaryBlue, fontWeight: FontWeight.w600))]),
      const SizedBox(height: 12),
      FutureBuilder<String>(future: ref.read(walletServiceProvider).getVerifiedThixId(), builder: (context, thixSnap) {
        if (!thixSnap.hasData) return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)), child: const Center(child: CircularProgressIndicator()));
        return FutureBuilder(future: Supabase.instance.client.from('thix_transactions').select().eq('thix_id', thixSnap.data!).order('created_at', ascending: false).limit(4), builder: (context, snap) {
          final list = (snap.data as List?)?? [];
          if (list.isEmpty) return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)), child: const Text('Aucune transaction', style: TextStyle(color: Colors.grey)));
          return Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 6))]), padding: const EdgeInsets.symmetric(vertical: 6), child: Column(children: list.map<Widget>((t) {
            final entrant = t['type'] == 'RECHARGE';
            return Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), child: Row(children: [
              Container(width: 42, height: 42, decoration: BoxDecoration(color: entrant? const Color(0xFFE7F6EE) : const Color(0xFFEFF3FB), borderRadius: BorderRadius.circular(14)), child: Icon(entrant? Icons.arrow_downward_rounded : Icons.phone_android_rounded, color: entrant? const Color(0xFF1FA97F) : primaryBlue, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t['type']?? '', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: navyDeep)), const SizedBox(height: 2), Text(t['ref_transa']?? '', style: const TextStyle(fontSize: 11.5, color: Colors.black45))])),
              Text('${entrant? '+' : '-'}${t['montant']} ${t['devise']}', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: entrant? const Color(0xFF1FA97F) : navyDeep)),
            ]));
          }).toList()));
        });
      }),
    ]));
  }

  Widget _buildFloatingNavBar() {
    final items = [Icons.home_rounded, Icons.pie_chart_rounded, Icons.qr_code_scanner_rounded, Icons.groups_rounded, Icons.person_rounded];
    return Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 22), child: ClipRRect(borderRadius: BorderRadius.circular(28), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), child: Container(height: 66, decoration: BoxDecoration(color: navyDeep.withOpacity(0.92), borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: navyDeep.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 10))]), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(items.length, (i) {
      if (i == 2) return GestureDetector(onTap: () => context.push(AppRoutes.thixMoneyScanner), child: Container(width: 50, height: 50, decoration: BoxDecoration(gradient: const LinearGradient(colors: [gold, Color(0xFFB8862A)]), shape: BoxShape.circle, boxShadow: [BoxShadow(color: gold.withOpacity(0.5), blurRadius: 12, offset: const Offset(0, 4))]), child: Icon(items[i], color: navyDeep, size: 22)));
      final active = i == _navIndex;
      return GestureDetector(onTap: () => setState(() => _navIndex = i), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(items[i], color: active? gold : Colors.white54, size: 22), const SizedBox(height: 4), AnimatedContainer(duration: const Duration(milliseconds: 200), width: active? 5 : 0, height: 5, decoration: const BoxDecoration(color: gold, shape: BoxShape.circle))]));
    }))))));
  }
}

class _ThixService {
  final String label; final IconData icon; final List<Color> gradient; final String? route;
  const _ThixService(this.label, this.icon, this.gradient, this.route);
}
