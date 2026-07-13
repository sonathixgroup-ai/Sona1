// lib/presentation/thix_sante/patient/screens/don_sang_page.dart
// THIX SANTE - Don de sang - Eligibilite + Centres + RDV - Supabase RLS
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/thix_sante_theme.dart';

class DonSangPage extends ConsumerStatefulWidget {
  const DonSangPage({super.key});
  @override
  ConsumerState<DonSangPage> createState() => _DonSangPageState();
}

class _DonSangPageState extends ConsumerState<DonSangPage> {
  String _groupe = 'O+';
  bool _eligible = true;

  final groupes = ['O+','O-','A+','A-','B+','B-','AB+','AB-'];

  final centres = [
    {'nom':'CNTS Kinshasa','adresse':'Av. du Commerce, Gombe','distance':'1.2 km','dispo':'Aujourd\'hui 08h-16h','tel':'082 123 4567','besoin':'Urgent O+'},
    {'nom':'Hôpital Général','adresse':'Av. Kasa-Vubu','distance':'2.8 km','dispo':'Lun-Sam 07h-17h','tel':'081 987 6543','besoin':'Besoins tous groupes'},
    {'nom':'Croix-Rouge RDC','adresse':'Lingwala','distance':'3.5 km','dispo':'Urgence 24/7','tel':'084 555 0011','besoin':'AB- rare recherché'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThixSanteColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)), onPressed: ()=> Navigator.pop(context)),
        title: const Text('Don de sang', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w800)),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _hero()),
          SliverToBoxAdapter(child: _groupeSelector()),
          SliverToBoxAdapter(child: _eligibilityCard()),
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16,20,16,10), child: Row(children: [const Text('Centres proches', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)), const Spacer(), TextButton(onPressed: (){}, child: const Text('Voir carte'))]))),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.separated(
              itemCount: centres.length,
              separatorBuilder: (_, __)=> const SizedBox(height: 10),
              itemBuilder: (c,i)=> _centreCard(centres[i]),
            ),
          ),
          SliverToBoxAdapter(child: _impact()),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
        child: ElevatedButton.icon(
          onPressed: _eligible? (){ ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('RDV Don de sang - bientôt via Supabase'))); } : null,
          icon: const Icon(Icons.favorite_rounded),
          label: Text(_eligible? 'Prendre RDV don' : 'Non éligible 90j'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        ),
      ),
    );
  }

  Widget _hero(){
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFEF4444)]), borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Sauvez 3 vies en 1 don', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 6),
          const Text('15 min de votre temps = espoir pour 3 patients', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: const Text('🩸 Besoin urgent cette semaine', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFDC2626)))),
        ])),
        const Text('🩸', style: TextStyle(fontSize: 48)),
      ]),
    );
  }

  Widget _groupeSelector(){
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Mon groupe sanguin', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
      const SizedBox(height: 8),
      SizedBox(height: 40, child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: groupes.length,
        separatorBuilder: (_, __)=> const SizedBox(width: 8),
        itemBuilder: (c,i){
          final g = groupes[i]; final sel = g==_groupe;
          return ChoiceChip(label: Text(g), selected: sel, selectedColor: const Color(0xFFDC2626), labelStyle: TextStyle(color: sel? Colors.white: const Color(0xFF6B7280), fontWeight: FontWeight.w800), onSelected: (_)=> setState(()=> _groupe=g));
        },
      )),
    ]);
  }

  Widget _eligibilityCard(){
    return Container(
      margin: const EdgeInsets.fromLTRB(16,16,16,0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _eligible? const Color(0xFFDCFCE7): const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(14), border: Border.all(color: _eligible? const Color(0xFFBBF7D0): const Color(0xFFFECACA))),
      child: Row(children: [
        Icon(_eligible? Icons.check_circle_rounded: Icons.block_rounded, color: _eligible? const Color(0xFF16A34A): const Color(0xFFDC2626)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_eligible? 'Vous êtes éligible au don':'Délai à respecter', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: _eligible? const Color(0xFF15803D): const Color(0xFF991B1B))),
          Text(_eligible? 'Dernier don il y a > 3 mois • Poids > 50kg':'Dernier don le 12/04/2026 • Prochain don possible le 12/07/2026', style: TextStyle(fontSize: 11, color: _eligible? const Color(0xFF166534): const Color(0xFF7F1D1D))),
        ])),
        Switch(value: _eligible, activeColor: const Color(0xFF16A34A), onChanged: (v)=> setState(()=> _eligible=v)),
      ]),
    );
  }

  Widget _centreCard(Map<String,String> c){
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.local_hospital_rounded, color: Color(0xFFDC2626))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c['nom']!, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            Text(c['adresse']!, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(20)), child: Text(c['distance']!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 10),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)), child: Text('⚠️ ${c['besoin']!}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF92400E)))),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF6B7280)), const SizedBox(width: 4), Text(c['dispo']!, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          const Spacer(),
          OutlinedButton(onPressed: (){}, style: OutlinedButton.styleFrom(minimumSize: const Size(0,32), padding: const EdgeInsets.symmetric(horizontal: 12)), child: const Text('Appeler', style: TextStyle(fontSize: 11))),
          const SizedBox(width: 8),
          ElevatedButton(onPressed: (){}, style: ElevatedButton.styleFrom(minimumSize: const Size(0,32), backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14)), child: const Text('RDV', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
        ])
      ]),
    );
  }

  Widget _impact(){
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _stat('12','Dons','❤️'), _stat('36','Vies sauvées','🙏'), _stat('Or','Donneur','🏅'),
      ]),
    );
  }
  Widget _stat(String v, String l, String i)=> Column(children: [Text(i, style: const TextStyle(fontSize: 20)), const SizedBox(height: 4), Text(v, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), Text(l, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11))]);
}
