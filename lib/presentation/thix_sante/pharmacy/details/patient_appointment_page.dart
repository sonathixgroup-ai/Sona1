// presentation/thix_sante/patient/details/patient_appointment_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';

class PatientAppointmentPage extends StatefulWidget {
  final String? appointmentId; // null = création
  final bool isEditing;

  const PatientAppointmentPage({
    super.key,
    this.appointmentId,
    this.isEditing = false,
  });

  @override
  State<PatientAppointmentPage> createState() => _PatientAppointmentPageState();
}

class _PatientAppointmentPageState extends State<PatientAppointmentPage> {
  final HealthService _service = HealthService.instance;
  Appointment? _appointment;
  bool _isLoading = true;

  // Contrôleurs pour le formulaire (création/édition)
  final _doctorNameController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _dateController = TextEditingController();
  final _notesController = TextEditingController();
  AppointmentType _selectedType = AppointmentType.inPerson;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _doctorNameController.dispose();
    _specialtyController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (widget.appointmentId == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      // Simuler un appel API
      final all = await _service.fetchAppointments('patient-123');
      final found = all.firstWhere((a) => a.id == widget.appointmentId);
      setState(() {
        _appointment = found;
        _doctorNameController.text = found.doctorName;
        _specialtyController.text = found.doctorSpecialty ?? '';
        _dateController.text = found.formattedDate;
        _notesController.text = found.notes ?? '';
        _selectedType = found.type;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    // Simuler sauvegarde
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rendez-vous enregistré (simulé)')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.appointmentId == null;
    final title = isNew ? 'Nouveau rendez-vous' : (widget.isEditing ? 'Modifier rendez-vous' : 'Détail rendez-vous');

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isNew && !widget.isEditing) ...[
                      _buildDetailView(),
                    ] else ...[
                      _buildFormView(),
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

  Widget _buildDetailView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('Médecin'),
          subtitle: Text(_appointment!.doctorName),
        ),
        ListTile(
          leading: const Icon(Icons.medical_services),
          title: const Text('Spécialité'),
          subtitle: Text(_appointment!.doctorSpecialty ?? 'Généraliste'),
        ),
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: const Text('Date'),
          subtitle: Text(_appointment!.formattedDate),
        ),
        ListTile(
          leading: const Icon(Icons.videocam),
          title: const Text('Type'),
          subtitle: Text(_appointment!.type.name),
        ),
        if (_appointment!.notes != null)
          ListTile(
            leading: const Icon(Icons.note),
            title: const Text('Notes'),
            subtitle: Text(_appointment!.notes!),
          ),
        if (_appointment!.teleconsultationLink != null)
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Lien Jitsi'),
            subtitle: Text(_appointment!.teleconsultationLink!),
            onTap: () {
              context.push('/sante/patient/teleconsultation/${_appointment!.id}',
                  extra: _appointment!.teleconsultationLink);
            },
          ),
      ],
    );
  }

  Widget _buildFormView() {
    return Column(
      children: [
        TextField(
          controller: _doctorNameController,
          decoration: const InputDecoration(labelText: 'Nom du médecin'),
        ),
        TextField(
          controller: _specialtyController,
          decoration: const InputDecoration(labelText: 'Spécialité'),
        ),
        TextField(
          controller: _dateController,
          decoration: const InputDecoration(labelText: 'Date (jj/mm/aaaa hh:mm)'),
        ),
        DropdownButtonFormField<AppointmentType>(
          value: _selectedType,
          items: AppointmentType.values.map((type) {
            return DropdownMenuItem(value: type, child: Text(type.name));
          }).toList(),
          onChanged: (value) => setState(() => _selectedType = value!),
          decoration: const InputDecoration(labelText: 'Type'),
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
