// lib/presentation/thix_sante/patient/screens/assistant_ia_page.dart
// =============================================================================
// Screen: AssistantIAPage - Service Rapide 11
// Role: Assistant IA sante avec contexte THIX ID dossier medical
// Fonctionnalites modernes: Chat streaming, suggestions, disclaimer medical
// =============================================================================

import 'package:flutter/material.dart';
import '../../core/thix_sante_colors.dart';

class AssistantIAPage extends StatefulWidget {
  const AssistantIAPage({super.key});
  @override
  State<AssistantIAPage> createState() => _AssistantIAPageState();
}

class _AssistantIAPageState extends State<AssistantIAPage> {
  final TextEditingController _ctrl = TextEditingController();
  final List<Map<String,String>> _messages = [
    {'role':'ia','text':'Bonjour Alex 👋 Je suis THIX IA Sante, entraine sur votre dossier lie par THIX ID UID. Comment puis-je vous aider aujourd hui?'},
  ];

  final List<String> _quickPrompts = ['Analyser mes derniers examens','Effets secondaires de mon traitement','Conseils nutrition selon mon dossier','Quand prendre mon prochain RDV?'];

  void _send(String text) {
    if (text.trim().isEmpty) return;
    setState(() { _messages.add({'role':'user','text':text}); _ctrl.clear(); });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _messages.add({'role':'ia','text':'D apres votre dossier THIX ID [12 consultations, 5 medicaments en cours], voici mon analyse:\n\n• Votre dernier bilan du 12/06 est dans les normes.\n• Continuez votre traitement actuel.\n\n⚠️ Ceci est une information educative, pas un avis medical. Consultez votre Dr lie par THIX ID pour confirmation.'}));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThixSanteColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(children: [Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: ThixSanteColors.primary, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16)), const SizedBox(width: 8), const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('THIX IA Sante', style: TextStyle(color: ThixSanteColors.ink, fontWeight: FontWeight.w800, fontSize: 15)), Text('Contexte THIX ID actif', style: TextStyle(color: ThixSanteColors.success, fontSize: 10, fontWeight: FontWeight.w600))])]),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: ThixSanteColors.ink), onPressed: () => Navigator.pop(context)),
        actions: [IconButton(icon: const Icon(Icons.info_outline_rounded, color: ThixSanteColors.muted), onPressed: () {})],
      ),
      body: Column(
        children: [
          Container(color: ThixSanteColors.warningLight, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), child: Row(children: [const Icon(Icons.medical_information_rounded, size: 16, color: ThixSanteColors.warning), const SizedBox(width: 8), const Expanded(child: Text('IA educative uniquement. Ne remplace pas un avis medical. THIX ID dossier utilise en lecture seule.', style: TextStyle(fontSize: 10, color: ThixSanteColors.inkLight))) ])),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (c,i) {
                final m = _messages[i];
                final isUser = m['role'] == 'user';
                return Align(
                  alignment: isUser? Alignment.centerRight: Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: isUser? ThixSanteColors.primary: Colors.white, borderRadius: BorderRadius.circular(16).copyWith(bottomRight: isUser? const Radius.circular(4): null, bottomLeft:!isUser? const Radius.circular(4): null), border: Border.all(color: isUser? ThixSanteColors.primary: ThixSanteColors.borderLight)),
                    child: Text(m['text']!, style: TextStyle(fontSize: 13, height: 1.4, color: isUser? Colors.white: ThixSanteColors.ink)),
                  ),
                );
              },
            ),
          ),
          if (_messages.length == 1) SizedBox(height: 40, child: ListView.separated(padding: const EdgeInsets.symmetric(horizontal: 16), scrollDirection: Axis.horizontal, itemCount: _quickPrompts.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (c,i) => ActionChip(label: Text(_quickPrompts[i], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)), onPressed: () => _send(_quickPrompts[i]), backgroundColor: Colors.white, side: const BorderSide(color: ThixSanteColors.border)))),
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(left: 12, right: 12, top: 10, bottom: MediaQuery.of(context).padding.bottom + 10),
            child: Row(children: [
              Expanded(child: TextField(controller: _ctrl, decoration: InputDecoration(hintText: 'Posez une question sante...', hintStyle: const TextStyle(fontSize: 13, color: ThixSanteColors.muted), filled: true, fillColor: ThixSanteColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)), onSubmitted: _send)),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: () => _send(_ctrl.text), icon: const Icon(Icons.send_rounded, size: 18), style: IconButton.styleFrom(backgroundColor: ThixSanteColors.primary, foregroundColor: Colors.white)),
            ]),
          ),
        ],
      ),
    );
  }
}
