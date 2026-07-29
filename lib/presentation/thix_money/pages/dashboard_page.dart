// lib/presentation/thix_money/pages/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/nav.dart';
import '../widgets/service_grid.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});
  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  // Palette THIX MONEY — identique au mockup HTML V2
  static const navyDeep = Color(0xFF0A1F44);
  static const navy = Color(0xFF123B7A);
  static const blue = Color(0xFF2D6CDF);
  static const gold = Color(0xFFE3B23C);
  static const ivory = Color(0xFFF6F7FB);
  static const textDark = Color(0xFF1B2A4A);
  static const textGrey = Color(0xFF8A93A6);
  static const lineColor = Color(0xFFE4E8F1);

  int _currentDot = 0;
  int _bottomIndex = 0;

  Future<Map<String, String>> _getProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return {'name': 'Bienvenue', 'phone': ''};
    final r = await Supabase.instance.client
        .from('profiles')
        .select('full_name, phone')
        .eq('id', user.id)
        .maybeSingle();
    final name = (r?['full_name'] ?? user.email?.split('@').first ?? 'Utilisateur').toString();
    final phone = (r?['phone'] ?? '').toString();
    return {'name': name, 'phone': phone};
  }

  String _formatBalance(double value) {
    final str = value.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i != 0 && (str.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const ServiceGrid(),
              _divider(),
              _promoBanner(),
              const SizedBox(height: 12),
              _dots(),
              const SizedBox(height: 24),
              _sectionTitle('Accès rapide'),
              const SizedBox(height: 6),
              _quickAccessRow(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  // ==========================================
  // HEADER — dégradé clair, logo centré, solde
  // ==========================================
  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFDCE3F0), Color(0xFFF6F7FB)],
        ),
      ),
      child: FutureBuilder<Map<String, String>>(
        future: _getProfile(),
        builder: (context, snap) {
          final name = snap.data?['name'] ?? '';
          final phone = snap.data?['phone'] ?? '';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => Scaffold.of(context).openDrawer(),
                    child: const Icon(Icons.menu_rounded, color: navyDeep, size: 26),
                  ),
                  Row(
                    children: [
                      _topIconBtn(Icons.search_rounded, () => context.push('/money/search')),
                      const SizedBox(width: 16),
                      _topIconBtn(Icons.notifications_outlined, () => context.push('/money/notifications')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Bienvenue,',
                style: TextStyle(color: textGrey, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                name.isEmpty ? 'Chargement...' : name,
                style: const TextStyle(color: navyDeep, fontSize: 20, fontWeight: FontWeight.w800),
              ),
              if (phone.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      phone,
                      style: const TextStyle(color: blue, fontSize: 13.5, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 5),
                    const Icon(Icons.keyboard_arrow_down_rounded, color: blue, size: 16),
                  ],
                ),
              ],
              const SizedBox(height: 26),
              Center(
                child: Column(
                  children: [
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 30, letterSpacing: -0.5, fontFamily: 'SpaceGrotesk'),
                        children: [
                          TextSpan(text: 'THIX', style: TextStyle(color: navyDeep)),
                          TextSpan(text: 'MONEY', style: TextStyle(color: gold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Solde disponible',
                      style: TextStyle(color: textGrey, fontSize: 13.5, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatBalance(1250000)} FC',
                      style: const TextStyle(color: navy, fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _topIconBtn(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: navyDeep.withOpacity(0.10), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Icon(icon, color: navy, size: 17),
        ),
      );

  Widget _divider() => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        color: lineColor,
      );

  // ==========================================
  // BANNIÈRE PROMO — dégradé navy
  // ==========================================
  Widget _promoBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => context.push(AppRoutes.thixMoneyTontines),
        child: Container(
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [navyDeep, navy],
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Row(
              children: [
                Container(
                  width: 130,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [blue, navy],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Ma Tontine',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.4, color: Colors.white),
                            children: [
                              const TextSpan(text: 'Épargnez '),
                              TextSpan(text: 'ensemble', style: TextStyle(color: gold)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Créez votre cercle en 2 minutes',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dots() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          final active = i == _currentDot;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            width: active ? 16 : 5,
            height: 5,
            decoration: BoxDecoration(
              color: active ? gold : lineColor,
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      );

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Text(
          t,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: navyDeep),
        ),
      );

  // ==========================================
  // ACCÈS RAPIDE — cercles horizontaux
  // ==========================================
  Widget _quickAccessRow() {
    final items = [
      {'l': 'Recharger', 'i': Icons.add_card_outlined, 'r': AppRoutes.thixMoneyRecharge},
      {'l': 'Crédit', 'i': Icons.bolt_outlined, 'r': AppRoutes.thixMoneyLoans},
      {'l': 'Tontine', 'i': Icons.groups_outlined, 'r': AppRoutes.thixMoneyTontines},
      {'l': 'Investir', 'i': Icons.trending_up_rounded, 'r': AppRoutes.thixMoneyInvestments},
    ];

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 18),
        itemBuilder: (_, i) {
          final item = items[i];
          return InkWell(
            onTap: () => context.push(item['r'] as String),
            borderRadius: BorderRadius.circular(32),
            child: SizedBox(
              width: 66,
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(color: ivory, shape: BoxShape.circle),
                    child: Icon(item['i'] as IconData, color: navy, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['l'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: navyDeep, height: 1.25),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // BOTTOM NAV — bouton scan flottant doré
  // ==========================================
  Widget _bottomNav() => Container(
        padding: const EdgeInsets.only(top: 14, bottom: 24, left: 10, right: 10),
        decoration: const BoxDecoration(color: navyDeep),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _navItem(Icons.home_rounded, 'Accueil', 0),
            _navItem(Icons.grid_view_rounded, 'Services', 1),
            GestureDetector(
              onTap: () => context.push(AppRoutes.thixMoneyScanner),
              child: Transform.translate(
                offset: const Offset(0, -22),
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [gold, Color(0xFFB8871F)]),
                    border: Border.all(color: navyDeep, width: 5),
                    boxShadow: [BoxShadow(color: gold.withOpacity(0.6), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded, color: navyDeep, size: 24),
                ),
              ),
            ),
            _navItem(Icons.receipt_long_outlined, 'Historique', 3),
            _navItem(Icons.person_outline_rounded, 'Profil', 4),
          ],
        ),
      );

  Widget _navItem(IconData icon, String label, int index) {
    final active = _bottomIndex == index;
    return InkWell(
      onTap: () => setState(() => _bottomIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: active ? gold : Colors.white.withOpacity(0.45)),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: active ? gold : Colors.white.withOpacity(0.45)),
          ),
        ],
      ),
    );
  }
}
