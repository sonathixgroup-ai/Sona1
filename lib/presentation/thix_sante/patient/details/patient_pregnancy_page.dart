// presentation/thix_sante/patient/details/patient_pregnancy_page.dart
import 'package:flutter/material.dart';

class PatientPregnancyPage extends StatefulWidget {
  final String? pregnancyId;
  final bool isEditing;

  const PatientPregnancyPage({super.key, this.pregnancyId, this.isEditing = false});

  @override
  State<PatientPregnancyPage> createState() => _PatientPregnancyPageState();
}

class _PatientPregnancyPageState extends State<PatientPregnancyPage> {
  bool _isLoading = false;

  final _weightController = TextEditingController();
  final _weekController = TextEditingController();

  @override
  void dispose() {
    _weightController.dispose();
    _weekController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Suivi grossesse enregistré (simulé)')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.pregnancyId == null;
    final title = isNew ? 'Ajouter suivi grossesse' : (widget.isEditing ? 'Modifier' : 'Détail grossesse');

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isNew && !widget.isEditing) ...[
                const ListTile(
                  leading: Icon(Icons.pregnant_woman),
                  title: Text('Semaine'),
                  subtitle: Text('12 semaines'),
                ),
                const ListTile(
                  leading: Icon(Icons.monitor_weight),
                  title: Text('Prise de poids'),
                  subtitle: Text('+3.5 kg'),
                ),
                const ListTile(
                  leading: Icon(Icons.calendar_today),
                  title: Text('Date prévue d\'accouchement'),
                  subtitle: Text('15/10/2024'),
                ),
                const SizedBox(height: 16),
                const Text('Historique des mesures', style: TextStyle(fontWeight: FontWeight.bold)),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Semaine 10'),
                  subtitle: const Text('Poids : 61.0 kg'),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Semaine 11'),
                  subtitle: const Text('Poids : 61.8 kg'),
                ),
              ] else ...[
                TextField(
                  controller: _weekController,
                  decoration: const InputDecoration(labelText: 'Semaine actuelle'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _weightController,
                  decoration: const InputDecoration(labelText: 'Poids (kg)'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
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
