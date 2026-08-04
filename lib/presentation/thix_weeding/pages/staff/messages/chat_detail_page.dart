// lib/presentation/thix_weeding/pages/staff/messages/chat_detail_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatDetailPage extends StatefulWidget {
  final String weddingId; final String guestIdOrName; final String? guestName;
  const ChatDetailPage({super.key, required this.weddingId, required this.guestIdOrName, this.guestName});
  @override State<ChatDetailPage> createState()=> _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String,dynamic>> _messages = [];
  bool _loading = true;
  late final RealtimeChannel _channel;

  @override void initState(){
    super.initState();
    _loadMessages();
    _subscribe();
  }

  Future<void> _loadMessages() async {
    final supa = Supabase.instance.client;
    List<Map<String,dynamic>> res;
    try{
      res = await supa.from('thix_weeding_messages').select().eq('wedding_id', widget.weddingId).or('guest_id.eq.${widget.guestIdOrName},sender_name.eq.${widget.guestIdOrName}').order('created_at', ascending: true);
    } catch(_){
      res = await supa.from('thix_weeding_messages').select().eq('wedding_id', widget.weddingId).order('created_at');
    }
    setState((){ _messages = List<Map<String,dynamic>>.from(res); _loading=false; });
    _markAsRead();
    _jump();
  }

  void _subscribe(){
    _channel = Supabase.instance.client.channel('chat_${widget.weddingId}_${widget.guestIdOrName}').onPostgresChanges(event: PostgresChangeEvent.insert, schema: 'public', table: 'thix_weeding_messages', filter: PostgresChangeFilter(column: 'wedding_id', value: widget.weddingId), callback: (payload){
      final newMsg = payload.newRecord;
      if(newMsg['guest_id'].toString()==widget.guestIdOrName || newMsg['sender_name']==widget.guestIdOrName || widget.guestIdOrName.length>20){
        setState(()=> _messages.add(newMsg));
        _jump();
      }
    }).subscribe();
  }

  Future<void> _markAsRead() async {
    await Supabase.instance.client.from('thix_weeding_messages').update({'is_read': true}).eq('wedding_id', widget.weddingId).eq('is_read', false);
  }

  Future<void> _send() async {
    if(_ctrl.text.trim().isEmpty) return;
    final text = _ctrl.text.trim();
    _ctrl.clear();
    final supa = Supabase.instance.client;
    await supa.from('thix_weeding_messages').insert({
      'wedding_id': widget.weddingId,
      'guest_id': widget.guestIdOrName.length>20? widget.guestIdOrName : null,
      'sender_name': 'Staff',
      'sender_type': 'staff',
      'content': text,
      'is_read': false,
    });
  }

  void _jump(){ WidgetsBinding.instance.addPostFrameCallback((_){ if(_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent+200, duration: const Duration(milliseconds:300), curve: Curves.easeOut); }); }

  @override void dispose(){ _channel.unsubscribe(); _ctrl.dispose(); _scroll.dispose(); super.dispose(); }

  @override Widget build(BuildContext context)=> Scaffold(
    appBar: AppBar(title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.guestName?? widget.guestIdOrName, style: const TextStyle(fontSize:16, fontWeight: FontWeight.bold)), Text('ID: ${widget.guestIdOrName.toString().substring(0,8)}', style: const TextStyle(fontSize:10, color: Colors.grey))]), backgroundColor: Colors.white),
    body: Column(children: [
      Expanded(child: _loading? const Center(child: CircularProgressIndicator()): _messages.isEmpty? const Center(child: Text('Aucun message, commencez la discussion')) : ListView.builder(controller: _scroll, padding: const EdgeInsets.all(16), itemCount: _messages.length, itemBuilder: (_,i){
        final m = _messages[i];
        final isMe = m['sender_type']=='staff';
        return Align(alignment: isMe? Alignment.centerRight: Alignment.centerLeft, child: Container(margin: const EdgeInsets.only(bottom:8), padding: const EdgeInsets.symmetric(horizontal:14, vertical:10), constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width*0.75), decoration: BoxDecoration(color: isMe? const Color(0xFF0B3B8F): Colors.white, borderRadius: BorderRadius.circular(16).copyWith(bottomRight: isMe? const Radius.circular(4): null, bottomLeft:!isMe? const Radius.circular(4): null)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(m['content'], style: TextStyle(color: isMe?Colors.white:Colors.black87)),
          const SizedBox(height:4),
          Text('${m['created_at'].toString().substring(11,16)} • ${m['id'].toString().substring(0,4)}', style: TextStyle(fontSize:9, color: isMe?Colors.white70:Colors.grey)),
        ])));
      })),
      Container(padding: const EdgeInsets.all(12), color: Colors.white, child: Row(children: [
        Expanded(child: TextField(controller: _ctrl, decoration: InputDecoration(hintText:'Écrire un message...', filled: true, fillColor: const Color(0xFFF1F5F9), border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none)), onSubmitted: (_)=> _send())),
        const SizedBox(width:8),
        CircleAvatar(backgroundColor: const Color(0xFF0B3B8F), child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: _send)),
      ])),
    ]),
  );
}
