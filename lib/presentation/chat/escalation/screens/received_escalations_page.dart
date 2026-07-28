import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../models/escalation_step.dart';
import '../models/escalation_status.dart';
import '../providers/escalation_provider.dart';
import '../../chat_screen.dart';
import '../../../../services/chat/chat_service.dart';

class _C {
  static const bg = Colors.white;
  static const searchBg = Color(0xFFF8FAFC);
  static const border = Color(0xFFE2E8F0);
  static const primary = Color(0xFF1D4ED8);
  static const primaryLight = Color(0xFFEFF6FF);
  static const textMain = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);
  static const red = Color(0xFFEF4444);
}

class ReceivedEscalationsPage extends StatefulWidget {
  const ReceivedEscalationsPage({super.key});
  @override State<ReceivedEscalationsPage> createState() => _ReceivedEscalationsPageState();
}

class _ReceivedEscalationsPageState extends State<ReceivedEscalationsPage> {
  final List<EscalationStep> _escalations = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  late ChatService _chatService;
  final _scroll = ScrollController();
  int _page = 0;
  static const _limit = 20;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(Supabase.instance.client);
    _loadEscalations(refresh: true);
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300 &&!_loadingMore && _hasMore) {
        _loadEscalations();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadEscalations({bool refresh = false}) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) { setState(() => _loading = false); return; }
    if (refresh) { _page = 0; _hasMore = true; _escalations.clear(); setState(() => _loading = true); }
    if (!_hasMore) return;
    setState(() => refresh? _loading = true : _loadingMore = true);
    try {
      final from = _page * _limit;
      final to = from + _limit - 1;
      final response = await Supabase.instance.client
         .from('escalation_steps')
         .select('*, from_agent_name, to_agent_name, reason, status, created_at, conversation_id')
         .eq('to_agent_id', user.id)
         .order('created_at', ascending: false)
         .range(from, to);

      final list = response.map((j) => EscalationStep.fromJson(j)).toList();
      setState(() {
        _escalations.addAll(list);
        _page++;
        _hasMore = list.length == _limit;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; _loadingMore = false; });
    }
  }

  Future<void> _openConversation(EscalationStep step) async {
    try {
      final conv = await _chatService.getConversation(step.conversationId);
      if (conv!= null && mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversationId: step.conversationId, conversation: conv)));
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conversation introuvable.'), backgroundColor: _C.textMain));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e'), backgroundColor: _C.red));
    }
  }

  Future<void> _accept(String id) async {
    final provider = context.read<EscalationProvider>();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final success = await provider.acceptEscalation(id, user.id);
    if (success!= null) {
      _loadEscalations(refresh: true);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escalade acceptée'), backgroundColor: Color(0xFF16A34A)));
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${provider.error}'), backgroundColor: _C.red));
    }
  }

  Future<void> _reject(String id) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: _C.border)),
        title: const Text('Refuser l\'escalade', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _C.textMain)),
        content: TextField(
          controller: reasonController,
          style: const TextStyle(color: _C.textMain, fontSize: 13),
          decoration: InputDecoration(hintText: 'Motif du refus', filled: true, fillColor: _C.searchBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _C.border))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler', style: TextStyle(color: _C.textMuted))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: _C.red), child: const Text('Refuser', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirmed!= true) return;
    final provider = context.read<EscalationProvider>();
    final success = await provider.rejectEscalation(id, reasonController.text);
    if (success!= null) {
      _loadEscalations(refresh: true);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escalade refusée'), backgroundColor: _C.textMain));
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${provider.error}'), backgroundColor: _C.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.bg,
        surfaceTintColor: _C.bg,
        elevation: 0,
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: _C.border)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: _C.textMain), onPressed: () => Navigator.pop(context)),
        title: const Text('Escalades reçues', style: TextStyle(color: _C.textMain, fontSize: 15, fontWeight: FontWeight.w800)),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded, color: _C.textMuted), onPressed: () => _loadEscalations(refresh: true))],
      ),
      body: _loading
         ? const Center(child: CircularProgressIndicator(color: _C.primary, strokeWidth: 2))
          : _error!= null
             ? Center(child: Text('Erreur : $_error', style: const TextStyle(color: _C.textMuted, fontSize: 12)))
              : _escalations.isEmpty
                 ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.inbox_outlined, size: 42, color: _C.border), SizedBox(height: 8), Text('Aucune escalade reçue', style: TextStyle(color: _C.textMuted, fontSize: 13))]))
                  : RefreshIndicator(
                      color: _C.primary,
                      onRefresh: () => _loadEscalations(refresh: true),
                      child: ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                        itemCount: _escalations.length + (_loadingMore? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _escalations.length) return const Padding(padding: EdgeInsets.all(16), child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _C.primary))));
                          final step = _escalations[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: _C.border), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2))]),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => _openConversation(step),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Container(width: 28, height: 28, decoration: BoxDecoration(color: _C.searchBg, shape: BoxShape.circle, border: Border.all(color: _C.border)), child: const Icon(Icons.person_rounded, size: 14, color: _C.textMuted)),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(step.fromAgentName?? 'Inconnu', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _C.textMain))),
                                    _buildStatusChip(step.status),
                                  ]),
                                  const SizedBox(height: 8),
                                  Text('Raison : ${step.reason}', style: const TextStyle(fontSize: 12, color: _C.textMain)),
                                  if (step.comment!= null) Padding(padding: const EdgeInsets.only(top: 2), child: Text('Commentaire : ${step.comment}', style: const TextStyle(fontSize: 11, color: _C.textMuted))),
                                  const SizedBox(height: 6),
                                  Text('Demandé le ${step.createdAt.toString().substring(0, 16)}', style: const TextStyle(fontSize: 10, color: _C.textMuted)),
                                  if (step.status == EscalationStatus.pending)...[
                                    const SizedBox(height: 10),
                                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                                      ElevatedButton.icon(
                                        onPressed: () => _accept(step.id),
                                        icon: const Icon(Icons.check_rounded, size: 16),
                                        label: const Text('Accepter', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                        style: ElevatedButton.styleFrom(backgroundColor: _C.primary, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton.icon(
                                        onPressed: () => _reject(step.id),
                                        icon: const Icon(Icons.close_rounded, size: 16),
                                        label: const Text('Refuser', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                        style: OutlinedButton.styleFrom(foregroundColor: _C.red, side: const BorderSide(color: _C.border), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                      ),
                                    ]),
                                  ],
                                ]),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildStatusChip(EscalationStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: status.color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: status.color.withOpacity(0.2))),
      child: Text(status.label, style: TextStyle(color: status.color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}
