// presentation/thix_sante/patient/details/patient_symptom_page.dart
import 'package:flutter/material.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';

class PatientSymptomPage extends StatefulWidget {
  final String? symptomId;
  final bool isEditing;

  const PatientSymptomPage({super.key, this.symptomId, this.isEditing = false});

  @override
  State<PatientSymptomPage> createState() => _PatientSymptomPageState();
}

class _PatientSymptomPageState extends State<PatientSymptomPage> {
  final HealthService _service = HealthService.instance;
  Symptom? _symptom;
  bool _isLoading = true;

  final _nameController = TextEditingController();
  final _intensityController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _intensityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (widget.symptomId == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final all = await _service.fetchSymptoms('patient-123');
      final found = all.firstWhere((s) => s.id == widget.symptomId);
      setState(() {
        _symptom = found;
        _nameController.text = found.name;
        _intensityController.text = found.intensity.toString();
        _notesController.text = found.notes ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    // Simuler sauvegarde
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Symptôme enregistré (simulé)')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.symptomId == null;
    final title = isNew ? 'Nouveau symptôme' : (widget.isEditing ? 'Modifier' : 'Détail');

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
                        child: Text(isNew ? 'Créer' : 'Enregistrer'),
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
          leading: const Icon(Icons.sick),
          title: const Text('Nom'),
          subtitle: Text(_symptom!.name),
        ),
        ListTile(
          leading: const Icon(Icons.star),
          title: const Text('Intensité'),
          subtitle: Text('${_symptom!.intensity}/5'),
        ),
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: const Text('Date'),
          subtitle: Text(_symptom!.date.toLocal().toString().split(' ')[0]),
        ),
        if (_symptom!.notes != null)
          ListTile(
            leading: const Icon(Icons.note),
            title: const Text('Notes'),
            subtitle: Text(_symptom!.notes!),
          ),
      ],
    );
  }

  Widget _buildFormView() {
    return Column(
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Nom du symptôme'),
        ),
        TextField(
          controller: _intensityController,
          decoration: const InputDecoration(labelText: 'Intensité (1-5)'),
          keyboardType: TextInputType.number,
        ),
        TextField(
          controller: _notesController,
          decoration: const InputDecoration(labelText: 'Notes'),
          maxLines: 3,
        ),
      ],
    );
  }
}
