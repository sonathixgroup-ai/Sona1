// lib/presentation/thix_weeding/pages/staff/checklist/task_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

final checklistDetailProvider = FutureProvider.family<Map<String,dynamic>, String>((ref, taskId) async {
  return await Supabase.instance.client.from('thix_weeding_checklist').select().eq('id', taskId).single();
});

class TaskDetailPage extends ConsumerStatefulWidget {
  final String weddingId; final String taskId;
  const TaskDetailPage({super.key, required this.weddingId, required this.taskId});
  @override ConsumerState<TaskDetailPage> createState()=> _TaskDetailPageState();
}

class _TaskDetailPageState extends ConsumerState<TaskDetailPage> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  DateTime? _dueDate;
  bool _isDone = false;
  bool _loading = false;
  bool _init = false;

  Future<void> _save() async {
    setState(()=> _loading=true);
    try{
      await Supabase.instance.client.from('thix_weeding_checklist').update({
        'title': _title.text.trim(),
        'description': _desc.text.trim(),
        'due_date': _dueDate?.toIso8601String().split('T')[0],
        'is_done': _isDone,
      }).eq('id', widget.taskId);
      if(mounted) context.pop();
    }catch(e){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur $e'))); }
    finally{ if(mounted) setState(()=> _loading=false); }
  }

  @override Widget build(BuildContext context){
    final async = ref.watch(checklistDetailProvider(widget.taskId));
    return Scaffold(appBar: AppBar(title: const Text('Détail tâche'), backgroundColor: Colors.white, actions: [
      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async {
        await Supabase.instance.client.from('thix_weeding_checklist').delete().eq('id', widget.taskId);
        if(context.mounted) context.pop();
      }),
    ]), body: async.when(
      loading: ()=> const Center(child: CircularProgressIndicator()),
      error: (e,s)=> Center(child: Text('$e')),
      data: (t){
        if(!_init){
          _title.text=t['title']; _desc.text=t['description']??''; _isDone=t['is_done']; _dueDate=t['due_date']!=null?DateTime.parse(t['due_date']):null; _init=true;
        }
        return ListView(padding: const EdgeInsets.all(20), children: [
          TextField(controller: _title, decoration: const InputDecoration(labelText:'Titre'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize:18)),
          const SizedBox(height:12),
          TextField(controller: _desc, decoration: const InputDecoration(labelText:'Description'), maxLines: 4),
          const SizedBox(height:12),
          ListTile(leading: const Icon(Icons.calendar_today), title: Text(_dueDate==null?'Ajouter une échéance':'Échéance: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'), trailing: const Icon(Icons.edit), onTap: () async {
            final picked = await showDatePicker(context: context, initialDate: _dueDate??DateTime.now(), firstDate: DateTime.now().subtract(const Duration(days:30)), lastDate: DateTime.now().add(const Duration(days:365)));
            if(picked!=null) setState(()=> _dueDate=picked);
          }),
          SwitchListTile(title: const Text('Marquer comme terminée'), value: _isDone, onChanged: (v)=> setState(()=> _isDone=v)),
          const SizedBox(height:12),
          Text('ID unique: ${t['id']}', style: const TextStyle(fontSize:11, color: Colors.grey)),
          Text('Créé le: ${t['created_at']}', style: const TextStyle(fontSize:11, color: Colors.grey)),
          const SizedBox(height:24),
          FilledButton(onPressed: _loading?null:_save, child: _loading? const CircularProgressIndicator(): const Text('Enregistrer')),
        ]);
      },
    ));
  }
}
