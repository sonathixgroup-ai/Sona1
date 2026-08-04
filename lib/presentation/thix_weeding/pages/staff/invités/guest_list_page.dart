// lib/presentation/thix_weeding/pages/staff/invités/guest_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final guestsListProvider = FutureProvider.family<List<Map<String,dynamic>>, String>((ref, weddingId) async {
  final res = await Supabase.instance.client.from('thix_weeding_guests').select().eq('wedding_id', weddingId).order('created_at', ascending: false);
  return List<Map<String,dynamic>>.from(res);
});

class GuestListPage extends ConsumerStatefulWidget {
  final String weddingId;
  const GuestListPage({super.key, required this.weddingId});
  @override ConsumerState<GuestListPage> createState() => _GuestListPageState();
}

class _GuestListPageState extends ConsumerState<GuestListPage> {
  String _search = '';
  String _filter = 'all';
  @override Widget build(BuildContext context) {
    final guestsAsync = ref.watch(guestsListProvider(widget.weddingId));
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: Text('Invités - ${widget.weddingId}'), backgroundColor: Colors.white, actions: [
        IconButton(icon: const Icon(Icons.bar_chart), onPressed: () => context.push('/thix-weeding/staff/${widget.weddingId}/rsvp')),
        IconButton(icon: const Icon(Icons.person_add), onPressed: () => context.push('/thix-weeding/staff/${widget.weddingId}/invites/add')),
      ]),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(onChanged: (v)=> setState(()=> _search=v), decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'Rechercher invité...', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
        SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal:12), child: Row(children: [
          _FilterChip(label:'Tous', selected:_filter=='all', onTap:()=>setState(()=>_filter='all')),
          _FilterChip(label:'En attente', selected:_filter=='pending', onTap:()=>setState(()=>_filter='pending')),
          _FilterChip(label:'Confirmés', selected:_filter=='yes', onTap:()=>setState(()=>_filter='yes')),
          _FilterChip(label:'Refusés', selected:_filter=='no', onTap:()=>setState(()=>_filter='no')),
        ])),
        Expanded(child: guestsAsync.when(
          loading: ()=> const Center(child: CircularProgressIndicator()),
          error: (e,s)=> Center(child: Text('Erreur $e')),
          data: (guests){
            var filtered = guests.where((g){
              final matchSearch = g['name'].toString().toLowerCase().contains(_search.toLowerCase());
              final matchFilter = _filter=='all' || g['rsvp_status']==_filter;
              return matchSearch && matchFilter;
            }).toList();
            if(filtered.isEmpty) return const Center(child: Text('Aucun invité'));
            return RefreshIndicator(onRefresh: () async => ref.invalidate(guestsListProvider(widget.weddingId)), child: ListView.separated(padding: const EdgeInsets.all(12), itemCount: filtered.length, separatorBuilder: (_,__)=> const SizedBox(height:8), itemBuilder: (_,i){
              final g = filtered[i];
              return Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: ListTile(
                leading: CircleAvatar(child: Text(g['name'][0].toUpperCase())),
                title: Text(g['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${g['group_name']} • ${g['guests_count']} pers • ID: ${g['id'].toString().substring(0,6)}'),
                trailing: _StatusBadge(status: g['rsvp_status']),
                onTap: ()=> context.push('/thix-weeding/staff/${widget.weddingId}/invites/${g['id']}'),
              ));
            }));
          },
        )),
      ]),
      floatingActionButton: FloatingActionButton.extended(onPressed: ()=> context.push('/thix-weeding/staff/${widget.weddingId}/invites/add'), icon: const Icon(Icons.add), label: const Text('Ajouter')),
    );
  }
}
class _FilterChip extends StatelessWidget {
  final String label; final bool selected; final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(right:8), child: ChoiceChip(label: Text(label), selected: selected, onSelected: (_)=> onTap()));
}
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});
  @override Widget build(BuildContext context){
    Color c = status=='yes'?Colors.green:status=='no'?Colors.red:status=='maybe'?Colors.orange:Colors.grey;
    String t = status=='yes'?'Oui':status=='no'?'Non':status=='maybe'?'Peut-être':'En attente';
    return Container(padding: const EdgeInsets.symmetric(horizontal:8, vertical:4), decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(20)), child: Text(t, style: TextStyle(color: c, fontSize:10, fontWeight: FontWeight.bold)));
  }
}
