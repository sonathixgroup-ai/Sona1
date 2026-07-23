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
  // Palette Premium et Minimaliste
  static const navyDeep = Color(0xFF0A1F44);
  static const navy = Color(0xFF123B7A);
  static const primaryBlue = Color(0xFF2D6CDF);
  static const gold = Color(0xFFE3B23C);
  static const backgroundLight = Color(0xFFF8F9FA); // Plus pur que l'ivory pour un look "Apple/Fintech"

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
      extendBody: true,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(), // Scroll très fluide
        slivers: [
          SliverToBoxAdapter(child: _header()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 24),
              child: const BalanceCard(),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _top4(),
                const SizedBox(height: 32),
                _title('Services financiers', showAction: true),
                const SizedBox(height: 16),
                _grid(),
                const SizedBox(height: 28),
                _promo(),
                const SizedBox(height: 28),
                _title('Tous les paiements', showAction: true),
                const SizedBox(height: 8),
                _tx(),
                const SizedBox(height: 110), // Espace pour la bottom nav
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _nav(),
    );
  }

  // ==========================================
  // HEADER CLEAN ET LUMINEUX
  // ==========================================
  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 60, 20, 10),
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
                Container(
                  width: 44, 
                  height: 44, 
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, 
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: navyDeep.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))
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
                      style: TextStyle(color: navyDeep, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5)
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
              BoxShadow(color: navyDeep.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))
            ]
          ), 
          child: Icon(i, color: navyDeep, size: 20)
        ), 
        if(dot) Positioned(
          top: 2, 
          right: 2, 
          child: Container(
            width: 8, 
            height: 8, 
            decoration: BoxDecoration(
              color: Colors.redAccent, // Point de notification rouge plus standard
              shape: BoxShape.circle, 
              border: Border.all(color: Colors.white, width: 1.5)
            )
          )
        )
      ]
    )
  );

  // ==========================================
  // ACTIONS RAPIDES (STYLE NEUMORPHISME DOUX)
  // ==========================================
  Widget _top4() {
    final items = [
      {'l':'Ingresos', 'i':Icons.arrow_downward_rounded, 'r':AppRoutes.thixMoneyRecharge},
      {'l':'Historial', 'i':Icons.history_rounded, 'r':AppRoutes.thixMoneyRetrait}, // Ajustez la route selon vos besoins
      {'l':'Envíos', 'i':Icons.arrow_upward_rounded, 'r':AppRoutes.thixMoneySend},
      {'l':'Más', 'i':Icons.grid_view_rounded, 'r':AppRoutes.thixMoneyScanner},
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal:20), 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
        children: items.map((a)=> InkWell(
          onTap:()=>context.push(a['r'] as String), 
          borderRadius: BorderRadius.circular(16), 
          child: Column(
            children:[
              Container(
                width: 58, 
                height: 58, 
                decoration: BoxDecoration(
                  color: Colors.white, 
                  shape: BoxShape.circle, 
                  boxShadow:[
                    BoxShadow(color: navyDeep.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 5))
                  ]
                ), 
                child: Icon(a['i'] as IconData, color: primaryBlue, size: 24)
              ),
              const SizedBox(height: 8),
              Text(
                a['l'] as String, 
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: navyDeep)
              ),
            ]
          )
        )).toList()
      )
    );
  }

  // ==========================================
  // TITRES DE SECTIONS
  // ==========================================
  Widget _title(String t, {bool showAction = false}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20), 
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
      children:[
        Text(
          t, 
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: navyDeep, letterSpacing: -0.3)
        ), 
        if (showAction) Text(
          'Voir plus >', 
          style: TextStyle(fontSize: 12.5, color: primaryBlue, fontWeight: FontWeight.w600)
        )
      ]
    )
  );

  // ==========================================
  // GRILLE DE SERVICES (FOND CLAIR, ICÔNES COLORÉES)
  // ==========================================
  Widget _grid() => GridView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 16), 
    shrinkWrap: true, 
    physics: const NeverScrollableScrollPhysics(), 
    itemCount: 12, 
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 4, 
      mainAxisSpacing: 16, 
      crossAxisSpacing: 8, 
      childAspectRatio: 0.8
    ), 
    itemBuilder: (_,i){
      // Couleurs dominantes uniques par icône
      const colors = [
        Color(0xFF2D6CDF), Color(0xFF1FA97F), Color(0xFFE3B23C), Color(0xFF9B59B6), 
        Color(0xFFE0743C), Color(0xFFE0507A), Color(0xFF2DA6DF), Color(0xFF3CB4E3), 
        Color(0xFF123B7A), Color(0xFF4CAF50), Color(0xFFE3B23C), Color(0xFF1A3D8C)
      ];
      const icons = [
        Icons.bolt_rounded, Icons.shield_rounded, Icons.savings_rounded, Icons.swap_horiz_rounded, 
        Icons.storefront_rounded, Icons.volunteer_activism_rounded, Icons.groups_rounded, Icons.school_rounded, 
        Icons.public_rounded, Icons.account_balance_rounded, Icons.trending_up_rounded, Icons.calendar_month_rounded
      ];
      const labels = [
        'Crédit\ninstantané','Assurance','Épargne','Change','Marchand','Dons','Tontine','Éducation','Virement','Microfinance','Invest.','Planif.'
      ];
      
      final c = colors[i];
      return Column(
        children:[
          Container(
            width: 52, 
            height: 52, 
            decoration: BoxDecoration(
              color: c.withOpacity(0.12), // Fond pastelle très élégant
              shape: BoxShape.circle,
            ), 
            child: Icon(icons[i], color: c, size: 24)
          ), 
          const SizedBox(height: 6), 
          Text(
            labels[i], 
            textAlign: TextAlign.center, 
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: navyDeep, height: 1.1)
          )
        ]
      );
  });

  // ==========================================
  // BANNIÈRE PROMO
  // ==========================================
  Widget _promo() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 20), 
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18), 
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20), 
      color: navyDeep, // Contraste fort comme sur Mixx
      boxShadow: [
        BoxShadow(color: navyDeep.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))
      ]
    ), 
    child: Row(
      children:[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children:[
              const Text(
                'Crédit instantané', 
                style: TextStyle(color: gold, fontSize: 15, fontWeight: FontWeight.w800)
              ), 
              const SizedBox(height: 4),
              Text(
                'Jusqu\'à 500 000 FC en 5 minutes,\nsans aucun dossier physique.', 
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11.5, height: 1.3)
              )
            ]
          )
        ), 
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
          child: const Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white)
        )
      ]
    )
  );

  // ==========================================
  // LISTE DES TRANSACTIONS ÉPURÉE
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
            padding: const EdgeInsets.all(16), 
            decoration: BoxDecoration(color:Colors.white, borderRadius:BorderRadius.circular(16)), 
            child: const Center(child: Text('Aucune transaction', style:TextStyle(fontSize:12, color:Colors.grey)))
          ); 
          return Container(
            margin: const EdgeInsets.symmetric(horizontal:20), 
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: navyDeep.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
              ]
            ), 
            child: Column(
              children: list.map<Widget>((t){
                // Simulation d'une belle interface de liste de paiement
                bool isDeposit = (t['type'] == 'reception' || t['type'] == 'Deposit');
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 44, 
                    height: 44, 
                    decoration: BoxDecoration(
                      color: isDeposit ? const Color(0xFFE7F6EE) : const Color(0xFFF3F0FF), 
                      borderRadius: BorderRadius.circular(12)
                    ), 
                    child: Icon(
                      isDeposit ? Icons.arrow_downward_rounded : Icons.receipt_long_rounded, 
                      size: 20, 
                      color: isDeposit ? const Color(0xFF1FA97F) : const Color(0xFF9B59B6)
                    )
                  ), 
                  title: Text(
                    t['type']??'Transaction', 
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: navyDeep)
                  ), 
                  subtitle: Text(
                    t['ref_transa']??'Détails', 
                    style: const TextStyle(fontSize: 11, color: Colors.black45)
                  ), 
                  trailing: Text(
                    '${isDeposit ? '+' : '-'} ${t['montant']} ${t['devise']}', 
                    style: TextStyle(
                      fontSize: 14, 
                      fontWeight: FontWeight.w800, 
                      color: isDeposit ? const Color(0xFF1FA97F) : navyDeep
                    )
                  ),
                );
              }).toList()
            )
          ); 
        }
      ); 
    }
  );

  // ==========================================
  // BOTTOM NAVIGATION FLOATTANTE & DESIGN
  // ==========================================
  Widget _nav() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), 
    child: Container(
      height: 68, 
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(30), 
        boxShadow: [
          BoxShadow(color: navyDeep.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))
        ]
      ), 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
        children:[
          const _NavIcon(icon: Icons.home_rounded, isActive: true),
          const _NavIcon(icon: Icons.bar_chart_rounded),
          GestureDetector(
            onTap: () => context.push(AppRoutes.thixMoneyScanner),
            child: Container(
              width: 52, 
              height: 52, 
              decoration: const BoxDecoration(
                color: navyDeep, 
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: navyDeep, blurRadius: 10, offset: Offset(0, 4))
                ]
              ), 
              child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 24)
            ),
          ),
          const _NavIcon(icon: Icons.account_balance_wallet_rounded),
          const _NavIcon(icon: Icons.person_outline_rounded),
        ]
      )
    )
  );
}

// Petit widget utilitaire pour la navigation du bas
class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  
  const _NavIcon({required this.icon, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: isActive ? const Color(0xFF0A1F44) : Colors.black26, size: 26),
        if (isActive) ...[
          const SizedBox(height: 4),
          Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFF0A1F44), shape: BoxShape.circle))
        ]
      ],
    );
  }
}
