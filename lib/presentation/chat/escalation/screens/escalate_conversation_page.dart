import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/escalation_level.dart';
import '../models/escalation_priority.dart';
import '../providers/escalation_provider.dart';
import '../services/escalation_service.dart';

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

class EscalateConversationPage extends StatefulWidget {
  final String conversationId;
  final String fromAgentId;
  final String? fromAgentName;
  const EscalateConversationPage({Key? key, required this.conversationId, required this.fromAgentId, this.fromAgentName}) : super(key: key);
  @override State<EscalateConversationPage> createState() => _EscalateConversationPageState();
}

class _EscalateConversationPageState extends State<EscalateConversationPage> {
  final _formKey = GlobalKey<FormState>();
  EscalationLevel? _selectedLevel;
  EscalationPriority _selectedPriority = EscalationPriority.medium;
  final _reasonController = TextEditingController();
  final _commentController = TextEditingController();
  final _targetController = TextEditingController();
  String? _targetUserId;
  bool _isSearching = false;
  String? _searchError;
  Map<String, dynamic>? _foundUser;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() { super.initState(); _loadUsers(); }

  Future<void> _loadUsers() async {
    try {
      final res = await Supabase.instance.client.from('profiles').select('id, display_name, username, avatar_url').limit(50);
      setState(() => _users = List<Map<String, dynamic>>.from(res));
    } catch (e) { debugPrint('users load error $e'); }
  }

  @override
  void dispose() {
    _reasonController.dispose(); _commentController.dispose(); _targetController.dispose(); super.dispose();
  }

  Future<void> _searchUser() async {
    final identifier = _targetController.text.trim();
    if (identifier.isEmpty) { setState(() { _searchError = 'Veuillez saisir un identifiant'; _targetUserId = null; _foundUser = null; }); return; }
    final clean = identifier.startsWith('@') ? identifier.substring(1) : identifier;
    setState(() { _isSearching = true; _searchError = null; _targetUserId = null; _foundUser = null; });
    try {
      final user = await EscalationService().getUserByHandle(clean);
      if (user != null && user['id'] != null) {
        final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');
        if (uuidRegex.hasMatch(user['id'])) {
          setState(() { _targetUserId = user['id']; _foundUser = user; });
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Utilisateur trouvé : ${user['display_name'] ?? user['username']}'), backgroundColor: const Color(0xFF16A34A)));
        } else {
          setState(() => _searchError = 'ID invalide (non UUID)');
        }
      } else { setState(() => _searchError = 'Aucun utilisateur trouvé @$clean'); }
    } catch (e) { setState(() => _searchError = 'Erreur : $e'); }
    finally { setState(() => _isSearching = false); }
  }

