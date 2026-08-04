// lib/presentation/thix_weeding/pages/staff/invités/rsvp_management_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final rsvpStatsProvider = FutureProvider.family<Map<String,int>, String>((ref, weddingId) async {
  final all = await Supabase.instance.client.from('thix_weeding_guests').select('rsvp_status').eq('wedding_id', weddingId);
  int total=all.length, yes=all.where((e)=>e['rsvp_status']=='yes').length, no=all.where((e)=>e['rsvp_status']=='no').length, pending=all.where((e)=>e['rsvp_status']=='pending').length, maybe=all.where((e)=>e['rsvp_status']=='maybe').length;
  return {'total':total,'yes':yes,'no':no,'pending':pending,'maybe':maybe};
});

class RsvpManagementPage extends ConsumerWidget {
  final String weddingId;
  const RsvpManagementPage({super.key, required this.weddingId});
  @override Widget build(BuildContext context, WidgetRef ref){
    final stats = ref.watch(rsvpStatsProvider(weddingId));
    return Scaffold(appBar: AppBar(title: const Text('Gestion RSVP')), body: stats.when(
      loading: ()=> const Center(child: CircularProgressIndicator()),
      error: (e,s)=> Center(child: Text('$e')),
      data: (s)=> ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          Expanded(child: _StatCard(label:'Total', value:s['total']!, color: Colors.blue)),
          const SizedBox(width:8),
          Expanded(child: _StatCard(label:'Confirmés', value:s['yes']!, color: Colors.green)),
          const SizedBox(width:8),
          Expanded(child: _StatCard(label:'Refusés', value:s['no']!, color: Colors.red)),
          const SizedBox(width:8),
          Expanded(child: _StatCard(label:'En attente', value:s['pending']!, color: Colors.grey)),
        ]),
        const SizedBox(height:20),
        const Text('Détails par invité - Temps réel DB', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height:12),
        FutureBuilder(future: Supabase.instance.client.from('thix_weeding_guests').select().eq('wedding_id', weddingId).order('rsvp_status'), builder: (c,snap){
          if(!snap.hasData) return const CircularProgressIndicator();
          final list = snap.data as List;
          return Column(children: list.map((g)=> ListTile(leading: CircleAvatar(child: Text(g['name'][0])), title: Text(g['name']), subtitle: Text('ID ${g['id'].toString().substring(0,8)}'), trailing: Text(g['rsvp_status'], style: const TextStyle(fontWeight: FontWeight.bold)))).toList());
        }),
      ]),
    ));
  }
}
class _StatCard extends StatelessWidget{
  final String label; final int value; final Color color;
  const _StatCard({required this.label, required this.value, required this.color});
  @override Widget build(BuildContext context)=> Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Column(children: [Text('$value', style: TextStyle(fontSize:22, fontWeight: FontWeight.w900, color: color)), Text(label, style: TextStyle(fontSize:11, color: color))]));
}
