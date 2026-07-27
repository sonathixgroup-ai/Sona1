import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key});
  @override State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  List<Map<String, dynamic>> _blocked = [];
  bool _loading = true;
  Set<String> _processing = {};

  @override void initState(){ super.initState(); _load(); }

  Future<void> _load() async {
    if(mounted) setState(()=> _loading=true);
    final supa = Supabase.instance.client;
    final uid = supa.auth.currentUser?.id;
    if(uid==null){ if(mounted) setState(()=> _loading=false); return; }
    try{
      // essaie users puis profiles pour compatibilité
      List data = [];
      try{
        final r = await supa.from('blocked_users').select('blocked_user_id, users!blocked_user_id(id, display_name, photo_url, avatar_url, profession)').eq('user_id', uid);
        data = r as List;
        _blocked = data.map((e)=> (e['users'] as Map<String,dynamic>?)?? {'id': e['blocked_user_id']}).toList();
      }catch(_){
        final r2 = await supa.from('blocked_users').select('blocked_user_id, profiles!blocked_user_id(id, display_name, photo_url, avatar_url, profession)').eq('user_id', uid);
        data = r2 as List;
        _blocked = data.map((e)=> (e['profiles'] as Map<String,dynamic>?)?? {'id': e['blocked_user_id']}).toList();
      }
      if(mounted) setState(()=> _loading=false);
    }catch(e){
      debugPrint('blocked load err $e');
      if(mounted) setState(()=> _loading=false);
    }
  }

  Future<void> _unblock(String id, String name) async {
    final ok = await showDialog<bool>(context: context, builder: (_)=> AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: const Text('Débloquer'), content: Text('Débloquer $name?'), actions: [TextButton(onPressed: ()=> Navigator.pop(context,false), child: const Text('Annuler')), ElevatedButton(onPressed: ()=> Navigator.pop(context,true), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), child: const Text('Débloquer'))]));
    if(ok!=true) return;
    setState(()=> _processing.add(id));
    try{
      await Supabase.instance.client.from('blocked_users').delete().eq('user_id', Supabase.instance.client.auth.currentUser!.id).eq('blocked_user_id', id);
      if(mounted) setState(()=> {_blocked.removeWhere((u)=> u['id']==id); _processing.remove(id);});
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Utilisateur débloqué'), backgroundColor: Colors.green));
    }catch(e){
      if(mounted) setState(()=> _processing.remove(id));
    }
  }

  Future<void> _unblockAll() async {
    if(_blocked.isEmpty) return;
    final ok = await showDialog<bool>(context: context, builder: (_)=> AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: const Text('Tout débloquer'), content: const Text('Débloquer tous? Action irréversible.'), actions: [TextButton(onPressed: ()=> Navigator.pop(context,false), child: const Text('Annuler')), ElevatedButton(onPressed: ()=> Navigator.pop(context,true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Tout débloquer'))]));
    if(ok!=true) return;
    setState(()=> _processing = _blocked.map((e)=> e['id'] as String).toSet());
    try{
      await Supabase.instance.client.from('blocked_users').delete().eq('user_id', Supabase.instance.client.auth.currentUser!.id);
      if(mounted) setState(()=> {_blocked.clear(); _processing.clear();});
    }catch(_){ if(mounted) setState(()=> _processing.clear()); }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0.5, title: const Text('Utilisateurs bloqués', style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold, fontSize: 18)), leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A1A2E), size: 20), onPressed: ()=> context.pop()), actions: [if(_blocked.isNotEmpty &&!_loading) TextButton(onPressed: _processing.isNotEmpty? null : _unblockAll, child: Text('Tout débloquer', style: TextStyle(color: _processing.isNotEmpty? Colors.grey.shade400 : const Color(0xFFD4AF37), fontWeight: FontWeight.w600)))]),
      body: _loading? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))) : _blocked.isEmpty? _empty() : RefreshIndicator(onRefresh: _load, color: const Color(0xFFD4AF37), child: ListView.builder(padding: const EdgeInsets.all(16), itemCount: _blocked.length, itemBuilder: (_,i)=> _tile(_blocked[i]))),
    );
  }

  Widget _empty()=> Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(padding: const EdgeInsets.all(32), decoration: BoxDecoration(color: const Color(0xFFD4AF37).withValues(alpha: 0.08), shape: BoxShape.circle), child: const Icon(Icons.block, size: 64, color: Color(0xFFD4AF37))), const SizedBox(height: 16), const Text('Aucun utilisateur bloqué', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))), const SizedBox(height: 8), const Text('Les utilisateurs bloqués apparaîtront ici.', style: TextStyle(color: Colors.grey)), const SizedBox(height: 24), ElevatedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Rafraîchir'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))))]));

  Widget _tile(Map<String,dynamic> u){
    final id = u['id'] as String;
    final name = (u['display_name']??'Utilisateur') as String;
    final photo = (u['photo_url']?? u['avatar_url']) as String?;
    final job = u['profession'] as String?;
    final proc = _processing.contains(id);
    return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0,2))]), child: Row(children: [
      CircleAvatar(radius: 26, backgroundColor: Colors.grey.shade200, child: ClipOval(child: photo!=null && photo.isNotEmpty? Image.network(photo, width: 52, height: 52, fit: BoxFit.cover, errorBuilder: (_,__,___)=> Text(name.isNotEmpty? name[0].toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.bold))) : Text(name.isNotEmpty? name[0].toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.bold))))),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1A1A2E)), maxLines: 1, overflow: TextOverflow.ellipsis), if(job!=null && job.isNotEmpty) Text(job, style: TextStyle(fontSize: 13, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis)])),
      SizedBox(height: 36, child: OutlinedButton(onPressed: proc? null : ()=> _unblock(id, name), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.green), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 16)), child: proc? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green)) : const Text('Débloquer', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 12)))),
    ]));
  }
}
