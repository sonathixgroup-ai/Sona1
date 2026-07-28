import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/chat/connection_service.dart';

class _C {
  static const bg = Color(0xFF050508);
  static const surface = Color(0xFF0C0C12);
  static const cardBorder = Color(0x14FFFFFF);
  static const violet = Color(0xFF7C5CFF);
  static const white = Colors.white;
  static const textMuted = Color(0x66FFFFFF);
  static const textSecondary = Color(0x99FFFFFF);
  static const red = Color(0xFFFF0A54);
  static const green = Color(0xFF10B981);
}

class ConnectionsState {
  final List<ConnectionRequest> received;
  final List<ConnectionRequest> sent;
  final List<dynamic> connections;
  final bool loading;
  final bool loadingMore;
  final bool hasMoreConnections;
  final String? error;
  const ConnectionsState({this.received = const [], this.sent = const [], this.connections = const [], this.loading = true, this.loadingMore = false, this.hasMoreConnections = true, this.error});
  ConnectionsState copyWith({List<ConnectionRequest>? received, List<ConnectionRequest>? sent, List<dynamic>? connections, bool? loading, bool? loadingMore, bool? hasMoreConnections, String? error}) => ConnectionsState(received: received?? this.received, sent: sent?? this.sent, connections: connections?? this.connections, loading: loading?? this.loading, loadingMore: loadingMore?? this.loadingMore, hasMoreConnections: hasMoreConnections?? this.hasMoreConnections, error: error);
}

class ConnectionsNotifier extends StateNotifier<ConnectionsState> {
  final ConnectionService _svc;
  static const _limit = 20;
  ConnectionsNotifier(this._svc) : super(const ConnectionsState()) { loadInitial(); }

  Future<void> loadInitial() async {
    state = state.copyWith(loading: true);
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) { state = state.copyWith(loading: false); return; }
    try {
      await _svc.loadData(uid, limit: _limit, offset: 0);
      state = ConnectionsState(
        received: _svc.receivedRequests,
        sent: _svc.sentRequests,
        connections: _svc.connections,
        loading: false,
        hasMoreConnections: _svc.connections.length == _limit,
      );
    } catch (e) { state = state.copyWith(loading: false, error: e.toString()); }
  }

  Future<void> loadMoreConnections() async {
    if (state.loadingMore ||!state.hasMoreConnections) return;
    state = state.copyWith(loadingMore: true);
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) { state = state.copyWith(loadingMore: false); return; }
    try {
      final more = await _svc.loadMoreConnections(uid, offset: state.connections.length, limit: _limit);
      state = state.copyWith(connections: [...state.connections,...more], hasMoreConnections: more.length == _limit, loadingMore: false);
    } catch (_) { state = state.copyWith(loadingMore: false); }
  }

  Future<bool> accept(String id) async {
    final uid = Supabase.instance.client.auth.currentUser?.id; if (uid==null) return false;
    final ok = await _svc.acceptRequest(id, uid); if (ok) await loadInitial(); return ok;
  }
  Future<bool> reject(String id) async {
    final uid = Supabase.instance.client.auth.currentUser?.id; if (uid==null) return false;
    final ok = await _svc.rejectRequest(id, uid); if (ok) await loadInitial(); return ok;
  }
  Future<bool> cancel(String id) async {
    final uid = Supabase.instance.client.auth.currentUser?.id; if (uid==null) return false;
    final ok = await _svc.cancelRequest(id, uid); if (ok) await loadInitial(); return ok;
  }
}

final connectionsProvider = StateNotifierProvider<ConnectionsNotifier, ConnectionsState>((ref) => ConnectionsNotifier(ConnectionService()));

class ConnectionsPage extends ConsumerStatefulWidget {
  const ConnectionsPage({super.key});
  @override ConsumerState<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends ConsumerState<ConnectionsPage> {
  final _scroll = ScrollController();
  @override void initState() { super.initState(); _scroll.addListener(() { if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) ref.read(connectionsProvider.notifier).loadMoreConnections(); }); }
  @override void dispose() { _scroll.dispose(); super.dispose(); }

