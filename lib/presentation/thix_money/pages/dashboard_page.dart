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
  // ─── PALETTE (Charte du design de référence — clair + carte sombre) ───
  static const Color bgLight = Color(0xFFF5F5F3);
  static const Color darkBg = Color(0xFF1C1C1E);
  static const Color darkCard = Color(0xFF2A2A2E);
  static const Color accentLime = Color(0xFFD4FF3D);
  static const Color textDark = Color(0xFF16161A);
  static const Color textGrey = Color(0xFF8E8E93);

  final PageController _cardController = PageController(viewportFraction: 0.88);
  final PageController _promoController = PageController(viewportFraction: 0.86);
  int _cardPage = 0;
  bool _balanceVisible = true;

  // ─── TES VRAIS SERVICES (inchangés) ───
  static const List<_Service> _services = [
    _Service(label: 'Crédit', color: Color(0xFF1E3A8A), icon: Icons.bolt_outlined, route: AppRoutes.thixMoneyLoans),
    _Service(label: 'Assurance', color: Color(0xFF0F766E), icon: Icons.security_outlined, route: null),
    _Service(label: 'Épargne', color: Color(0xFFB45309), icon: Icons.savings_outlined, route: AppRoutes.thixMoneySavings),
    _Service(label: 'Change', color: Color(0xFF6D28D9), icon: Icons.currency_exchange_outlined, route: null),
    _Service(label: 'Marchand', color: Color(0xFFC2410C), icon: Icons.storefront_outlined, route: AppRoutes.thixMarket),
    _Service(label: 'Dons', color: Color(0xFFBE123C), icon: Icons.favorite_border_rounded, route: null),
    _Service(label: 'Tontine', color: Color(0xFF0369A1), icon: Icons.groups_outlined, route: AppRoutes.thixMoneyTontines),
    _Service(label: 'Éducation', color: Color(0xFF0E7490), icon: Icons.school_outlined, route: AppRoutes.education),
    _Service(label: 'Virement', color: Color(0xFF1D4ED8), icon: Icons.language_outlined, route: AppRoutes.thixMoneySend),
    _Service(label: 'Microfinance', color: Color(0xFF15803D), icon: Icons.account_balance_outlined, route: AppRoutes.thixMoneyLoans),
    _Service(label: 'Investir', color: Color(0xFFB45309), icon: Icons.show_chart_rounded, route: AppRoutes.thixMoneyInvestments),
    _Service(label: 'Planifier', color: Color(0xFF0F172A), icon: Icons.calendar_month_outlined, route: AppRoutes.thixMoneySavings),
  ];

  // ─── DONNÉES RÉELLES SUPABASE ───
  Future<Map<String, dynamic>> _getRealDashboardData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return {'name': 'Utilisateur', 'balance_fc': 0.0, 'balance_usd': 0.0, 'thix_id': '', 'avatar_url': null};
    }

    final profileRes = await Supabase.instance.client
        .from('profiles')
        .select('first_name, full_name, avatar_url')
        .eq('id', user.id)
        .maybeSingle();
    final name = profileRes?['first_name'] ?? profileRes?['full_name'] ?? 'Utilisateur';
    final avatarUrl = profileRes?['avatar_url'] as String?;

    // Le Thix ID et le solde (FC + USD) proviennent tous deux du wallet enregistré en base.
    final walletRes = await Supabase.instance.client
        .from('wallets')
        .select('balance, balance_usd, thix_id')
        .eq('user_id', user.id)
        .maybeSingle();

    final balanceFc = (walletRes?['balance'] ?? 0.0).toDouble();
    final balanceUsd = (walletRes?['balance_usd'] ?? 0.0).toDouble();
    final thixId = walletRes?['thix_id'] ?? '';

    return {
      'name': name,
      'balance_fc': balanceFc,
      'balance_usd': balanceUsd,
      'thix_id': thixId,
      'avatar_url': avatarUrl,
    };
  }

  Stream<List<Map<String, dynamic>>> _promoStream() {
    return Supabase.instance.client
        .from('thix_money_promos')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(6);
  }

  String _formatAmount(double value) {
    final str = value.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i != 0 && (str.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  // Formate le Thix ID enregistré en base comme un numéro de carte (groupes de 4)
  String _formatThixId(String thixId) {
    if (thixId.isEmpty) return '•••• •••• •••• ••••';
    final clean = thixId.replaceAll(RegExp(r'\s+'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      if (i != 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(clean[i]);
    }
    return buffer.toString();
  }

  @override
  void dispose() {
    _cardController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getRealDashboardData(),
        builder: (context, snapshot) {
          final data = snapshot.data ??
              {'name': '...', 'balance_fc': 0.0, 'balance_usd': 0.0, 'thix_id': '', 'avatar_url': null};
          final thixId = data['thix_id'] as String;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ─── EN-TÊTE CLAIR ───
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopBar(data['name'], data['avatar_url']),
                        const SizedBox(height: 20),
                        _buildSearchBar(),
                        const SizedBox(height: 28),
                        _sectionTitle('Services'),
                        const SizedBox(height: 14),
                        _buildServiceFavorites(),
                        const SizedBox(height: 28),
                        _sectionTitle('Mon compte', trailing: '+ Ajouter'),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── SECTION SOMBRE — CARTE(S) DE SOLDE ───
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: darkBg,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  padding: const EdgeInsets.only(top: 24, bottom: 24),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 220,
                        child: PageView(
                          controller: _cardController,
                          onPageChanged: (i) => setState(() => _cardPage = i),
                          children: [
                            _buildBalanceCard(
                              thixId: thixId,
                              balanceFc: data['balance_fc'] as double,
                              balanceUsd: data['balance_usd'] as double,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDotsIndicator(1),
                    ],
                  ),
                ),
              ),

              // ─── RESTE DU CONTENU SUR FOND CLAIR ───
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 28),
                    _sectionTitle('Tous les services'),
                    const SizedBox(height: 16),
                    _buildServiceGrid(),
                    const SizedBox(height: 28),
                    _sectionTitle('Promo & Discount', trailing: 'See more'),
                    const SizedBox(height: 14),
                    _buildPromoCarousel(),
                    const SizedBox(height: 28),
                    _sectionTitle('Opérations récentes'),
                    const SizedBox(height: 12),
                    _buildRealTransactions(thixId),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  // BARRE DU HAUT (Bonjour + avatar)
  // ==========================================
  Widget _buildTopBar(String name, String? avatarUrl) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Bonjour, $name',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textDark),
        ),
        InkWell(
          onTap: () => context.push('/account'),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: darkBg,
            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
            child: (avatarUrl == null || avatarUrl.isEmpty)
                ? const Icon(Icons.person, color: Colors.white70)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return InkWell(
      onTap: () => context.push('/thix-money/search'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('Rechercher', style: TextStyle(color: textGrey, fontSize: 14)),
            Icon(Icons.search_rounded, color: textGrey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, {String? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: textDark)),
        if (trailing != null)
          InkWell(
            onTap: () => context.push('/thix-money/services'),
            child: Text(
              trailing,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textGrey, letterSpacing: 0.4),
            ),
          ),
      ],
    );
  }

  // ==========================================
  // "FAVORITES" — remplacé par tes services THIX MONEY
  // (mêmes cercles sombres, mêmes tailles, juste les glyphes/couleurs qui changent)
  // ==========================================
  Widget _buildServiceFavorites() {
    final favorites = _services.take(6).toList();
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: favorites.length,
        separatorBuilder: (_, __) => const SizedBox(width: 18),
        itemBuilder: (context, index) {
          final s = favorites[index];
          final bool enabled = s.route != null;
          return InkWell(
            onTap: enabled
                ? () => context.push(s.route!)
                : () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${s.label} — bientôt disponible')),
                    ),
            borderRadius: BorderRadius.circular(32),
            child: Opacity(
              opacity: enabled ? 1.0 : 0.5,
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(color: darkBg, shape: BoxShape.circle),
                    child: Icon(s.icon, color: s.color, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(s.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textDark)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // CARTE DE SOLDE — Thix ID en numéro de carte,
  // solde FC + USD toujours en petite taille,
  // + les 4 boutons d'action (aucun oublié)
  // ==========================================
  Widget _buildBalanceCard({
    required String thixId,
    required double balanceFc,
    required double balanceUsd,
  }) {
    final actions = [
      {'label': 'Top Up', 'icon': Icons.add_card_outlined, 'route': '/thix-money/topup'},
      {'label': 'Envoyer', 'icon': Icons.north_east_rounded, 'route': AppRoutes.thixMoneySend},
      {'label': 'Demander', 'icon': Icons.south_west_rounded, 'route': '/thix-money/request'},
      {'label': 'Historique', 'icon': Icons.history_rounded, 'route': '/thix-money/history'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [darkCard, darkBg],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.sim_card_rounded, color: accentLime, size: 26),
                Text(
                  'THIX ID',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              _formatThixId(thixId),
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1.5),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  _balanceVisible ? '${_formatAmount(balanceFc)} FC' : '•••••• FC',
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                Container(width: 3, height: 3, decoration: BoxDecoration(color: Colors.white38, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(
                  _balanceVisible ? '\$ ${balanceUsd.toStringAsFixed(2)}' : '•••• \$',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => setState(() => _balanceVisible = !_balanceVisible),
                  child: Icon(
                    _balanceVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: Colors.white38,
                    size: 16,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: actions.map((a) {
                return InkWell(
                  onTap: () => context.push(a['route'] as String),
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: accentLime.withOpacity(0.14), shape: BoxShape.circle),
                        child: Icon(a['icon'] as IconData, color: accentLime, size: 20),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        a['label'] as String,
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDotsIndicator(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == _cardPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? accentLime : Colors.white24,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  // ==========================================
  // GRILLE COMPLÈTE DE TES SERVICES
  // ==========================================
  Widget _buildServiceGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _services.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 18,
          crossAxisSpacing: 8,
          childAspectRatio: 0.78,
        ),
        itemBuilder: (context, index) {
          final s = _services[index];
          final bool enabled = s.route != null;
          return InkWell(
            onTap: enabled
                ? () => context.push(s.route!)
                : () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${s.label} — bientôt disponible')),
                    ),
            borderRadius: BorderRadius.circular(18),
            child: Opacity(
              opacity: enabled ? 1.0 : 0.55,
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(color: s.color.withOpacity(0.12), shape: BoxShape.circle),
                    child: Icon(s.icon, color: s.color, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textDark, height: 1.2),
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
  // PROMO & DISCOUNT — CARROUSEL RÉEL (Supabase)
  // ==========================================
  Widget _buildPromoCarousel() {
    return SizedBox(
      height: 130,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _promoStream(),
        builder: (context, snapshot) {
          final promos = snapshot.data ?? [];

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: darkBg));
          }

          if (promos.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(color: darkBg, borderRadius: BorderRadius.circular(20)),
                child: const Center(
                  child: Text('Aucune offre pour le moment', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ),
              ),
            );
          }

          return PageView.builder(
            controller: _promoController,
            padEnds: false,
            itemCount: promos.length,
            itemBuilder: (context, index) {
              final p = promos[index];
              return Padding(
                padding: const EdgeInsets.only(left: 20, right: 10),
                child: InkWell(
                  onTap: () => context.push('/thix-money/promos/${p['id']}'),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(color: darkBg, borderRadius: BorderRadius.circular(20)),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -10,
                          top: -10,
                          child: Icon(Icons.blur_circular, color: accentLime.withOpacity(0.10), size: 90),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                p['title'] ?? '',
                                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, height: 1.2),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                p['subtitle'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.3),
                              ),
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

  // ==========================================
  // TRANSACTIONS RÉELLES (Supabase)
  // ==========================================
  Widget _buildRealTransactions(String thixId) {
    if (thixId.isEmpty) {
      return const Center(child: Text('Chargement du Thix ID...', style: TextStyle(color: textGrey)));
    }

    return FutureBuilder(
      future: Supabase.instance.client
          .from('thix_transactions')
          .select()
          .eq('thix_id', thixId)
          .order('created_at', ascending: false)
          .limit(5),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: darkBg));
        }

        final list = (snapshot.data as List?) ?? [];

        if (list.isEmpty) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: const Center(child: Text('Aucune opération récente', style: TextStyle(fontSize: 13, color: textGrey))),
          );
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: list.asMap().entries.map((entry) {
              final idx = entry.key;
              final t = entry.value;
              final bool isDeposit = (t['type'] == 'reception' || t['type'] == 'Deposit');

              return Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDeposit ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isDeposit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                        color: isDeposit ? Colors.green : Colors.red,
                        size: 20,
                      ),
                    ),
                    title: Text(t['type'] ?? 'Opération', style: const TextStyle(fontWeight: FontWeight.w700, color: textDark, fontSize: 13)),
                    subtitle: Text(t['ref_transa'] ?? 'Détails indisponibles', style: const TextStyle(fontSize: 11, color: textGrey)),
                    trailing: Text(
                      '${isDeposit ? '+' : '-'} ${t['montant']} ${t['devise']}',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: isDeposit ? Colors.green : textDark),
                    ),
                  ),
                  if (idx < list.length - 1)
                    Divider(height: 1, indent: 64, color: Colors.grey.withOpacity(0.1)),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
