// lib/presentation/thix_weeding/pages/staff/paiements/payments_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final paymentsProvider = FutureProvider.family<List<Map<String,dynamic>>, String>((ref, weddingId) async {
  final res = await Supabase.instance.client.from('thix_weeding_payments').select('*, thix_weeding_vendors(name), thix_weeding_expenses(title)').eq('wedding_id', weddingId).order('created_at', ascending: false);
  return List<Map<String,dynamic>>.from(res);
});

class PaymentsPage extends ConsumerWidget {
  final String weddingId;
  const PaymentsPage({super.key, required this.weddingId});
  @override Widget build(BuildContext context, WidgetRef ref){
    final async = ref.watch(paymentsProvider(weddingId));
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('Paiements'), backgroundColor: Colors.white, actions: [
        IconButton(icon: const Icon(Icons.add_card), onPressed: ()=> context.push('/thix-weeding/staff/$weddingId/paiements/add')),
      ]),
      body: async.when(
        loading: ()=> const Center(child: CircularProgressIndicator()),
        error: (e,s)=> Center(child: Text('$e')),
        data: (pays){
          final total = pays.fold<double>(0, (sum,e)=> sum + (e['amount'] as num).toDouble());
          return Column(children: [
            Container(margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Row(children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.payments, color: Colors.green)),
              const SizedBox(width:12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Total payé', style: TextStyle(color: Colors.grey, fontSize:12)), Text('$total FCFA', style: const TextStyle(fontWeight: FontWeight.w900, fontSize:18, color: Colors.green))]),
              const Spacer(),
              Text('${pays.length} paiements', style: const TextStyle(fontSize:12, color: Colors.grey)),
            ])),
            Expanded(child: pays.isEmpty? const Center(child: Text('Aucun paiement')) : RefreshIndicator(onRefresh: () async => ref.invalidate(paymentsProvider(weddingId)), child: ListView.separated(padding: const EdgeInsets.all(12), itemCount: pays.length, separatorBuilder: (_,__)=> const SizedBox(height:8), itemBuilder: (_,i){
              final p = pays[i];
              return Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: ListTile(
                leading: Icon(p['status']=='completed'?Icons.check_circle:Icons.pending, color: p['status']=='completed'?Colors.green:Colors.orange),
                title: Text('${p['amount']} FCFA • ${p['thix_weeding_vendors']?['name']?? p['thix_weeding_expenses']?['title']??'Paiement'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${p['method']} • Ref: ${p['reference_code']??'-'} • ID: ${p['id'].toString().substring(0,6)}'),
                trailing: Text(p['status'], style: TextStyle(fontSize:10, color: p['status']=='completed'?Colors.green:Colors.orange, fontWeight: FontWeight.bold)),
                onTap: ()=> context.push('/thix-weeding/staff/$weddingId/paiements/${p['id']}'),
              ));
            }))),
          ]);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: ()=> context.push('/thix-weeding/staff/$weddingId/paiements/add'), icon: const Icon(Icons.add), label: const Text('Nouveau paiement')),
    );
  }
}
