// presentation/thix_sante/patient/details/patient_consultation_page.dart
import 'package:flutter/material.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';

class PatientConsultationPage extends StatefulWidget {
  final String consultationId;
  const PatientConsultationPage({super.key, required this.consultationId});

  @override
  State<PatientConsultationPage> createState() => _PatientConsultationPageState();
}

class _PatientConsultationPageState extends State<PatientConsultationPage> {
  final HealthService _service = HealthService.instance;
  Appointment? _consultation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final all = await _service.fetchAppointments('patient-123');
      final found = all.firstWhere((a) => a.id == widget.consultationId);
      setState(() {
        _consultation = found;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détail consultation')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Médecin'),
                    subtitle: Text(_consultation!.doctorName),
                  ),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Date'),
                    subtitle: Text(_consultation!.formattedDate),
                  ),
                  ListTile(
                    leading: const Icon(Icons.medical_services),
                    title: const Text('Spécialité'),
                    subtitle: Text(_consultation!.doctorSpecialty ?? 'Généraliste'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('Statut'),
                    subtitle: Text(_consultation!.status.name),
                  ),
                  if (_consultation!.notes != null)
                    ListTile(
                      leading: const Icon(Icons.note),
                      title: const Text('Notes'),
                      subtitle: Text(_consultation!.notes!),
                    ),
                ],
              ),
            ),
    );
  }
}
