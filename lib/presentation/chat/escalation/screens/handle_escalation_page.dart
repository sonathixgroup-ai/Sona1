import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/escalation_level.dart';
import '../models/escalation_step.dart';
import '../models/escalation_status.dart';
import '../providers/escalation_provider.dart';
import '../widgets/level_badge.dart';
import '../widgets/priority_chip.dart';
import '../widgets/status_indicator.dart';

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

class HandleEscalationPage extends StatefulWidget {
  final String escalationId;
  final String agentId;
  const HandleEscalationPage({Key? key, required this.escalationId, required this.agentId}) : super(key: key);
  @override State<HandleEscalationPage> createState() => _HandleEscalationPageState();
}

class _HandleEscalationPageState extends State<HandleEscalationPage> {
  final _rejectReasonController = TextEditingController();
  bool _showRejectReason = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = context.read<EscalationProvider>();
    await provider.loadPendingEscalations(widget.agentId, EscalationLevel.senior);
  }

  @override
  void dispose() {
    _rejectReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EscalationProvider>();
    EscalationStep? escalation;
    try {
      escalation = provider.pendingEscalations.firstWhere((e) => e.id == widget.escalationId);
    } catch (_) {
      escalation = null;
    }

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.bg,
        surfaceTintColor: _C.bg,
        elevation: 0,
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: _C.border)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: _C.textMain), onPressed: () => context.pop()),
        title: const Text('Gérer l\'escalade', style: TextStyle(color: _C.textMain, fontSize: 15, fontWeight: FontWeight.w800)),
      ),
      body: escalation == null
          ? const Center(child: CircularProgressIndicator(color: _C.primary, strokeWidth: 2))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.border)),
                  child: Row(children: [
                    LevelBadge(level: escalation.toLevel),
                    const SizedBox(width: 8),
                    PriorityChip(priority: escalation.priority),
                    const Spacer(),
                    StatusIndicator(status: escalation.status),
                  ]),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: _C.searchBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.border)),
                  child: Column(children: [
                    _infoRow('De', escalation.fromAgentName ?? escalation.fromAgentId),
                    _infoRow('À', escalation.toAgentName ?? escalation.toAgentId),
                    _infoRow('Raison', escalation.reason),
                    if (escalation.comment != null) _infoRow('Commentaire', escalation.comment!),
                    _infoRow('Date', escalation.createdAt.toString().substring(0, 16)),
                  ]),
                ),
                const SizedBox(height: 20),
                if (escalation.status == EscalationStatus.pending) ...[
                  const Text('Actions', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: _C.textMain)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: provider.isLoading ? null : _accept,
                        icon: provider.isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Accepter', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(backgroundColor: _C.primary, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: provider.isLoading ? null : () => setState(() => _showRejectReason = !_showRejectReason),
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text('Refuser', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(foregroundColor: _C.red, side: const BorderSide(color: _C.border), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                  ]),
                  if (_showRejectReason) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _rejectReasonController,
                      style: const TextStyle(color: _C.textMain, fontSize: 13),
                      maxLines: 2,
                      decoration: InputDecoration(hintText: 'Motif du refus', filled: true, fillColor: _C.bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _C.border)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _C.primary))),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(width: double.infinity, child: ElevatedButton(onPressed: provider.isLoading ? null : _reject, style: ElevatedButton.styleFrom(backgroundColor: _C.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('Confirmer le refus'))),
                  ],
                ],
                if (escalation.status == EscalationStatus.accepted) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFA7F3D0))),
                    child: const Row(children: [Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18), SizedBox(width: 8), Expanded(child: Text('Escalade acceptée. Vous pouvez maintenant traiter la conversation.', style: TextStyle(color: Color(0xFF166534), fontSize: 12)))]),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: provider.isLoading ? null : _resolve,
                      icon: provider.isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.done_all_rounded, size: 18),
                      label: const Text('Marquer comme résolu', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      style: ElevatedButton.styleFrom(backgroundColor: _C.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                ],
                if (escalation.status == EscalationStatus.resolved)
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFA7F3D0))), child: const Row(children: [Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18), SizedBox(width: 8), Text('Cette escalade est résolue.', style: TextStyle(color: Color(0xFF166534), fontSize: 12, fontWeight: FontWeight.w600))])),
                if (escalation.status == EscalationStatus.rejected)
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFECACA))), child: const Row(children: [Icon(Icons.cancel_rounded, color: _C.red, size: 18), SizedBox(width: 8), Text('Cette escalade a été refusée.', style: TextStyle(color: _C.red, fontSize: 12, fontWeight: FontWeight.w600))])),
                const SizedBox(height: 20),
                if (provider.error != null) Text('Erreur: ${provider.error}', style: const TextStyle(color: _C.red, fontSize: 11)),
              ]),
            ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 90, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600, color: _C.textMuted, fontSize: 12))),
        Expanded(child: Text(value, style: const TextStyle(color: _C.textMain, fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
    );
  }

  void _accept() async {
    final provider = context.read<EscalationProvider>();
    final success = await provider.acceptEscalation(widget.escalationId, widget.agentId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success != null ? 'Escalade acceptée' : 'Erreur: ${provider.error}'), backgroundColor: success != null ? const Color(0xFF16A34A) : _C.red));
  }

  void _reject() async {
    if (_rejectReasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez indiquer un motif de refus')));
      return;
    }
    final provider = context.read<EscalationProvider>();
    final success = await provider.rejectEscalation(widget.escalationId, _rejectReasonController.text);
    if (!mounted) return;
    if (success != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escalade refusée'), backgroundColor: _C.textMain));
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${provider.error}'), backgroundColor: _C.red));
    }
  }

  void _resolve() async {
    final provider = context.read<EscalationProvider>();
    final success = await provider.resolveEscalation(widget.escalationId);
    if (!mounted) return;
    if (success != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escalade résolue'), backgroundColor: Color(0xFF16A34A)));
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${provider.error}'), backgroundColor: _C.red));
    }
  }
}
