// lib/presentation/thix_weeding/pages/staff/paiements/payment_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final paymentDetailProvider = FutureProvider.family<Map<String,dynamic>, String>((ref, paymentId) async {
  return await Supabase.instance.client.from('thix_weeding_payments').select('*, thix_weeding_vendors(name), thix_weeding_expenses(title)').eq('id', paymentId).single();
});

class PaymentDetailPage extends ConsumerWidget {
  final String weddingId; final String paymentId;
  const PaymentDetailPage({super.key, required this.weddingId, required this.paymentId});
  @override Widget build(BuildContext context, WidgetRef ref){
    final async = ref.watch(paymentDetailProvider(paymentId));
    return Scaffold(appBar: AppBar(title: const Text('Détail paiement'), backgroundColor: Colors.white, actions: [
      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async {
        await Supabase.instance.client.from('thix_weeding_payments').delete().eq('id', paymentId);
        if(context.mounted) Navigator.pop(context);
      }),
    ]), body: async.when(
      loading: ()=> const Center(child: CircularProgressIndicator()),
      error: (e,s)=> Center(child: Text('$e')),
      data: (p)=> ListView(padding: const EdgeInsets.all(20), children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${p['amount']} FCFA', style: const TextStyle(fontSize:28, fontWeight: FontWeight.w900, color: Colors.green)),
          const SizedBox(height:12),
          _Row(label:'ID', value:p['id']),
          _Row(label:'Méthode', value:p['method']),
          _Row(label:'Statut', value:p['status']),
          _Row(label:'Référence', value:p['reference_code']??'-'),
          _Row(label:'Prestataire', value:p['thix_weeding_vendors']?['name']??'-'),
          _Row(label:'Dépense liée', value:p['thix_weeding_expenses']?['title']??'-'),
          _Row(label:'Date', value:p['created_at']),
        ])),
        const SizedBox(height:20),
        FilledButton.icon(onPressed: p['status']=='completed'?null:() async {
          await Supabase.instance.client.from('thix_weeding_payments').update({'status':'completed'}).eq('id', paymentId);
          ref.invalidate(paymentDetailProvider(paymentId));
        }, icon: const Icon(Icons.check), label: Text(p['status']=='completed'?'Déjà complété':'Marquer comme complété')),
      ]),
    ));
  }
}
class _Row extends StatelessWidget{ final String label; final String value; const _Row({required this.label, required this.value}); @override Widget build(BuildContext context)=> Padding(padding: const EdgeInsets.only(bottom:10), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.grey, fontSize:12)), Flexible(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right))])); }
