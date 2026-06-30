// presentation/thix_sante/patient/details/patient_exam_page.dart
import 'package:flutter/material.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';

class PatientExamPage extends StatefulWidget {
  final String examId;
  const PatientExamPage({super.key, required this.examId});

  @override
  State<PatientExamPage> createState() => _PatientExamPageState();
}

class _PatientExamPageState extends State<PatientExamPage> {
  final HealthService _service = HealthService.instance;
  ExamResult? _exam;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final all = await _service.fetchExamResults('patient-123');
      final found = all.firstWhere((e) => e.id == widget.examId);
      setState(() {
        _exam = found;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Résultat examen')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: const Icon(Icons.science),
                    title: const Text('Examen'),
                    subtitle: Text(_exam!.examName),
                  ),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Date'),
                    subtitle: Text(_exam!.date.toLocal().toString().split(' ')[0]),
                  ),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('Statut'),
                    subtitle: Text(_exam!.status.name),
                  ),
                  if (_exam!.result != null)
                    ListTile(
                      leading: const Icon(Icons.assignment),
                      title: const Text('Résultat'),
                      subtitle: Text(_exam!.result!),
                    ),
                  if (_exam!.comments != null)
                    ListTile(
                      leading: const Icon(Icons.note),
                      title: const Text('Commentaires'),
                      subtitle: Text(_exam!.comments!),
                    ),
                  if (_exam!.pdfUrl != null)
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Voir le PDF'),
                    ),
                ],
              ),
            ),
    );
  }
}
