// lib/presentation/thix_sante/patient/screens/assistant_ia_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/thix_sante_colors.dart';

class AssistantIAPage extends StatefulWidget {
  const AssistantIAPage({super.key});
  @override State<AssistantIAPage> createState() => _AssistantIAPageState();
}

class _AssistantIAPageState extends State<AssistantIAPage> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _db = Supabase.instance.client;
  String? _convId;
  bool _loading = false;
  List<Map<String,dynamic>> _messages = [];
  Map<String,dynamic>? _dossier;

  @override
  void initState(){ super.initState(); _init(); }

  Future<void> _init() async {
    final uid = _db.auth.currentUser!.id;
    // 1. recup dossier reel pour header
    final c = await _db.from('health_links').select('id').eq('patient_id', uid);
    final e = await _db.from('health_records').select('id').eq('patient_id', uid);
    final p = await _db.from('prescriptions').select('id').eq('patient_id', uid);
    setState(()=> _dossier = {'c': (c as List).length, 'e': (e as List).length, 'p': (p as List).length});

    // 2. cree ou recupere derniere conversation
    final conv = await _db.from('ai_conversations').select().eq('patient_id', uid).order('created_at', ascending:false).limit(1).maybeSingle();
    if(conv==null){
      final newConv = await _db.from('ai_conversations').insert({'patient_id': uid, 'title': 'Nouvelle discussion'}).select().single();
      _convId = newConv['id'];
      _messages = [{'role':'ia','content':'Bonjour 👋 Je suis THIX IA Santé, branché à votre dossier THIX ID (${_dossier!['c']} consultations, ${_dossier!['e']} examens). Comment puis-je vous aider?'}];
    } else {
      _convId = conv['id'];
      final msgs = await _db.from('ai_messages').select().eq('conversation_id', _convId!).order('created_at');
      setState(()=> _messages = List<Map<String,dynamic>>.from(msgs).map((m)=> {'role': m['role'], 'content': m['content']}).toList());
      if(_messages.isEmpty){
        _messages = [{'role':'ia','content':'Re-bonjour 👋 On reprend où on s\'était arrêté?'}];
      }
    }
    setState((){});
  }

  Future<void> _send(String text) async {
    if(text.trim().isEmpty || _convId==null) return;
    setState((){ _messages.add({'role':'user','content':text}); _loading=true; _ctrl.clear(); });
    _toBottom();
    try{
      final res = await _db.functions.invoke('thix-ia-chat', body: {'conversation_id': _convId, 'message': text});
      final reply = res.data['reply']?? 'Désolé, erreur IA';
      setState(()=> _messages.add({'role':'ia','content':reply}));
    } catch(e){
      setState(()=> _messages.add({'role':'ia','content':'Erreur connexion IA: $e'}));
    }
    setState(()=> _loading=false);
    _toBottom();
  }

  void _toBottom()=> WidgetsBinding.instance.addPostFrameCallback((_){
    if(_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent+100, duration: const Duration(milliseconds:300), curve: Curves.easeOut);
  });

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation:0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)), onPressed: ()=> Navigator.pop(context)),
        title: Row(children:[
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size:16)),
          const SizedBox(width:8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
            const Text('THIX IA Santé', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize:15)),
            Text(_dossier==null? 'Connexion THIX ID...' : 'THIX ID actif • ${_dossier!['c']} cons. • ${_dossier!['e']} examens', style: const TextStyle(color: Color(0xFF22C55E), fontSize:10, fontWeight: FontWeight.w600)),
          ])
        ]),
      ),
      body: Column(children:[
        Container(color: const Color(0xFFFEF9C3), padding: const EdgeInsets.symmetric(horizontal:14, vertical:8), child: const Row(children:[Icon(Icons.medical_information_rounded, size:16, color: Color(0xFFCA8A04)), SizedBox(width:8), Expanded(child: Text('IA éducative uniquement. Ne remplace pas un avis médical. Dossier THIX ID utilisé en lecture seule.', style: TextStyle(fontSize:10, color: Color(0xFF713F12))))])),
        Expanded(child: ListView.separated(
          controller: _scroll,
          padding: const EdgeInsets.all(16),
          itemCount: _messages.length + (_loading?1:0),
          separatorBuilder: (_,__)=> const SizedBox(height:10),
          itemBuilder: (c,i){
            if(_loading && i==_messages.length) return const Align(alignment: Alignment.centerLeft, child: Text('THIX IA écrit...', style: TextStyle(fontSize:11, color: Colors.grey)));
            final m = _messages[i];
            final isUser = m['role']=='user';
            return Align(
              alignment: isUser? Alignment.centerRight: Alignment.centerLeft,
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width*0.78),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: isUser? const Color(0xFF2563EB): Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isUser? const Color(0xFF2563EB): const Color(0xFFE2E8F0))),
                child: Text(m['content'], style: TextStyle(fontSize:13, height:1.4, color: isUser? Colors.white: const Color(0xFF0F172A))),
              ),
            );
          },
        )),
        Container(
          color: Colors.white,
          padding: EdgeInsets.only(left:12,right:12,top:10,bottom: MediaQuery.of(context).padding.bottom+10),
          child: Row(children:[
            Expanded(child: TextField(controller: _ctrl, decoration: InputDecoration(hintText: 'Posez une question santé...', filled:true, fillColor: const Color(0xFFF1F5F9), border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal:16, vertical:10)), onSubmitted: _send)),
            const SizedBox(width:8),
            IconButton.filled(onPressed: _loading? null: ()=> _send(_ctrl.text), icon: const Icon(Icons.send_rounded, size:18), style: IconButton.styleFrom(backgroundColor: const Color(0xFF2563EB))),
          ]),
        )
      ]),
    );
  }
}
