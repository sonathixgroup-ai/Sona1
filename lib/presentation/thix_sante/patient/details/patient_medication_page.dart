// presentation/thix_sante/patient/details/patient_medication_page.dart
import 'package:flutter/material.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';

class PatientMedicationPage extends StatefulWidget {
  final String? medicationId;
  final bool isEditing;

  const PatientMedicationPage({super.key, this.medicationId, this.isEditing = false});

  @override
  State<PatientMedicationPage> createState() => _PatientMedicationPageState();
}

class _PatientMedicationPageState extends State<PatientMedicationPage> {
  final HealthService _service = HealthService.instance;
  Medication? _medication;
  bool _isLoading = true;

  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (widget.medicationId == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final all = await _service.fetchMedications('patient-123', activeOnly: false);
      final found = all.firstWhere((m) => m.id == widget.medicationId);
      setState(() {
        _medication = found;
        _nameController.text = found.name;
        _dosageController.text = found.dosage;
        _frequencyController.text = found.frequency;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Médicament enregistré (simulé)')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.medicationId == null;
    final title = isNew ? 'Ajouter médicament' : (widget.isEditing ? 'Modifier' : 'Détail');

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (!isNew && !widget.isEditing) ...[
                      _buildDetailView(),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.push(
                            '/sante/patient/medication/${_medication!.id}/reminders',
                          );
                        },
                        child: const Text('Gérer les rappels'),
                      ),
                    ] else ...[
                      _buildFormView(),
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

  Widget _buildDetailView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const Icon(Icons.medication),
          title: const Text('Nom'),
          subtitle: Text(_medication!.name),
        ),
        ListTile(
          leading: const Icon(Icons.medication_liquid),
          title: const Text('Dosage'),
          subtitle: Text(_medication!.dosage),
        ),
        ListTile(
          leading: const Icon(Icons.timer),
          title: const Text('Fréquence'),
          subtitle: Text(_medication!.frequency),
        ),
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: const Text('Début'),
          subtitle: Text(_medication!.startDate.toLocal().toString().split(' ')[0]),
        ),
        if (_medication!.endDate != null)
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Fin'),
            subtitle: Text(_medication!.endDate!.toLocal().toString().split(' ')[0]),
          ),
        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('Statut'),
          subtitle: Text(_medication!.isActive ? 'Actif' : 'Terminé'),
        ),
      ],
    );
  }

  Widget _buildFormView() {
    return Column(
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Nom'),
        ),
        TextField(
          controller: _dosageController,
          decoration: const InputDecoration(labelText: 'Dosage'),
        ),
        TextField(
          controller: _frequencyController,
          decoration: const InputDecoration(labelText: 'Fréquence'),
        ),
      ],
    );
  }
}
