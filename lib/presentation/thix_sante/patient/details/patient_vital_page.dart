// presentation/thix_sante/patient/details/patient_vital_page.dart
import 'package:flutter/material.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';

class PatientVitalPage extends StatefulWidget {
  final String? vitalId;
  final bool isEditing;

  const PatientVitalPage({super.key, this.vitalId, this.isEditing = false});

  @override
  State<PatientVitalPage> createState() => _PatientVitalPageState();
}

class _PatientVitalPageState extends State<PatientVitalPage> {
  final HealthService _service = HealthService.instance;
  VitalSign? _vital;
  bool _isLoading = true;

  final _valueController = TextEditingController();
  VitalType? _selectedType;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (widget.vitalId == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final all = await _service.fetchVitalSigns('patient-123');
      final found = all.firstWhere((v) => v.id == widget.vitalId);
      setState(() {
        _vital = found;
        _valueController.text = found.value.toString();
        _selectedType = found.type;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Constante enregistrée (simulé)')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.vitalId == null;
    final title = isNew ? 'Ajouter constante' : (widget.isEditing ? 'Modifier' : 'Détail');

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
                    if (!isNew && !widget.isEditing)
                      ElevatedButton(
                        onPressed: () {
                          context.push('/sante/patient/vitals/chart');
                        },
                        child: const Text('Voir le graphique'),
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
          leading: Icon(VitalSign.getVitalIcon(_vital!.type)),
          title: const Text('Type'),
          subtitle: Text(VitalSign.getVitalLabel(_vital!.type)),
        ),
        ListTile(
          leading: const Icon(Icons.numbers),
          title: const Text('Valeur'),
          subtitle: Text(_vital!.displayValue),
        ),
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: const Text('Date'),
          subtitle: Text(_vital!.date.toLocal().toString().split(' ')[0]),
        ),
      ],
    );
  }

  Widget _buildFormView() {
    return Column(
      children: [
        DropdownButtonFormField<VitalType>(
          value: _selectedType,
          items: VitalType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(VitalSign.getVitalLabel(type)),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedType = value!),
          decoration: const InputDecoration(labelText: 'Type'),
        ),
        TextField(
          controller: _valueController,
          decoration: const InputDecoration(labelText: 'Valeur'),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
        ),
      ],
    );
  }
}
