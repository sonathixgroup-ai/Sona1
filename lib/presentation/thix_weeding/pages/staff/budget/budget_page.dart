// lib/presentation/thix_weeding/pages/staff/budget/budget_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final budgetProvider = FutureProvider.family<Map<String,dynamic>, String>((ref, weddingId) async {
  final budget = await Supabase.instance.client.from('thix_weeding_budget').select().eq('wedding_id', weddingId).maybeSingle();
  if(budget==null){
    await Supabase.instance.client.from('thix_weeding_budget').insert({'wedding_id': weddingId, 'total_budget': 3500000, 'total_spent': 0});
    return {'wedding_id': weddingId, 'total_budget': 3500000, 'total_spent': 0};
  }
  return budget;
});

final expensesProvider = FutureProvider.family<List<Map<String,dynamic>>, String>((ref, weddingId) async {
  final res = await Supabase.instance.client.from('thix_weeding_expenses').select('*, thix_weeding_vendors(name)').eq('wedding_id', weddingId).order('created_at', ascending: false);
  return List<Map<String,dynamic>>.from(res);
});

class BudgetPage extends ConsumerStatefulWidget {
  final String weddingId;
  const BudgetPage({super.key, required this.weddingId});
  @override ConsumerState<BudgetPage> createState()=> _BudgetPageState();
}

class _BudgetPageState extends ConsumerState<BudgetPage> {
  String _filter = 'all';
  @override Widget build(BuildContext context){
    final budgetAsync = ref.watch(budgetProvider(widget.weddingId));
    final expensesAsync = ref.watch(expensesProvider(widget.weddingId));
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('Budget'), backgroundColor: Colors.white, actions: [
        IconButton(icon: const Icon(Icons.edit), onPressed: ()=> _editTotalBudget(context, ref)),
      ]),
      body: budgetAsync.when(
        loading: ()=> const Center(child: CircularProgressIndicator()),
        error: (e,s)=> Center(child: Text('$e')),
        data: (budget){
          final totalBudget = (budget['total_budget'] as num).toDouble();
          final totalSpent = (budget['total_spent'] as num).toDouble();
          final remaining = totalBudget - totalSpent;
          final percent = (totalBudget>0? totalSpent/totalBudget : 0).clamp(0,1).toDouble();
          return Column(children: [
            Container(margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Budget global', style: TextStyle(fontWeight: FontWeight.w900, fontSize:16)),
                Text('${(percent*100).toInt()}%', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height:12),
              LinearProgressIndicator(value: percent, backgroundColor: Colors.grey[200], color: Colors.green, minHeight: 10),
              const SizedBox(height:16),
              Row(children: [
                Expanded(child: _MoneyBox(label:'Dépensé', value: totalSpent, color: Colors.red)),
                const SizedBox(width:12),
                Expanded(child: _MoneyBox(label:'Restant', value: remaining, color: Colors.green)),
                const SizedBox(width:12),
                Expanded(child: _MoneyBox(label:'Total', value: totalBudget, color: const Color(0xFF0B3B8F))),
              ]),
            ])),
            Padding(padding: const EdgeInsets.symmetric(horizontal:16), child: Row(children: [
              _FilterChip(label:'Toutes', sel:_filter=='all', tap:()=>setState(()=>_filter='all')),
              const SizedBox(width:8),
              _FilterChip(label:'Payées', sel:_filter=='paid', tap:()=>setState(()=>_filter='paid')),
              const SizedBox(width:8),
              _FilterChip(label:'Impayées', sel:_filter=='unpaid', tap:()=>setState(()=>_filter='unpaid')),
            ])),
            Expanded(child: expensesAsync.when(
              loading: ()=> const Center(child: CircularProgressIndicator()),
              error: (e,s)=> Center(child: Text('$e')),
              data: (expenses){
                var filtered = expenses.where((e){
                  if(_filter=='paid') return e['paid']==true;
                  if(_filter=='unpaid') return e['paid']==false;
                  return true;
                }).toList();
                if(filtered.isEmpty) return const Center(child: Text('Aucune dépense'));
                return RefreshIndicator(onRefresh: () async { ref.invalidate(expensesProvider(widget.weddingId)); ref.invalidate(budgetProvider(widget.weddingId)); }, child: ListView.separated(padding: const EdgeInsets.all(16), itemCount: filtered.length, separatorBuilder: (_,__)=> const SizedBox(height:8), itemBuilder: (_,i){
                  final e = filtered[i];
                  return Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: ListTile(
                    leading: Icon(e['paid']?Icons.check_circle:Icons.pending, color: e['paid']?Colors.green:Colors.orange),
                    title: Text(e['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${e['thix_weeding_vendors']?['name']??'Sans prestataire'} • ID: ${e['id'].toString().substring(0,6)}'),
                    trailing: Text('${e['amount']} FCFA', style: TextStyle(fontWeight: FontWeight.bold, color: e['paid']?Colors.green:Colors.red)),
                    onTap: ()=> context.push('/thix-weeding/staff/${widget.weddingId}/budget/${e['id']}'),
                  ));
                }));
              },
            )),
          ]);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: ()=> context.push('/thix-weeding/staff/${widget.weddingId}/budget/add'), icon: const Icon(Icons.add), label: const Text('Dépense')),
    );
  }

  void _editTotalBudget(BuildContext context, WidgetRef ref){
    final c = TextEditingController();
    showDialog(context: context, builder: (_)=> AlertDialog(title: const Text('Modifier budget total'), content: TextField(controller: c, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText:'3500000')), actions: [
      TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Annuler')),
      FilledButton(onPressed: () async {
        final val = double.tryParse(c.text);
        if(val!=null){ await Supabase.instance.client.from('thix_weeding_budget').update({'total_budget': val}).eq('wedding_id', widget.weddingId); ref.invalidate(budgetProvider(widget.weddingId)); if(context.mounted) Navigator.pop(context); }
      }, child: const Text('Enregistrer')),
    ]));
  }
}
class _MoneyBox extends StatelessWidget{ final String label; final double value; final Color color; const _MoneyBox({required this.label, required this.value, required this.color}); @override Widget build(BuildContext context)=> Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontSize:10, color: color)), Text('${value.toInt()} FCFA', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize:12))])); }
class _FilterChip extends StatelessWidget{ final String label; final bool sel; final VoidCallback tap; const _FilterChip({required this.label, required this.sel, required this.tap}); @override Widget build(BuildContext context)=> ChoiceChip(label: Text(label), selected: sel, onSelected: (_)=> tap()); }
