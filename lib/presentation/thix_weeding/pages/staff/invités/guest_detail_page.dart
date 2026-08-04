// lib/presentation/thix_weeding/pages/staff/invités/guest_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

final guestDetailProvider = FutureProvider.family<Map<String,dynamic>, String>((ref, guestId) async {
  return await Supabase.instance.client.from('thix_weeding_guests').select().eq('id', guestId).single();
});

class GuestDetailPage extends ConsumerWidget {
  final String weddingId; final String guestId;
  const GuestDetailPage({super.key, required this.weddingId, required this.guestId});
  @override Widget build(BuildContext context, WidgetRef ref){
    final async = ref.watch(guestDetailProvider(guestId));
    return Scaffold(appBar: AppBar(title: const Text('Détail invité'), backgroundColor: Colors.white, actions: [
      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async {
        await Supabase.instance.client.from('thix_weeding_guests').delete().eq('id', guestId);
        if(context.mounted) context.pop();
      }),
    ]), body: async.when(
      loading: ()=> const Center(child: CircularProgressIndicator()),
      error: (e,s)=> Center(child: Text('$e')),
      data: (g)=> ListView(padding: const EdgeInsets.all(20), children: [
        Center(child: CircleAvatar(radius:40, child: Text(g['name'][0], style: const TextStyle(fontSize:28)))),
        const SizedBox(height:12),
        Center(child: Text(g['name'], style: const TextStyle(fontSize:22, fontWeight: FontWeight.w900))),
        Center(child: Text('ID: ${g['id']}', style: const TextStyle(fontSize:11, color: Colors.grey))),
        const SizedBox(height:20),
        _RowInfo(icon: Icons.group, label:'Groupe', value:g['group_name']),
        _RowInfo(icon: Icons.phone, label:'Téléphone', value:g['phone']??'Non renseigné'),
        _RowInfo(icon: Icons.email, label:'Email', value:g['email']??'Non renseigné'),
        _RowInfo(icon: Icons.people, label:'Nombre', value:'${g['guests_count']} personnes'),
        _RowInfo(icon: Icons.table_restaurant, label:'Table', value:g['table_number']?.toString()??'Non assignée'),
        _RowInfo(icon: Icons.check_circle, label:'RSVP', value:g['rsvp_status']),
        const SizedBox(height:20),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: ()=> context.push('/thix-weeding/staff/$weddingId/invites/add?edit=${g['id']}'), icon: const Icon(Icons.edit), label: const Text('Modifier'))),
          const SizedBox(width:12),
          Expanded(child: FilledButton.icon(onPressed: (){}, icon: const Icon(Icons.share), label: const Text('Partager invitation'))),
        ]),
        const SizedBox(height:12),
        SelectableText('Lien invitation: https://thix.id/w/$weddingId?guest=${g['id']}', style: const TextStyle(fontSize:12, color: Colors.blue)),
      ]),
    ));
  }
}
class _RowInfo extends StatelessWidget{
  final IconData icon; final String label; final String value;
  const _RowInfo({required this.icon, required this.label, required this.value});
  @override Widget build(BuildContext context)=> Padding(padding: const EdgeInsets.only(bottom:12), child: Row(children: [Icon(icon, size:20, color: const Color(0xFF0B3B8F)), const SizedBox(width:12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize:11, color: Colors.grey)), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))])]));
}
