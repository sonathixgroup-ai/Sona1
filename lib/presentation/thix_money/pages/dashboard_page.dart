// lib/presentation/thix_money/pages/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/nav.dart';
import '../widgets/service_grid.dart'; // Import de ton fichier externe

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});
  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  // Palette "Grandeur Fintech" : Luxueuse, institutionnelle et moderne
  static const premiumDark = Color(0xFF0F172A); // Bleu nuit très profond/Ardoise
  static const premiumBlue = Color(0xFF1E3A8A); // Bleu royal institutionnel
  static const premiumGold = Color(0xFFD4AF37); // Or métallique pour l'accentuation
  static const bgScaffold = Color(0xFFF4F6F9); // Fond gris perle ultra clean
  static const surfaceWhite = Colors.white;

  // ─── LOGIQUE RÉELLE CONNECTÉE À SUPABASE ───
  Future<Map<String, dynamic>> _getDashboardData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return {'name': '', 'initial': 'T', 'balance': 0.0, 'thix_id': ''};

    // 1. Récupérer le Profil
    final r = await Supabase.instance.client.from('profiles').select('first_name, full_name').eq('id', user.id).maybeSingle();
    final full = (r?['first_name'] ?? r?['full_name'] ?? user.email?.split('@').first ?? 'THIX').toString();
    final first = full.split(' ').first;
    final initial = first.isNotEmpty ? first[0].toUpperCase() : 'T';

    // 2. Récupérer le Solde et Thix ID
    final walletRes = await Supabase.instance.client.from('wallets').select('balance, thix_id').eq('user_id', user.id).maybeSingle();
    final balance = (walletRes?['balance'] ?? 0.0).toDouble();
    final thixId = walletRes?['thix_id'] ?? '';

    return {'name': first, 'initial': initial, 'balance': balance, 'thix_id': thixId};
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
      backgroundColor: bgScaffold,
      extendBody: true,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getDashboardData(),
        builder: (context, snapshot) {
          final data = snapshot.data ?? {'name': '...', 'initial': 'T', 'balance': 0.0, 'thix_id': ''};
          final thixId = data['thix_id'] as String;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()), 
            slivers: [
              SliverToBoxAdapter(child: _header(data['name'], data['initial'])),
              
              // 🌟 Section Solde avec la vraie donnée
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 20),
                  child: _buildPremiumBalanceCard(data['balance'] as double),
                ),
              ),
              
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _top4UnifiedCard(), // Carte unifiée pour les actions rapides
                    const SizedBox(height: 28),
                    
                    _sectionTitle('Services Financiers', showAction: false),
                    const SizedBox(height: 12),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: ServiceGrid(), // Appel de ton fichier service_grid.dart
                    ),
                    
                    const SizedBox(height: 28),
                    _promoCardPremium(),
                    
                    const SizedBox(height: 28),
                    _sectionTitle('Opérations Récentes', showAction: true),
                    const SizedBox(height: 12),
                    
                    // 🌟 Transactions réelles basées sur le Thix ID
                    _transactionsList(thixId),
                    
                    const SizedBox(height: 120), // Espace pour la navigation
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _premiumNav(),
    );
  }

  // ==========================================
  // HEADER : STATUT ET ÉLÉGANCE
  // ==========================================
  Widget _header(String name, String initial) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
      children: [
        Row(
          children: [
            Container(
              width: 52, 
              height: 52, 
              decoration: BoxDecoration(
                shape: BoxShape.circle, 
                color: surfaceWhite,
                border: Border.all(color: premiumGold.withOpacity(0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(color: premiumDark.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ), 
              child: Center(
                child: Text(
                  initial, 
                  style: const TextStyle(color: premiumDark, fontWeight: FontWeight.w800, fontSize: 20)
                )
              )
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(
                  name.isEmpty ? 'Bienvenue' : 'Bonjour, $name', 
                  style: const TextStyle(color: premiumDark, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5)
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: premiumBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6)
                  ),
                  child: const Text(
                    'Compte Personnel', 
                    style: TextStyle(color: premiumBlue, fontSize: 11, fontWeight: FontWeight.w700)
                  ),
                )
              ]
            ),
          ]
        ),
        Row(
          children: [ 
            _actionPill(Icons.qr_code_scanner_rounded, () => context.push(AppRoutes.thixMoneyScanner)), 
            const SizedBox(width: 10), 
            _actionPill(Icons.notifications_outlined, (){}, dot: true)
          ]
        ),
      ]
    ),
  );

  Widget _actionPill(IconData i, VoidCallback t, {bool dot=false}) => InkWell(
    onTap:t, 
    borderRadius: BorderRadius.circular(16),
    child: Stack(
      clipBehavior: Clip.none, 
      children:[
        Container(
          padding: const EdgeInsets.all(12), 
          decoration: BoxDecoration(
            color: surfaceWhite, 
            borderRadius: BorderRadius.circular(14), 
            border: Border.all(color: Colors.black.withOpacity(0.03)),
            boxShadow: [
              BoxShadow(color: premiumDark.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))
            ]
          ), 
          child: Icon(i, color: premiumDark, size: 22)
        ), 
        if(dot) Positioned(
          top: -2, 
          right: -2, 
          child: Container(
            width: 12, 
            height: 12, 
            decoration: BoxDecoration(
              color: const Color(0xFFE11D48), // Rouge alerte premium
              shape: BoxShape.circle, 
              border: Border.all(color: surfaceWhite, width: 2)
            )
          )
        )
      ]
    )
  );

  // ==========================================
  // CARTE DE SOLDE PREMIUM (Le Solde Réel)
  // ==========================================
  Widget _buildPremiumBalanceCard(double balance) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: premiumDark,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: premiumDark.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 10))
        ],
        image: DecorationImage(
          image: const AssetImage('assets/noise_texture.png'), // Texture subtile si tu l'as
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.2), BlendMode.dstATop),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Solde Principal', 
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w600)
              ),
              const Icon(Icons.visibility_outlined, color: premiumGold, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatBalance(balance), 
                style: const TextStyle(color: surfaceWhite, fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1.0)
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text('FC', style: TextStyle(color: premiumGold, fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: surfaceWhite.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: premiumGold, size: 14),
                    const SizedBox(width: 6),
                    Text('Compte Sécurisé', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // ==========================================
  // ACTIONS RAPIDES : CARTE UNIFIÉE BLANCHE
  // ==========================================
  Widget _top4UnifiedCard() {
    final items = [
      {'l':'Dépôt', 'i':Icons.arrow_downward_rounded, 'r':AppRoutes.thixMoneyRecharge, 'c': const Color(0xFF10B981)},
      {'l':'Envoi', 'i':Icons.arrow_upward_rounded, 'r':AppRoutes.thixMoneySend, 'c': premiumBlue},
      {'l':'Relevé', 'i':Icons.receipt_long_outlined, 'r':AppRoutes.thixMoneyLoans, 'c': premiumDark}, 
      {'l':'Scanner', 'i':Icons.qr_code_2_rounded, 'r':AppRoutes.thixMoneyScanner, 'c': premiumDark},
    ];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: premiumDark.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))
        ]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround, 
        children: items.map((a){
          final color = a['c'] as Color;
          return InkWell(
            onTap:()=>context.push(a['r'] as String), 
            borderRadius: BorderRadius.circular(16), 
            child: Column(
              children:[
                Container(
                  width: 52, 
                  height: 52, 
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08), 
                    borderRadius: BorderRadius.circular(16), 
                  ), 
                  child: Icon(a['i'] as IconData, color: color, size: 24)
                ),
                const SizedBox(height: 10),
                Text(
                  a['l'] as String, 
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: premiumDark, letterSpacing: -0.2)
                ),
              ]
            )
          );
        }).toList()
      )
    );
  }

  Widget _sectionTitle(String t, {bool showAction = false}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20), 
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
      children:[
        Text(
          t, 
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: premiumDark, letterSpacing: -0.4)
        ), 
        if (showAction) Text(
          'Voir tout', 
          style: TextStyle(fontSize: 13, color: premiumBlue, fontWeight: FontWeight.w700)
        )
      ]
    )
  );

  // ==========================================
  // CARTE PROMO "BLACK METAL" (Prestige)
  // ==========================================
  Widget _promoCardPremium() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 20), 
    padding: const EdgeInsets.all(24), 
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24), 
      color: premiumDark,
      image: DecorationImage(
        image: const AssetImage('assets/noise_texture.png'), 
        fit: BoxFit.cover,
        colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.2), BlendMode.dstATop),
      ),
      boxShadow: [
        BoxShadow(color: premiumDark.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
      ]
    ), 
    child: Row(
      children:[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children:[
              Row(
                children: [
                  Icon(Icons.stars_rounded, color: premiumGold, size: 16),
                  const SizedBox(width: 6),
                  const Text('THIX PRESTIGE', style: TextStyle(color: premiumGold, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Ligne de Crédit', 
                style: TextStyle(color: surfaceWhite, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5)
              ), 
              const SizedBox(height: 6),
              Text(
                'Accédez jusqu\'à 500 000 FC instantanément.\nSans paperasse.', 
                style: TextStyle(color: surfaceWhite.withOpacity(0.7), fontSize: 12, height: 1.4)
              )
            ]
          )
        ), 
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: premiumGold, 
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: premiumGold.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))
            ]
          ),
          child: const Icon(Icons.arrow_forward_rounded, size: 24, color: premiumDark)
        )
      ]
    )
  );

  // ==========================================
  // LISTE DES TRANSACTIONS RÉELLES
  // ==========================================
  Widget _transactionsList(String thixId) {
    if(thixId.isEmpty) return const SizedBox();
    
    return FutureBuilder(
      future: Supabase.instance.client.from('thix_transactions').select().eq('thix_id', thixId).order('created_at', ascending:false).limit(4), 
      builder: (c,snap){ 
        final list=(snap.data as List?)?? []; 
        if(list.isEmpty) return Container(
          margin: const EdgeInsets.symmetric(horizontal:20), 
          padding: const EdgeInsets.all(20), 
          decoration: BoxDecoration(color:surfaceWhite, borderRadius:BorderRadius.circular(20)), 
          child: const Center(child: Text('Aucune opération récente', style:TextStyle(fontSize:13, color:Colors.grey)))
        ); 
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: surfaceWhite,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: premiumDark.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))
            ]
          ),
          child: Column(
            children: list.asMap().entries.map((entry){
              int idx = entry.key;
              var t = entry.value;
              bool isDeposit = (t['type'] == 'reception' || t['type'] == 'Deposit');
              
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 42, 
                          height: 42, 
                          decoration: BoxDecoration(
                            color: isDeposit ? const Color(0xFF10B981).withOpacity(0.1) : premiumDark.withOpacity(0.06), 
                            borderRadius: BorderRadius.circular(12),
                          ), 
                          child: Icon(
                            isDeposit ? Icons.south_west_rounded : Icons.north_east_rounded, 
                            size: 20, 
                            color: isDeposit ? const Color(0xFF10B981) : premiumDark
                          )
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t['type']??'Opération', 
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: premiumDark)
                              ), 
                              const SizedBox(height: 3),
                              Text(
                                t['ref_transa']??'Détails indisponibles', 
                                style: const TextStyle(fontSize: 11, color: Colors.black45)
                              ), 
                            ],
                          ),
                        ),
                        Text(
                          '${isDeposit ? '+' : '-'} ${t['montant']} ${t['devise']}', 
                          style: TextStyle(
                            fontSize: 15, 
                            fontWeight: FontWeight.w800, 
                            letterSpacing: -0.5,
                            color: isDeposit ? const Color(0xFF10B981) : premiumDark
                          )
                        ),
                      ],
                    ),
                  ),
                  if (idx < list.length - 1)
                    Divider(height: 1, color: Colors.black.withOpacity(0.04)),
                ],
              );
            }).toList()
          ),
        ); 
      }
    ); 
  }

   // ==========================================
  // BOTTOM NAV : BARRE FLOTTANTE "PREMIUM DARK"
  // ==========================================
  Widget _premiumNav() => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: premiumDark, 
          borderRadius: BorderRadius.circular(36), 
          boxShadow: [
            BoxShadow(color: premiumDark.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
          ]
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
          children:[
            const _NavIcon(icon: Icons.grid_view_rounded, isActive: true),
            const _NavIcon(icon: Icons.insert_chart_outlined),
            
            // Bouton Action Centrale (Gold)
            Transform.translate(
              offset: const Offset(0, -12),
              child: GestureDetector(
                onTap: () => context.push(AppRoutes.thixMoneyScanner),
                child: Container(
                  width: 58, 
                  height: 58, 
                  decoration: BoxDecoration(
                    color: premiumGold, 
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: premiumGold.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 6))
                    ],
                    border: Border.all(color: surfaceWhite, width: 3)
                  ), 
                  child: const Icon(Icons.compare_arrows_rounded, color: premiumDark, size: 28)
                ),
              ),
            ),
            
            const _NavIcon(icon: Icons.account_balance_wallet_outlined),
            const _NavIcon(icon: Icons.person_outline_rounded),
          ]
        )
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
        Icon(icon, color: isActive ? Colors.white : Colors.white54, size: 26),
        if (isActive) ...[
          const SizedBox(height: 6),
          Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFFD4AF37), shape: BoxShape.circle))
        ]
      ],
    );
  }
}
