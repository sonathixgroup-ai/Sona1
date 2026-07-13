import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    {'nom':'CNTS Kinshasa','adresse':'Gombe','dist':'1.2 km'},
    {'nom':'Hôpital Général','adresse':'Kasa-Vubu','dist':'2.8 km'},
    {'nom':'Croix-Rouge','adresse':'Lingwala','dist':'3.5 km'},
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('Don de sang', style: TextStyle(fontWeight: FontWeight.w800)), backgroundColor: Colors.white, leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: ()=>Navigator.pop(context))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFEF4444)]), borderRadius: BorderRadius.circular(16)), child: const Text('Sauvez 3 vies en 1 don - 15 min', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16))),
        const SizedBox(height: 12),
        const Text('Mon groupe', style: TextStyle(fontWeight: FontWeight.w700)),
        Wrap(spacing: 6, children: groupes.map((g)=> ChoiceChip(label: Text(g), selected: _groupe==g, onSelected: (_)=>setState(()=>_groupe=g))).toList()),
        const SizedBox(height: 12),
        SwitchListTile(title: Text(_eligible?'Eligible':'Non eligible'), value: _eligible, onChanged: (v)=>setState(()=>_eligible=v)),
        const Divider(),
        const Text('Centres proches', style: TextStyle(fontWeight: FontWeight.w800)),
        ...centres.map((c)=> Card(child: ListTile(title: Text(c['nom']!), subtitle: Text(c['adresse']!), trailing: Text(c['dist']!), onTap: (){}))),
      ]),
      bottomNavigationBar: Padding(padding: const EdgeInsets.all(16), child: ElevatedButton.icon(onPressed: _eligible? (){}: null, icon: const Icon(Icons.favorite), label: const Text('Prendre RDV don'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)))),
    );
  }
}
