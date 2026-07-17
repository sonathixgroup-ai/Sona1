// lib/presentation/chat/chat_screen.dart
// VERSION SUPERAPP BLEU/BLANC - MATCH HOMEPAGE - FULL FEATURES
import 'dart:io'; import 'dart:async'; import 'dart:typed_data';
import 'package:flutter/material.dart'; import 'package:flutter/services.dart';
import 'package:intl/intl.dart'; import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart'; import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart'; import 'package:provider/provider.dart';
import 'package:thix_id/services/chat/chat_service.dart'; import 'package:thix_id/services/chat/presence_service.dart';
import 'package:thix_id/services/chat/audio_service.dart'; import 'package:thix_id/services/chat/group_service.dart';
import 'package:thix_id/models/chat/chat_message.dart'; import 'package:thix_id/models/chat/chat_conversation.dart';
import 'package:thix_id/models/chat/user_status.dart'; import 'package:thix_id/models/chat/group_info.dart';
import 'package:thix_id/presentation/chat/widgets/chat_message_bubble.dart';
import 'package:thix_id/presentation/chat/widgets/audio_recorder.dart';
import 'package:thix_id/presentation/chat/encryption_service.dart';
import 'package:thix_id/presentation/chat/escalation/providers/escalation_provider.dart';
import 'package:thix_id/models/chat/call_status.dart'; import 'package:thix_id/presentation/chat/call/call_page.dart'; import 'package:thix_id/presentation/chat/call/providers/call_provider.dart';

