import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/chat/chat_service.dart';
import '../../services/chat/presence_service.dart';
import '../../models/chat/chat_conversation.dart';
import 'chat_screen.dart';
import 'new_conversation_page.dart';
import 'package:thix_id/presentation/chat/screens/group_create_page.dart';

class _C {
  static const blue = Color(0xFF3B82F6);
  static const blueLight = Color(0xFF5B9CF6);
  static const blueSoft = Color(0xFFE9F0FF);
  static const bg = Color(0xFFF5F7FF);
  static const white = Colors.white;
  static const textDark = Color(0xFF0F172A);
  static const textMuted = Color(0xFF94A3B8);
  static const border = Color(0xFFE2E8F0);
}

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});
  @override State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  late ChatService _chatService; late PresenceService _presenceService;
  final _searchCtrl = TextEditingController();
  List<ChatConversation> _all = []; List<ChatConversation> _filtered = [];
  bool _isLoading = true; int _selectedFilter = 0; int _selectedNav = 1;
  int _pendingEscalationsCount = 0;

  @override void initState(){ super.initState(); _chatService=ChatService(Supabase.instance.client); _presenceService=PresenceService(Supabase.instance.client); _load(); _presenceService.initPresence(); }
  @override void dispose(){ _searchCtrl.dispose(); _presenceService.dispose(); super.dispose(); }

  Future<void> _load() async {
    if(mounted) setState(()=>_isLoading=true);
    try{
      final convs=await _chatService.getConversations(); int pending=0;
      final u=Supabase.instance.client.auth.currentUser;
      if(u!=null){ try{ final r=await Supabase.instance.client.from('escalation_steps').select('id').eq('to_agent_id',u.id).eq('status',0).count(); pending=(r.count as int?)??0; }catch(_){} }
      if(!mounted) return; setState((){_all=convs; _filtered=convs; _pendingEscalationsCount=pending; _isLoading=false;}); _applyFilter();
    }catch(_){ if(mounted) setState(()=>_isLoading=false); }
  }
  void _onSearch(String v){ final q=v.trim().toLowerCase(); setState(()=>_filtered=_all.where((c)=>c.displayName.toLowerCase().contains(q)||(c.lastMessage?.content??'').toLowerCase().contains(q)).toList()); _applyFilter(); }
  void _applyFilter(){ final base=_searchCtrl.text.trim().isEmpty?_all:_filtered; List<ChatConversation> r=base; switch(_selectedFilter){ case 1: r=base.where((c)=>c.isGroup).toList(); break; case 2: r=base.where((c)=>!c.isGroup).toList(); break; case 3: r=base.where((c)=>c.unreadCount>0).toList(); break; } if(!mounted) return; setState(()=>_filtered=r); }

  @override Widget build(BuildContext context){
    final unread=_all.fold<int>(0,(s,c)=>s+c.unreadCount);
    return Scaffold(
      backgroundColor: _C.bg,
      bottomNavigationBar: _bottomNotchPro(unread),
      body: _isLoading? const Center(child:CircularProgressIndicator(color:_C.blue))
      : RefreshIndicator(onRefresh:_load, color:_C.blue, child: Stack(children:[
        Container(height: 210, decoration: const BoxDecoration(gradient: LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[_C.blue,_C.blueLight]))),
        CustomScrollView(physics: const BouncingScrollPhysics(parent:AlwaysScrollableScrollPhysics()), slivers:[
          SliverToBoxAdapter(child: _headerTHIX()),
          SliverToBoxAdapter(child: _searchField()),
          SliverToBoxAdapter(child: _whiteSheet()),
          SliverToBoxAdapter(child: _filters()),
          const SliverToBoxAdapter(child: SizedBox(height:6)),
          _chatList(),
          const SliverToBoxAdapter(child:SizedBox(height:120)),
        ]),
      ])),
    );
  }

  // HEADER: THIX CHAT + search réduit + escalation VERTICAL + notif
  Widget _headerTHIX(){
    return SafeArea(bottom:false, child: Padding(padding: const EdgeInsets.fromLTRB(16,12,12,10), child: Row(children:[
      const Text('THIX CHAT', style:TextStyle(fontSize:18, fontWeight:FontWeight.w900, color:Colors.white, letterSpacing:-.3)),
      const Spacer(),
      // search réduit
      InkWell(onTap:(){}, borderRadius:BorderRadius.circular(20), child: Container(width:30,height:30, decoration:BoxDecoration(color:Colors.white.withOpacity(.20), shape:BoxShape.circle, border:Border.all(color:Colors.white.withOpacity(.35),width:.8)), child:const Icon(Icons.search_rounded,color:Colors.white,size:15))),
      const SizedBox(width:8),
      // escalation VERTICAL
      Stack(clipBehavior:Clip.none, children:[
        InkWell(onTap:()=>context.pushNamed('chatEscalationReceived'), borderRadius:BorderRadius.circular(20), child: Container(width:32,height:32, decoration:BoxDecoration(color:Colors.white,shape:BoxShape.circle, boxShadow:[BoxShadow(color:Colors.black.withOpacity(.08),blurRadius:6)]), child:const Icon(Icons.swap_vert_rounded,size:16,color:_C.blue))),
        if(_pendingEscalationsCount>0) Positioned(right:-3,top:-4, child: Container(constraints:const BoxConstraints(minWidth:14,minHeight:14), padding:const EdgeInsets.symmetric(horizontal:3), decoration:BoxDecoration(color:const Color(0xFFEF4444),borderRadius:BorderRadius.circular(8),border:Border.all(color:Colors.white,width:1.2)), child:Text('$_pendingEscalationsCount',textAlign:TextAlign.center,style:const TextStyle(color:Colors.white,fontSize:7.5,fontWeight:FontWeight.w800)))),
      ]),
      const SizedBox(width:8),
      // notif
      InkWell(onTap:(){}, borderRadius:BorderRadius.circular(20), child: Container(width:32,height:32, decoration:BoxDecoration(color:Colors.white.withOpacity(.20),shape:BoxShape.circle,border:Border.all(color:Colors.white.withOpacity(.35),width:.8)), child:const Icon(Icons.notifications_none_rounded,color:Colors.white,size:16))),
    ])));
  }

  Widget _searchField(){
    return Padding(padding: const EdgeInsets.fromLTRB(16,2,16,14), child: Container(height:38, decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(12), boxShadow:[BoxShadow(color:Colors.black.withOpacity(.06),blurRadius:10)]), child:TextField(controller:_searchCtrl,onChanged:_onSearch, style:const TextStyle(fontSize:12.5,fontWeight:FontWeight.w600,color:_C.textDark), decoration:const InputDecoration(hintText:'Rechercher un chat...',hintStyle:TextStyle(fontSize:11.5,color:_C.textMuted), prefixIcon:Icon(Icons.search_rounded,size:16,color:_C.blue), border:InputBorder.none, contentPadding:EdgeInsets.symmetric(vertical:10)))));
  }

  Widget _whiteSheet(){ return Container(height:18, decoration:const BoxDecoration(color:_C.white,borderRadius:BorderRadius.vertical(top:Radius.circular(22))), child:Center(child:Container(margin:const EdgeInsets.only(top:7),width:30,height:3.5,decoration:BoxDecoration(color:_C.border,borderRadius:BorderRadius.circular(2))))); }
  Widget _filters(){
    final tabs=['Tous','Groupes','Persos','Non lus']; final counts=[_all.length,_all.where((c)=>c.isGroup).length,_all.where((c)=>!c.isGroup).length,_all.where((c)=>c.unreadCount>0).length];
    return Container(color:_C.white, padding:const EdgeInsets.fromLTRB(0,4,0,8), child:SizedBox(height:30, child:ListView.builder(padding:const EdgeInsets.symmetric(horizontal:12),scrollDirection:Axis.horizontal,itemCount:tabs.length,itemBuilder:(ctx,i){ final sel=_selectedFilter==i; return Padding(padding:const EdgeInsets.only(right:6), child:InkWell(onTap:(){setState(()=>_selectedFilter=i);_applyFilter();},borderRadius:BorderRadius.circular(18),child:AnimatedContainer(duration:const Duration(milliseconds:180),padding:const EdgeInsets.symmetric(horizontal:12),decoration:BoxDecoration(color:sel?_C.blue:_C.white,borderRadius:BorderRadius.circular(18),border:Border.all(color:sel?_C.blue:_C.border)),child:Row(children:[Text(tabs[i],style:TextStyle(fontSize:11.5,fontWeight:sel?FontWeight.w800:FontWeight.w600,color:sel?Colors.white:_C.textDark)),const SizedBox(width:5),Container(padding:const EdgeInsets.symmetric(horizontal:5,vertical:1),decoration:BoxDecoration(color:sel?Colors.white.withOpacity(.22):_C.blueSoft,borderRadius:BorderRadius.circular(99)),child:Text('${counts[i]}',style:TextStyle(fontSize:9,fontWeight:FontWeight.w800,color:sel?Colors.white:_C.blue))) ])))); })));
  }

  Widget _chatList(){
    if(_filtered.isEmpty) return const SliverToBoxAdapter(child:Padding(padding:EdgeInsets.all(32),child:Center(child:Text('Aucune conversation',style:TextStyle(color:_C.textMuted,fontSize:12)))));
    return SliverList(delegate:SliverChildBuilderDelegate((ctx,idx){ final conv=_filtered[idx]; final last=conv.lastMessage; final t=last!=null?last.createdAt:conv.updatedAt; final unread=conv.unreadCount>0; return Container(color:_C.white, child:InkWell(onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ChatScreen(conversationId:conv.id,conversation:conv))), child:Padding(padding:const EdgeInsets.fromLTRB(16,9,14,9), child:Row(children:[CircleAvatar(radius:21,backgroundColor:_C.blueSoft,backgroundImage:conv.displayAvatar!=null?NetworkImage(conv.displayAvatar!):null,child:conv.displayAvatar==null?Text(conv.displayName.isNotEmpty?conv.displayName[0].toUpperCase():'?',style:const TextStyle(fontWeight:FontWeight.w800,color:_C.blue,fontSize:12)):null),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(conv.displayName,maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:13,fontWeight:unread?FontWeight.w800:FontWeight.w700,color:_C.textDark)),const SizedBox(height:2),Text(last?.content??'Commencez à discuter...',maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:11.2,fontWeight:unread?FontWeight.w600:FontWeight.w500,color:unread?_C.textDark:_C.textMuted))])),const SizedBox(width:8),Column(crossAxisAlignment:CrossAxisAlignment.end,children:[Text(_fmt(t),style:TextStyle(fontSize:9.5,fontWeight:FontWeight.w500,color:unread?_C.blue:_C.textMuted)),const SizedBox(height:5),if(unread)Container(width:18,height:18,alignment:Alignment.center,decoration:const BoxDecoration(color:_C.blue,shape:BoxShape.circle),child:Text('${conv.unreadCount}',style:const TextStyle(color:Colors.white,fontSize:9,fontWeight:FontWeight.w800)))else const SizedBox(height:18)])]))); },childCount:_filtered.length));
  }

  // BOTTOM BARRE TYPE PHOTO 2 avec notch
  Widget _bottomNotchPro(int unread){
    return Container(
      margin:const EdgeInsets.fromLTRB(10,0,10,10),
      height:72,
      decoration:BoxDecoration(color:_C.white,borderRadius:BorderRadius.circular(28),boxShadow:[BoxShadow(color:Colors.black.withOpacity(.07),blurRadius:18,offset:const Offset(0,6))],border:Border.all(color:_C.border)),
      child: Stack(clipBehavior:Clip.none, alignment:Alignment.topCenter, children:[
        Row(mainAxisAlignment:MainAxisAlignment.spaceAround, children:[
          _navItem(Icons.home_rounded,'Accueil',0,false),
          _navItem(Icons.chat_bubble_rounded,'Chats',1,unread>0,badge:unread),
          const SizedBox(width:56),
          _navItem(Icons.workspaces_rounded,'Spaces',2,false),
          _navItem(Icons.person_rounded,'Profil',3,false),
        ]),
        Positioned(top:-14, child: GestureDetector(onTap:_showCreateMenu, child: Container(width:54,height:54,decoration:BoxDecoration(gradient:const LinearGradient(colors:[_C.blueLight,_C.blue]),shape:BoxShape.circle,boxShadow:[BoxShadow(color:_C.blue.withOpacity(.32),blurRadius:12,offset:const Offset(0,5))],border:Border.all(color:Colors.white,width:3)),child:const Icon(Icons.add_rounded,color:Colors.white,size:28)))),
      ]),
    );
  }
  Widget _navItem(IconData ic,String lb,int idx,bool hasBadge,{int badge=0}){ final sel=_selectedNav==idx; return InkWell(onTap:()=>setState(()=>_selectedNav=idx), child:SizedBox(width:56,child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Stack(clipBehavior:Clip.none,children:[Icon(ic,size:20,color:sel?_C.blue:_C.textMuted),if(hasBadge)Positioned(right:-6,top:-4,child:Container(width:8,height:8,decoration:const BoxDecoration(color:Color(0xFFEF4444),shape:BoxShape.circle)))]),const SizedBox(height:3),Text(lb,style:TextStyle(fontSize:9,fontWeight:sel?FontWeight.w800:FontWeight.w600,color:sel?_C.blue:_C.textMuted))]))); }

  void _showCreateMenu(){ showModalBottomSheet(context:context,backgroundColor:Colors.transparent,builder:(ctx)=>Container(padding:const EdgeInsets.all(16),decoration:const BoxDecoration(color:_C.white,borderRadius:BorderRadius.vertical(top:Radius.circular(22))),child:Column(mainAxisSize:MainAxisSize.min,children:[Container(width:32,height:4,decoration:BoxDecoration(color:_C.border,borderRadius:BorderRadius.circular(2))),const SizedBox(height:14),_sheetOpt(Icons.chat_bubble_rounded,'Nouvelle discussion',()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const NewConversationPage()))),const SizedBox(height:8),_sheetOpt(Icons.group_add_rounded,'Nouveau groupe',()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const GroupCreatePage())))]))); }
  Widget _sheetOpt(IconData i,String t,VoidCallback tap)=>InkWell(onTap:(){Navigator.pop(context);tap();},borderRadius:BorderRadius.circular(12),child:Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(border:Border.all(color:_C.border),borderRadius:BorderRadius.circular(12)),child:Row(children:[Container(width:32,height:32,decoration:BoxDecoration(color:_C.blue,borderRadius:BorderRadius.circular(9)),child:Icon(i,size:16,color:Colors.white)),const SizedBox(width:10),Text(t,style:const TextStyle(fontSize:13,fontWeight:FontWeight.w700,color:_C.textDark))])));
  String _fmt(DateTime d){ final now=DateTime.now(); final day=DateTime(d.year,d.month,d.day); final today=DateTime(now.year,now.month,now.day); if(day==today) return DateFormat('HH:mm').format(d); if(day==today.subtract(const Duration(days:1))) return 'Hier'; if(now.difference(d).inDays<7) return DateFormat('E','fr_FR').format(d); return DateFormat('dd/MM').format(d); }
}
