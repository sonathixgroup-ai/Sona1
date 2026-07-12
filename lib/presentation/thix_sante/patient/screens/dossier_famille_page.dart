// lib/presentation/thix_sante/patient/screens/dossier_famille_page.dart
// =============================================================================
// Screen: DossierFamillePage - NEW 2
// Role: Gestion famille sous un THIX ID tuteur - cas d'usage RDC
// Fonctionnalites: Ajout enfant par THIX ID mineur, switch profil
// =============================================================================

import 'package:flutter/material.dart';
import '../../core/thix_id_validator.dart';

class DossierFamillePage extends StatefulWidget {
  const DossierFamillePage({super.key});
  @override
  State<DossierFamillePage> createState() => _DossierFamillePageState();
}

class _DossierFamillePageState extends State<DossierFamillePage> {
  final List<Map<String, String>> _membres = [
    {'nom': 'Alex (Vous)', 'thix': 'THIX-CD-0726-12345-ABC-1', 'role': 'Tuteur', 'avatar': 'https://i.pravatar.cc/100?img=12'},
    {'nom': 'Lina', 'thix': 'THIX-CD-0325-54321-XYZ-2', 'role': 'Fille - 8 ans', 'avatar': 'https://i.pravatar.cc/100?img=5'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThixSanteColors.background,
      appBar: AppBar(
        backgroundColor: ThixSanteColors.surface,
        elevation: 0,
        title: const Text('Dossier Famille', style: TextStyle(color: ThixSanteColors.ink, fontWeight: FontWeight.w800)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: ThixSanteColors.ink), onPressed: () => Navigator.pop(context)),
        actions: [IconButton(icon: const Icon(Icons.person_add_rounded, color: ThixSanteColors.primary), onPressed: _showAddMember)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: ThixSanteColors.warningLight, borderRadius: BorderRadius.circular(14), border: Border.all(color: ThixSanteColors.warning.withOpacity(0.2))),
            child: const Row(children: [Icon(Icons.info_rounded, color: ThixSanteColors.warning), SizedBox(width: 10), Expanded(child: Text('Un seul compte THIX ID gere toute la famille. Ajoutez vos enfants par leur THIX ID mineur.', style: TextStyle(fontSize: 12, color: ThixSanteColors.inkLight)))]),
          ),
          const SizedBox(height: 16),
         ..._membres.map((m) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: ThixSanteColors.borderLight)),
                child: Row(
                  children: [
                    CircleAvatar(radius: 24, backgroundImage: NetworkImage(m['avatar']!)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(m['nom']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)), Text(m['role']!, style: const TextStyle(fontSize: 11, color: ThixSanteColors.muted)), const SizedBox(height: 2), Text(m['thix']!, style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: ThixSanteColors.mutedLight))])),
                    const Icon(Icons.chevron_right_rounded, color: ThixSanteColors.mutedLight),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _showAddMember,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ajouter un membre par THIX ID'),
              style: OutlinedButton.styleFrom(foregroundColor: ThixSanteColors.primary, side: const BorderSide(color: ThixSanteColors.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMember() {
    final TextEditingController ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Ajouter un enfant', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(controller: ctrl, decoration: InputDecoration(labelText: 'THIX ID enfant', hintText: 'THIX-CD-0325-...', prefixIcon: const Icon(Icons.child_care_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), textCapitalization: TextCapitalization.characters),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () { if (ThixIdValidator.isValidFormat(ctrl.text)) { setState(() => _membres.add({'nom': 'Nouveau membre', 'thix': ThixIdValidator.clean(ctrl.text), 'role': 'Enfant', 'avatar': 'https://i.pravatar.cc/100?img=8'})); Navigator.pop(ctx); } }, style: ElevatedButton.styleFrom(backgroundColor: ThixSanteColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Verifier et ajouter')),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
