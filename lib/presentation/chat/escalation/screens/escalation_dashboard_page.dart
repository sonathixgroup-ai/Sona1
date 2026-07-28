import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/escalation_provider.dart';
import '../models/escalation_level.dart';
import '../models/escalation_step.dart';

class _C {
  static const bg = Colors.white;
  static const searchBg = Color(0xFFF8FAFC);
  static const border = Color(0xFFE2E8F0);
  static const primary = Color(0xFF1D4ED8);
  static const textMain = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);
}

class EscalationDashboardPage extends StatelessWidget {
  final String agentId;
  final EscalationLevel agentLevel;
  const EscalationDashboardPage({Key? key, required this.agentId, required this.agentLevel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EscalationProvider>();
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.bg,
        surfaceTintColor: _C.bg,
        elevation: 0,
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: _C.border)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: _C.textMain), onPressed: () => context.pop()),
        title: const Text('Dashboard Escalades', style: TextStyle(color: _C.textMain, fontSize: 15, fontWeight: FontWeight.w800)),
      ),
      body: RefreshIndicator(
        color: _C.primary,
        onRefresh: () => provider.loadPendingEscalations(agentId, agentLevel),
        child: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: _C.primary, strokeWidth: 2))
            : Column(children: [
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _C.border), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 2))]),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    _statItem('En attente', provider.pendingEscalations.length.toString(), _C.primary),
                    Container(width: 1, height: 36, color: _C.border),
                    _statItem('Acceptées', provider.history.where((e) => e.status.index == 1).length.toString(), const Color(0xFF16A34A)),
                    Container(width: 1, height: 36, color: _C.border),
                    _statItem('Résolues', provider.history.where((e) => e.status.index == 4).length.toString(), _C.textMain),
                  ]),
                ),
                Expanded(
                  child: provider.pendingEscalations.isEmpty
                    ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.inbox_outlined, size: 42, color: _C.border), SizedBox(height: 8), Text('Aucune escalade en attente', style: TextStyle(color: _C.textMuted, fontSize: 13))]))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                          itemCount: provider.pendingEscalations.length,
                          itemBuilder: (context, index) => _card(provider.pendingEscalations[index], context),
                        ),
                ),
              ]),
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) => Column(children: [Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)), const SizedBox(height: 2), Text(label, style: const TextStyle(fontSize: 11, color: _C.textMuted, fontWeight: FontWeight.w600))]);

  Widget _card(EscalationStep step, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: _C.border)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: step.priority.color.withOpacity(0.12), shape: BoxShape.circle, border: Border.all(color: step.priority.color.withOpacity(0.2))), child: Center(child: Text(step.priority.label[0], style: TextStyle(color: step.priority.color, fontWeight: FontWeight.w800, fontSize: 13)))),
        title: Text('De: ${step.fromAgentName?? step.fromAgentId}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _C.textMain)),
        subtitle: Text(step.reason, style: const TextStyle(fontSize: 11, color: _C.textMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Container(width: 32, height: 32, decoration: BoxDecoration(color: _C.searchBg, shape: BoxShape.circle, border: Border.all(color: _C.border)), child: IconButton(icon: const Icon(Icons.arrow_forward_rounded, color: _C.primary, size: 18), padding: EdgeInsets.zero, onPressed: () => context.push('/chat/escalation/handle/${step.id}'))),
      ),
    );
  }
}