  Future<void> _confirmCancel(String id) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: _C.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color:_C.cardBorder)),
      title: const Text('Annuler la demande?', style: TextStyle(color:Colors.white,fontWeight:FontWeight.w800,fontSize:13)),
      content: const Text('Irréversible.', style: TextStyle(color:_C.textSecondary,fontSize:11)),
      actions: [TextButton(onPressed:()=> Navigator.pop(ctx,false), child: const Text('Non',style:TextStyle(color:_C.textMuted))), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor:_C.red), onPressed:()=> Navigator.pop(ctx,true), child: const Text('Oui, annuler',style:TextStyle(color:Colors.white,fontSize:11)))],
    ));
    if (ok==true) { final svc = ref.read(connectionsProvider.notifier); final res = await svc.cancel(id); if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res?'Demande annulée':'Erreur'), backgroundColor: res? _C.red : _C.red)); }
  }

  @override Widget build(BuildContext context) {
    final state = ref.watch(connectionsProvider);
    final notifier = ref.read(connectionsProvider.notifier);

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: ClipRRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX:20,sigmaY:20), child: AppBar(backgroundColor:_C.bg.withOpacity(0.85), elevation:0, leading: IconButton(icon: const Icon(Icons.arrow_back_rounded,color:Colors.white,size:18), onPressed:()=> Navigator.pop(context)), title: const Text('Connexions',style:TextStyle(color:Colors.white,fontSize:13,fontWeight:FontWeight.w800)), actions: [IconButton(icon: const Icon(Icons.refresh_rounded,color:Colors.white,size:18), onPressed:()=> notifier.loadInitial())]))),
      ),
      body: state.loading? const Center(child: CircularProgressIndicator(color:_C.violet,strokeWidth:2)) : RefreshIndicator(
        color: Colors.white, backgroundColor: _C.surface,
        onRefresh: () async => notifier.loadInitial(),
        child: ListView(
          controller: _scroll,
          padding: const EdgeInsets.all(12),
          children: [
            if (state.received.isNotEmpty)...[
              _section('Demandes reçues (${state.received.length})'),
             ...state.received.map((r) => _reqCard(name: r.sender?['display_name']??'Inconnu', sub: r.message??'Souhaite vous contacter', onAccept: () async { final ok = await notifier.accept(r.id); if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok?'Connexion acceptée':'Erreur'), backgroundColor: ok? _C.green : _C.red)); }, onReject: () async { final ok = await notifier.reject(r.id); if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok?'Demande refusée':'Erreur'), backgroundColor: Colors.orange)); })),
              const SizedBox(height:8),
            ],
            if (state.sent.isNotEmpty)...[
              _section('Demandes envoyées'),
             ...state.sent.map((r) => _reqCard(name: r.receiver?['display_name']??'Inconnu', sub: 'En attente...', onCancel: ()=> _confirmCancel(r.id))),
              const SizedBox(height:8),
            ],
            _section('Vos connexions (${state.connections.length})'),
            if (state.connections.isEmpty) Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color:_C.surface,borderRadius:BorderRadius.circular(14),border:Border.all(color:_C.cardBorder)), child: const Center(child: Text('Aucune connexion',style:TextStyle(color:_C.textMuted,fontSize:11)))),
           ...state.connections.map((c) => Container(
              margin: const EdgeInsets.only(bottom:8),
              decoration: BoxDecoration(color:_C.surface,borderRadius:BorderRadius.circular(14),border:Border.all(color:_C.cardBorder)),
              child: ListTile(
                leading: CircleAvatar(radius:18,backgroundColor:_C.violet.withOpacity(0.14),child:Text((c['display_name']??'?')[0].toUpperCase(),style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800,fontSize:12))),
                title: Text(c['display_name']??'Inconnu',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w700,fontSize:12)),
                subtitle: Text('@${c['username']??''}',style:const TextStyle(color:_C.textMuted,fontSize:10)),
                trailing: const Icon(Icons.chevron_right_rounded,color:_C.textMuted,size:18),
                onTap: (){},
              ),
            )),
            if (state.loadingMore) const Padding(padding:EdgeInsets.all(20),child:Center(child:CircularProgressIndicator(color:_C.violet,strokeWidth:2))),
            const SizedBox(height:80),
          ],
        ),
      ),
    );
  }

  Widget _section(String t) => Padding(padding: const EdgeInsets.only(top:12,bottom:8,left:4), child: Text(t,style: const TextStyle(color:Colors.white,fontWeight:FontWeight.w800,fontSize:12)));
  Widget _reqCard({required String name, required String sub, VoidCallback? onAccept, VoidCallback? onReject, VoidCallback? onCancel}) => Container(
    margin: const EdgeInsets.only(bottom:8),
    decoration: BoxDecoration(color:_C.surface,borderRadius:BorderRadius.circular(14),border:Border.all(color:_C.cardBorder)),
    child: ListTile(
      leading: CircleAvatar(radius:18,backgroundColor:_C.violet.withOpacity(0.14),child:Text(name.isNotEmpty? name[0].toUpperCase():'?',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800,fontSize:12))),
      title: Text(name,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w700,fontSize:12)),
      subtitle: Text(sub,style:const TextStyle(color:_C.textMuted,fontSize:10),maxLines:1,overflow:TextOverflow.ellipsis),
      trailing: onCancel!=null? IconButton(icon: const Icon(Icons.close_rounded,color:_C.textMuted,size:18), onPressed: onCancel) : Row(mainAxisSize:MainAxisSize.min,children:[IconButton(icon: const Icon(Icons.check_rounded,color:_C.green,size:18), onPressed: onAccept), IconButton(icon: const Icon(Icons.close_rounded,color:_C.textMuted,size:18), onPressed: onReject)]),
    ),
  );
}
