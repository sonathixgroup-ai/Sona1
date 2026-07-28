import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/chat/chat_service.dart';
import '../../services/chat/connection_service.dart';
import 'chat_screen.dart';

class _C {
  static const bg = Color(0xFF050508);
  static const surface = Color(0xFF0C0C12);
  static const surfaceAlt = Color(0xFF111118);
  static const cardBorder = Color(0x14FFFFFF);
  static const violet = Color(0xFF7C5CFF);
  static const gold = Color(0xFFE3B23C);
  static const white = Colors.white;
  static const textMuted = Color(0x66FFFFFF);
  static const textSecondary = Color(0x99FFFFFF);
  static const red = Color(0xFFFF0A54);
  static const green = Color(0xFF10B981);
}

class NewConvState {
  final List<Map<String, dynamic>> results;
  final List<Map<String, dynamic>> selected;
  final Map<String, String> connStatus;
  final bool isLoading;
  final bool isCreating;
  final bool hasMore;
  final String query;
  final String groupName;
  const NewConvState({this.results = const [], this.selected = const [], this.connStatus = const {}, this.isLoading = false, this.isCreating = false, this.hasMore = true, this.query = '', this.groupName = ''});
  NewConvState copyWith({List<Map<String, dynamic>>? results, List<Map<String, dynamic>>? selected, Map<String,String>? connStatus, bool? isLoading, bool? isCreating, bool? hasMore, String? query, String? groupName}) => NewConvState(results: results?? this.results, selected: selected?? this.selected, connStatus: connStatus?? this.connStatus, isLoading: isLoading?? this.isLoading, isCreating: isCreating?? this.isCreating, hasMore: hasMore?? this.hasMore, query: query?? this.query, groupName: groupName?? this.groupName);
}

class NewConvNotifier extends StateNotifier<NewConvState> {
  final SupabaseClient supabase;
  final ConnectionService connSvc;
  static const _limit = 25;
  int _offset = 0;
  Timer? _debounce;
  NewConvNotifier(this.supabase, this.connSvc) : super(const NewConvState());

  void setGroupName(String v) => state = state.copyWith(groupName: v);

  void search(String raw) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _doSearch(raw.trim(), reset: true));
  }

  Future<void> _doSearch(String q, {bool reset = false}) async {
    if (q.isEmpty) { state = state.copyWith(results: [], query: '', hasMore: true, isLoading: false); return; }
    if (reset) { _offset = 0; state = state.copyWith(query: q, isLoading: true, hasMore: true); }
    try {
      // scalable: ilike avec limit + offset, 2 queries fusionnées puis dedup
      final exact = await supabase.from('profiles').select('id, display_name, avatar_url, profession, thix_chat').ilike('thix_chat', '%$q%').range(_offset, _offset + 4);
      final names = await supabase.from('profiles').select('id, display_name, avatar_url, profession, thix_chat').ilike('display_name', '%$q%').range(_offset, _offset + _limit - 1);

      final seen = <String>{...state.selected.map((e)=> e['id'] as String)};
      final merged = <Map<String,dynamic>>[];
      for (var r in [...exact,...names]) {
        final id = r['id'] as String;
        if (!seen.contains(id)) { seen.add(id); merged.add(Map<String,dynamic>.from(r)); }
      }
      // cache status
      await _loadStatus(merged);

      final finalList = reset? merged : [...state.results,...merged];
      // dedup results
      final deduped = <String, Map<String,dynamic>>{};
      for (var e in finalList) deduped[e['id']] = e;

      state = state.copyWith(results: deduped.values.where((e)=>!state.selected.any((s)=> s['id']==e['id'])).toList(), isLoading: false, hasMore: merged.length == _limit);
      _offset += _limit;
    } catch (_) { state = state.copyWith(isLoading: false); }
  }

  Future<void> loadMore() async {
    if (state.isLoading ||!state.hasMore || state.query.isEmpty) return;
    state = state.copyWith(isLoading: true);
    await _doSearch(state.query, reset: false);
  }

  Future<void> _loadStatus(List<Map<String,dynamic>> users) async {
    final cur = supabase.auth.currentUser?.id;
    if (cur==null) return;
    final map = Map<String,String>.from(state.connStatus);
    for (var u in users) {
      final id = u['id'] as String;
      if (id==cur || map.containsKey(id)) continue;
      map[id] = await connSvc.getStatusBetween(cur, id);
    }
    state = state.copyWith(connStatus: map);
  }

  void toggleSelect(Map<String,dynamic> user) {
    final exists = state.selected.any((s)=> s['id']==user['id']);
    List<Map<String,dynamic>> sel;
    List<Map<String,dynamic>> res = List.from(state.results);
    if (exists) {
      sel = state.selected.where((s)=> s['id']!=user['id']).toList();
      res = [...res, user];
    } else {
      sel = [...state.selected, user];
      res = res.where((r)=> r['id']!=user['id']).toList();
    }
    state = state.copyWith(selected: sel, results: res);
  }

  void addSelectedForSingle(Map<String,dynamic> user) {
    if (state.selected.isEmpty) state = state.copyWith(selected: [user], results: state.results.where((r)=> r['id']!=user['id']).toList());
  }

  void setCreating(bool v) => state = state.copyWith(isCreating: v);
  void updateStatus(String userId, String status) {
    final m = Map<String,String>.from(state.connStatus)..[userId]=status;
    state = state.copyWith(connStatus: m);
  }

  @override void dispose() { _debounce?.cancel(); super.dispose(); }
}

