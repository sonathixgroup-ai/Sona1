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
  // Palette Ultra-Premium
  static const navyDeep = Color(0xFF0A1F44);
  static const navy = Color(0xFF123B7A);
  static const primaryBlue = Color(0xFF2D6CDF);
  static const gold = Color(0xFFE3B23C);
  static const backgroundLight = Color(0xFFF4F6F9); // Un gris bleuté très subtil et luxueux

  Future<Map<String,String>> _getProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user==null) return {'name':'','initial':'T'};
    final r = await Supabase.instance.client.from('profiles').select('first_name, full_name').eq('id', user.id).maybeSingle();
    final full = (r?['first_name']?? r?['full_name']?? user.email?.split('@').first?? 'THIX').toString();
    final first = full.split(' ').first;
    return {'name': first, 'initial': first.isNotEmpty? first[0].toUpperCase() : 'T'};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      extendBody: true, // Essentiel pour que la liste passe SOUS la navigation transparente
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()), 
        slivers: [
          SliverToBoxAdapter(child: _header()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 28),
              child: const BalanceCard(),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _top4(),
                const SizedBox(height: 36),
                _title('Services financiers', showAction: true),
                const SizedBox(height: 16),
                _grid(),
                const SizedBox(height: 32),
                _promoCard(),
                const SizedBox(height: 32),
                _title('Tous les paiements', showAction: true),
                const SizedBox(height: 12),
                _tx(),
                const SizedBox(height: 120), // Espace confortable pour la bottom nav
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _nav(),
    );
  }

  // ==========================================
  // HEADER : ÉPURÉ ET MODERNE
  // ==========================================
  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 64, 20, 16),
    child: FutureBuilder<Map<String,String>>(
      future: _getProfile(), 
      builder: (c,s){
        final name = s.data?['name']?? '';
        final initial = s.data?['initial']?? 'T';
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, 
          children: [
            Row(
              children: [
                // Avatar avec ombre douce et bordure
                Container(
                  width: 48, 
                  height: 48, 
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, 
                    color: Colors.white,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(color: navyDeep.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))
                    ],
                  ), 
                  child: Center(
                    child: Text(
                      initial, 
                      style: const TextStyle(color: navyDeep, fontWeight: FontWeight.w800, fontSize: 18)
                    )
                  )
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    Text(
                      name.isEmpty? 'Bonjour 👋' : 'Bonjour, $name', 
                      style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Bienvenue', 
                      style: TextStyle(color: navyDeep, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)
                    ),
                  ]
                ),
              ]
            ),
            Row(
              children: [ 
                _hIcon(Icons.qr_code_scanner_rounded, () => context.push(AppRoutes.thixMoneyScanner)), 
                const SizedBox(width: 12), 
                _hIcon(Icons.notifications_none_rounded, (){}, dot:true)
              ]
            ),
          ]
        );
      }
    ),
  );

  Widget _hIcon(IconData i, VoidCallback t, {bool dot=false}) => InkWell(
    onTap:t, 
    borderRadius: BorderRadius.circular(50),
    child: Stack(
      clipBehavior: Clip.none, 
      children:[
        Container(
          padding: const EdgeInsets.all(10), 
          decoration: BoxDecoration(
            color: Colors.white, 
            shape: BoxShape.circle, 
            boxShadow: [
              BoxShadow(color: navyDeep.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))
            ]
          ), 
          child: Icon(i, color: navyDeep, size: 22)
        ), 
        if(dot) Positioned(
          top: 0, 
          right: 0, 
          child: Container(
            width: 10, 
            height: 10, 
            decoration: BoxDecoration(
              color: const Color(0xFFE84A7A), // Rouge premium
              shape: BoxShape.circle, 
              border: Border.all(color: backgroundLight, width: 2)
            )
          )
        )
      ]
    )
  );

  // ==========================================
  // ACTIONS RAPIDES : TRADUIT ET AFFINÉ
  // ==========================================
  Widget _top4() {
    final items = [
      {'l':'Recharger', 'i':Icons.arrow_downward_rounded, 'r':AppRoutes.thixMoneyRecharge},
      {'l':'Envoyer', 'i':Icons.arrow_upward_rounded, 'r':AppRoutes.thixMoneySend},
      {'l':'Historique', 'i':Icons.history_rounded, 'r':AppRoutes.thixMoneyLoans}, 
      {'l':'Plus', 'i':Icons.grid_view_rounded, 'r':AppRoutes.thixMoneyScanner},
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24), 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
        children: items.map((a)=> InkWell(
          onTap:()=>context.push(a['r'] as String), 
          borderRadius: BorderRadius.circular(20), 
          splashColor: primaryBlue.withOpacity(0.1),
          child: Column(
            children:[
              Container(
                width: 60, 
                height: 60, 
                decoration: BoxDecoration(
                  color: Colors.white, 
                  shape: BoxShape.circle, 
                  boxShadow:[
                    BoxShadow(color: primaryBlue.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 8))
                  ]
                ), 
                child: Icon(a['i'] as IconData, color: primaryBlue, size: 26)
              ),
              const SizedBox(height: 10),
              Text(
                a['l'] as String, 
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: navyDeep, letterSpacing: -0.2)
              ),
            ]
          )
        )).toList()
      )
    );
  }

  Widget _title(String t, {bool showAction = false}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20), 
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
      children:[
        Text(
          t, 
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: navyDeep, letterSpacing: -0.3)
        ), 
        if (showAction) Text(
          'Voir plus >', 
          style: TextStyle(fontSize: 13, color: primaryBlue, fontWeight: FontWeight.w700)
        )
      ]
    )
  );

  // ==========================================
  // GRILLE DE SERVICES : ALIGNÉE SUR VOTRE DEMANDE
  // ==========================================
  Widget _grid() {
    final services = [
      {'l': 'Crédit\ninstantané', 'c': const Color(0xFF2D6CDF), 'i': Icons.bolt_rounded, 'r': AppRoutes.thixMoneyLoans},
      {'l': 'Assurance', 'c': const Color(0xFF22A57D), 'i': Icons.shield_rounded, 'r': ''},
      {'l': 'Épargne\nplanifiée', 'c': const Color(0xFFE3B23C), 'i': Icons.savings_rounded, 'r': AppRoutes.thixMoneySavings},
      {'l': 'Change', 'c': const Color(0xFF9B5CF6), 'i': Icons.swap_horiz_rounded, 'r': ''},
      {'l': 'Marchand', 'c': const Color(0xFFDC7A2B), 'i': Icons.storefront_rounded, 'r': ''},
      {'l': 'Dons &\nContrib.', 'c': const Color(0xFFE84A7A), 'i': Icons.volunteer_activism_rounded, 'r': ''},
      {'l': 'Ma Tontine', 'c': const Color(0xFF2D9CDB), 'i': Icons.groups_rounded, 'r': AppRoutes.thixMoneyTontines},
      {'l': 'Éducation', 'c': const Color(0xFF3AB6D9), 'i': Icons.school_rounded, 'r': ''},
      {'l': 'Virement\ninternational', 'c': const Color(0xFF1E3A8A), 'i': Icons.public_rounded, 'r': ''},
      {'l': 'Microfinance', 'c': const Color(0xFF4CAF50), 'i': Icons.account_balance_rounded, 'r': ''},
      {'l': 'Investissement', 'c': const Color(0xFFD4A72C), 'i': Icons.trending_up_rounded, 'r': AppRoutes.thixMoneyInvestments},
      {'l': 'Planification', 'c': const Color(0xFF123B7A), 'i': Icons.calendar_month_rounded, 'r': ''},
    ];

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16), 
      shrinkWrap: true, 
      physics: const NeverScrollableScrollPhysics(), 
      itemCount: 12, 
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, 
        mainAxisSpacing: 18, 
        crossAxisSpacing: 8, 
        childAspectRatio: 0.78 // Aspect ajusté pour que l'icône respire
      ), 
      itemBuilder: (_,i){
        final s = services[i];
        final color = s['c'] as Color;
        final route = s['r'] as String;
        return GestureDetector(
          onTap: () => route.isNotEmpty ? context.push(route) : null,
          child: Column(
            children:[
              Container(
                width: 56, 
                height: 56, 
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08), // Pastel luxueux
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.1), width: 1.5), // Finesse du détail
                ), 
                child: Icon(s['i'] as IconData, color: color, size: 26)
              ), 
              const SizedBox(height: 8), 
              Text(
                s['l'] as String, 
                textAlign: TextAlign.center, 
                maxLines: 2,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: navyDeep, height: 1.1, letterSpacing: -0.2)
              )
            ]
          ),
        );
    });
  }

  // ==========================================
  // CARTE PROMO "GLOWING" (Atout Investisseur)
  // ==========================================
  Widget _promoCard() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 20), 
    padding: const EdgeInsets.all(22), 
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24), 
      gradient: const LinearGradient(
        colors: [navyDeep, Color(0xFF162D5A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(color: navyDeep.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 10))
      ]
    ), 
    child: Row(
      children:[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children:[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: gold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8)
                ),
                child: const Text('NOUVEAU', style: TextStyle(color: gold, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Crédit instantané', 
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)
              ), 
              const SizedBox(height: 4),
              Text(
                'Jusqu\'à 500 000 FC en 5 minutes,\nsans aucun dossier physique.', 
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, height: 1.4)
              )
            ]
          )
        ), 
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15), 
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1)
          ),
          child: const Icon(Icons.arrow_forward_rounded, size: 22, color: Colors.white)
        )
      ]
    )
  );

  // ==========================================
  // LISTE DES TRANSACTIONS (Style Carte Séparée)
  // ==========================================
  Widget _tx() => FutureBuilder<String>(
    future: ref.read(walletServiceProvider).getVerifiedThixId(), 
    builder: (c,s){ 
      if(!s.hasData) return const SizedBox(); 
      return FutureBuilder(
        future: Supabase.instance.client.from('thix_transactions').select().eq('thix_id', s.data!).order('created_at', ascending:false).limit(3), 
        builder: (c,snap){ 
          final list=(snap.data as List?)?? []; 
          if(list.isEmpty) return Container(
            margin: const EdgeInsets.symmetric(horizontal:20), 
            padding: const EdgeInsets.all(20), 
            decoration: BoxDecoration(color:Colors.white, borderRadius:BorderRadius.circular(20)), 
            child: const Center(child: Text('Aucune transaction récente', style:TextStyle(fontSize:13, color:Colors.grey)))
          ); 
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: list.map<Widget>((t){
                bool isDeposit = (t['type'] == 'reception' || t['type'] == 'Deposit');
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black.withOpacity(0.02), width: 1),
                    boxShadow: [
                      BoxShadow(color: navyDeep.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                    ]
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46, 
                        height: 46, 
                        decoration: BoxDecoration(
                          color: isDeposit ? const Color(0xFF1FA97F).withOpacity(0.12) : navy.withOpacity(0.08), 
                          shape: BoxShape.circle,
                        ), 
                        child: Icon(
                          isDeposit ? Icons.arrow_downward_rounded : Icons.receipt_long_rounded, 
                          size: 22, 
                          color: isDeposit ? const Color(0xFF1FA97F) : navy
                        )
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t['type']??'Transaction', 
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: navyDeep)
                            ), 
                            const SizedBox(height: 2),
                            Text(
                              t['ref_transa']??'Détails indisponibles', 
                              style: const TextStyle(fontSize: 11.5, color: Colors.black45)
                            ), 
                          ],
                        ),
                      ),
                      Text(
                        '${isDeposit ? '+' : '-'} ${t['montant']} ${t['devise']}', 
                        style: TextStyle(
                          fontSize: 15, 
                          fontWeight: FontWeight.w900, 
                          letterSpacing: -0.5,
                          color: isDeposit ? const Color(0xFF1FA97F) : navyDeep
                        )
                      ),
                    ],
                  ),
                );
              }).toList()
            ),
          ); 
        }
      ); 
    }
  );

   // ==========================================
  // BOTTOM NAV : VERRE DÉPOLI (CORRIGÉ)
  // ==========================================
  Widget _nav() => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35), 
          boxShadow: [
            BoxShadow(color: navyDeep.withOpacity(0.12), blurRadius: 25, offset: const Offset(0, 10))
          ]
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              height: 70, 
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85), // Transparence pour le blur
                border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
              ), 
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
                children:[
                  const _NavIcon(icon: Icons.home_rounded, isActive: true),
                  const _NavIcon(icon: Icons.bar_chart_rounded),
                  
                  // Bouton Central Flottant Superposé
                  Transform.translate(
                    offset: const Offset(0, -6),
                    child: GestureDetector(
                      onTap: () => context.push(AppRoutes.thixMoneyScanner),
                      child: Container(
                        width: 56, 
                        height: 56, 
                        decoration: BoxDecoration(
                          color: navyDeep, 
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: navyDeep.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 6))
                          ]
                        ), 
                        child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 26)
                      ),
                    ),
                  ),
                  
                  const _NavIcon(icon: Icons.account_balance_wallet_rounded),
                  const _NavIcon(icon: Icons.person_outline_rounded),
                ]
              )
            ),
          ),
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
        Icon(icon, color: isActive ? const Color(0xFF0A1F44) : Colors.black26, size: 28),
        if (isActive) ...[
          const SizedBox(height: 6),
          Container(width: 5, height: 5, decoration: const BoxDecoration(color: Color(0xFF0A1F44), shape: BoxShape.circle))
        ]
      ],
    );
  }
}
