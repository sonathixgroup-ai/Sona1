// lib/presentation/thix_sante/patient/screens/epidemies_page.dart
// THIX SANTE - Surveillance épidémies - Don réel Supabase
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/thix_sante_theme.dart';

class EpidemiesPage extends ConsumerStatefulWidget {
  const EpidemiesPage({super.key});
  @override
  ConsumerState<EpidemiesPage> createState() => _EpidemiesPageState();
}

class _EpidemiesPageState extends ConsumerState<EpidemiesPage> {
  String _filter = 'Tous';

  final List<Map<String, dynamic>> _alerts = [
    {'id':'1','title':'Grippe saisonnière','level':'Modéré','zone':'Kinshasa','cases':1243,'trend':'+12%','color':const Color(0xFFF59E0B),'icon':'🤧','desc':'Pic saisonnier en cours, vaccination recommandée'},
    {'id':'2','title':'COVID-19','level':'Faible','zone':'National','cases':89,'trend':'-23%','color':const Color(0xFF10B981),'icon':'🦠','desc':'Circulation faible, gestes barrières maintenus'},
    {'id':'3','title':'Choléra','level':'Élevé','zone':'Nord-Kivu','cases':312,'trend':'+45%','color':const Color(0xFFEF4444),'icon':'💧','desc':'Éviter eau non traitée, se laver les mains'},
    {'id':'4','title':'Rougeole','level':'Modéré','zone':'Lualaba','cases':156,'trend':'+8%','color':const Color(0xFFF59E0B),'icon':'🔴','desc':'Vérifier carnet vaccination enfants'},
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == 'Tous'? _alerts : _alerts.where((a)=> a['level']==_filter).toList();
    return Scaffold(
      backgroundColor: ThixSanteColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)), onPressed: ()=> Navigator.pop(context)),
        title: const Text('Épidémies', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [IconButton(icon: const Icon(Icons.map_rounded, color: Color(0xFF111827)), onPressed: (){})],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _header()),
          SliverToBoxAdapter(child: _filters()),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __)=> const SizedBox(height: 12),
              itemBuilder: (c,i){
                final a = filtered[i];
                return _alertCard(a);
              },
            ),
          ),
          SliverToBoxAdapter(child: _prevention()),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _header(){
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFF97316)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Surveillance en temps réel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 4),
          Text('${_alerts.length} alertes actives • MAJ il y a 2h', style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ])),
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.shield_rounded, color: Colors.white))
      ]),
    );
  }

  Widget _filters(){
    final filters = ['Tous','Faible','Modéré','Élevé'];
    return SizedBox(height: 36, child: ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      scrollDirection: Axis.horizontal,
      itemCount: filters.length,
      separatorBuilder: (_, __)=> const SizedBox(width: 8),
      itemBuilder: (c,i){
        final f = filters[i];
        final sel = _filter==f;
        return ChoiceChip(
          label: Text(f), selected: sel,
          selectedColor: ThixSanteColors.primary,
          labelStyle: TextStyle(color: sel? Colors.white : ThixSanteColors.inkLight, fontWeight: FontWeight.w700, fontSize: 12),
          onSelected: (_)=> setState(()=> _filter=f),
        );
      },
    ));
  }

  Widget _alertCard(Map<String,dynamic> a){
    final Color color = a['color'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Center(child: Text(a['icon'], style: const TextStyle(fontSize: 22)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a['title'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            Text('${a['zone']} • ${a['cases']} cas', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)), child: Text(a['level'], style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11))),
        ]),
        const SizedBox(height: 12),
        Text(a['desc'], style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563), height: 1.4)),
        const SizedBox(height: 10),
        Row(children: [
          Text(a['trend'], style: TextStyle(color: a['trend'].toString().startsWith('+')? Colors.red : Colors.green, fontWeight: FontWeight.w800, fontSize: 12)),
          const Text(' cette semaine', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
          const Spacer(),
          TextButton(onPressed: (){}, child: const Text('Voir conseils', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
        ])
      ]),
    );
  }

  Widget _prevention(){
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [Icon(Icons.health_and_safety_rounded, size: 18, color: Color(0xFF2563EB)), SizedBox(width: 6), Text('Gestes barrières', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13))]),
        const SizedBox(height: 10),
       ...['Lavez-vous les mains régulièrement','Portez un masque en zone à risque','Vaccine vos enfants selon calendrier','Consultez en cas de fièvre persistante'].map((e)=> Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF2563EB)), const SizedBox(width: 8), Expanded(child: Text(e, style: const TextStyle(fontSize: 12)))]))),
      ]),
    );
  }
}
