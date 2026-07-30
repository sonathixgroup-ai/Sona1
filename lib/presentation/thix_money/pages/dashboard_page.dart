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
  final IconData icon;
  final String? route;
  const _Service({required this.label, required this.icon, this.route});
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  static const bgLight = Color(0xFFF5F5F7);
  static const bgDark = Color(0xFF121212);
  static const neon = Color(0xFFE8FF3D);
  static const blackCircle = Color(0xFF232323);
  static const textDark = Color(0xFF121212);
  static const textGrey = Color(0xFF9A9AA0);

  final PageController _cardController = PageController(viewportFraction: 0.88);
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int _cardIndex = 0;

  static const List<_Service> _allServices = [
    _Service(label: 'Crédit', icon: Icons.bolt_rounded, route: AppRoutes.thixMoneyLoans),
    _Service(label: 'Assurance', icon: Icons.security_rounded, route: null),
    _Service(label: 'Épargne', icon: Icons.savings_rounded, route: AppRoutes.thixMoneySavings),
    _Service(label: 'Change', icon: Icons.currency_exchange_rounded, route: null),
    _Service(label: 'Marchand', icon: Icons.storefront_rounded, route: AppRoutes.thixMarket),
    _Service(label: 'Dons', icon: Icons.favorite_rounded, route: null),
    _Service(label: 'Tontine', icon: Icons.groups_rounded, route: AppRoutes.thixMoneyTontines),
    _Service(label: 'Éducation', icon: Icons.school_rounded, route: AppRoutes.education),
    _Service(label: 'Virement', icon: Icons.send_rounded, route: AppRoutes.thixMoneySend),
    _Service(label: 'Micro', icon: Icons.account_balance_rounded, route: AppRoutes.thixMoneyLoans),
    _Service(label: 'Investir', icon: Icons.trending_up_rounded, route: AppRoutes.thixMoneyInvestments),
    _Service(label: 'Planifier', icon: Icons.calendar_month_rounded, route: AppRoutes.thixMoneySavings),
  ];

  Future<Map<String, dynamic>> _getRealDashboardData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return {'name': 'Utilisateur', 'balance_fc': 0.0, 'balance_usd': 0.0, 'thix_id': '', 'avatar_url': null};

    final profile = await Supabase.instance.client.from('profiles').select('first_name, full_name, avatar_url').eq('id', user.id).maybeSingle();
    // Essaie balance + balance_usd, sinon fallback sur balance seul
    final wallet = await Supabase.instance.client.from('wallets').select('balance, balance_usd, thix_id').eq('user_id', user.id).maybeSingle();

    final name = profile?['first_name']?? profile?['full_name']?? 'Utilisateur';
    return {
      'name': name,
      'balance_fc': (wallet?['balance']?? 0).toDouble(),
      'balance_usd': (wallet?['balance_usd']?? (wallet?['balance']?? 0) / 2850).toDouble(),
      'thix_id': wallet?['thix_id']?? '',
      'avatar_url': profile?['avatar_url'],
    };
  }

  String _formatFc(double v) {
    return v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ');
  }
  String _formatThixId(String id) {
    if (id.isEmpty) return '•••• •••• •••• ••••';
    final clean = id.replaceAll(' ', '');
    final buffer = StringBuffer();
    for(int i=0;i<clean.length;i++){
      if(i!=0 && i%4==0) buffer.write(' ');
      buffer.write(clean[i]);
    }
    return buffer.toString().toUpperCase();
  }

  @override
  void dispose() {
    _cardController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getRealDashboardData(),
        builder: (context, snap) {
          final data = snap.data?? {'name': '...', 'balance_fc': 0.0, 'balance_usd': 0.0, 'thix_id': '', 'avatar_url': null};
          final filtered = _allServices.where((s) => s.label.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── PARTIE CLAIRE ──
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Hello, ${data['name']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textDark, letterSpacing: -0.3)),
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.white,
                              backgroundImage: (data['avatar_url']!=null && (data['avatar_url'] as String).isNotEmpty)? NetworkImage(data['avatar_url']) : null,
                              child: (data['avatar_url']==null)? const Icon(Icons.person, size: 18) : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        // SEARCH
                        Container(
                          height: 48,
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)]),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (v)=> setState(()=> _searchQuery=v),
                            decoration: const InputDecoration(
                              hintText: 'Search service',
                              hintStyle: TextStyle(fontSize: 13, color: textGrey),
                              prefixIcon: SizedBox(),
                              suffixIcon: Icon(Icons.search_rounded, color: textDark, size: 20),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Text('Services', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textDark)),
                        const SizedBox(height: 18),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 20, crossAxisSpacing: 10, childAspectRatio: 0.85),
                          itemBuilder: (_, i) {
                            final s = filtered[i];
                            final enabled = s.route!= null;
                            return InkWell(
                              onTap: enabled? ()=> context.push(s.route!) : (){},
                              borderRadius: BorderRadius.circular(20),
                              child: Opacity(
                                opacity: enabled?1:0.4,
                                child: Column(
                                  children: [
                                    Container(
                                      width: 62, height: 62,
                                      decoration: const BoxDecoration(color: blackCircle, shape: BoxShape.circle),
                                      child: Icon(s.icon, color: neon, size: 24),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(s.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: textDark)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                // ── PARTIE NOIRE CARDS ──
                const SizedBox(height: 20),
                Container(
                  decoration: const BoxDecoration(color: bgDark, borderRadius: BorderRadius.vertical(top: Radius.circular(42))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Cards', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
                            InkWell(onTap: (){}, child: Text('+ ADD MORE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.6)))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        height: 240,
                        child: PageView.builder(
                          controller: _cardController,
                          onPageChanged: (i)=> setState(()=> _cardIndex=i),
                          itemCount: 2,
                          itemBuilder: (context, index) {
                            final isFc = index==0;
                            return Padding(
                              padding: const EdgeInsets.only(left: 20, right: 8),
                              child: _buildWalletCard(
                                balance: isFc? data['balance_fc'] : data['balance_usd'],
                                thixId: data['thix_id'],
                                isFc: isFc,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 18),
                      // dots
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: List.generate(2, (i) => Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: _cardIndex==i? 28 : 8, height: 8,
                            decoration: BoxDecoration(color: _cardIndex==i? neon : Colors.white24, borderRadius: BorderRadius.circular(10)),
                          )),
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: neon,
        elevation: 0,
        shape: const CircleBorder(),
        onPressed: () => context.push(AppRoutes.thixMoneyScanner),
        child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.black, size: 26),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: bgDark, shape: const CircularNotchedRectangle(), notchMargin: 10, elevation: 0,
        child: SizedBox(height: 64, child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          Icon(Icons.home_filled, color: Colors.white, size: 22),
          Icon(Icons.bar_chart_rounded, color: Colors.white38, size: 22),
          const SizedBox(width: 40),
          Icon(Icons.receipt_long_rounded, color: Colors.white38, size: 22),
          Icon(Icons.person_outline_rounded, color: Colors.white38, size: 22),
        ])),
      ),
    );
  }

  Widget _buildWalletCard({required double balance, required String thixId, required bool isFc}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Stack(
        children: [
          Positioned(right: -30, top: -30, child: Container(width: 140, height: 140, decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), shape: BoxShape.circle))),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 28, height: 28, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                    Transform.translate(offset: const Offset(-12, 0), child: Container(width: 28, height: 28, decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), shape: BoxShape.circle, border: Border.all(color: const Color(0xFF242424), width: 2)))),
                  ],
                ),
                const Spacer(),
                Text(isFc? 'FC ${_formatFc(balance)}' : '\$ ${balance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1)),
                const SizedBox(height: 22),
                Text(_formatThixId(thixId), style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, letterSpacing: 1.2, fontWeight: FontWeight.w500)),
                Text(isFc? 'THIX ID • FC WALLET' : 'THIX ID • USD WALLET', style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 10, letterSpacing: 1)),
              ],
            ),
          ),
          Positioned(
            bottom: 14, left: 0, right: 0,
            child: Center(
              child: Container(
                height: 46, padding: const EdgeInsets.symmetric(horizontal: 28),
                decoration: BoxDecoration(color: neon, borderRadius: BorderRadius.circular(30)),
                child: InkWell(
                  onTap: ()=> context.push(AppRoutes.thixMoneySend),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [Text('Pay', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 15)), SizedBox(width: 8), Icon(Icons.credit_card, color: Colors.black, size: 18)]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
