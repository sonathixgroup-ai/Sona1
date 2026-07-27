import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FollowersListPage extends ConsumerStatefulWidget {
  final String userId;
  const FollowersListPage({super.key, required this.userId});
  @override ConsumerState<FollowersListPage> createState() => _FollowersListPageState();
}

class _FollowersListPageState extends ConsumerState<FollowersListPage> {
  List<Map<String, dynamic>> _all = [], _filtered = [];
  Set<String> _myFollowing = {};
  bool _loading = true;
  final _search = TextEditingController();

  @override void initState(){
    super.initState();
    _load();
    _search.addListener(_doFilter);
  }
  @override void dispose(){ _search.dispose(); super.dispose(); }

  void _doFilter(){
    final q = _search.text.toLowerCase();
    setState(()=> _filtered = q.isEmpty ? _all : _all.where((e){
      final p = e['profiles'] as Map? ?? {};
      return (p['display_name']??'').toString().toLowerCase().contains(q);
    }).toList());
  }

  Future<void> _load() async {
    setState(()=> _loading=true);
    final supa = Supabase.instance.client;
    try{
      final res = await supa.from('follows').select('follower_id, created_at, profiles!follows_follower_id_fkey(id, display_name, photo_url, avatar_url, profession)').eq('following_id', widget.userId).order('created_at', ascending: false).limit(300);
      final me = supa.auth.currentUser?.id;
      if(me!=null){
        final myF = await supa.from('follows').select('following_id').eq('follower_id', me);
        _myFollowing = (myF as List).map((e)=> e['following_id'] as String).toSet();
      }
      if(!mounted) return;
      setState((){
        _all = (res as List).cast<Map<String,dynamic>>();
        _filtered = _all;
        _loading=false;
      });
    }catch(_){
      if(mounted) setState(()=> _loading=false);
    }
  }

  Future<void> _toggleFollow(String otherId) async {
    final supa = Supabase.instance.client;
    final me = supa.auth.currentUser!.id;
    final isFollowing = _myFollowing.contains(otherId);
    setState(()=> isFollowing ? _myFollowing.remove(otherId) : _myFollowing.add(otherId));
    try{
      if(isFollowing) await supa.from('follows').delete().eq('follower_id', me).eq('following_id', otherId);
      else await supa.from('follows').insert({'follower_id': me, 'following_id': otherId});
    }catch(_){ setState(()=> isFollowing ? _myFollowing.add(otherId) : _myFollowing.remove(otherId)); }
  }

  Future<void> _removeFollower(String followerId) async {
    if(Supabase.instance.client.auth.currentUser?.id != widget.userId) return;
    setState((){
      _all.removeWhere((e)=> e['follower_id']==followerId);
      _filtered.removeWhere((e)=> e['follower_id']==followerId);
    });
    await Supabase.instance.client.from('follows').delete().eq('follower_id', followerId).eq('following_id', widget.userId);
  }

  @override Widget build(BuildContext context) {
    final isOwner = Supabase.instance.client.auth.currentUser?.id == widget.userId;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Color(0xFF0B1B3D)), title: Text('Abonnés (${_all.length})', style: const TextStyle(color: Color(0xFF0B1B3D), fontWeight: FontWeight.bold))),
      body: Column(children: [
        Container(color: Colors.white, padding: const EdgeInsets.all(12), child: TextField(controller: _search, decoration: InputDecoration(hintText: 'Rechercher', prefixIcon: const Icon(Icons.search), filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)))),
        Expanded(child: _loading ? const Center(child: CircularProgressIndicator(color: Color(0xFF2B5CFF))) : _filtered.isEmpty ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.people, size: 80, color: Colors.grey), SizedBox(height: 16), Text('Aucun abonné pour le moment')])) : RefreshIndicator(onRefresh: _load, child: ListView.builder(padding: const EdgeInsets.all(12), itemCount: _filtered.length, itemBuilder: (_,i){
          final item = _filtered[i];
          final p = item['profiles'] as Map?;
          final fid = item['follower_id'] as String;
          final avatar = p?['photo_url'] ?? p?['avatar_url'];
          final name = p?['display_name'] ?? 'Utilisateur';
          final followsBack = _myFollowing.contains(fid);
          return Container(margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)]), child: ListTile(
            leading: CircleAvatar(radius: 22, backgroundColor: Colors.grey.shade200, child: ClipOval(child: avatar!=null ? Image.network(avatar, width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (_,__,___)=> const Icon(Icons.person)) : const Icon(Icons.person)))),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(p?['profession']??'', style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: isOwner ? Row(mainAxisSize: MainAxisSize.min, children: [
              if(fid != widget.userId) ElevatedButton(onPressed: ()=> _toggleFollow(fid), style: ElevatedButton.styleFrom(backgroundColor: followsBack ? Colors.grey.shade200 : const Color(0xFF2B5CFF), foregroundColor: followsBack ? Colors.black : Colors.white, minimumSize: const Size(80, 32), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 12)), child: Text(followsBack ? 'Suivi' : 'Suivre', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
              IconButton(icon: const Icon(Icons.close, size: 18), onPressed: ()=> _removeFollower(fid)),
            ]) : ElevatedButton(onPressed: fid==Supabase.instance.client.auth.currentUser?.id ? null : ()=> _toggleFollow(fid), style: ElevatedButton.styleFrom(backgroundColor: followsBack ? Colors.grey.shade200 : const Color(0xFF2B5CFF), foregroundColor: followsBack ? Colors.black : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: Text(followsBack ? 'Suivi' : 'Suivre', style: const TextStyle(fontSize: 11))),
            onTap: ()=> context.push('/network/member/$fid'),
          ));
        }))),
      ]),
    );
  }
}
