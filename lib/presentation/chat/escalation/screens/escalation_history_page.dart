import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/escalation_provider.dart';
import '../widgets/level_badge.dart';
import '../widgets/priority_chip.dart';
import '../widgets/status_indicator.dart';
import '../../../chat/chat_screen.dart';
import '../../../../services/chat/chat_service.dart';

class _C {
  static const bg = Colors.white;
  static const searchBg = Color(0xFFF8FAFC);
  static const border = Color(0xFFE2E8F0);
  static const primary = Color(0xFF1D4ED8);
  static const textMain = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);
  static const red = Color(0xFFEF4444);
}

class EscalationHistoryPage extends StatelessWidget {
  final String conversationId;
  const EscalationHistoryPage({Key? key, required this.conversationId}) : super(key: key);

  Future<void> _openConversation(BuildContext context, String convId) async {
    try {
      final chatService = ChatService(Supabase.instance.client);
      final conv = await chatService.getConversation(convId);
      if (conv != null && context.mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversationId: convId, conversation: conv)));
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e'), backgroundColor: _C.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EscalationProvider>(context, listen: true);

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.bg,
        surfaceTintColor: _C.bg,
        elevation: 0,
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: _C.border)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: _C.textMain), onPressed: () => Navigator.pop(context)),
        title: const Text('Historique des escalades', style: TextStyle(color: _C.textMain, fontSize: 15, fontWeight: FontWeight.w800)),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: _C.primary, strokeWidth: 2))
          : provider.history.isEmpty
              ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.history_rounded, size: 42, color: _C.border), SizedBox(height: 8), Text('Aucune escalade pour cette conversation', style: TextStyle(color: _C.textMuted, fontSize: 13))]))
              : RefreshIndicator(
                  color: _C.primary,
                  onRefresh: () => provider.loadHistory(conversationId),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                    itemCount: provider.history.length,
                    itemBuilder: (context, index) {
                      final step = provider.history[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: _C.border), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2))]),
                        child: InkWell(
                          onTap: () => _openConversation(context, step.conversationId),
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                LevelBadge(level: step.fromLevel),
                                const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.arrow_forward_rounded, size: 14, color: _C.textMuted)),
                                LevelBadge(level: step.toLevel),
                                const Spacer(),
                                PriorityChip(priority: step.priority),
                              ]),
                              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: _C.border)),
                              Text(step.reason, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _C.textMain)),
                              if (step.comment != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text('Commentaire: ${step.comment}', style: const TextStyle(fontSize: 11, color: _C.textMuted))),
                              const SizedBox(height: 10),
                              Row(children: [StatusIndicator(status: step.status), const Spacer(), Text(step.createdAt.toString().substring(0, 16), style: const TextStyle(fontSize: 10, color: _C.textMuted))]),
                              if (step.resolvedAt != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text('Résolu le: ${step.resolvedAt!.toString().substring(0, 16)}', style: const TextStyle(fontSize: 10, color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
                                ),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
