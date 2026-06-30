// presentation/thix_sante/doctor/details/doctor_note_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DoctorNotePage extends StatefulWidget {
  final String? noteId;
  final bool isEditing;
  const DoctorNotePage({super.key, this.noteId, this.isEditing = false});

  @override
  State<DoctorNotePage> createState() => _DoctorNotePageState();
}

class _DoctorNotePageState extends State<DoctorNotePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String _patientName = 'Michel L.';

  @override
  void initState() {
    super.initState();
    if (widget.noteId != null) {
      _titleController.text = 'Consultation du 10/03';
      _contentController.text = 'Patient présentant une douleur thoracique...';
    }
  }

  Future<void> _save() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note enregistrée (simulé)')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.noteId == null;
    final title = isNew ? 'Nouvelle note' : (widget.isEditing ? 'Modifier' : 'Détail note');

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isNew && !widget.isEditing) ...[
                const Text('Patient : Michel L.'),
                const Text('Date : 10/03/2024'),
                const SizedBox(height: 8),
                const Text('Contenu :', style: TextStyle(fontWeight: FontWeight.bold)),
                const Text('Patient présentant une douleur thoracique...'),
              ] else ...[
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Titre'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _contentController,
                  decoration: const InputDecoration(labelText: 'Contenu'),
                  maxLines: 5,
                ),
              ],
              const SizedBox(height: 16),
              if (widget.isEditing || isNew)
                ElevatedButton(
                  onPressed: _save,
                  child: Text(isNew ? 'Créer' : 'Enregistrer'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
