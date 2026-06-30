// presentation/thix_sante/patient/details/patient_family_page.dart
import 'package:flutter/material.dart';

class PatientFamilyPage extends StatefulWidget {
  final String? memberId;
  final bool isEditing;

  const PatientFamilyPage({super.key, this.memberId, this.isEditing = false});

  @override
  State<PatientFamilyPage> createState() => _PatientFamilyPageState();
}

class _PatientFamilyPageState extends State<PatientFamilyPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _relationshipController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Membre enregistré (simulé)')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.memberId == null;
    final title = isNew ? 'Ajouter membre' : (widget.isEditing ? 'Modifier' : 'Détail membre');

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
                  title: Text('Nom'),
                  subtitle: Text('Marie Dupont'),
                ),
                const ListTile(
                  leading: Icon(Icons.family_restroom),
                  title: Text('Lien de parenté'),
                  subtitle: Text('Épouse'),
                ),
                const ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Partage de dossier'),
                  subtitle: Text('Activé'),
                ),
              ] else ...[
                TextField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'Prénom'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _relationshipController,
                  decoration: const InputDecoration(labelText: 'Lien de parenté'),
                ),
                const SizedBox(height: 16),
              ],
              if (widget.isEditing || isNew)
                ElevatedButton(
                  onPressed: _save,
                  child: Text(isNew ? 'Ajouter' : 'Enregistrer'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
