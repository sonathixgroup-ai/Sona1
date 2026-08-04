// lib/presentation/thix_weeding/pages/staff/livre_or/guestbook_management_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final guestbookProvider = FutureProvider.family<List<Map<String,dynamic>>, String>((ref, weddingId) async {
  final res = await Supabase.instance.client.from('thix_weeding_guestbook').select().eq('wedding_id', weddingId).order('created_at', ascending: false);
  return List<Map<String,dynamic>>.from(res);
});

class GuestbookManagementPage extends ConsumerStatefulWidget {
  final String weddingId;
  const GuestbookManagementPage({super.key, required this.weddingId});
  @override ConsumerState<GuestbookManagementPage> createState()=> _GuestbookManagementPageState();
}

class _GuestbookManagementPageState extends ConsumerState<GuestbookManagementPage> {
  String _filter = 'all';
  @override Widget build(BuildContext context){
    final async = ref.watch(guestbookProvider(widget.weddingId));
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('Livre d\'or'), backgroundColor: Colors.white, actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: ()=> ref.invalidate(guestbookProvider(widget.weddingId))),
      ]),
      body: async.when(
        loading: ()=> const Center(child: CircularProgressIndicator()),
        error: (e,s)=> Center(child: Text('$e')),
        data: (messages){
          var filtered = messages.where((m){
            if(_filter=='approved') return m['is_approved']==true;
            if(_filter=='pending') return m['is_approved']==false;
            return true;
          }).toList();
          return Column(children: [
            Container(margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Row(children: [
              _StatBox(label:'Total', value:messages.length, color: const Color(0xFF0B3B8F)),
              const SizedBox(width:12),
              _StatBox(label:'Approuvés', value:messages.where((m)=>m['is_approved']==true).length, color: Colors.green),
              const SizedBox(width:12),
              _StatBox(label:'En attente', value:messages.where((m)=>m['is_approved']==false).length, color: Colors.orange),
            ])),
            SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal:16), child: Row(children: [
              _Chip(label:'Tous', sel:_filter=='all', tap:()=>setState(()=>_filter='all')),
              _Chip(label:'Approuvés', sel:_filter=='approved', tap:()=>setState(()=>_filter=='approved')),
              _Chip(label:'En attente', sel:_filter=='pending', tap:()=>setState(()=>_filter=='pending')),
            ])),
            const SizedBox(height:8),
            Expanded(child: filtered.isEmpty? const Center(child: Text('Aucun message')) : RefreshIndicator(onRefresh: () async => ref.invalidate(guestbookProvider(widget.weddingId)), child: ListView.separated(padding: const EdgeInsets.all(16), itemCount: filtered.length, separatorBuilder: (_,__)=> const SizedBox(height:10), itemBuilder: (_,i){
              final m = filtered[i];
              return Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border(left: BorderSide(color: m['is_approved']?Colors.green:Colors.orange, width:4))), child: ListTile(
                leading: CircleAvatar(child: Text(m['guest_name'][0].toUpperCase())),
                title: Row(children: [Expanded(child: Text(m['guest_name'], style: const TextStyle(fontWeight: FontWeight.bold))), Container(padding: const EdgeInsets.symmetric(horizontal:6, vertical:2), decoration: BoxDecoration(color: m['is_approved']?Colors.green.withOpacity(0.1):Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Text(m['is_approved']?'Publié':'Masqué', style: TextStyle(fontSize:10, color: m['is_approved']?Colors.green:Colors.orange)))]),
                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SizedBox(height:4),
                  Text(m['message']),
                  const SizedBox(height:6),
                  Text('ID: ${m['id'].toString().substring(0,8)} • ${DateTime.parse(m['created_at']).day}/${DateTime.parse(m['created_at']).month}', style: const TextStyle(fontSize:10, color: Colors.grey)),
                ]),
                trailing: PopupMenuButton(onSelected: (v) async {
                  if(v=='toggle'){ await Supabase.instance.client.from('thix_weeding_guestbook').update({'is_approved': !m['is_approved']}).eq('id', m['id']); ref.invalidate(guestbookProvider(widget.weddingId)); }
                  if(v=='delete'){ await Supabase.instance.client.from('thix_weeding_guestbook').delete().eq('id', m['id']); ref.invalidate(guestbookProvider(widget.weddingId)); }
                }, itemBuilder: (_)=> [PopupMenuItem(value:'toggle', child: Text(m['is_approved']?'Masquer':'Approuver')), const PopupMenuItem(value:'delete', child: Text('Supprimer', style: TextStyle(color: Colors.red)))]),
              ));
            }))),
          ]);
        },
      ),
    );
  }
}
class _StatBox extends StatelessWidget{ final String label; final int value; final Color color; const _StatBox({required this.label, required this.value, required this.color}); @override Widget build(BuildContext context)=> Expanded(child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Column(children: [Text('$value', style: TextStyle(fontSize:20, fontWeight: FontWeight.w900, color: color)), Text(label, style: TextStyle(fontSize:11, color: color))]))); }
class _Chip extends StatelessWidget{ final String label; final bool sel; final VoidCallback tap; const _Chip({required this.label, required this.sel, required this.tap}); @override Widget build(BuildContext context)=> Padding(padding: const EdgeInsets.only(right:8), child: ChoiceChip(label: Text(label), selected: sel, onSelected: (_)=> tap())); }
