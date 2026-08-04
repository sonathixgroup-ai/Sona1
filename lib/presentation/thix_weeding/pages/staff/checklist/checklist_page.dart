// lib/presentation/thix_weeding/pages/staff/checklist/checklist_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final checklistProvider = FutureProvider.family<List<Map<String,dynamic>>, String>((ref, weddingId) async {
  final res = await Supabase.instance.client.from('thix_weeding_checklist').select().eq('wedding_id', weddingId).order('order_index', ascending: true).order('created_at');
  return List<Map<String,dynamic>>.from(res);
});

class ChecklistPage extends ConsumerStatefulWidget {
  final String weddingId;
  const ChecklistPage({super.key, required this.weddingId});
  @override ConsumerState<ChecklistPage> createState()=> _ChecklistPageState();
}

class _ChecklistPageState extends ConsumerState<ChecklistPage> {
  String _filter = 'all';
  final _newTaskCtrl = TextEditingController();

  Future<void> _addQuick() async {
    if(_newTaskCtrl.text.trim().isEmpty) return;
    await Supabase.instance.client.from('thix_weeding_checklist').insert({
      'wedding_id': widget.weddingId,
      'title': _newTaskCtrl.text.trim(),
      'is_done': false,
      'order_index': DateTime.now().millisecondsSinceEpoch,
    });
    _newTaskCtrl.clear();
    ref.invalidate(checklistProvider(widget.weddingId));
  }

  @override Widget build(BuildContext context){
    final async = ref.watch(checklistProvider(widget.weddingId));
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('Checklist'), backgroundColor: Colors.white),
      body: async.when(
        loading: ()=> const Center(child: CircularProgressIndicator()),
        error: (e,s)=> Center(child: Text('$e')),
        data: (tasks){
          final total = tasks.length;
          final done = tasks.where((t)=> t['is_done']==true).length;
          final percent = total>0? done/total : 0.0;
          var filtered = tasks.where((t){
            if(_filter=='done') return t['is_done']==true;
            if(_filter=='todo') return t['is_done']==false;
            return true;
          }).toList();
          return Column(children: [
            Container(margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('$done / $total tâches', style: const TextStyle(fontWeight: FontWeight.bold)), Text('${(percent*100).toInt()}%', style: const TextStyle(color: Color(0xFF0B3B8F), fontWeight: FontWeight.bold))]),
              const SizedBox(height:8),
              LinearProgressIndicator(value: percent, backgroundColor: Colors.grey[200], color: const Color(0xFF0B3B8F)),
            ])),
            Padding(padding: const EdgeInsets.symmetric(horizontal:16), child: Row(children: [
              _Chip(label:'Toutes', sel:_filter=='all', tap:()=>setState(()=>_filter='all')),
              const SizedBox(width:8),
              _Chip(label:'À faire', sel:_filter=='todo', tap:()=>setState(()=>_filter='todo')),
              const SizedBox(width:8),
              _Chip(label:'Faites', sel:_filter=='done', tap:()=>setState(()=>_filter='done')),
            ])),
            Padding(padding: const EdgeInsets.all(16), child: Row(children: [
              Expanded(child: TextField(controller: _newTaskCtrl, decoration: InputDecoration(hintText:'Ajouter une tâche rapide...', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), onSubmitted: (_)=> _addQuick())),
              const SizedBox(width:8),
              FilledButton(onPressed: _addQuick, child: const Icon(Icons.add)),
            ])),
            Expanded(child: filtered.isEmpty? const Center(child: Text('Aucune tâche')) : RefreshIndicator(onRefresh: () async => ref.invalidate(checklistProvider(widget.weddingId)), child: ListView.separated(padding: const EdgeInsets.symmetric(horizontal:16), itemCount: filtered.length, separatorBuilder: (_,__)=> const SizedBox(height:8), itemBuilder: (_,i){
              final t = filtered[i];
              return Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: ListTile(
                leading: Checkbox(value: t['is_done'], onChanged: (v) async {
                  await Supabase.instance.client.from('thix_weeding_checklist').update({'is_done': v}).eq('id', t['id']);
                  ref.invalidate(checklistProvider(widget.weddingId));
                }),
                title: Text(t['title'], style: TextStyle(decoration: t['is_done']?TextDecoration.lineThrough:null, fontWeight: t['is_done']?FontWeight.normal:FontWeight.bold)),
                subtitle: Text('ID: ${t['id'].toString().substring(0,6)} • ${t['due_date']??'Sans date'}'),
                trailing: IconButton(icon: const Icon(Icons.more_vert), onPressed: ()=> context.push('/thix-weeding/staff/${widget.weddingId}/checklist/${t['id']}')),
                onTap: ()=> context.push('/thix-weeding/staff/${widget.weddingId}/checklist/${t['id']}'),
              ));
            }))),
          ]);
        },
      ),
    );
  }
}
class _Chip extends StatelessWidget{ final String label; final bool sel; final VoidCallback tap; const _Chip({required this.label, required this.sel, required this.tap}); @override Widget build(BuildContext context)=> ChoiceChip(label: Text(label), selected: sel, onSelected: (_)=> tap()); }