  void _openContactPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _C.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(color: _C.bg, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(color: _C.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          Row(children: [const Text('Sélectionner un destinataire', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _C.textMain)), const Spacer(), IconButton(icon: const Icon(Icons.close_rounded, color: _C.textMuted), onPressed: () => Navigator.pop(ctx))]),
          const Divider(color: _C.border),
          TextField(decoration: InputDecoration(hintText: 'Rechercher...', prefixIcon: const Icon(Icons.search_rounded, color: _C.textMuted, size: 18), filled: true, fillColor: _C.searchBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _C.border)))),
          const SizedBox(height: 8),
          Expanded(child: _buildContactList(ctx)),
        ]),
      ),
    );
  }

  Widget _buildContactList(BuildContext ctx) {
    if (_users.isEmpty) return const Center(child: CircularProgressIndicator(color: _C.primary, strokeWidth: 2));
    return ListView.builder(
      itemCount: _users.length,
      itemBuilder: (_, i) {
        final user = _users[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(border: Border.all(color: _C.border), borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: _C.searchBg, shape: BoxShape.circle, border: Border.all(color: _C.border)), child: Center(child: Text((user['display_name'] ?? user['username'] ?? '?')[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700, color: _C.textMuted, fontSize: 12)))),
            title: Text(user['display_name'] ?? user['username'] ?? 'Inconnu', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _C.textMain)),
            subtitle: Text('@${user['username'] ?? ''}', style: const TextStyle(fontSize: 11, color: _C.textMuted)),
            onTap: () {
              final id = user['id'] as String;
              if (!RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$').hasMatch(id)) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID invalide'), backgroundColor: _C.red)); return;
              }
              _targetController.text = '@${user['username']}'; _targetUserId = id; _foundUser = user;
              setState(() => _searchError = null);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${user['display_name'] ?? user['username']} sélectionné'), backgroundColor: const Color(0xFF16A34A)));
            },
          ),
        );
      },
    );
  }

  InputDecoration _dec(String hint, {Widget? prefix, Widget? suffix, String? error}) {
    return InputDecoration(hintText: hint, hintStyle: const TextStyle(color: _C.textMuted, fontSize: 12), filled: true, fillColor: _C.bg, errorText: error, prefixIcon: prefix, suffixIcon: suffix, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _C.border)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _C.border)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _C.primary, width: 1.2)));
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
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: _C.textMain), onPressed: () => context.pop()),
        title: const Text('Escalader la conversation', style: TextStyle(color: _C.textMain, fontSize: 14, fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _C.searchBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.border)), child: Row(children: [Container(width: 28, height: 28, decoration: BoxDecoration(color: _C.primaryLight, shape: BoxShape.circle, border: Border.all(color: _C.primary.withOpacity(0.15))), child: const Icon(Icons.chat_bubble_rounded, color: _C.primary, size: 14)), const SizedBox(width: 8), Expanded(child: Text('Conversation #${widget.conversationId.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: _C.textMain)))])),
            const SizedBox(height: 20),
            const Text('Destinataire (@identifiant) *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _C.textMain)),
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: TextFormField(controller: _targetController, style: const TextStyle(fontSize: 13, color: _C.textMain), decoration: _dec('ex: @nlumina', prefix: const Icon(Icons.person_rounded, size: 18, color: _C.textMuted), suffix: _isSearching ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _C.primary)) : _foundUser != null ? const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18) : null, error: _searchError), validator: (v) { if (v == null || v.isEmpty) return 'Saisir identifiant'; if (_targetUserId == null) return 'Vérifiez ou sélectionnez'; return null; })),
              const SizedBox(width: 8),
              Column(children: [
                ElevatedButton(onPressed: _isSearching ? null : _searchUser, style: ElevatedButton.styleFrom(backgroundColor: _C.primary, foregroundColor: Colors.white, elevation: 0, minimumSize: const Size(74, 42), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('Vérifier', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                const SizedBox(height: 6),
                OutlinedButton(onPressed: _openContactPicker, style: OutlinedButton.styleFrom(side: const BorderSide(color: _C.border), minimumSize: const Size(74, 32), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('📋 Contacts', style: TextStyle(fontSize: 11, color: _C.textMuted))),
              ]),
            ]),
            if (_foundUser != null) Padding(padding: const EdgeInsets.only(top: 6), child: Row(children: [const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF16A34A)), const SizedBox(width: 4), Text('${_foundUser!['display_name'] ?? _foundUser!['username']}', style: const TextStyle(color: Color(0xFF16A34A), fontSize: 12, fontWeight: FontWeight.w600))])),
            const SizedBox(height: 20),
            const Text('Niveau cible', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _C.textMain)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: EscalationLevel.values.where((l) => l != EscalationLevel.agent).map((level) => ChoiceChip(label: Text(level.shortLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _selectedLevel == level ? Colors.white : _C.textMain)), selected: _selectedLevel == level, onSelected: (s) => setState(() => _selectedLevel = s ? level : null), selectedColor: _C.primary, backgroundColor: _C.searchBg, side: BorderSide(color: _selectedLevel == level ? _C.primary : _C.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))).toList()),
            const SizedBox(height: 20),
            const Text('Priorité', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _C.textMain)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: EscalationPriority.values.map((p) => ChoiceChip(label: Text(p.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _selectedPriority == p ? Colors.white : _C.textMain)), selected: _selectedPriority == p, onSelected: (s) => setState(() => _selectedPriority = s ? p : EscalationPriority.medium), selectedColor: p.color, backgroundColor: _C.searchBg, side: BorderSide(color: _selectedPriority == p ? p.color : _C.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))).toList()),
            const SizedBox(height: 20),
            const Text('Raison *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _C.textMain)),
            const SizedBox(height: 8),
            TextFormField(controller: _reasonController, style: const TextStyle(fontSize: 13, color: _C.textMain), maxLines: 3, decoration: _dec('Expliquez pourquoi vous escaladez'), validator: (v) => v == null || v.isEmpty ? 'Raison requise' : null),
            const SizedBox(height: 16),
            const Text('Commentaire (optionnel)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _C.textMain)),
            const SizedBox(height: 8),
            TextFormField(controller: _commentController, style: const TextStyle(fontSize: 13, color: _C.textMain), maxLines: 2, decoration: _dec('Ajoutez un commentaire')),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: ElevatedButton.icon(onPressed: provider.isLoading ? null : _submit, icon: provider.isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded, size: 16), label: const Text('Escalader', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), style: ElevatedButton.styleFrom(backgroundColor: _C.primary, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton(onPressed: () => context.pop(), style: OutlinedButton.styleFrom(side: const BorderSide(color: _C.border), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Annuler', style: TextStyle(color: _C.textMuted, fontSize: 13, fontWeight: FontWeight.w600)))),
            ]),
            if (provider.error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text('Erreur: ${provider.error}', style: const TextStyle(color: _C.red, fontSize: 11))),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLevel == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sélectionnez un niveau cible'))); return; }
    if (_targetUserId == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Destinataire invalide'))); return; }
    if (!RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$').hasMatch(_targetUserId!)) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID invalide'), backgroundColor: _C.red)); return; }
    final provider = Provider.of<EscalationProvider>(context, listen: false);
    final success = await provider.createEscalation(conversationId: widget.conversationId, fromAgentId: widget.fromAgentId, targetAgentId: _targetUserId!, toLevel: _selectedLevel!, reason: _reasonController.text, priority: _selectedPriority, comment: _commentController.text.isNotEmpty ? _commentController.text : null, fromAgentName: widget.fromAgentName);
    if (!mounted) return;
    if (success != null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escalade envoyée'), backgroundColor: Color(0xFF16A34A))); context.pop(true); } else { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${provider.error}'), backgroundColor: _C.red)); }
  }
}
