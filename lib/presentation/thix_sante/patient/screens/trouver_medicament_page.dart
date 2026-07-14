// lib/presentation/thix_sante/patient/screens/trouver_medicament_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/thix_sante_colors.dart';
import '../providers/medicament_provider.dart';
import 'pharmacies_proches_page.dart';

class TrouverMedicamentPage extends ConsumerWidget {
  const TrouverMedicamentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(medicamentSearchProvider);
    final async = ref.watch(medicamentsProvider);
    final filter = ref.watch(medicamentFilterProvider);
    final ctrl = TextEditingController(text: search);

    return Scaffold(
      backgroundColor: ThixSanteColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)), onPressed: ()=> Navigator.pop(context)),
        title: const Text('Médicaments', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w800)),
      ),
      body: Column(children: [
        Container(color: Colors.white, padding: const EdgeInsets.all(16), child: TextField(
          controller: ctrl,
          onChanged: (v)=> ref.read(medicamentSearchProvider.notifier).state = v,
          decoration: InputDecoration(hintText: 'DCI, nom commercial...', prefixIcon: const Icon(Icons.search), filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
        )),
        SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal:16), child: Row(children: [
          _chip('Dispo', filter==MedicamentFilter.dispo, ()=> ref.read(medicamentFilterProvider.notifier).state=MedicamentFilter.dispo),
          _chip('Prix ↑', filter==MedicamentFilter.prixAsc, ()=> ref.read(medicamentFilterProvider.notifier).state=MedicamentFilter.prixAsc),
          _chip('Prix ↓', filter==MedicamentFilter.prixDesc, ()=> ref.read(medicamentFilterProvider.notifier).state=MedicamentFilter.prixDesc),
          _chip('Stock', filter==MedicamentFilter.stock, ()=> ref.read(medicamentFilterProvider.notifier).state=MedicamentFilter.stock),
        ])),
        const SizedBox(height:8),
        Expanded(child: async.when(
          loading: ()=> const Center(child: CircularProgressIndicator()),
          error: (e,_)=> Center(child: Text('Erreur $e')),
          data: (list)=> ListView.builder(padding: const EdgeInsets.all(16), itemCount: list.length, itemBuilder: (_,i){
            final m = list[i]; final ph = m['pharmacies'] as Map?;
            return Container(margin: const EdgeInsets.only(bottom:10), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))), child: Row(children:[
              const Icon(Icons.medication_rounded, color: Color(0xFF0B63F6)), const SizedBox(width:10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text(m['nom']??'', style: const TextStyle(fontWeight: FontWeight.w700)), Text('${ph?['nom']??''} • ${m['prix']} FC', style: const TextStyle(fontSize:11, color: Colors.grey))])),
              Text('x${m['quantite']}', style: const TextStyle(fontWeight: FontWeight.w800)),
            ]));
          }),
        )),
      ]),
    );
  }
  Widget _chip(String l,bool a,VoidCallback t)=> Padding(padding: const EdgeInsets.only(right:8), child: ChoiceChip(label: Text(l), selected: a, onSelected: (_)=> t()));
}
