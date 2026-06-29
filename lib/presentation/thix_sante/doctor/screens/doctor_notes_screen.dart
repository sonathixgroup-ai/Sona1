// 📁 lib/presentation/thix_sante/doctor/screens/doctor_notes_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/medical_note_editor.dart';
import '../../../common/widgets/empty_state.dart';

class DoctorNotesScreen extends ConsumerStatefulWidget {
  const DoctorNotesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DoctorNotesScreen> createState() => _DoctorNotesScreenState();
}

class _DoctorNotesScreenState extends ConsumerState<DoctorNotesScreen> {
  final List<Map<String, dynamic>> _notes = [
    {'patient': 'Michel Dupont', 'date': '10/12/2024', 'content': 'Patient stable. Suivi dans 1 mois. Tension 120/80.'},
    {'patient': 'Sophie Martin', 'date': '05/12/2024', 'content': 'Nouveau traitement. À revoir dans 15 jours.'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addNote(context),
          ),
        ],
      ),
      body: _notes.isEmpty
          ? const EmptyStateWidget(
              title: 'Aucune note',
              subtitle: 'Ajoutez des notes sur vos patients',
              icon: Icons.note_add_outlined,
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _notes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final n = _notes[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(n['patient'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Text(n['date'], style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(n['content'], style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _addNote(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ajouter une note', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(labelText: 'Patient', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            MedicalNoteEditor(
              onSave: (note) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Note ajoutée'), backgroundColor: Colors.green),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
