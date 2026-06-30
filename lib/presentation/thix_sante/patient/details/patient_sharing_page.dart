// presentation/thix_sante/patient/details/patient_sharing_page.dart
import 'package:flutter/material.dart';

class PatientSharingPage extends StatefulWidget {
  final String? shareId;
  final bool isEditing;

  const PatientSharingPage({super.key, this.shareId, this.isEditing = false});

  @override
  State<PatientSharingPage> createState() => _PatientSharingPageState();
}

class _PatientSharingPageState extends State<PatientSharingPage> {
  final _emailController = TextEditingController();
  final _typeController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Partage créé (simulé)')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.shareId == null;
    final title = isNew ? 'Nouveau partage' : (widget.isEditing ? 'Modifier' : 'Détail partage');

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (!isNew && !widget.isEditing) ...[
                const ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Partagé avec'),
                  subtitle: Text('Dr. Dupont'),
                ),
                const ListTile(
                  leading: Icon(Icons.shield),
                  title: Text('Niveau d\'accès'),
                  subtitle: Text('Complet'),
                ),
                const ListTile(
                  leading: Icon(Icons.calendar_today),
                  title: Text('Expiration'),
                  subtitle: Text('30 jours'),
                ),
              ] else ...[
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email du destinataire'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _typeController,
                  decoration: const InputDecoration(labelText: 'Type d\'accès (complet/limite)'),
                ),
                const SizedBox(height: 16),
              ],
              if (widget.isEditing || isNew)
                ElevatedButton(
                  onPressed: _save,
                  child: Text(isNew ? 'Partager' : 'Enregistrer'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
