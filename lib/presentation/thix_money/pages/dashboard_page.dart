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
  // ─── PALETTE MIX (Style de l'image Mixx) ───
  static const Color primaryBlue = Color(0xFF003882); // Bleu profond de Mixx
  static const Color accentYellow = Color(0xFFFFC72C); // Doré pour le bouton
  static const Color bgLight = Color(0xFFF8F9FB); 
  static const Color circleBg = Color(0xFFEBF0FA); 
  static const Color textDark = Color(0xFF1E2A4F); 
  static const Color textGrey = Color(0xFF64748B); 

  int _bottomIndex = 0;

  // ─── LOGIQUE RÉELLE CONNECTÉE À SUPABASE ───
  Future<Map<String, dynamic>> _getRealDashboardData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return {'name': 'Utilisateur', 'balance': 0.0, 'thix_id': ''};

    // 1. Récupérer le Profil
    final profileRes = await Supabase.instance.client
        .from('profiles')
        .select('first_name, full_name')
        .eq('id', user.id)
        .maybeSingle();
    final name = profileRes?['first_name'] ?? profileRes?['full_name'] ?? 'Utilisateur';

    // 2. Récupérer le Wallet (Solde et Thix ID)
    final walletRes = await Supabase.instance.client
        .from('wallets')
        .select('balance, thix_id')
        .eq('user_id', user.id)
        .maybeSingle();
    
    final balance = (walletRes?['balance'] ?? 0.0).toDouble();
    final thixId = walletRes?['thix_id'] ?? '';

    return {'name': name, 'balance': balance, 'thix_id': thixId};
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
      backgroundColor: bgLight,
      extendBody: true, 
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getRealDashboardData(),
        builder: (context, snapshot) {
          final data = snapshot.data ?? {'name': '...', 'balance': 0.0, 'thix_id': ''};
          final thixId = data['thix_id'] as String;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En-tête simple (façon Mixx)
                      _buildHeader(data['name'], data['balance']),
                      const SizedBox(height: 10),
                      
                      // TA GRILLE DE SERVICES AVEC LES ICÔNES COLORÉES
                      const ServiceGrid(),
                      const SizedBox(height: 24),
                      
                      // Bannière bleue
                      _buildPromoBanner(),
                      const SizedBox(height: 32),
                      
                      // Section "Personnalisé pour vous"
                      _sectionTitle('Personnalisé pour vous'),
                      const SizedBox(height: 16),
                      _buildPersonalisedRow(),
                      const SizedBox(height: 32),

                      // Section Transactions
                      _sectionTitle('Opérations récentes'),
                      const SizedBox(height: 12),
                      _buildRealTransactions(thixId),
                      
                      const SizedBox(height: 120), 
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      
      // ─── BOTTOM NAVIGATION BAR (Style Mixx avec la barre bleue en bas) ───
      floatingActionButton: FloatingActionButton(
        backgroundColor: accentYellow,
        elevation: 4,
        shape: const CircleBorder(),
        onPressed: () => context.push(AppRoutes.thixMoneyScanner),
        child: const Icon(Icons.qr_code_scanner_rounded, color: primaryBlue, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: primaryBlue,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _bottomNavItem(Icons.home_filled, 'Accueil', 0),
              _bottomNavItem(Icons.grid_view_rounded, 'Mini Apps', 1),
              const SizedBox(width: 48), 
              _bottomNavItem(Icons.headset_mic_rounded, 'Support', 2),
              _bottomNavItem(Icons.person_rounded, 'Compte', 3),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // WIDGETS DE L'INTERFACE
  // ==========================================

  Widget _buildHeader(String name, double balance) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bonjour, $name', style: const TextStyle(color: textGrey, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${_formatBalance(balance)} FC', 
                        style: const TextStyle(color: primaryBlue, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.visibility_outlined, color: textGrey, size: 18),
                    ],
                  ),
                ],
              ),
              CircleAvatar(
                radius: 20,
                backgroundColor: circleBg,
                child: const Icon(Icons.person, color: primaryBlue),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 100,
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, height: 1.2),
                      children: [
                        TextSpan(text: 'Achetez des forfaits et du crédit pour '),
                        TextSpan(text: 'vous', style: TextStyle(color: accentYellow)),
                        TextSpan(text: ' ou vos proches !'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 100,
            decoration: const BoxDecoration(
              color: Color(0xFF002B66),
              borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
            ),
            child: const Center(child: Icon(Icons.people_alt_rounded, color: Colors.white24, size: 50)),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: primaryBlue),
      ),
    );
  }

  Widget _buildPersonalisedRow() {
    final items = [
      {'l': 'Recharge', 'i': Icons.phone_android_rounded},
      {'l': 'Lipa Simu', 'i': Icons.qr_code_rounded},
      {'l': 'Loterie', 'i': Icons.casino_outlined},
      {'l': 'Forfaits', 'i': Icons.shopping_cart_outlined},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          return SizedBox(
            width: 70,
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: circleBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item['i'] as IconData, color: primaryBlue, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  item['l'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textDark, height: 1.2),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================
  // LOGIQUE DE TRANSACTIONS RÉELLES (Supabase)
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
          return const Center(child: CircularProgressIndicator(color: primaryBlue));
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
                      width: 40, height: 40,
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
  // BOTTOM NAVIGATION ITEM
  // ==========================================
  Widget _bottomNavItem(IconData icon, String label, int index) {
    final isActive = _bottomIndex == index;
    return InkWell(
      onTap: () => setState(() => _bottomIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? accentYellow : Colors.white70, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? accentYellow : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
