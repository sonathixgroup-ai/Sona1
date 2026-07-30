// lib/presentation/thix_money/pages/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/nav.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});
  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _Service {
  final String label;
  final Color color;
  final IconData icon;
  final String? route;
  const _Service({required this.label, required this.color, required this.icon, this.route});
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  // ─── PALETTE PREMIUM - exact ref Figma ───
  static const Color gradientTop = Color(0xFF5B2DD6);
  static const Color gradientBottom = Color(0xFF2A0B6E);
  static const Color accentPurple = Color(0xFF6A35E0);
  static const Color bgPage = Color(0xFFF8F7FC);
  static const Color cardIconBg = Color(0xFFF5F3FF);
  static const Color textDark = Color(0xFF1C1A2B);
  static const Color textGrey = Color(0xFF8E8BA0);
  static const Color textGreyLight = Color(0xFFC7C4D6);

  int _bottomIndex = 0;
  final PageController _promoController = PageController(viewportFraction: 0.88);
  bool _balanceVisible = true;

  static const List<_Service> _services = [
    _Service(label: 'Crédit', color: Color(0xFF1E3A8A), icon: Icons.bolt_rounded, route: AppRoutes.thixMoneyLoans),
    _Service(label: 'Assurance', color: Color(0xFF0F766E), icon: Icons.security_rounded, route: null),
    _Service(label: 'Épargne', color: Color(0xFFB45309), icon: Icons.savings_rounded, route: AppRoutes.thixMoneySavings),
    _Service(label: 'Change', color: Color(0xFF6D28D9), icon: Icons.currency_exchange_rounded, route: null),
    _Service(label: 'Marchand', color: Color(0xFFEA4C2B), icon: Icons.storefront_rounded, route: AppRoutes.thixMarket),
    _Service(label: 'Dons', color: Color(0xFFE11D48), icon: Icons.favorite_rounded, route: null),
    _Service(label: 'Tontine', color: Color(0xFF0284C7), icon: Icons.groups_rounded, route: AppRoutes.thixMoneyTontines),
    _Service(label: 'Éducation', color: Color(0xFF0E7490), icon: Icons.school_rounded, route: AppRoutes.education),
    _Service(label: 'Virement', color: Color(0xFF2563EB), icon: Icons.language_rounded, route: AppRoutes.thixMoneySend),
    _Service(label: 'Microfinance', color: Color(0xFF16A34A), icon: Icons.account_balance_rounded, route: AppRoutes.thixMoneyLoans),
    _Service(label: 'Investir', color: Color(0xFFD97706), icon: Icons.show_chart_rounded, route: AppRoutes.thixMoneyInvestments),
    _Service(label: 'Planifier', color: Color(0xFF1E293B), icon: Icons.calendar_month_rounded, route: AppRoutes.thixMoneySavings),
  ];

  Future<Map<String, dynamic>> _getRealDashboardData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return {'name': 'Utilisateur', 'balance': 0.0, 'thix_id': '', 'avatar_url': null};
    final profileRes = await Supabase.instance.client.from('profiles').select('first_name, full_name, avatar_url').eq('id', user.id).maybeSingle();
    final walletRes = await Supabase.instance.client.from('wallets').select('balance, thix_id').eq('user_id', user.id).maybeSingle();
    return {
      'name': profileRes?['first_name']?? profileRes?['full_name']?? 'Utilisateur',
      'balance': (walletRes?['balance']?? 0.0).toDouble(),
      'thix_id': walletRes?['thix_id']?? '',
      'avatar_url': profileRes?['avatar_url'],
    };
  }

  Stream<List<Map<String, dynamic>>> _promoStream() {
    return Supabase.instance.client.from('thix_money_promos').stream(primaryKey: ['id']).order('created_at', ascending: false).limit(6);
  }

  String _formatBalance(double value) {
    final str = value.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i!= 0 && (str.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgPage,
      extendBody: true,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getRealDashboardData(),
        builder: (context, snapshot) {
          final data = snapshot.data?? {'name': '...', 'balance': 0.0, 'thix_id': '', 'avatar_url': null};
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  height: 285,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [gradientTop, gradientBottom]),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: _buildBalanceHeader(data['name'], data['balance'], data['avatar_url']),
                    ),
                  ),
                ),
              ),
              // SHEET BLANC + CARTE FLOTTANTE QUI CHEVAUCHE
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 46),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 72),
                          _sectionTitle('Mes services'),
                          const SizedBox(height: 16),
                          _buildServiceGrid(),
                          const SizedBox(height: 28),
                          _sectionTitle('Promo & Discount', trailing: 'See more'),
                          const SizedBox(height: 14),
                          _buildPromoCarousel(),
                          const SizedBox(height: 28),
                          _sectionTitle('Opérations récentes'),
                          const SizedBox(height: 12),
                          _buildRealTransactions(data['thix_id'] as String),
                          const SizedBox(height: 130),
                        ],
                      ),
                    ),
                    Positioned(
                      top: -8,
                      left: 20,
                      right: 20,
                      child: _buildQuickActionsCard(),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF5B2DD6)]),
          boxShadow: [BoxShadow(color: accentPurple.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: const CircleBorder(),
          onPressed: () => context.push(AppRoutes.thixMoneyScanner),
          child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 26),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        elevation: 20,
        shadowColor: Colors.black.withOpacity(0.08),
        child: SizedBox(
          height: 68,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _bottomNavItem(Icons.home_rounded, 'Accueil', 0),
              _bottomNavItem(Icons.bar_chart_rounded, 'Activité', 1),
              const SizedBox(width: 56),
              _bottomNavItem(Icons.receipt_long_rounded, 'Historique', 2),
              _bottomNavItem(Icons.person_rounded, 'Compte', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceHeader(String name, double balance, String? avatarUrl) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white.withOpacity(0.18),
              backgroundImage: (avatarUrl!= null && avatarUrl.isNotEmpty)? NetworkImage(avatarUrl) : null,
              child: (avatarUrl == null || avatarUrl.isEmpty)? const Icon(Icons.person, color: Colors.white, size: 20) : null,
            ),
            InkWell(
              onTap: () => context.push('/thix-money/notifications'),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.22), width: 1.2),
                ),
                child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text('Available Balance', style: TextStyle(color: Colors.white.withOpacity(0.62), fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.2)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _balanceVisible? '\$${_formatBalance(balance)}' : '••••••',
              style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: -1.2, height: 1),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: () => setState(() => _balanceVisible =!_balanceVisible),
              child: Icon(_balanceVisible? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.white.withOpacity(0.7), size: 18),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionsCard() {
    final actions = [
      {'label': 'Top Up', 'icon': Icons.account_balance_wallet_outlined, 'route': '/thix-money/topup'},
      {'label': 'Envoyer', 'icon': Icons.arrow_outward_rounded, 'route': AppRoutes.thixMoneySend},
      {'label': 'Demander', 'icon': Icons.call_received_rounded, 'route': '/thix-money/request'},
      {'label': 'Historique', 'icon': Icons.history_rounded, 'route': '/thix-money/history'},
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 28, offset: const Offset(0, 12))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: actions.map((a) {
          return InkWell(
            onTap: () => context.push(a['route'] as String),
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(a['icon'] as IconData, color: accentPurple, size: 26),
                const SizedBox(height: 8),
                Text(a['label'] as String, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: textDark, letterSpacing: 0.1)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _sectionTitle(String title, {String? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textDark, letterSpacing: -0.2)),
          if (trailing!= null)
            InkWell(
              onTap: () => context.push('/thix-money/promos'),
              child: const Text('See more', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: accentPurple)),
            ),
        ],
      ),
    );
  }

  Widget _buildServiceGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _services.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 18,
          crossAxisSpacing: 4,
          childAspectRatio: 0.82,
        ),
        itemBuilder: (context, index) {
          final s = _services[index];
          final enabled = s.route!= null;
          return InkWell(
            onTap: enabled? () => context.push(s.route!) : () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${s.label} — bientôt disponible'))),
            borderRadius: BorderRadius.circular(18),
            child: Opacity(
              opacity: enabled? 1 : 0.45,
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(color: const Color(0xFFF6F5FA), borderRadius: BorderRadius.circular(18)),
                    child: Icon(s.icon, color: s.color, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(s.label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: textDark, height: 1.1)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPromoCarousel() {
    return SizedBox(
      height: 146,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _promoStream(),
        builder: (context, snapshot) {
          final promos = snapshot.data?? [];
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: accentPurple, strokeWidth: 2));
          if (promos.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(color: const Color(0xFF22134D), borderRadius: BorderRadius.circular(22)),
                child: const Center(child: Text('Aucune offre pour le moment', style: TextStyle(color: Colors.white60, fontSize: 12.5))),
              ),
            );
          }
          return PageView.builder(
            controller: _promoController,
            padEnds: false,
            itemCount: promos.length,
            itemBuilder: (context, index) {
              final p = promos[index];
              final Color bg = index.isEven? const Color(0xFF22134D) : const Color(0xFF0FB5B5);
              return Padding(
                padding: const EdgeInsets.only(left: 20, right: 8),
                child: InkWell(
                  onTap: () => context.push('/thix-money/promos/${p['id']}'),
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(22)),
                    child: Stack(
                      children: [
                        Positioned(right: -18, top: -18, child: Container(width: 110, height: 110, decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(24)))),
                        Positioned(right: 28, bottom: 18, child: Container(width: 52, height: 14, decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(12)))),
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(p['title']?? 'Special Offer', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, height: 1.2)),
                              const SizedBox(height: 6),
                              Text(p['subtitle']?? 'Get discount for every top up', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.62), fontSize: 12, height: 1.35)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRealTransactions(String thixId) {
    if (thixId.isEmpty) return const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: LinearProgressIndicator(minHeight: 2, color: accentPurple));
    return FutureBuilder(
      future: Supabase.instance.client.from('thix_transactions').select().eq('thix_id', thixId).order('created_at', ascending: false).limit(5),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: accentPurple, strokeWidth: 2));
        final list = (snapshot.data as List?)?? [];
        if (list.isEmpty) {
          return Container(margin: const EdgeInsets.symmetric(horizontal: 20), padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF0EFF5))), child: const Center(child: Text('Aucune opération récente', style: TextStyle(fontSize: 12.5, color: textGrey))));
        }
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFF0EFF5))),
          child: Column(
            children: list.asMap().entries.map((e) {
              final t = e.value;
              final isDeposit = (t['type'] == 'reception' || t['type'] == 'Deposit');
              return Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    leading: Container(width: 38, height: 38, decoration: BoxDecoration(color: isDeposit? const Color(0xFFEBF8F0) : const Color(0xFFFFEFEF), borderRadius: BorderRadius.circular(12)), child: Icon(isDeposit? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: isDeposit? const Color(0xFF16A34A) : const Color(0xFFEF4444), size: 18)),
                    title: Text(t['type']?? 'Opération', style: const TextStyle(fontWeight: FontWeight.w600, color: textDark, fontSize: 12.5)),
                    subtitle: Text(t['ref_transa']?? '', style: const TextStyle(fontSize: 10.5, color: textGrey)),
                    trailing: Text('${isDeposit? '+' : '-'} ${t['montant']} ${t['devise']?? ''}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: isDeposit? const Color(0xFF16A34A) : textDark)),
                  ),
                  if (e.key < list.length - 1) Divider(height: 1, indent: 66, color: const Color(0xFFF2F1F6)),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _bottomNavItem(IconData icon, String label, int index) {
    final isActive = _bottomIndex == index;
    return InkWell(
      onTap: () => setState(() => _bottomIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive? accentPurple : textGreyLight, size: 22),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: isActive? FontWeight.w700 : FontWeight.w500, color: isActive? accentPurple : textGreyLight, letterSpacing: 0.1)),
          ],
        ),
      ),
    );
  }
}
