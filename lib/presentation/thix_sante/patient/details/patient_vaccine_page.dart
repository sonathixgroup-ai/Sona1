// presentation/thix_sante/patient/details/patient_vaccine_page.dart
import 'package:flutter/material.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';

class PatientVaccinePage extends StatefulWidget {
  final String? vaccineId;
  final bool isEditing;

  const PatientVaccinePage({super.key, this.vaccineId, this.isEditing = false});

  @override
  State<PatientVaccinePage> createState() => _PatientVaccinePageState();
}

class _PatientVaccinePageState extends State<PatientVaccinePage> {
  final HealthService _service = HealthService.instance;
  Vaccine? _vaccine;
  bool _isLoading = true;

  final _nameController = TextEditingController();
  final _batchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _batchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (widget.vaccineId == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final all = await _service.fetchVaccines('patient-123');
      final found = all.firstWhere((v) => v.id == widget.vaccineId);
      setState(() {
        _vaccine = found;
        _nameController.text = found.name;
        _batchController.text = found.batchNumber ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vaccin enregistré (simulé)')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.vaccineId == null;
    final title = isNew ? 'Ajouter vaccin' : (widget.isEditing ? 'Modifier' : 'Détail');

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
          leading: const Icon(Icons.vaccines),
          title: const Text('Nom'),
          subtitle: Text(_vaccine!.name),
        ),
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: const Text('Administré le'),
          subtitle: Text(_vaccine!.dateAdministered.toLocal().toString().split(' ')[0]),
        ),
        if (_vaccine!.boosterDate != null)
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Rappel'),
            subtitle: Text(_vaccine!.boosterDate!.toLocal().toString().split(' ')[0]),
          ),
        if (_vaccine!.batchNumber != null)
          ListTile(
            leading: const Icon(Icons.qr_code_scanner),
            title: const Text('Lot'),
            subtitle: Text(_vaccine!.batchNumber!),
          ),
        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('Rappel dû'),
          subtitle: Text(_vaccine!.isBoosterDue ? 'Oui' : 'Non'),
        ),
      ],
    );
  }

  Widget _buildFormView() {
    return Column(
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Nom du vaccin'),
        ),
        TextField(
          controller: _batchController,
          decoration: const InputDecoration(labelText: 'Numéro de lot'),
        ),
      ],
    );
  }
}