class ChatScreen extends StatefulWidget { final String conversationId; final ChatConversation conversation; const ChatScreen({super.key, required this.conversationId, required this.conversation}); @override State<ChatScreen> createState()=>_ChatScreenState(); }

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver{
  static const blue = Color(0xFF3B82F6); static const blueLight = Color(0xFF5B9CF6); static const blueSoft = Color(0xFFE9F0FF); static const bg = Color(0xFFF5F7FF); static const white = Colors.white; static const dark = Color(0xFF0F172A); static const muted = Color(0xFF94A3B8); static const border = Color(0xFFE2E8F0);
  late ChatService _chatService; late PresenceService _presenceService; late AudioService _audioService; late GroupService _groupService;
  List<ChatMessage> _messages=[]; bool _isLoading=true; bool _isLoadingMore=false; bool _hasMore=true; bool _isSending=false; int _page=0; static const _pageSize=30;
  final _scroll=ScrollController(); final _input=TextEditingController(); final _focus=FocusNode();
  UserStatus? _other; List<GroupMember> _groupMembers=[]; String _replyToId=''; bool _isEphemeral=false; int? _ephemeralDur;
  bool _isTyping=false; bool _otherTyping=false; Timer? _typingTimer; RealtimeChannel? _typingChannel;
  bool _isAgent=false; bool _isInternal=false; StreamSubscription<List<ChatMessage>>? _msgSub; Stream<UserStatus?>? _presenceStream;
  static const _quick=['🔥','🙌','❤️','😀','😖','👍'];

  @override void initState(){ super.initState(); final c=Supabase.instance.client; _chatService=ChatService(c); _presenceService=PresenceService(c); _audioService=AudioService(c); _groupService=GroupService(c); _loadRole(); WidgetsBinding.instance.addObserver(this); _loadMessages(); _getParticipant(); _markRead(); _setupScroll(); _subPresence(); _subMessages(); _subTyping(); _loadGroup(); }
  Future<void> _loadRole() async{ final u=_chatService.currentUser; if(u!=null){ _isAgent=u.role=='agent'||u.role=='admin'||u.role=='support'; setState((){}); } }
  @override void dispose(){ WidgetsBinding.instance.removeObserver(this); _scroll.dispose(); _input.dispose(); _focus.dispose(); _typingTimer?.cancel(); _msgSub?.cancel(); _typingChannel?.unsubscribe(); _audioService.dispose(); super.dispose(); }

  Future<void> _loadMessages({bool more=false}) async{ if(more){ if(_isLoadingMore||!_hasMore) return; setState(()=>_isLoadingMore=true);} else {setState(()=>_isLoading=true); _page=0;} try{ final m=await _chatService.getMessages(widget.conversationId,limit:_pageSize,offset:_page*_pageSize); setState((){ if(more){ _messages=[...m.reversed,..._messages]; _hasMore=m.length>=_pageSize; } else { _messages=m; _hasMore=m.length>=_pageSize; } _isLoading=false; _isLoadingMore=false;}); if(!more) _toBottom(); }catch(_){ setState(()=>_isLoading=false);} }
  void _setupScroll(){ _scroll.addListener((){ if(_scroll.position.pixels>=_scroll.position.maxScrollExtent-200 && _hasMore &&!_isLoadingMore){ _page++; _loadMessages(more:true);} }); }
  Future<void> _markRead() async=>await _chatService.markAsRead(widget.conversationId);
  void _toBottom(){ if(_scroll.hasClients) _scroll.animateTo(0,duration:const Duration(milliseconds:280),curve:Curves.easeOut); }

  void _subPresence(){ if(widget.conversation.isGroup) return; final otherId=widget.conversation.participantIds.firstWhere((id)=>id!=_chatService.currentUserId,orElse:()=>''); if(otherId.isNotEmpty){ _presenceStream=_chatService.subscribeToPresence([otherId]).map((l)=>l.isNotEmpty?l.first:null); _presenceStream?.listen((s){ if(mounted) setState(()=>_other=s);}); } }
  Future<void> _getParticipant() async{ if(widget.conversation.isGroup) return; final oid=widget.conversation.participantIds.firstWhere((id)=>id!=_chatService.currentUserId,orElse:()=>''); if(oid.isNotEmpty){ final p=await _chatService.getUserPresence(oid); if(mounted) setState(()=>_other=p);} }
  void _subMessages(){ _msgSub=_chatService.subscribeToMessages(widget.conversationId).listen((upd){ if(!mounted) return; setState((){ for(var msg in upd){ final i=_messages.indexWhere((m)=>m.id==msg.id); if(i!=-1){ if(msg.isDeleted) _messages.removeAt(i); else _messages[i]=msg; } else if(!msg.isDeleted) _messages.add(msg);} }); _toBottom();}); }
  void _subTyping(){ final cur=_chatService.currentUserId; _typingChannel=Supabase.instance.client.channel('typing:${widget.conversationId}').onBroadcast(event:'typing',callback:(p){ final sid=p['senderId'] as String?; final it=(p['isTyping'] as bool?)??false; if(sid!=null&&sid!=cur&&mounted) setState(()=>_otherTyping=it);}).subscribe(); }
  void _sendTyping(bool t){ final cur=_chatService.currentUserId; if(cur==null||_typingChannel==null) return; _typingChannel!.sendBroadcastMessage(event:'typing',payload:{'senderId':cur,'isTyping':t}); }
  Future<void> _loadGroup() async{ if(!widget.conversation.isGroup) return; try{ final m=await _chatService.getGroupMembers(widget.conversationId); setState(()=>_groupMembers=m);}catch(_){} }

  void _startCall(CallType type){ final otherId=widget.conversation.participantIds.firstWhere((id)=>id!=_chatService.currentUserId,orElse:()=>''); final prov=context.read<CallProvider>(); prov.start(channel:widget.conversationId,calleeId:otherId,callType:type); Navigator.push(context,MaterialPageRoute(builder:(_)=>CallPage(channel:widget.conversationId,name:widget.conversation.displayName,type:type,isCaller:true))); }

  Future<void> _sendMessage() async{ final txt=_input.text.trim(); if(txt.isEmpty||_isSending) return; _isTyping=false; _sendTyping(false); setState(()=>_isSending=true); try{ final msg=await _chatService.sendMessage(conversationId:widget.conversationId,content:txt,replyToId:_replyToId.isEmpty?null:_replyToId,isEphemeral:_isEphemeral,ephemeralDuration:_isEphemeral?_ephemeralDur:null); setState((){ if(!_messages.any((m)=>m.id==msg.id)) _messages.add(msg); _input.clear(); _replyToId=''; _isSending=false; if(_isInternal) _isInternal=false;}); _toBottom(); }catch(e){ setState(()=>_isSending=false); _snack('Erreur: $e',Colors.red);} }
  void _onTypingChanged(String t){ if(t.isNotEmpty&&!_isTyping){ _isTyping=true; _sendTyping(true);} else if(t.isEmpty&&_isTyping){ _isTyping=false; _sendTyping(false);} _typingTimer?.cancel(); _typingTimer=Timer(const Duration(seconds:2),(){ if(_isTyping){ _isTyping=false; _sendTyping(false);} }); }

  // FILE / AUDIO (gardé)
  Future<void> _pickFile({FileType type=FileType.any}) async{ try{ final r=await FilePicker.platform.pickFiles(allowMultiple:false,type:type); if(r==null||r.files.isEmpty) return; final f=r.files.first; final bytes=f.bytes??await File(f.path!).readAsBytes(); final ext=f.extension??'file'; final ok=await _showPreview(f.name,f.size,Uint8List.fromList(bytes),ext); if(ok!=true) return; final url=await _chatService.uploadFileWithUniqueName('chat-media','messages/${widget.conversationId}',Uint8List.fromList(bytes),ext); if(url!=null){ await _chatService.sendMessage(conversationId:widget.conversationId,content:'📎 ${f.name}',mediaUrl:url,mediaType:_mediaType(ext),mediaName:f.name,mediaSize:f.size,mimeType:_mime(ext),isEphemeral:_isEphemeral,ephemeralDuration:_isEphemeral?_ephemeralDur:null); _toBottom(); } }catch(e){ _snack('Erreur fichier: $e',Colors.red);} }
  String _mime(String e){ switch(e.toLowerCase()){ case 'jpg': case 'jpeg': return 'image/jpeg'; case 'png': return 'image/png'; case 'mp4': return 'video/mp4'; case 'pdf': return 'application/pdf'; default: return 'application/octet-stream'; } }
  String _mediaType(String e){ const i={'jpg','jpeg','png','gif','webp'}; const v={'mp4','mov','avi'}; if(i.contains(e)) return 'image'; if(v.contains(e)) return 'video'; return 'file'; }
  Future<bool?> _showPreview(String name,int size,Uint8List bytes,String ext){ return showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18)),title:const Text('Envoyer ce fichier?',style:TextStyle(fontSize:14,fontWeight:FontWeight.w700)),content:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[bytes.length<5000000 && _mime(ext).startsWith('image/')? ClipRRect(borderRadius:BorderRadius.circular(10),child:Image.memory(bytes,height:120,fit:BoxFit.cover)): Icon(Icons.insert_drive_file_rounded,size:48,color:blue),const SizedBox(height:8),Text(name,style:const TextStyle(fontSize:12)),Text('${(size/1024).toStringAsFixed(1)} KB',style:const TextStyle(fontSize:11,color:muted))]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Annuler')),ElevatedButton(onPressed:()=>Navigator.pop(ctx,true),style:ElevatedButton.styleFrom(backgroundColor:blue,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(10))),child:const Text('Envoyer',style:TextStyle(color:Colors.white))) ])); }

  // ACTIONS MESSAGE - DESIGN PHOTO 1
  void _showMessageActions(ChatMessage msg,bool isOwn){
    showModalBottomSheet(context:context,isScrollControlled:true,backgroundColor:Colors.transparent,builder:(ctx){
      return DraggableScrollableSheet(initialChildSize:.62,minChildSize:.4,maxChildSize:.88,expand:false,builder:(c,sc){
        return Container(decoration:const BoxDecoration(color:white,borderRadius:BorderRadius.vertical(top:Radius.circular(24))),child:SafeArea(top:false,child:ListView(controller:sc,padding:const EdgeInsets.fromLTRB(16,10,16,18),children:[
          Center(child:Container(width:34,height:4,margin:const EdgeInsets.only(bottom:14),decoration:BoxDecoration(color:border,borderRadius:BorderRadius.circular(4)))),
          Align(alignment:isOwn?Alignment.centerRight:Alignment.centerLeft,child:Container(constraints:const BoxConstraints(maxWidth:300),padding:const EdgeInsets.symmetric(horizontal:16,vertical:12),decoration:BoxDecoration(color:isOwn?blue:blueSoft,borderRadius:BorderRadius.only(topLeft:const Radius.circular(16),topRight:const Radius.circular(16),bottomLeft:Radius.circular(isOwn?16:4),bottomRight:Radius.circular(isOwn?4:16))),child:Text(msg.content,style:TextStyle(fontSize:13.5,height:1.35,fontWeight:FontWeight.w500,color:isOwn?Colors.white:dark)))),
          const SizedBox(height:18), const Text('React',style:TextStyle(fontSize:13,fontWeight:FontWeight.w800,color:dark)), const SizedBox(height:10),
          Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:_quick.map((e)=>InkWell(onTap:(){_chatService.toggleReaction(msg.id,e);Navigator.pop(ctx);},borderRadius:BorderRadius.circular(20),child:Padding(padding:const EdgeInsets.all(6),child:Text(e,style:const TextStyle(fontSize:24))))).toList()),
          const SizedBox(height:10), const Divider(height:1,color:border),
          _act('Reply',Icons.reply_rounded,(){Navigator.pop(ctx);setState(()=>_replyToId=msg.id); _focus.requestFocus();}),
          _act('Forward',Icons.forward_rounded,(){Navigator.pop(ctx); _snack('Forward',blue);}),
          _act('Copy',Icons.copy_rounded,(){Navigator.pop(ctx); Clipboard.setData(ClipboardData(text:msg.content)); _snack('Copié',dark);}),
          _act('Delete',Icons.delete_outline_rounded,(){Navigator.pop(ctx); setState(()=>_messages.removeWhere((m)=>m.id==msg.id)); if(isOwn) _chatService.deleteMessage(msg.id);},color:Colors.red),
          _act('More..',Icons.more_horiz_rounded,(){Navigator.pop(ctx);},isLast:true),
        ])));
      });
    });
  }
  Widget _act(String label,IconData ic,VoidCallback tap,{Color color=dark,bool isLast=false}){ return Column(children:[InkWell(onTap:tap,child:Padding(padding:const EdgeInsets.symmetric(vertical:14),child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(label,style:TextStyle(fontSize:13.5,fontWeight:FontWeight.w600,color:color)),Icon(ic,size:18,color:color==Colors.red?Colors.red:muted)]))), if(!isLast) const Divider(height:1,color:border)]); }

  // INPUT BAR - MATCH PHOTO 2 (large horizontal)
  Widget _inputBar(){
    return Container(padding:const EdgeInsets.fromLTRB(12,8,12,12), decoration:BoxDecoration(color:white,boxShadow:[BoxShadow(color:Colors.black.withOpacity(.04),blurRadius:12,offset:const Offset(0,-2))],border:Border(top:BorderSide(color:border))), child:Column(children:[
      if(_replyToId.isNotEmpty) Container(margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.symmetric(horizontal:12,vertical:8),decoration:BoxDecoration(color:blueSoft,borderRadius:BorderRadius.circular(10),border:Border(left:BorderSide(color:blue,width:3))),child:Row(children:[Expanded(child:Text(_messages.firstWhere((m)=>m.id==_replyToId,orElse:()=>_messages.first).content,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:11.5,color:dark))),InkWell(onTap:()=>setState(()=>_replyToId=''),child:const Icon(Icons.close_rounded,size:16,color:muted))])),
      Row(children:[
        InkWell(onTap:()=>_showAttach(),borderRadius:BorderRadius.circular(20),child:Container(width:34,height:34,alignment:Alignment.center,decoration:BoxDecoration(color:bg,shape:BoxShape.circle,border:Border.all(color:border)),child:const Icon(Icons.attach_file_rounded,size:18,color:muted))),
        const SizedBox(width:8),
        Expanded(child:Container(height:42,decoration:BoxDecoration(color:bg,borderRadius:BorderRadius.circular(22),border:Border.all(color:border)),child:TextField(controller:_input,focusNode:_focus,onChanged:_onTypingChanged,style:const TextStyle(fontSize:13.5),decoration:InputDecoration(hintText:_isInternal?'Note interne...':'Type something',hintStyle:const TextStyle(fontSize:12.5,color:muted),border:InputBorder.none,contentPadding:const EdgeInsets.symmetric(horizontal:14,vertical:10),suffixIcon:InkWell(onTap:(){},child:const Icon(Icons.emoji_emotions_outlined,size:20,color:muted)))))),
        const SizedBox(width:8),
        GestureDetector(onTap:_sendMessage,child:Container(width:42,height:42,decoration:BoxDecoration(gradient:const LinearGradient(colors:[blueLight,blue]),shape:BoxShape.circle,boxShadow:[BoxShadow(color:blue.withOpacity(.28),blurRadius:8,offset:const Offset(0,3))]),child:_isSending? const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:white)): Icon(_input.text.trim().isEmpty?Icons.mic_rounded:Icons.send_rounded,color:white,size:18))),
      ]),
      if(_isEphemeral) Container(margin:const EdgeInsets.only(top:6),padding:const EdgeInsets.symmetric(horizontal:10,vertical:4),decoration:BoxDecoration(color:Colors.orange.withOpacity(.12),borderRadius:BorderRadius.circular(8)),child:Row(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.timer_rounded,size:12,color:Colors.orange),const SizedBox(width:4),Text('Ephemeral ${_ephemeralDur??''}s',style:const TextStyle(fontSize:10,color:Colors.orange,fontWeight:FontWeight.w600)),const SizedBox(width:6),InkWell(onTap:()=>setState(()=>_isEphemeral=false),child:const Icon(Icons.close,size:12,color:Colors.orange))]))
    ]));
  }

  void _showAttach(){ showModalBottomSheet(context:context,backgroundColor:white,shape:const RoundedRectangleBorder(borderRadius:BorderRadius.vertical(top:Radius.circular(18))),builder:(ctx)=>SafeArea(child:Column(mainAxisSize:MainAxisSize.min,children:[const SizedBox(height:8),Container(width:32,height:4,decoration:BoxDecoration(color:border,borderRadius:BorderRadius.circular(2))),ListTile(leading:Container(padding:const EdgeInsets.all(8),decoration:BoxDecoration(color:blueSoft,borderRadius:BorderRadius.circular(8)),child:const Icon(Icons.image_rounded,color:blue,size:18)),title:const Text('Photo',style:TextStyle(fontSize:13,fontWeight:FontWeight.w600)),onTap:(){Navigator.pop(ctx);_pickFile(type:FileType.image);}),ListTile(leading:Container(padding:const EdgeInsets.all(8),decoration:BoxDecoration(color:blueSoft,borderRadius:BorderRadius.circular(8)),child:const Icon(Icons.videocam_rounded,color:blue,size:18)),title:const Text('Vidéo',style:TextStyle(fontSize:13,fontWeight:FontWeight.w600)),onTap:(){Navigator.pop(ctx);_pickFile(type:FileType.video);}),ListTile(leading:Container(padding:const EdgeInsets.all(8),decoration:BoxDecoration(color:blueSoft,borderRadius:BorderRadius.circular(8)),child:const Icon(Icons.insert_drive_file_rounded,color:blue,size:18)),title:const Text('Document',style:TextStyle(fontSize:13,fontWeight:FontWeight.w600)),onTap:(){Navigator.pop(ctx);_pickFile();}),ListTile(leading:Container(padding:const EdgeInsets.all(8),decoration:BoxDecoration(color:Colors.orange.withOpacity(.12),borderRadius:BorderRadius.circular(8)),child:const Icon(Icons.lock_rounded,color:Colors.orange,size:18)),title:const Text('Message chiffré',style:TextStyle(fontSize:13,fontWeight:FontWeight.w600)),onTap:(){Navigator.pop(ctx);_showPassword();}),const SizedBox(height:10)]))); }

  void _showPassword(){ final mc=TextEditingController(); final pc=TextEditingController(); showDialog(context:context,builder:(ctx)=>AlertDialog(shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16)),title:const Text('Message chiffré',style:TextStyle(fontSize:14,fontWeight:FontWeight.w800)),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:mc,decoration:const InputDecoration(labelText:'Message',border:OutlineInputBorder())),const SizedBox(height:10),TextField(controller:pc,obscureText:true,decoration:const InputDecoration(labelText:'Mot de passe',border:OutlineInputBorder()))]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Annuler')),ElevatedButton(style:ElevatedButton.styleFrom(backgroundColor:blue),onPressed:()async{if(mc.text.isNotEmpty&&pc.text.isNotEmpty){final enc=EncryptionService.encryptMessage(mc.text,pc.text); await _chatService.sendMessage(conversationId:widget.conversationId,content:enc); if(mounted) Navigator.pop(ctx);}},child:const Text('Envoyer',style:TextStyle(color:white))) ])); }

  void _snack(String m,Color c){ if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(m,style:const TextStyle(fontSize:12)),backgroundColor:c,behavior:SnackBarBehavior.floating,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(10)))); }

  @override Widget build(BuildContext context){
    return Scaffold(backgroundColor:bg, body: Stack(children:[
      Container(height:220,decoration:const BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[blue,blueLight]))),
      Column(children:[
        _appBar(),
        Expanded(child: Container(decoration:const BoxDecoration(color:white,borderRadius:BorderRadius.vertical(top:Radius.circular(22))), child: ClipRRect(borderRadius:const BorderRadius.vertical(top:Radius.circular(22)), child: Column(children:[
          if(_otherTyping) Container(width:double.infinity,padding:const EdgeInsets.symmetric(horizontal:16,vertical:6),color:blueSoft,child:Row(children:[const SizedBox(width:4),Text('${widget.conversation.displayName} est en train d\'écrire...',style:const TextStyle(fontSize:11,color:blue,fontStyle:FontStyle.italic)),const SizedBox(width:8),const _Dots()])),
          Expanded(child: _isLoading? const Center(child:CircularProgressIndicator(color:blue)) : _messageList()),
          _inputBar(),
        ])))),
      ]),
    ]));
  }

  Widget _appBar(){ return SafeArea(bottom:false,child:Padding(padding:const EdgeInsets.fromLTRB(8,8,8,12),child:Row(children:[
    InkWell(onTap:()=>Navigator.pop(context),borderRadius:BorderRadius.circular(10),child:Container(width:34,height:34,decoration:BoxDecoration(color:white.withOpacity(.18),borderRadius:BorderRadius.circular(10),border:Border.all(color:Colors.white.withOpacity(.3))),child:const Icon(Icons.arrow_back_rounded,color:white,size:18))),
    const SizedBox(width:10),
    CircleAvatar(radius:18,backgroundColor:white,backgroundImage:widget.conversation.displayAvatar!=null?NetworkImage(widget.conversation.displayAvatar!):null,child:widget.conversation.displayAvatar==null?Text(widget.conversation.displayName[0].toUpperCase(),style:const TextStyle(color:blue,fontWeight:FontWeight.w800)):null),
    const SizedBox(width:10),
    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(widget.conversation.displayName,style:const TextStyle(fontSize:14,fontWeight:FontWeight.w800,color:white),maxLines:1,overflow:TextOverflow.ellipsis), if(_other!=null) Row(children:[Container(width:6,height:6,decoration:BoxDecoration(shape:BoxShape.circle,color:_other!.status=='online'?const Color(0xFF22C55E):Colors.white54)),const SizedBox(width:5),Text(_other!.status=='online'?'En ligne':'Hors ligne',style:const TextStyle(fontSize:10.5,color:Colors.white70))])])),
    _circleIcon(Icons.videocam_rounded,()=>_startCall(CallType.video)),
    const SizedBox(width:6),
    _circleIcon(Icons.call_rounded,()=>_startCall(CallType.audio)),
    const SizedBox(width:6),
    PopupMenuButton<String>(icon:Container(width:30,height:30,decoration:BoxDecoration(color:white.withOpacity(.18),shape:BoxShape.circle),child:const Icon(Icons.more_vert_rounded,color:white,size:16)),onSelected:(v){ if(v=='esc') GoRouter.of(context).pushNamed('chatEscalate',pathParameters:{'conversationId':widget.conversationId}); },itemBuilder:(_)=>[const PopupMenuItem(value:'esc',child:Text('Escalader',style:TextStyle(fontSize:12)))])
  ]))); }
  Widget _circleIcon(IconData ic,VoidCallback tap)=>InkWell(onTap:tap,borderRadius:BorderRadius.circular(20),child:Container(width:32,height:32,decoration:BoxDecoration(color:white.withOpacity(.18),shape:BoxShape.circle,border:Border.all(color:Colors.white.withOpacity(.25))),child:Icon(ic,color:white,size:16)));

  Widget _messageList(){ return ListView.builder(controller:_scroll,reverse:true,padding:const EdgeInsets.symmetric(horizontal:10,vertical:12),itemCount:_messages.length+(_isLoadingMore?1:0),itemBuilder:(ctx,idx){ if(idx==_messages.length&&_isLoadingMore) return const Padding(padding:EdgeInsets.all(8),child:Center(child:CircularProgressIndicator(strokeWidth:2,color:blue))); final msg=_messages[_messages.length-1-idx]; final isOwn=msg.senderId==_chatService.currentUserId; return GestureDetector(onLongPress:()=>_showMessageActions(msg,isOwn),child:Padding(padding:const EdgeInsets.only(bottom:10),child:Row(crossAxisAlignment:CrossAxisAlignment.end,children:[ if(!isOwn) CircleAvatar(radius:14,backgroundColor:blueSoft,backgroundImage:widget.conversation.displayAvatar!=null?NetworkImage(widget.conversation.displayAvatar!):null), if(!isOwn) const SizedBox(width:6), Expanded(child: Column(crossAxisAlignment:isOwn?CrossAxisAlignment.end:CrossAxisAlignment.start,children:[ if(msg.replyToId!=null) Container(margin:const EdgeInsets.only(bottom:4),padding:const EdgeInsets.all(8),decoration:BoxDecoration(color:bg,borderRadius:BorderRadius.circular(8),border:Border(left:BorderSide(color:blue,width:2.5))),child:Text(_messages.firstWhere((m)=>m.id==msg.replyToId,orElse:()=>msg).content,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:11,color:muted))), Container(padding:const EdgeInsets.symmetric(horizontal:14,vertical:10),decoration:BoxDecoration(color:isOwn?blue:blueSoft,borderRadius:BorderRadius.only(topLeft:const Radius.circular(16),topRight:const Radius.circular(16),bottomLeft:Radius.circular(isOwn?16:4),bottomRight:Radius.circular(isOwn?4:16)),boxShadow:[BoxShadow(color:Colors.black.withOpacity(.03),blurRadius:4,offset:const Offset(0,1))]),child:Text(msg.content,style:TextStyle(fontSize:13.2,height:1.35,fontWeight:FontWeight.w500,color:isOwn?white:dark))), const SizedBox(height:3), Row(mainAxisSize:MainAxisSize.min,children:[Text(DateFormat('HH:mm').format(msg.createdAt),style:const TextStyle(fontSize:9,color:muted),if(isOwn)...[const SizedBox(width:4),Icon(Icons.done_all_rounded,size:12,color:msg.isRead?blue:muted)]]) ])), if(isOwn) const SizedBox(width:6), if(isOwn) const CircleAvatar(radius:11,backgroundColor:blueSoft,child:Icon(Icons.person_rounded,size:12,color:blue)) ]))); }); }
}

class _Dots extends StatefulWidget{ const _Dots(); @override State<_Dots> createState()=>_DotsS(); }
class _DotsS extends State<_Dots> with SingleTickerProviderStateMixin{ late AnimationController _c; @override void initState(){ super.initState(); _c=AnimationController(vsync:this,duration:const Duration(milliseconds:1100))..repeat(); } @override void dispose(){ _c.dispose(); super.dispose(); } @override Widget build(BuildContext context){ return Row(mainAxisSize:MainAxisSize.min,children:List.generate(3,(i)=>AnimatedBuilder(animation:_c,builder:(_,__){ final v=(_c.value+i*.2)%1; final o=v<.5?v*2:1-((v-.5)*2); return Opacity(opacity:o,child:Container(margin:const EdgeInsets.symmetric(horizontal:1.5),width:4,height:4,decoration:const BoxDecoration(color:Color(0xFF3B82F6),shape:BoxShape.circle)));}))); } }
