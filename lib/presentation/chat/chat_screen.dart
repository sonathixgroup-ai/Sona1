import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Services
import 'package:thix_id/services/chat/chat_service.dart';
import 'package:thix_id/services/chat/presence_service.dart';
import 'package:thix_id/services/chat/audio_service.dart';
import 'package:thix_id/services/chat/group_service.dart';
import 'package:thix_id/services/chat/connection_service.dart';

// Modèles
import 'package:thix_id/models/chat/chat_message.dart';
import 'package:thix_id/models/chat/chat_conversation.dart';
import 'package:thix_id/models/chat/user_status.dart';
import 'package:thix_id/models/chat/group_info.dart';

// Widgets
import 'package:thix_id/presentation/chat/widgets/chat_message_bubble.dart';
import 'package:thix_id/presentation/chat/widgets/chat_input_bar.dart';
import 'package:thix_id/presentation/chat/widgets/audio_recorder.dart';
import 'package:thix_id/presentation/chat/group/group_info_panel.dart';
import 'package:thix_id/presentation/chat/encryption_service.dart';
import 'package:thix_id/models/chat/call_status.dart';
import 'package:thix_id/presentation/chat/call/call_page.dart';
import 'package:thix_id/presentation/chat/call/providers/call_provider.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final ChatConversation conversation;
  const ChatScreen({super.key, required this.conversationId, required this.conversation});
  @override State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  late ChatService _chatService;
  late PresenceService _presenceService;
  late AudioService _audioService;
  late GroupService _groupService;
  late ConnectionService _connectionService;

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;
  bool _isSending = false;
  int _page = 0;
  static const int _pageSize = 30;

  final _scrollController = ScrollController();
  final _inputController = TextEditingController();
  final _inputFocus = FocusNode();

  UserStatus? _otherParticipant;
  List<GroupMember> _groupMembers = [];
  String _replyToId = '';
  bool _isEphemeral = false;
  int? _ephemeralDuration;

  bool _isTyping = false;
  bool _otherUserTyping = false;
  Timer? _typingTimer;
  RealtimeChannel? _typingChannel;

  bool _isAgent = false;
  bool _isInternalNoteMode = false;
  bool _isConversationEscalated = false;

  StreamSubscription<List<ChatMessage>>? _messageSubscription;

  static const primaryBlue = Color(0xFF4A8BFF);
  static const leftBubbleColor = Color(0xFFE9F0FF);
  static const navyDeep = Color(0xFF0A1F44);
  static const pureWhite = Color(0xFFFFFFFF);
  static const darkText = Color(0xFF10182B);
  static const mutedText = Color(0xFF6B7690);
  static const success = Color(0xFF1FA971);
  static const danger = Color(0xFFD64545);
  static const hairline = Color(0xFFE7EAF3);
  static const ivory = Color(0xFFF3F5FA);
  static const gold = Color(0xFFE3B23C);

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _chatService = ChatService(client);
    _presenceService = PresenceService(client);
    _audioService = AudioService(client);
    _groupService = GroupService(client);
    _connectionService = ConnectionService();
    WidgetsBinding.instance.addObserver(this);
    _loadUserRole();
    _loadMessages();
    _getParticipantInfo();
    _markAsRead();
    _setupScrollListener();
    _subscribeToPresence();
    _subscribeToRealtimeMessages();
    _subscribeToTypingChannel();
    _loadGroupMembersIfGroup();
  }

  Future<void> _loadUserRole() async {
    final user = _chatService.currentUser;
    if(user!=null){ _isAgent = user.role=='agent'||user.role=='admin'||user.role=='support'; if(mounted) setState((){}); }
  }

  @override void dispose(){ WidgetsBinding.instance.removeObserver(this); _scrollController.dispose(); _inputController.dispose(); _inputFocus.dispose(); _typingTimer?.cancel(); _messageSubscription?.cancel(); _typingChannel?.unsubscribe(); _audioService.dispose(); super.dispose(); }

  Future<void> _loadMessages({bool loadMore=false}) async {
    if(loadMore){ if(_isLoadingMore||!_hasMoreMessages) return; setState(()=>_isLoadingMore=true); } else { setState(()=>_isLoading=true); _page=0; }
    try{
      final msgs = await _chatService.getMessages(widget.conversationId, limit:_pageSize, offset:_page*_pageSize);
      if(!mounted) return;
      setState((){ if(loadMore){ _messages=[...msgs.reversed,..._messages]; _hasMoreMessages=msgs.length>=_pageSize; } else { _messages=msgs; _hasMoreMessages=msgs.length>=_pageSize; } _isLoading=false; _isLoadingMore=false; });
      if(!loadMore) _scrollToBottom();
    }catch(_){ if(mounted) setState(()=>_isLoading=_isLoadingMore=false); }
  }

  Future<void> _loadGroupMembersIfGroup() async { if(!widget.conversation.isGroup) return; try{ final m=await _chatService.getGroupMembers(widget.conversationId); if(mounted) setState(()=>_groupMembers=m); }catch(e){ debugPrint('members $e'); } }
  void _setupScrollListener(){ _scrollController.addListener((){ if(_scrollController.position.pixels >= _scrollController.position.maxScrollExtent-200){ if(_hasMoreMessages&&!_isLoadingMore){ _page++; _loadMessages(loadMore:true); } } }); }
  Future<void> _markAsRead() async => await _chatService.markAsRead(widget.conversationId);
  void _scrollToBottom(){ if(_scrollController.hasClients) _scrollController.animateTo(0, duration: const Duration(milliseconds:300), curve: Curves.easeOut); }

  void _subscribeToPresence(){
    if(widget.conversation.isGroup) return;
    final otherId = widget.conversation.participantIds.firstWhere((id)=>id!=_chatService.currentUserId, orElse:()=>'');
    if(otherId.isNotEmpty){
      _chatService.subscribeToPresence([otherId]).listen((list){ if(mounted&&list.isNotEmpty) setState(()=>_otherParticipant=list.first); });
    }
  }
  Future<void> _getParticipantInfo() async { if(widget.conversation.isGroup) return; final otherId=widget.conversation.participantIds.firstWhere((id)=>id!=_chatService.currentUserId, orElse:()=>''); if(otherId.isNotEmpty){ final p=await _chatService.getUserPresence(otherId); if(mounted) setState(()=>_otherParticipant=p); } }

  void _subscribeToRealtimeMessages(){
    _messageSubscription=_chatService.subscribeToMessages(widget.conversationId).listen((updated){
      if(!mounted) return;
      setState((){ for(var msg in updated){ final idx=_messages.indexWhere((m)=>m.id==msg.id); if(idx!=-1){ if(msg.isDeleted) _messages.removeAt(idx); else _messages[idx]=msg; } else if(!msg.isDeleted){ _messages.add(msg); } } });
      _scrollToBottom(); _markAsRead();
    });
  }

  void _subscribeToTypingChannel(){
    final cur=_chatService.currentUserId;
    _typingChannel=Supabase.instance.client.channel('typing:${widget.conversationId}').onBroadcast(event:'typing', callback:(p){ final sid=p['senderId'] as String?; final typing=p['isTyping'] as bool? ?? false; if(sid!=null&&sid!=cur&&mounted) setState(()=>_otherUserTyping=typing); }).subscribe();
  }
  void _sendTypingStatus(bool t){ final cur=_chatService.currentUserId; if(cur==null||_typingChannel==null) return; _typingChannel!.sendBroadcastMessage(event:'typing', payload:{'senderId':cur,'isTyping':t}); }

  void _startCall(CallType type){
    final otherId=widget.conversation.participantIds.firstWhere((id)=>id!=_chatService.currentUserId, orElse:()=>'');
    final prov=context.read<CallProvider>(); prov.start(channel:widget.conversationId, calleeId:otherId, callType:type);
    Navigator.push(context, MaterialPageRoute(builder:(_)=>CallPage(channel:widget.conversationId, name:widget.conversation.displayName, type:type, isCaller:true)));
  }

  Future<void> _sendMessage() async {
    final text=_inputController.text.trim(); if(text.isEmpty||_isSending) return;
    if(!widget.conversation.isGroup && !_isInternalNoteMode){
      final cur=_chatService.currentUserId;
      if(cur!=null){ final otherId=widget.conversation.participantIds.firstWhere((id)=>id!=cur, orElse:()=>''); if(otherId.isNotEmpty){ final ok=await _connectionService.checkConnection(cur, otherId); if(!ok){ if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Vous devez être connecté'), backgroundColor: Colors.orange)); return; } } }
    }
    _isTyping=false; _sendTypingStatus(false); setState(()=>_isSending=true);
    try{
      final msg=await _chatService.sendMessage(conversationId:widget.conversationId, content:text, replyToId:_replyToId.isEmpty?null:_replyToId, isEphemeral:_isEphemeral, ephemeralDuration:_isEphemeral?_ephemeralDuration:null);
      if(mounted) setState((){ if(!_messages.any((m)=>m.id==msg.id)) _messages.add(msg); _inputController.clear(); _replyToId=''; _isSending=false; if(_isInternalNoteMode) _isInternalNoteMode=false; });
      _scrollToBottom();
    }catch(e){ if(mounted) setState(()=>_isSending=false); if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Erreur: $e'), backgroundColor:danger)); }
  }

  // ============ EPHEMERE AVEC DESACTIVER + TEMPS PERSO ============
  void _showEphemeralTimerDialog(){
    final customCtrl=TextEditingController();
    showModalBottomSheet(context:context, backgroundColor:Colors.transparent, isScrollControlled:true, builder:(ctx)=>Container(
      padding:const EdgeInsets.fromLTRB(16,12,16,32),
      decoration:const BoxDecoration(color:Colors.white, borderRadius:BorderRadius.vertical(top:Radius.circular(22))),
      child:Column(mainAxisSize:MainAxisSize.min, children:[
        Container(width:40,height:4,decoration:BoxDecoration(color:hairline,borderRadius:BorderRadius.circular(4))),
        const SizedBox(height:16),
        Row(children:[Container(padding:const EdgeInsets.all(7),decoration:BoxDecoration(color:primaryBlue,borderRadius:BorderRadius.circular(10)),child:const Icon(Icons.timer_rounded,size:16,color:Colors.white)), const SizedBox(width:10), const Text("Messages éphémères",style:TextStyle(fontWeight:FontWeight.w800,fontSize:16))]),
        const SizedBox(height:16),
        ListTile(leading:Icon(Icons.timer_off_rounded,color:!_isEphemeral?primaryBlue:mutedText), title:Text("Désactiver - Envoyer sans éphémère",style:TextStyle(fontWeight:!_isEphemeral?FontWeight.w800:FontWeight.w500,color:!_isEphemeral?primaryBlue:darkText)), trailing:!_isEphemeral?const Icon(Icons.check_circle_rounded,color:primaryBlue):null, onTap:(){ setState((){_isEphemeral=false; _ephemeralDuration=null;}); Navigator.pop(ctx); }),
        const Divider(),
       ...[[10,'10 secondes'],[30,'30 secondes'],[60,'1 minute'],[300,'5 minutes'],[3600,'1 heure'],[86400,'24 heures']].map((e){
          final sec=e[0] as int; final label=e[1] as String; final sel=_isEphemeral&&_ephemeralDuration==sec;
          return ListTile(leading:Icon(Icons.timer_rounded,color:sel?primaryBlue:darkText), title:Text(label,style:TextStyle(fontWeight:sel?FontWeight.w800:FontWeight.w500,color:sel?primaryBlue:darkText)), trailing:sel?const Icon(Icons.check_circle_rounded,color:primaryBlue):null, onTap:(){ setState((){_isEphemeral=true; _ephemeralDuration=sec;}); Navigator.pop(ctx); });
        }),
        const Divider(), const SizedBox(height:8),
        Row(children:[Expanded(child:TextField(controller:customCtrl, keyboardType:TextInputType.number, inputFormatters:[FilteringTextInputFormatter.digitsOnly], decoration:InputDecoration(hintText:'Temps perso en sec (ex: 120)', filled:true, fillColor:ivory, border:OutlineInputBorder(borderRadius:BorderRadius.circular(12), borderSide:BorderSide.none)))), const SizedBox(width:8), ElevatedButton(style:ElevatedButton.styleFrom(backgroundColor:primaryBlue), onPressed:(){ final v=int.tryParse(customCtrl.text); if(v!=null&&v>0){ setState((){_isEphemeral=true; _ephemeralDuration=v;}); Navigator.pop(ctx); } }, child:const Text('OK',style:TextStyle(color:Colors.white)))]),
      ]),
    ));
  }

  void _showPasswordProtectDialog(){
    final msgCtrl=TextEditingController(); final passCtrl=TextEditingController();
    showDialog(context:context, builder:(ctx)=>AlertDialog(backgroundColor:pureWhite, shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16)), title:const Row(children:[Icon(Icons.lock_rounded,color:primaryBlue),SizedBox(width:8),Text('Message Protégé',style:TextStyle(fontWeight:FontWeight.bold))]), content:Column(mainAxisSize:MainAxisSize.min, children:[TextField(controller:msgCtrl,maxLines:5,decoration:InputDecoration(hintText:'Message secret...',filled:true,fillColor:ivory,border:OutlineInputBorder(borderRadius:BorderRadius.circular(12),borderSide:BorderSide.none))), const SizedBox(height:12), TextField(controller:passCtrl,obscureText:true,decoration:InputDecoration(hintText:'Mot de passe',prefixIcon:const Icon(Icons.key_rounded,color:primaryBlue),filled:true,fillColor:ivory,border:OutlineInputBorder(borderRadius:BorderRadius.circular(12),borderSide:BorderSide.none)))]), actions:[TextButton(onPressed:()=>Navigator.pop(ctx), child:const Text('Annuler')), ElevatedButton(style:ElevatedButton.styleFrom(backgroundColor:primaryBlue), onPressed:() async { if(msgCtrl.text.isNotEmpty&&passCtrl.text.isNotEmpty){ final enc=EncryptionService.encryptMessage(msgCtrl.text, passCtrl.text); await _chatService.sendMessage(conversationId:widget.conversationId, content:enc, replyToId:_replyToId.isEmpty?null:_replyToId, isEphemeral:_isEphemeral, ephemeralDuration:_ephemeralDuration); if(mounted) Navigator.pop(ctx); } }, child:const Text('Envoyer',style:TextStyle(color:Colors.white)))]));
  }

  void _startAudioRecording() async { final st=await Permission.microphone.request(); if(st.isGranted){ showModalBottomSheet(context:context, isScrollControlled:true, backgroundColor:Colors.transparent, builder:(ctx)=>Container(decoration:const BoxDecoration(color:Colors.white,borderRadius:BorderRadius.vertical(top:Radius.circular(22))), padding:const EdgeInsets.all(20), child:AudioRecorderWidget(audioService:_audioService, onRecordingComplete:(p,d){ Navigator.pop(ctx); _sendAudio(p,d); }, onRecordingCanceled:()=>Navigator.pop(ctx), maxDuration:120))); } else if(st.isPermanentlyDenied){ openAppSettings(); } }
  Future<void> _sendAudio(String path,int dur) async { try{ final bytes=await File(path).readAsBytes(); final msg=await _chatService.sendAudioMessage(conversationId:widget.conversationId, audioData:Uint8List.fromList(bytes), duration:dur, isEphemeral:_isEphemeral, ephemeralDuration:_ephemeralDuration, replyToId:_replyToId.isEmpty?null:_replyToId); if(mounted) setState((){_messages.add(msg); _replyToId='';}); _scrollToBottom(); }catch(e){ if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Erreur audio: $e'),backgroundColor:danger)); } }

  void _showAttachmentMenu(){
    showModalBottomSheet(context:context, backgroundColor:pureWhite, shape:const RoundedRectangleBorder(borderRadius:BorderRadius.vertical(top:Radius.circular(22))), builder:(ctx)=>SafeArea(child:Column(mainAxisSize:MainAxisSize.min, children:[
      const SizedBox(height:12), Container(width:40,height:4,decoration:BoxDecoration(color:hairline,borderRadius:BorderRadius.circular(4))),
      const Padding(padding:EdgeInsets.all(16), child:Row(children:[Icon(Icons.attach_file_rounded,color:primaryBlue),SizedBox(width:10),Text('Envoyer',style:TextStyle(fontWeight:FontWeight.w800,fontSize:16))])),
      ListTile(leading:Container(padding:const EdgeInsets.all(8),decoration:BoxDecoration(color:gold.withValues(alpha:0.12),borderRadius:BorderRadius.circular(10)),child:const Icon(Icons.image_rounded,color:gold)), title:const Text('Photo'), onTap:(){ Navigator.pop(ctx); _pickFile(type:FileType.image); }),
      ListTile(leading:Container(padding:const EdgeInsets.all(8),decoration:BoxDecoration(color:primaryBlue.withValues(alpha:0.12),borderRadius:BorderRadius.circular(10)),child:const Icon(Icons.videocam_rounded,color:primaryBlue)), title:const Text('Vidéo'), onTap:(){ Navigator.pop(ctx); _pickFile(type:FileType.video); }),
      ListTile(leading:Container(padding:const EdgeInsets.all(8),decoration:BoxDecoration(color:navyDeep.withValues(alpha:0.12),borderRadius:BorderRadius.circular(10)),child:const Icon(Icons.insert_drive_file_rounded,color:navyDeep)), title:const Text('Document'), onTap:(){ Navigator.pop(ctx); _pickFile(type:FileType.any); }),
      const SizedBox(height:12),
    ])));
  }

  Future<void> _pickFile({FileType type=FileType.any}) async {
    try{
      final result=await FilePicker.platform.pickFiles(allowMultiple:false, type:type, withData:true);
      if(result==null||result.files.isEmpty) return;
      final f=result.files.first; final bytes=f.bytes ?? (f.path!=null? await File(f.path!).readAsBytes() : null); if(bytes==null) return;
      final ext=f.extension??'jpg'; final size=f.size;
      final url=await _chatService.uploadFileWithUniqueName('chat-media','messages/${widget.conversationId}', Uint8List.fromList(bytes), ext);
      if(url!=null){ final msg=await _chatService.sendMessage(conversationId:widget.conversationId, content: f.name, mediaUrl:url, mediaType: _getMediaType(ext), mediaName:f.name, mediaSize:size, isEphemeral:_isEphemeral, ephemeralDuration:_ephemeralDuration); if(mounted) setState(()=>_messages.add(msg)); _scrollToBottom(); }
    }catch(e){ if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Erreur fichier: $e'),backgroundColor:danger)); }
  }
  String _getMediaType(String ext){ const img={'jpg','jpeg','png','gif','webp'}; const vid={'mp4','mov','avi','mkv'}; const aud={'mp3','wav','m4a'}; final e=ext.toLowerCase(); if(img.contains(e)) return 'image'; if(vid.contains(e)) return 'video'; if(aud.contains(e)) return 'audio'; return 'file'; }

  void _escalateConversation(){ context.pushNamed('chatEscalate', pathParameters:{'conversationId':widget.conversationId}, queryParameters:{'agentId':_chatService.currentUserId??'','agentName':_chatService.currentUser?.userMetadata?['full_name']??'Agent'}); }
  void _viewEscalationHistory(){ context.pushNamed('chatEscalationHistory', pathParameters:{'conversationId':widget.conversationId}); }
  void _toggleInternalNoteMode(){ setState(()=>_isInternalNoteMode=!_isInternalNoteMode); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(_isInternalNoteMode?'Mode note interne ON':'Mode note interne OFF'), backgroundColor:_isInternalNoteMode?Colors.orange:mutedText)); }

  void _onTypingChanged(String t){ if(t.isNotEmpty&&!_isTyping){ _isTyping=true; _sendTypingStatus(true); } else if(t.isEmpty&&_isTyping){ _isTyping=false; _sendTypingStatus(false); } _typingTimer?.cancel(); _typingTimer=Timer(const Duration(seconds:2),(){ if(_isTyping){ _isTyping=false; _sendTypingStatus(false); } }); }

  @override Widget build(BuildContext context){
    return Scaffold(
      backgroundColor:primaryBlue,
      appBar:AppBar(
        backgroundColor:primaryBlue, elevation:0, titleSpacing:0,
        leading:IconButton(icon:const Icon(Icons.arrow_back_rounded,color:Colors.white), onPressed:()=>Navigator.pop(context)),
        title:Row(children:[
          CircleAvatar(radius:19,backgroundColor:Colors.white.withValues(alpha:0.2),child:widget.conversation.isGroup?const Icon(Icons.groups_rounded,color:Colors.white,size:18): ClipOval(child:CachedNetworkImage(imageUrl:'https://i.pravatar.cc/150?img=11',width:38,height:38,fit:BoxFit.cover, errorWidget:(_,__,___)=>const Icon(Icons.person,color:Colors.white)))) ,
          const SizedBox(width:12),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Text(widget.conversation.displayName,style:const TextStyle(fontSize:16,fontWeight:FontWeight.bold,color:Colors.white),maxLines:1,overflow:TextOverflow.ellipsis), if(!widget.conversation.isGroup&&_otherParticipant!=null) Row(children:[Container(width:7,height:7,decoration:BoxDecoration(shape:BoxShape.circle,color:_otherParticipant!.status=='online'?success:Colors.white38)), const SizedBox(width:5), Text(_otherParticipant!.status=='online'?'En ligne':'Vu ${_formatLastSeen(_otherParticipant!.lastSeenAt??DateTime.now())}',style:const TextStyle(fontSize:11,color:Colors.white70))])])),
        ]),
        actions:[
          IconButton(icon:const Icon(Icons.videocam_rounded,color:Colors.white), onPressed:()=>_startCall(CallType.video)),
          IconButton(icon:const Icon(Icons.call_rounded,color:Colors.white), onPressed:()=>_startCall(CallType.audio)),
          PopupMenuButton<String>(icon:const Icon(Icons.more_vert_rounded,color:Colors.white), onSelected:(v){ if(v=='escalate') _escalateConversation(); else if(v=='history') _viewEscalationHistory(); else if(v=='group') GoRouter.of(context).go('/group/${widget.conversationId}'); }, itemBuilder:(c)=>[const PopupMenuItem(value:'escalate',child:Row(children:[Icon(Icons.arrow_upward,color:Colors.orange),SizedBox(width:8),Text('Escalader')])), const PopupMenuItem(value:'history',child:Row(children:[Icon(Icons.history,color:Colors.blue),SizedBox(width:8),Text('Historique escalades')])), if(widget.conversation.isGroup) const PopupMenuItem(value:'group',child:Row(children:[Icon(Icons.info_outline),SizedBox(width:8),Text('Infos groupe')]))]),
          const SizedBox(width:4),
        ],
      ),
      body:SafeArea(bottom:false, child:Column(children:[
        Expanded(child:Container(width:double.infinity,decoration:const BoxDecoration(color:pureWhite,borderRadius:BorderRadius.vertical(top:Radius.circular(22))), child:ClipRRect(borderRadius:const BorderRadius.vertical(top:Radius.circular(22)), child:Column(children:[
          if(widget.conversation.isGroup) GroupInfoPanel(conversation:widget.conversation,members:_groupMembers,onViewAllMembers:()=>GoRouter.of(context).go('/group/${widget.conversationId}'),onEditGroup:(){},onLeaveGroup:(){},onDeleteGroup:(){}),
          if(_isConversationEscalated) Container(padding:const EdgeInsets.all(8),color:Colors.orange.shade100,child:const Row(children:[Icon(Icons.warning_amber_rounded,color:Colors.orange),SizedBox(width:8),Expanded(child:Text('Conversation escaladée',style:TextStyle(color:Colors.orange)))])),
          Expanded(child:_isLoading?const Center(child:CircularProgressIndicator(color:primaryBlue)):Stack(children:[ListView.builder(controller:_scrollController,reverse:true,padding:const EdgeInsets.symmetric(horizontal:16,vertical:12),itemCount:_messages.length+(_isLoadingMore?1:0),itemBuilder:(ctx,i){ if(i==_messages.length&&_isLoadingMore) return const Padding(padding:EdgeInsets.all(8),child:Center(child:CircularProgressIndicator(strokeWidth:2,color:primaryBlue))); final msg=_messages[_messages.length-1-i]; final isOwn=msg.senderId==_chatService.currentUserId; return ChatMessageBubble(message:msg,isOwn:isOwn,onReply:()=>setState(()=>_replyToId=msg.id),onDelete:() async { setState(()=>_messages.removeWhere((m)=>m.id==msg.id)); if(isOwn) try{await _chatService.deleteMessage(msg.id);}catch(_){} },onReaction:(r)=>_chatService.toggleReaction(msg.id,r),replyToMessage:msg.replyToId!=null?_messages.where((m)=>m.id==msg.replyToId).firstOrNull:null,isEphemeralActive:msg.isEphemeral,isInternalNote:msg.isInternalNote,isAgentView:_isAgent); }), if(_otherUserTyping) Positioned(bottom:8,left:16,child:Container(padding:const EdgeInsets.symmetric(horizontal:14,vertical:9),decoration:BoxDecoration(color:leftBubbleColor,borderRadius:BorderRadius.circular(20)),child:const Text("En train d'écrire...",style:TextStyle(fontSize:11,color:primaryBlue,fontStyle:FontStyle.italic))))])),
          if(_replyToId.isNotEmpty) Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:8),decoration:BoxDecoration(color:pureWhite,border:Border(top:BorderSide(color:hairline))),child:Row(children:[Container(width:4,height:40,decoration:BoxDecoration(color:primaryBlue,borderRadius:BorderRadius.circular(4))),const SizedBox(width:10),Expanded(child:Text(_messages.firstWhere((m)=>m.id==_replyToId,orElse:()=>_messages.first).content,maxLines:1,overflow:TextOverflow.ellipsis)),IconButton(icon:const Icon(Icons.close_rounded,size:16),onPressed:()=>setState(()=>_replyToId=''))])),
          ChatInputBar(controller:_inputController,focusNode:_inputFocus,onSend:_sendMessage,isSending:_isSending,onAttach:_showAttachmentMenu,onAudio:_startAudioRecording,onSecureMessage:_showPasswordProtectDialog,onEphemeralToggle:_showEphemeralTimerDialog,isEphemeral:_isEphemeral,onTyping:_onTypingChanged,onInternalNoteToggle:_isAgent? _toggleInternalNoteMode : null,isInternalNote:_isInternalNoteMode),
        ])))),
      ])),
    );
  }

  String _formatLastSeen(DateTime d){ final diff=DateTime.now().difference(d); if(diff.inDays==0) return 'à ${DateFormat('HH:mm').format(d)}'; if(diff.inDays==1) return 'hier à ${DateFormat('HH:mm').format(d)}'; return 'le ${DateFormat('dd/MM/yyyy').format(d)}'; }
}
