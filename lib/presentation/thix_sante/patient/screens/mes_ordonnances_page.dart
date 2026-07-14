// lib/presentation/thix_sante/patient/screens/mes_ordonnances_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/thix_sante_colors.dart';
import '../providers/patient_dashboard_provider.dart';

class MesOrdonnancesPage extends ConsumerWidget {
  const MesOrdonnancesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordosAsync = ref.watch(prescriptionsProvider);

    return Scaffold(
      backgroundColor: ThixSanteColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)), onPressed: ()=> Navigator.pop(context)),
        title: const Text('Mes Ordonnances', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w800)),
      ),
      body: ordosAsync.when(
        data: (list){
          if(list.isEmpty) return const Center(child: Text('Aucune ordonnance'));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_,__ )=> const SizedBox(height:10),
            itemBuilder: (_,i){
              final o = list[i];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E7EB))),
                child: Row(
                  children: [
                    Container(width:44,height:44,decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF0B63F6))),
                    const SizedBox(width:12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                      Text(o.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize:13)),
                      Text('${o.createdAt.day}/${o.createdAt.month}/${o.createdAt.year} • ${o.doctorName?? 'Dr THIX'}', style: const TextStyle(fontSize:11, color: Color(0xFF6B7280))),
                    ])),
                    IconButton(icon: const Icon(Icons.send_rounded, size:18), onPressed: ()=> _showSendSheet(context, ref, o.id)),
                  ],
                ),
              );
            },
          );
        },
        loading: ()=> const Center(child: CircularProgressIndicator()),
        error: (e,_ )=> Center(child: Text('Erreur $e')),
      ),
    );
  }

  void _showSendSheet(BuildContext context, WidgetRef ref, String prescriptionId){
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Envoyer a la pharmacie par THIX ID', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height:12),
            TextField(controller: ctrl, decoration: InputDecoration(labelText: 'THIX ID Pharmacie', hintText: 'THIX-CD-...', prefixIcon: const Icon(Icons.local_pharmacy_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), textCapitalization: TextCapitalization.characters),
            const SizedBox(height:16),
            ElevatedButton(
              onPressed: () async {
                try{
                  await ref.read(prescriptionServiceProvider).sendToPharmacy(prescriptionId: prescriptionId, pharmacyThixId: ctrl.text.trim());
                  if(context.mounted){ Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ordonnance envoyee'), backgroundColor: Color(0xFF16A34A))); ref.invalidate(prescriptionsProvider); }
                }catch(e){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red)); }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B63F6), foregroundColor: Colors.white),
              child: const Text('Envoyer'),
            ),
            const SizedBox(height:20),
          ],
        ),
      ),
    );
  }
}
