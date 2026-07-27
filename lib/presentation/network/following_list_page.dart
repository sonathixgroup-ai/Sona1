import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FollowingListPage extends ConsumerStatefulWidget {
  final String userId;
  const FollowingListPage({super.key, required this.userId});
  @override ConsumerState<FollowingListPage> createState() => _FollowingListPageState();
}

class _FollowingListPageState extends ConsumerState<FollowingListPage> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  final _search = TextEditingController();

  @override void initState(){ super.initState(); _load(); _search.addListener(_filter); }
  @override void dispose(){ _search.dispose(); super.dispose(); }

  void _filter(){
    final q = _search.text.toLowerCase();
    setState(()=> _filtered = q.isEmpty? _users : _users.where((u){ final p = u['profiles'] as Map? ?? u; return (p['display_name']??'').toString().toLowerCase().contains(q); }).toList());
  }

  Future<void> _load() async {
    setState(()=> _loading=true);
    final supa = Supabase.instance.client;
    try{
      // following = je suis follower, je suis user_id et je suis l'autre
      final res = await supa.from('follows').select('following_id, created_at, profiles!follows_following_id_fkey(id, display_name, photo_url, avatar_url, profession)').eq('follower_id', widget.userId).order('created_at', ascending: false).limit(200);
      if(!mounted) return;
      setState(()=> {_users = (res as List).cast<Map<String,dynamic>>(), _filtered = (res as List).cast<Map<String,dynamic>>(), _loading=false});
    }catch(e){
      // fallback follows table = connections
      try{
        final res2 = await supa.from('connections').select('connection_id, created_at, profiles!connections_connection_id_fkey(id, display_name, photo_url, avatar_url, profession)').eq('user_id', widget.userId).limit(200);
        if(!mounted) return;
        setState(()=> {_users = (res2 as List).map((m)=> {'following_id': m['connection_id'], 'profiles': m['profiles'], 'created_at': m['created_at']}).toList(), _filtered = (res2 as List).map((m)=> {'following_id': m['connection_id'], 'profiles': m['profiles'], 'created_at': m['created_at']}).toList(), _loading=false});
      }catch(_){ if(mounted) setState(()=> _loading=false); }
    }
  }

  Future<void> _unfollow(String followingId) async {
    final supa = Supabase.instance.client;
    final me = supa.auth.currentUser?.id;
    if(me!=widget.userId) return; // seul owner peut unfollow
    setState(()=> {_users.removeWhere((u)=> u['following_id']==followingId); _filtered.removeWhere((u)=> u['following_id']==followingId);});
    try{
      await supa.from('follows').delete().eq('follower_id', widget.userId).eq('following_id', followingId);
      await supa.from('connections').delete().eq('user_id', widget.userId).eq('connection_id', followingId);
    }catch(_){ _load(); }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, iconTheme: IconThemeData(color: Color(0xFF0B1B3D)), title: Text('Abonnements (${_users.length})', style: TextStyle(color: Color(0xFF0B1B3D), fontWeight: FontWeight.bold))),
      body: Column(children: [
        Container(color: Colors.white, padding: EdgeInsets.all(12), child: TextField(controller: _search, decoration: InputDecoration(hintText: 'Rechercher...', prefixIcon: Icon(Icons.search), filled: true, fillColor: Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none), contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10)))),
        Expanded(child: _loading? Center(child: CircularProgressIndicator(color: Color(0xFF2B5CFF))) : _filtered.isEmpty? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.people_outline, size: 80, color: Colors.grey.shade300), SizedBox(height: 16), Text('Aucun abonnement pour le moment')])) : RefreshIndicator(onRefresh: _load, child: ListView.builder(padding: EdgeInsets.all(12), itemCount: _filtered.length, itemBuilder: (_,i){
          final item = _filtered[i];
          final profile = item['profiles'] as Map?;
          final id = item['following_id'] as String;
          final name = profile?['display_name']?? 'Utilisateur';
          final job = profile?['profession']?? '';
          final avatar = profile?['photo_url']?? profile?['avatar_url'];
          final isMe = Supabase.instance.client.auth.currentUser?.id == widget.userId;
          return Container(margin: EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: ListTile(
            leading: CircleAvatar(radius: 22, backgroundColor: Colors.grey.shade200, child: ClipOval(child: avatar!=null? Image.network(avatar, width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (_,__,___)=> Icon(Icons.person)) : Icon(Icons.person))),
            title: Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: job.isNotEmpty? Text(job, style: TextStyle(fontSize: 11, color: Colors.grey)) : null,
            trailing: isMe? OutlinedButton(onPressed: ()=> _unfollow(id), style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: Text('Abonné', style: TextStyle(fontSize: 12))) : ElevatedButton(onPressed: ()=> context.push('/network/member/$id'), style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF2B5CFF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: Text('Voir', style: TextStyle(fontSize: 12, color: Colors.white))),
            onTap: ()=> context.push('/network/member/$id'),
          ));
        }))),
      ]),
    );
  }
}
