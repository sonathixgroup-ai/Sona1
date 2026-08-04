// lib/presentation/thix_weeding/pages/staff/budget/payment_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

final expenseDetailProvider = FutureProvider.family<Map<String,dynamic>, String>((ref, expenseId) async {
  return await Supabase.instance.client.from('thix_weeding_expenses').select('*, thix_weeding_vendors(name)').eq('id', expenseId).single();
});

class PaymentDetailPage extends ConsumerWidget {
  final String weddingId; final String expenseId;
  const PaymentDetailPage({super.key, required this.weddingId, required this.expenseId});
  @override Widget build(BuildContext context, WidgetRef ref){
    final async = ref.watch(expenseDetailProvider(expenseId));
    return Scaffold(appBar: AppBar(title: const Text('Détail paiement'), actions: [
      IconButton(icon: const Icon(Icons.edit), onPressed: ()=> context.push('/thix-weeding/staff/$weddingId/budget/add?edit=$expenseId')),
      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async {
        await Supabase.instance.client.from('thix_weeding_expenses').delete().eq('id', expenseId);
        if(context.mounted) context.pop();
      }),
    ]), body: async.when(
      loading: ()=> const Center(child: CircularProgressIndicator()),
      error: (e,s)=> Center(child: Text('$e')),
      data: (e)=> ListView(padding: const EdgeInsets.all(20), children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(e['title'], style: const TextStyle(fontSize:22, fontWeight: FontWeight.w900)),
          const SizedBox(height:8),
          Text('ID: ${e['id']}', style: const TextStyle(fontSize:11, color: Colors.grey)),
          const Divider(height:24),
          _Row(label:'Montant', value:'${e['amount']} FCFA'),
          _Row(label:'Prestataire', value:e['thix_weeding_vendors']?['name']??'Aucun'),
          _Row(label:'Statut', value:e['paid']?'Payé':'Impayé'),
          _Row(label:'Date paiement', value:e['paid_at']?.toString()??'-'),
          _Row(label:'Créé le', value:e['created_at']?.toString()??'-'),
        ])),
        const SizedBox(height:20),
        FilledButton.icon(onPressed: e['paid']?null:() async {
          await Supabase.instance.client.from('thix_weeding_expenses').update({'paid': true, 'paid_at': DateTime.now().toIso8601String()}).eq('id', expenseId);
          ref.invalidate(expenseDetailProvider(expenseId));
        }, icon: const Icon(Icons.check), label: Text(e['paid']?'Déjà payé':'Marquer comme payé')),
      ]),
    ));
  }
}
class _Row extends StatelessWidget{ final String label; final String value; const _Row({required this.label, required this.value}); @override Widget build(BuildContext context)=> Padding(padding: const EdgeInsets.only(bottom:10), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.grey)), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))])); }
