// lib/presentation/thix_weeding/pages/staff/messages/staff_messages_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final conversationsProvider = FutureProvider.family<List<Map<String,dynamic>>, String>((ref, weddingId) async {
  final res = await Supabase.instance.client.from('thix_weeding_messages').select('guest_id, sender_name, content, created_at, is_read, sender_type').eq('wedding_id', weddingId).order('created_at', ascending: false);
  // group by guest_id / sender_name
  final Map<String, Map<String,dynamic>> grouped = {};
  for(var m in res){
    final key = (m['guest_id']?? m['sender_name']).toString();
    if(!grouped.containsKey(key)) grouped[key]=m;
  }
  return grouped.values.toList();
});

class StaffMessagesPage extends ConsumerWidget {
  final String weddingId;
  const StaffMessagesPage({super.key, required this.weddingId});
  @override Widget build(BuildContext context, WidgetRef ref){
    final async = ref.watch(conversationsProvider(weddingId));
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('Messages'), backgroundColor: Colors.white),
      body: async.when(
        loading: ()=> const Center(child: CircularProgressIndicator()),
        error: (e,s)=> Center(child: Text('$e')),
        data: (convs){
          if(convs.isEmpty) return const Center(child: Text('Aucune discussion'));
          return RefreshIndicator(onRefresh: () async => ref.invalidate(conversationsProvider(weddingId)), child: ListView.separated(padding: const EdgeInsets.all(12), itemCount: convs.length, separatorBuilder: (_,__)=> const SizedBox(height:8), itemBuilder: (_,i){
            final c = convs[i];
            final unread = c['is_read']==false && c['sender_type']=='guest';
            return Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: ListTile(
              leading: Stack(children: [CircleAvatar(child: Text(c['sender_name'][0].toUpperCase())), if(unread) Positioned(right:0, top:0, child: Container(width:10,height:10,decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)))]),
              title: Row(children: [Expanded(child: Text(c['sender_name'], style: TextStyle(fontWeight: unread?FontWeight.w900:FontWeight.bold))), if(unread) Container(padding: const EdgeInsets.symmetric(horizontal:6, vertical:2), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)), child: const Text('Nouveau', style: TextStyle(color: Colors.white, fontSize:9)))]),
              subtitle: Text(c['content'], maxLines:1, overflow: TextOverflow.ellipsis),
              trailing: Text(c['created_at'].toString().substring(11,16), style: const TextStyle(fontSize:11, color: Colors.grey)),
              onTap: ()=> context.push('/thix-weeding/staff/$weddingId/messages/${c['guest_id']??c['sender_name']}', extra: c['sender_name']),
            ));
          }));
        },
      ),
    );
  }
}
