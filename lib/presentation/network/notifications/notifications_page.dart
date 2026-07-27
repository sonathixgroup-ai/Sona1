import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/services/network_service.dart';
import 'package:thix_id/models/network_notification.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> with SingleTickerProviderStateMixin {
  late NetworkService _networkService;
  List<NetworkNotification> _all = [], _filtered = [];
  bool _loading = true;
  String _filter = 'all';
  late TabController _tab;

  @override void initState(){
    super.initState();
    _tab = TabController(length: 5, vsync: this);
    _networkService = NetworkService(Supabase.instance.client);
    _load();
  }
  @override void dispose(){ _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(()=> _loading=true);
    try{
      final notifs = await _networkService.getNotifications();
      if(!mounted) return;
      setState((){
        _all = notifs;
        _applyFilter();
        _loading=false;
      });
      await _networkService.markAllNotificationsAsRead();
    }catch(e){
      debugPrint('notif err $e');
      if(mounted) setState(()=> _loading=false);
    }
  }

  void _applyFilter(){
    if(_filter=='all') _filtered = _all;
    else _filtered = _all.where((n)=> n.type==_filter).toList();
  }

  void _handleTap(NetworkNotification n){
    if(n.type=='connection_request' && n.actorId!=null) context.push('/network/member/${n.actorId}');
    else if(n.postId!=null) context.push('/network/post/${n.postId}');
    else if(n.actorId!=null) context.push('/network/member/${n.actorId}');
  }

  Future<void> _delete(String id) async {
    setState((){
      _all.removeWhere((e)=> e.id==id);
      _applyFilter();
    });
    try{ await Supabase.instance.client.from('notifications').delete().eq('id', id); }catch(_){}
  }

  String _fmt(DateTime d){
    final diff = DateTime.now().difference(d);
    if(diff.inDays>7) return '${d.day}/${d.month}/${d.year}';
    if(diff.inDays>0) return 'il y a ${diff.inDays}j';
    if(diff.inHours>0) return 'il y a ${diff.inHours}h';
    if(diff.inMinutes>0) return 'il y a ${diff.inMinutes}min';
    return 'à l\'instant';
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, title: const Text('Notifications', style: TextStyle(color: Color(0xFF0B1B3D), fontWeight: FontWeight.bold)), bottom: TabBar(controller: _tab, isScrollable: true, onTap: (i){
        const types = ['all','like','comment','connection_request','connection_accepted'];
        _filter = types[i];
        setState(()=> _applyFilter());
      }, labelColor: const Color(0xFF2B5CFF), indicatorColor: const Color(0xFF2B5CFF), tabs: const [Tab(text: 'Tout'), Tab(text: 'Likes'), Tab(text: 'Comms'), Tab(text: 'Invits'), Tab(text: 'Acceptées')]))),
      body: _loading? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))) : _filtered.isEmpty? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade400), const SizedBox(height: 16), const Text('Aucune notification', style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(_filter=='all'? 'Les notifications apparaîtront ici' : 'Aucune notif de type $_filter', style: TextStyle(color: Colors.grey.shade600))])) : RefreshIndicator(onRefresh: _load, color: const Color(0xFFD4AF37), child: ListView.separated(itemCount: _filtered.length, separatorBuilder: (_, __)=> Divider(height: 0, color: Colors.grey.shade200), itemBuilder: (_,i)=> _tile(_filtered[i]))),
    );
  }

  Widget _tile(NetworkNotification n){
    IconData icon; Color color;
    switch(n.type){
      case 'like': icon=Icons.favorite; color=Colors.red; break;
      case 'comment': icon=Icons.comment; color=Colors.blue; break;
      case 'connection_request': icon=Icons.person_add; color=Colors.green; break;
      case 'connection_accepted': icon=Icons.people; color=const Color(0xFFD4AF37); break;
      default: icon=Icons.notifications; color=Colors.grey;
    }
    return Dismissible(key: ValueKey(n.id), direction: DismissDirection.endToStart, onDismissed: (_)=> _delete(n.id), background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16), child: const Icon(Icons.delete, color: Colors.white)), child: GestureDetector(onTap: ()=> _handleTap(n), child: Container(padding: const EdgeInsets.all(16), color: n.isRead==false? Colors.white : Colors.transparent, child: Row(children: [
      Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(n.title, style: TextStyle(fontWeight: n.isRead==false? FontWeight.bold : FontWeight.w600, fontSize: 14)), const SizedBox(height: 2), Text(n.body, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), maxLines: 2, overflow: TextOverflow.ellipsis), const SizedBox(height: 4), Text(_fmt(n.createdAt), style: TextStyle(fontSize: 10, color: Colors.grey.shade500))])),
      if(n.isRead==false) Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFD4AF37), shape: BoxShape.circle)),
    ]))));
  }
}
