// lib/presentation/thix_money/pages/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});
  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  // ─── PALETTE (Charte du nouveau design) ───
  static const Color gradientTop = Color(0xFF6D28D9);
  static const Color gradientBottom = Color(0xFF3B0764);
  static const Color accentPurple = Color(0xFF7C3AED);
  static const Color bgLight = Color(0xFFF7F7FB);
  static const Color textDark = Color(0xFF1E1B2E);
  static const Color textGrey = Color(0xFF9291A5);
  static const Color textGreyLight = Color(0xFFC9C6D6);

  int _bottomIndex = 0;
  final PageController _promoController = PageController(viewportFraction: 0.86);
  bool _balanceVisible = true;

  // ─── DONNÉES RÉELLES SUPABASE ───
  Future<Map<String, dynamic>> _getRealDashboardData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return {'name': 'Utilisateur', 'balance': 0.0, 'thix_id': ''};

    final profileRes = await Supabase.instance.client
        .from('profiles')
        .select('first_name, full_name, avatar_url')
        .eq('id', user.id)
        .maybeSingle();
    final name = profileRes?['first_name'] ?? profileRes?['full_name'] ?? 'Utilisateur';
    final avatarUrl = profileRes?['avatar_url'] as String?;

    final walletRes = await Supabase.instance.client
        .from('wallets')
        .select('balance, thix_id')
        .eq('user_id', user.id)
        .maybeSingle();

    final balance = (walletRes?['balance'] ?? 0.0).toDouble();
    final thixId = walletRes?['thix_id'] ?? '';

    return {'name': name, 'balance': balance, 'thix_id': thixId, 'avatar_url': avatarUrl};
  }

  Stream<List<Map<String, dynamic>>> _promoStream() {
    return Supabase.instance.client
        .from('thix_money_promos')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(6);
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
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      extendBody: true,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getRealDashboardData(),
        builder: (context, snapshot) {
          final data = snapshot.data ?? {'name': '...', 'balance': 0.0, 'thix_id': '', 'avatar_url': null};
          final thixId = data['thix_id'] as String;

          return Stack(
            children: [
              // ─── FOND DÉGRADÉ VIOLET ───
              Container(
                height: 340,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [gradientTop, gradientBottom],
                  ),
                ),
              ),
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(data['name'], data['balance'], data['avatar_url']),
                          const SizedBox(height: 14),
                          _buildQuickActionsCard(thixId),
                          const SizedBox(height: 28),
                          _sectionTitle('Payment List'),
                          const SizedBox(height: 16),
                          _buildPaymentGrid(),
                          const SizedBox(height: 28),
                          _sectionTitle('Promo & Discount', trailing: 'See more'),
                          const SizedBox(height: 14),
                          _buildPromoCarousel(),
                          const SizedBox(height: 28),
                          _sectionTitle('Opérations récentes'),
                          const SizedBox(height: 12),
                          _buildRealTransactions(thixId),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),

      // ─── BOUTON SCAN CENTRAL ───
      floatingActionButton: FloatingActionButton(
        backgroundColor: accentPurple,
        elevation: 4,
        shape: const CircleBorder(),
        onPressed: () => context.push('/thix-money/scanner'),
        child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 26),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ─── BARRE DE NAVIGATION ───
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        elevation: 12,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _bottomNavItem(Icons.home_rounded, 'Accueil', 0),
              _bottomNavItem(Icons.show_chart_rounded, 'Activité', 1),
              const SizedBox(width: 48),
              _bottomNavItem(Icons.receipt_long_rounded, 'Historique', 2),
              _bottomNavItem(Icons.person_rounded, 'Compte', 3),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // EN-TÊTE (Solde disponible)
  // ==========================================
  Widget _buildHeader(String name, double balance, String? avatarUrl) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white24,
                backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                    ? NetworkImage(avatarUrl)
                    : null,
                child: (avatarUrl == null || avatarUrl.isEmpty)
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
              InkWell(
                onTap: () => context.push('/thix-money/notifications'),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white38),
                  ),
                  child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Solde disponible',
            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _balanceVisible ? '${_formatBalance(balance)} FC' : '•••••• FC',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () => setState(() => _balanceVisible = !_balanceVisible),
                child: Icon(
                  _balanceVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
        ],
      ),
    );
  }

  // ==========================================
  // CARTE FLOTTANTE — ACTIONS RAPIDES
  // ==========================================
  Widget _buildQuickActionsCard(String thixId) {
    final actions = [
      {'label': 'Top Up', 'icon': Icons.account_balance_wallet_outlined, 'route': '/thix-money/topup'},
      {'label': 'Envoyer', 'icon': Icons.arrow_upward_rounded, 'route': '/thix-money/send'},
      {'label': 'Demander', 'icon': Icons.arrow_downward_rounded, 'route': '/thix-money/request'},
      {'label': 'Historique', 'icon': Icons.history_rounded, 'route': '/thix-money/history'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8)),
          ],
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
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1EAFE),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(a['icon'] as IconData, color: accentPurple, size: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    a['label'] as String,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textDark),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, {String? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textDark),
          ),
          if (trailing != null)
            InkWell(
              onTap: () => context.push('/thix-money/promos'),
              child: Text(
                trailing,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: accentPurple),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // GRILLE DES SERVICES (Payment List)
  // ==========================================
  Widget _buildPaymentGrid() {
    final services = [
      {
        'label': 'Internet',
        'icon': Icons.wifi_rounded,
        'bg': const Color(0xFFFFE5E5),
        'fg': const Color(0xFFFF5A5A),
        'route': '/thix-money/internet',
      },
      {
        'label': 'Électricité',
        'icon': Icons.bolt_rounded,
        'bg': const Color(0xFFFFF1D6),
        'fg': const Color(0xFFFFA726),
        'route': '/thix-money/electricity',
      },
      {
        'label': 'Voucher',
        'icon': Icons.confirmation_number_outlined,
        'bg': const Color(0xFFE3F7E8),
        'fg': const Color(0xFF34C759),
        'route': '/thix-money/voucher',
      },
      {
        'label': 'Assurance',
        'icon': Icons.health_and_safety_outlined,
        'bg': const Color(0xFFDFF6F6),
        'fg': const Color(0xFF17A2A2),
        'route': '/thix-money/insurance',
      },
      {
        'label': 'M Card',
        'icon': Icons.credit_card_rounded,
        'bg': const Color(0xFFEDE4FB),
        'fg': accentPurple,
        'route': '/thix-money/mcard',
      },
      {
        'label': 'Facture',
        'icon': Icons.receipt_long_rounded,
        'bg': const Color(0xFFE1EBFB),
        'fg': const Color(0xFF2D6CDF),
        'route': '/thix-money/bill',
      },
      {
        'label': 'Marchand',
        'icon': Icons.storefront_rounded,
        'bg': const Color(0xFFFCE4F1),
        'fg': const Color(0xFFE91E8C),
        'route': '/thix-money/merchant',
      },
      {
        'label': 'Plus',
        'icon': Icons.apps_rounded,
        'bg': const Color(0xFFEDE4FB),
        'fg': accentPurple,
        'route': '/thix-money/more',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: services.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 18,
          crossAxisSpacing: 8,
          childAspectRatio: 0.78,
        ),
        itemBuilder: (context, index) {
          final s = services[index];
          return InkWell(
            onTap: () => context.push(s['route'] as String),
            borderRadius: BorderRadius.circular(18),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: s['bg'] as Color, shape: BoxShape.circle),
                  child: Icon(s['icon'] as IconData, color: s['fg'] as Color, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  s['label'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textDark, height: 1.2),
                ),
              ],
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
            return const Center(child: CircularProgressIndicator(color: accentPurple));
          }

          if (promos.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(color: gradientBottom, borderRadius: BorderRadius.circular(20)),
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
              final Color bg = index.isEven ? gradientBottom : const Color(0xFF0F766E);
              return Padding(
                padding: const EdgeInsets.only(left: 20, right: 10),
                child: InkWell(
                  onTap: () => context.push('/thix-money/promos/${p['id']}'),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -10,
                          top: -10,
                          child: Icon(Icons.blur_circular, color: Colors.white.withOpacity(0.08), size: 90),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                p['title'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                p['subtitle'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
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
          return const Center(child: CircularProgressIndicator(color: accentPurple));
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

  // ==========================================
  // NAVIGATION DU BAS
  // ==========================================
  Widget _bottomNavItem(IconData icon, String label, int index) {
    final isActive = _bottomIndex == index;
    return InkWell(
      onTap: () => setState(() => _bottomIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? accentPurple : textGreyLight, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? accentPurple : textGreyLight,
            ),
          ),
        ],
      ),
    );
  }
}
