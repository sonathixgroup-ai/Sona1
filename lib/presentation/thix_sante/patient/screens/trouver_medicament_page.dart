// lib/presentation/thix_sante/patient/screens/trouver_medicament_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/thix_sante_colors.dart';
import '../providers/medicament_provider.dart';
import 'trouver_medicament_detail_page.dart';
import 'pharmacies_proches_page.dart';

class TrouverMedicamentPage extends ConsumerWidget {
  const TrouverMedicamentPage({super.key}); // <-- CONST pour ne pas toucher aux 3 autres fichiers

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(medicamentSearchProvider);
    final asyncMeds = ref.watch(medicamentsProvider);
    final filter = ref.watch(medicamentFilterProvider);
    final controller = TextEditingController(text: search);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)), onPressed: ()=> Navigator.pop(context)),
        title: const Text('Médicaments', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w800)),
        actions: [IconButton(icon: const Icon(Icons.local_pharmacy_rounded, color: Color(0xFF0B63F6)), onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> const PharmaciesProchesPage())))],
      ),
      body: Column(children: [
        Container(color: Colors.white, padding: const EdgeInsets.all(16), child: TextField(
          controller: controller,
          onChanged: (v)=> ref.read(medicamentSearchProvider.notifier).state = v,
          decoration: InputDecoration(
            hintText: 'DCI, nom commercial...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: search.isNotEmpty ? IconButton(icon: const Icon(Icons.clear_rounded), onPressed: ()=> ref.read(medicamentSearchProvider.notifier).state='') : null,
            filled: true, fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        )),
        SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal:16), child: Row(children: [
          _chip('Dispo', filter==MedicamentFilter.dispo, ()=> ref.read(medicamentFilterProvider.notifier).state=MedicamentFilter.dispo),
          _chip('Prix ↑', filter==MedicamentFilter.prixAsc, ()=> ref.read(medicamentFilterProvider.notifier).state=MedicamentFilter.prixAsc),
          _chip('Prix ↓', filter==MedicamentFilter.prixDesc, ()=> ref.read(medicamentFilterProvider.notifier).state=MedicamentFilter.prixDesc),
          _chip('Stock', filter==MedicamentFilter.stock, ()=> ref.read(medicamentFilterProvider.notifier).state=MedicamentFilter.stock),
        ])),
        const SizedBox(height:8),
        Expanded(child: asyncMeds.when(
          loading: ()=> const Center(child: CircularProgressIndicator()),
          error: (e,_ )=> Center(child: Text('Erreur: $e')),
          data: (list){
            if(list.isEmpty) return const Center(child: Text('Aucun médicament trouvé'));
            return ListView.builder(padding: const EdgeInsets.all(16), itemCount: list.length, itemBuilder: (_,i){
              final m = list[i]; final ph = m['pharmacies'] as Map?;
              final qty = (m['quantite'] as num?)?.toInt() ?? 0;
              return InkWell(
                onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> TrouverMedicamentDetailPage(stock: m))),
                child: Container(margin: const EdgeInsets.only(bottom:10), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))), child: Row(children:[
                  Container(width:44,height:44,decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.medication_rounded, color: Color(0xFF0B63F6))),
                  const SizedBox(width:10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text(m['nom']??'', style: const TextStyle(fontWeight: FontWeight.w700, fontSize:13)), Text('${ph?['nom']??'Pharmacie'} • ${m['prix']} FC', style: const TextStyle(fontSize:11, color: Color(0xFF6B7280))) ])),
                  Text('x$qty', style: const TextStyle(fontWeight: FontWeight.w800)),
                ])),
              );
            });
          },
        )),
      ]),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap){
    return Padding(padding: const EdgeInsets.only(right:8), child: ChoiceChip(
      label: Text(label, style: TextStyle(fontSize:12, fontWeight: FontWeight.w600, color: active? Colors.white : const Color(0xFF374151))),
      selected: active, onSelected: (_)=> onTap(),
      selectedColor: const Color(0xFF0B63F6), backgroundColor: Colors.white,
      side: BorderSide(color: active? const Color(0xFF0B63F6) : const Color(0xFFE5E7EB)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ));
  }
}
