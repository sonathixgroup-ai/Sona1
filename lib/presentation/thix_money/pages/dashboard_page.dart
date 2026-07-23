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
  static const navyDeep = Color(0xFF0A1F44);
  static const navy = Color(0xFF123B7A);
  static const primaryBlue = Color(0xFF2D6CDF);
  static const gold = Color(0xFFE3B23C);
  static const ivory = Color(0xFFF6F7FB);

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
      backgroundColor: ivory,
      extendBody: true,
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: _header()),
        // SOLDE CARD BIEN PLACE AU DESSUS - overlap -24 seulement
        SliverToBoxAdapter(child: Transform.translate(offset: const Offset(0, -24), child: const BalanceCard())),
        SliverToBoxAdapter(child: Transform.translate(offset: const Offset(0, -12), child: Column(children: [
          _top4(),
          const SizedBox(height: 12),
          _title('Services financiers'),
          _grid(),
          const SizedBox(height: 12),
          _promo(),
          const SizedBox(height: 10),
          _title('Transactions récentes'),
          _tx(),
          const SizedBox(height: 90),
        ]))),
      ]),
      bottomNavigationBar: _nav(),
    );
  }

  Widget _header() => Container(
    padding: const EdgeInsets.fromLTRB(16, 48, 16, 48),
    decoration: const BoxDecoration(gradient: LinearGradient(colors: [navyDeep, navy]), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24))),
    child: FutureBuilder<Map<String,String>>(future: _getProfile(), builder: (c,s){
      final name = s.data?['name']?? '';
      final initial = s.data?['initial']?? 'T';
      return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [gold, Color(0xFFB8862A)]), border: Border.all(color: Colors.white24)), child: Center(child: Text(initial, style: const TextStyle(color: navyDeep, fontWeight: FontWeight.w800, fontSize: 14)))),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name.isEmpty? 'Bonjour 👋' : 'Bonjour, $name 👋', style: const TextStyle(color: Colors.white70, fontSize: 11)),
            const Text('THIX MONEY', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
          ]),
        ]),
        Row(children: [ _hIcon(Icons.qr_code_scanner_rounded, () => context.push(AppRoutes.thixMoneyScanner)), const SizedBox(width: 8), _hIcon(Icons.notifications_none_rounded, (){}, dot:true)]),
      ]);
    }),
  );

  Widget _hIcon(IconData i, VoidCallback t, {bool dot=false}) => InkWell(onTap:t, child: Stack(clipBehavior: Clip.none, children:[Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), shape: BoxShape.circle, border: Border.all(color: Colors.white24)), child: Icon(i,color:Colors.white,size:16)), if(dot) Positioned(top:0,right:0,child: Container(width:7,height:7,decoration: BoxDecoration(color:gold,shape:BoxShape.circle,border: Border.all(color:navyDeep,width:1))))]));

  Widget _top4() {
    final items = [
      {'l':'Envoyer','i':Icons.arrow_upward_rounded,'r':AppRoutes.thixMoneySend},
      {'l':'Recharger','i':Icons.add_rounded,'r':AppRoutes.thixMoneyRecharge},
      {'l':'Scanner','i':Icons.qr_code_scanner_rounded,'r':AppRoutes.thixMoneyScanner},
      {'l':'Retrait','i':Icons.account_balance_wallet_rounded,'r':AppRoutes.thixMoneyRetrait},
    ];
    return Padding(padding: const EdgeInsets.symmetric(horizontal:16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: items.map((a)=> InkWell(onTap:()=>context.push(a['r'] as String), borderRadius: BorderRadius.circular(14), child: Column(children:[
      Container(width:48,height:48,decoration: BoxDecoration(color:Colors.white, borderRadius: BorderRadius.circular(14), boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.05), blurRadius:6)]), child: Icon(a['i'] as IconData, color:navy, size:20)),
      const SizedBox(height:4),
      Text(a['l'] as String, style: const TextStyle(fontSize:10, fontWeight:FontWeight.w600, color:navyDeep)),
    ]))).toList()));
  }

  Widget _title(String t) => Padding(padding: const EdgeInsets.fromLTRB(16,0,16,8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[Text(t, style: const TextStyle(fontSize:12.5, fontWeight:FontWeight.w800, color:navyDeep)), Text('Voir tout', style: TextStyle(fontSize:10.5, color:primaryBlue, fontWeight:FontWeight.w600))]));

  Widget _grid() => GridView.builder(padding: const EdgeInsets.symmetric(horizontal:12), shrinkWrap:true, physics: const NeverScrollableScrollPhysics(), itemCount: 12, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:4, mainAxisSpacing:8, crossAxisSpacing:8, childAspectRatio:0.86), itemBuilder: (_,i){
    const grads = [[Color(0xFF2D6CDF),Color(0xFF123B7A)],[Color(0xFF1FA97F),Color(0xFF0E6B4E)],[Color(0xFFE3B23C),Color(0xFFB8862A)],[Color(0xFF9B59B6),Color(0xFF5E3370)],[Color(0xFFE0743C),Color(0xFF9C4A22)],[Color(0xFFE0507A),Color(0xFF9C2E4E)],[Color(0xFF2DA6DF),Color(0xFF12557A)],[Color(0xFF3CB4E3),Color(0xFF1D6F8C)],[Color(0xFF123B7A),Color(0xFF0A1F44)],[Color(0xFF4CAF50),Color(0xFF2E6B30)],[Color(0xFFE3B23C),Color(0xFF8A6420)],[Color(0xFF2D6CDF),Color(0xFF1A3D8C)]];
    const icons = [Icons.bolt_rounded, Icons.shield_rounded, Icons.savings_rounded, Icons.swap_horiz_rounded, Icons.storefront_rounded, Icons.volunteer_activism_rounded, Icons.groups_rounded, Icons.school_rounded, Icons.public_rounded, Icons.account_balance_rounded, Icons.trending_up_rounded, Icons.calendar_month_rounded];
    const labels = ['Crédit\ninstantané','Assurance','Épargne\nplanifiée','Change','Marchand','Don &\nContributions','Ma Tontine','Éducation','Virement\ninternational','Microfinance','Investissement','Planification'];
    final g = grads[i];
    return Column(children:[Container(width:44,height:44,decoration: BoxDecoration(gradient: LinearGradient(colors:g, begin:Alignment.topLeft, end:Alignment.bottomRight), borderRadius: BorderRadius.circular(12)), child: Icon(icons[i], color:Colors.white, size:18)), const SizedBox(height:3), Text(labels[i], textAlign:TextAlign.center, style: const TextStyle(fontSize:8, fontWeight:FontWeight.w600, color:navyDeep, height:1.1))]);
  });

  Widget _promo() => Container(margin: const EdgeInsets.symmetric(horizontal:16), padding: const EdgeInsets.symmetric(horizontal:14, vertical:12), decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: const LinearGradient(colors:[gold, Color(0xFFB8862A)])), child: Row(children:[Expanded(child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[const Text('Crédit instantané', style:TextStyle(color:navyDeep, fontSize:12, fontWeight:FontWeight.w800)), Text('Jusqu\'à 500 000 FC en 5 minutes, sans dossier', style:TextStyle(color:navyDeep, fontSize:9.5))])), const Icon(Icons.arrow_forward_rounded, size:16, color:navyDeep)]));

  Widget _tx() => FutureBuilder<String>(future: ref.read(walletServiceProvider).getVerifiedThixId(), builder: (c,s){ if(!s.hasData) return const SizedBox(); return FutureBuilder(future: Supabase.instance.client.from('thix_transactions').select().eq('thix_id', s.data!).order('created_at', ascending:false).limit(2), builder: (c,snap){ final list=(snap.data as List?)?? []; if(list.isEmpty) return Container(margin: const EdgeInsets.symmetric(horizontal:16), padding:const EdgeInsets.all(10), decoration:BoxDecoration(color:Colors.white, borderRadius:BorderRadius.circular(12)), child: const Text('Aucune transaction', style:TextStyle(fontSize:10, color:Colors.grey))); return Container(margin: const EdgeInsets.symmetric(horizontal:16), decoration:BoxDecoration(color:Colors.white, borderRadius:BorderRadius.circular(12)), child: Column(children:list.map<Widget>((t)=> ListTile(dense:true, leading: Container(width:30,height:30,decoration:BoxDecoration(color: const Color(0xFFEFF3FB), borderRadius:BorderRadius.circular(8)), child: const Icon(Icons.receipt_long_rounded, size:14, color:primaryBlue)), title: Text(t['type']??'', style: const TextStyle(fontSize:10.5, fontWeight:FontWeight.w600)), subtitle: Text(t['ref_transa']??'', style: const TextStyle(fontSize:8)), trailing: Text('${t['montant']} ${t['devise']}', style: const TextStyle(fontSize:10, fontWeight:FontWeight.bold)),)).toList())); }); });

  Widget _nav() => Padding(padding: const EdgeInsets.fromLTRB(14,0,14,12), child: ClipRRect(borderRadius:BorderRadius.circular(20), child: BackdropFilter(filter: ImageFilter.blur(sigmaX:8, sigmaY:8), child: Container(height:52, decoration:BoxDecoration(color:navyDeep.withOpacity(0.94), borderRadius:BorderRadius.circular(20)), child: Row(mainAxisAlignment:MainAxisAlignment.spaceEvenly, children:[
    const Icon(Icons.home_rounded, color:gold, size:20),
    const Icon(Icons.pie_chart_rounded, color:Colors.white54, size:18),
    Container(width:38,height:38,decoration: const BoxDecoration(gradient:LinearGradient(colors:[gold, Color(0xFFB8862A)]), shape:BoxShape.circle), child: const Icon(Icons.qr_code_scanner_rounded, color:navyDeep, size:18)),
    const Icon(Icons.groups_rounded, color:Colors.white54, size:18),
    const Icon(Icons.person_rounded, color:Colors.white54, size:18),
  ])))));
}