final newConvProvider = StateNotifierProvider<NewConvNotifier, NewConvState>((ref) {
  return NewConvNotifier(Supabase.instance.client, ConnectionService());
});

class NewConversationPage extends ConsumerStatefulWidget {
  const NewConversationPage({super.key});
  @override ConsumerState<NewConversationPage> createState() => _NewConversationPageState();
}

class _NewConversationPageState extends ConsumerState<NewConversationPage> {
  final _searchCtrl = TextEditingController();
  final _scroll = ScrollController();
  late ChatService _chatService;

  @override void initState() {
    super.initState();
    _chatService = ChatService(Supabase.instance.client);
    _scroll.addListener(() { if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) ref.read(newConvProvider.notifier).loadMore(); });
  }
  @override void dispose() { _searchCtrl.dispose(); _scroll.dispose(); super.dispose(); }

  (String, Color) _statusDisplay(String? s) {
    switch(s) {
      case 'connected': return ('Connecté', _C.green);
      case 'pending': return ('En attente', Colors.orange);
      case 'rejected': return ('Refusé', _C.red);
      default: return ('', Colors.transparent);
    }
  }

  void _onUserTap(Map<String,dynamic> user) {
    final state = ref.read(newConvProvider);
    final curId = Supabase.instance.client.auth.currentUser?.id;
    if (user['id']==curId) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Pas vous-même'))); return; }
    final status = state.connStatus[user['id']]??'none';
    if (status=='connected') {
      if (state.selected.isEmpty) { ref.read(newConvProvider.notifier).addSelectedForSingle(user); _startChat(); }
      else ref.read(newConvProvider.notifier).toggleSelect(user);
    } else if (status=='pending') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Demande en attente'),backgroundColor:Colors.orange));
    } else if (status=='rejected') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Refusé'),backgroundColor:_C.red));
    } else _showRequestDialog(user);
  }

  void _showRequestDialog(Map<String,dynamic> user) {
    final msgCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: _C.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color:_C.cardBorder)),
      title: Row(children:[CircleAvatar(radius:16,backgroundColor:_C.violet,backgroundImage: user['avatar_url']!=null? NetworkImage(user['avatar_url']) : null), const SizedBox(width:8), Expanded(child: Text('Demander à ${user['display_name']}',style:const TextStyle(color:Colors.white,fontSize:13,fontWeight:FontWeight.w800)))]),
      content: Column(mainAxisSize:MainAxisSize.min,children:[const Text('Envoyez une demande pour discuter.',style:TextStyle(color:_C.textSecondary,fontSize:11)), const SizedBox(height:12), TextField(controller:msgCtrl,style:const TextStyle(color:Colors.white,fontSize:12),maxLines:3,decoration:InputDecoration(hintText:'Message optionnel',hintStyle:const TextStyle(color:_C.textMuted,fontSize:11),filled:true,fillColor:_C.bg,border:OutlineInputBorder(borderRadius:BorderRadius.circular(12),borderSide:const BorderSide(color:_C.cardBorder))))]),
      actions:[TextButton(onPressed:()=> Navigator.pop(ctx), child:const Text('Annuler',style:TextStyle(color:_C.textMuted))), ElevatedButton(style:ElevatedButton.styleFrom(backgroundColor:Colors.white,foregroundColor:Colors.black), onPressed:() async { Navigator.pop(ctx); await _sendRequest(user, msgCtrl.text.trim()); }, child:const Text('Envoyer',style:TextStyle(fontSize:11,fontWeight:FontWeight.w800)))],
    ));
  }

  Future<void> _sendRequest(Map<String,dynamic> user, String msg) async {
    final cur = Supabase.instance.client.auth.currentUser?.id; if (cur==null) return;
    final svc = ConnectionService();
    final ok = await svc.sendRequest(senderId: cur, receiverId: user['id'], message: msg.isNotEmpty? msg : null);
    if (ok) { ref.read(newConvProvider.notifier).updateStatus(user['id'], 'pending'); if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Demande envoyée'),backgroundColor:_C.green)); }
    else if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(svc.error??'Déjà existante'),backgroundColor:_C.red));
  }

  Future<void> _startChat() async {
    final state = ref.read(newConvProvider);
    if (state.selected.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Sélectionnez une personne'))); return; }
    final cur = Supabase.instance.client.auth.currentUser?.id; if (cur==null) return;
    final notConnected = state.selected.where((u){ final s = state.connStatus[u['id']]??'none'; return s!='connected'; }).toList();
    if (notConnected.isNotEmpty) { final names = notConnected.map((u)=> u['display_name']).join(', '); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Non connecté: $names'),backgroundColor:Colors.orange)); return; }
    ref.read(newConvProvider.notifier).setCreating(true);
    try {
      final ids = [...state.selected.map((u)=> u['id'] as String), cur];
      final conv = await _chatService.createConversation(participantIds: ids.toSet().toList(), isGroup: state.selected.length>1, groupName: state.selected.length>1? state.groupName.trim() : null);
      if(mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder:(_)=> ChatScreen(conversationId: conv.id, conversation: conv)));
    } catch(e){ if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Erreur: $e'),backgroundColor:_C.red)); }
    finally { ref.read(newConvProvider.notifier).setCreating(false); }
  }

  @override Widget build(BuildContext context) {
    final state = ref.watch(newConvProvider);
    final notifier = ref.read(newConvProvider.notifier);

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: PreferredSize(preferredSize: const Size.fromHeight(56), child: ClipRRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX:20,sigmaY:20), child: AppBar(backgroundColor:_C.bg.withOpacity(0.85), elevation:0, leading: IconButton(icon: const Icon(Icons.arrow_back_rounded,color:Colors.white,size:18), onPressed:()=> Navigator.pop(context)), title: const Text('Nouvelle conversation',style:TextStyle(color:Colors.white,fontSize:13,fontWeight:FontWeight.w800)), actions: [if(state.selected.isNotEmpty) state.isCreating? const Padding(padding:EdgeInsets.symmetric(horizontal:20),child:SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2,color:_C.violet))) : Padding(padding:const EdgeInsets.only(right:10),child: InkWell(onTap:_startChat,borderRadius:BorderRadius.circular(20),child:Container(padding:const EdgeInsets.symmetric(horizontal:14,vertical:7),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20)),child:Row(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.send_rounded,size:14,color:Colors.black),const SizedBox(width:6),Text('Démarrer (${state.selected.length})',style:const TextStyle(color:Colors.black,fontWeight:FontWeight.w800,fontSize:11))]))))])))),
      body: Column(children:[
        Padding(padding: const EdgeInsets.fromLTRB(12,12,12,0), child: Container(decoration:BoxDecoration(color:_C.surface,borderRadius:BorderRadius.circular(14),border:Border.all(color:_C.cardBorder)), child: TextField(controller:_searchCtrl,onChanged:(v)=> notifier.search(v),style:const TextStyle(color:Colors.white,fontSize:12,fontWeight:FontWeight.w600),decoration:InputDecoration(hintText:'Rechercher @THIX CHAT ou nom',hintStyle:const TextStyle(color:_C.textMuted,fontSize:11),prefixIcon:const Icon(Icons.search_rounded,color:_C.textMuted,size:18),suffixIcon: _searchCtrl.text.isNotEmpty? IconButton(icon: const Icon(Icons.clear_rounded,color:_C.textMuted,size:16),onPressed:(){ _searchCtrl.clear(); notifier.search(''); }) : null,border:InputBorder.none,contentPadding:const EdgeInsets.symmetric(vertical:12))))),
        if (state.selected.length>1) Padding(padding: const EdgeInsets.fromLTRB(12,10,12,0), child: Container(decoration:BoxDecoration(color:_C.surface,borderRadius:BorderRadius.circular(12),border:Border.all(color:_C.cardBorder)), child: TextField(onChanged:(v)=> notifier.setGroupName(v),style:const TextStyle(color:Colors.white,fontSize:12),decoration:const InputDecoration(hintText:'Nom du groupe (optionnel)',hintStyle:TextStyle(color:_C.textMuted,fontSize:11),prefixIcon:Icon(Icons.groups_rounded,color:_C.textMuted,size:18),border:InputBorder.none,contentPadding:EdgeInsets.symmetric(vertical:10))))),
        if (state.selected.isNotEmpty) Container(height:56,padding: const EdgeInsets.fromLTRB(12,10,12,0), child: ListView.builder(scrollDirection:Axis.horizontal,itemCount:state.selected.length,itemBuilder:(ctx,i){ final u=state.selected[i]; return Padding(padding:const EdgeInsets.only(right:8),child:Container(padding:const EdgeInsets.only(left:4,right:8),decoration:BoxDecoration(color:_C.surface,borderRadius:BorderRadius.circular(20),border:Border.all(color:_C.cardBorder)),child:Row(mainAxisSize:MainAxisSize.min,children:[CircleAvatar(radius:12,backgroundImage:u['avatar_url']!=null? NetworkImage(u['avatar_url']) : null,backgroundColor:_C.violet),const SizedBox(width:6),Text(u['display_name']??'',style:const TextStyle(color:Colors.white,fontSize:11,fontWeight:FontWeight.w700)),const SizedBox(width:4),InkWell(onTap:()=> notifier.toggleSelect(u),child:const Icon(Icons.close_rounded,size:14,color:_C.textMuted))]))); })),
        Expanded(child: state.isLoading && state.results.isEmpty? const Center(child:CircularProgressIndicator(color:_C.violet,strokeWidth:2)) : state.results.isEmpty? Center(child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Container(width:64,height:64,decoration:BoxDecoration(color:_C.surface,shape:BoxShape.circle,border:Border.all(color:_C.cardBorder)),child:const Icon(Icons.people_outline_rounded,color:_C.textMuted,size:28)),const SizedBox(height:12),Text(_searchCtrl.text.isEmpty? 'Recherchez un utilisateur' : 'Aucun résultat',style:const TextStyle(color:Colors.white,fontSize:12,fontWeight:FontWeight.w700))])) : ListView.separated(controller:_scroll,padding:const EdgeInsets.fromLTRB(12,12,12,80),itemCount:state.results.length + (state.hasMore?1:0),separatorBuilder:(_,__)=> const SizedBox(height:8),itemBuilder:(ctx,i){ if(i==state.results.length) return const Padding(padding:EdgeInsets.all(16),child:Center(child:CircularProgressIndicator(color:_C.violet,strokeWidth:2))); final user=state.results[i]; final id=user['id']; final isSel=state.selected.any((s)=> s['id']==id); final (label,color)=_statusDisplay(state.connStatus[id]); return InkWell(onTap:()=> _onUserTap(user),borderRadius:BorderRadius.circular(14),child:Container(padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:_C.surface,borderRadius:BorderRadius.circular(14),border:Border.all(color:isSel? _C.violet : _C.cardBorder,width:isSel?1.2:1)),child:Row(children:[CircleAvatar(radius:20,backgroundColor:_C.surfaceAlt,backgroundImage:user['avatar_url']!=null? NetworkImage(user['avatar_url']) : null,child:user['avatar_url']==null? const Icon(Icons.person_rounded,color:Colors.white,size:18) : null),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Flexible(child:Text(user['display_name']??'User',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w700,fontSize:12),overflow:TextOverflow.ellipsis)),const SizedBox(width:6),if(label.isNotEmpty) Container(padding:const EdgeInsets.symmetric(horizontal:6,vertical:2),decoration:BoxDecoration(color:color.withOpacity(0.12),borderRadius:BorderRadius.circular(10),border:Border.all(color:color.withOpacity(0.3))),child:Text(label,style:TextStyle(color:color,fontSize:8,fontWeight:FontWeight.w800)))]),if((user['profession']??'').toString().isNotEmpty) Text(user['profession'],style:const TextStyle(color:_C.textMuted,fontSize:10)),if(user['thix_chat']!=null) Text(user['thix_chat'],style:const TextStyle(color:_C.violet,fontSize:10,fontWeight:FontWeight.w700))])),if(label=='Connecté') isSel? const Icon(Icons.check_circle_rounded,color:_C.violet,size:20) : Container(padding:const EdgeInsets.all(5),decoration:BoxDecoration(color:_C.bg,shape:BoxShape.circle,border:Border.all(color:_C.cardBorder)),child:const Icon(Icons.add_rounded,color:Colors.white,size:16)) else if(label=='En attente') const Icon(Icons.hourglass_top_rounded,color:Colors.orange,size:16) else if(label=='Refusé') const Icon(Icons.block_rounded,color:_C.red,size:16) else IconButton(icon:const Icon(Icons.person_add_alt_1_rounded,color:_C.violet,size:18),onPressed:()=> _showRequestDialog(user))]))); })),
      ]),
    );
  }
}
