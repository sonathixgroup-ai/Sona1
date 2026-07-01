// presentation/thix_sante/patient/details/patient_exam_result_detail_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/supabase/supabase_config.dart';

class PatientExamResultDetailPage extends StatefulWidget {
  final String examId;

  const PatientExamResultDetailPage({
    super.key,
    required this.examId,
  });

  @override
  State<PatientExamResultDetailPage> createState() =>
      _PatientExamResultDetailPageState();
}

class _PatientExamResultDetailPageState
    extends State<PatientExamResultDetailPage> {
  final SupabaseClient _supabase = SupabaseConfig.client;
  ExamResult? _exam;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExam();
  }

  Future<void> _loadExam() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Récupérer l'examen depuis Supabase
      final response = await _supabase
          .from('health_exams')
          .select('*')
          .eq('id', widget.examId)
          .maybeSingle();

      if (response == null) {
        throw Exception('Examen introuvable');
      }

      final statusName = (response['status'] as String?) ?? ExamStatus.pending.name;

      setState(() {
        _exam = ExamResult(
          id: response['id'] as String,
          patientId: response['patient_id'] as String? ?? user.id,
          examName: response['exam_name'] as String? ?? 'Examen',
          date: DateTime.parse(response['performed_at'] as String),
          result: response['result'] as String?,
          status: ExamStatus.values.firstWhere(
            (e) => e.name == statusName,
            orElse: () => ExamStatus.pending,
          ),
          comments: response['comments'] as String?,
          pdfUrl: response['pdf_url'] as String?,
          imageUrl: response['image_url'] as String?,
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultat d\'examen'),
        backgroundColor: const Color(0xFF2563FF),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 8),
                      Text('Erreur : $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadExam,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _exam == null
                  ? const Center(child: Text('Aucun examen trouvé'))
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    final e = _exam!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec statut
          Card(
            color: e.status == ExamStatus.completed
                ? Colors.green[50]
                : Colors.orange[50],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    e.status == ExamStatus.completed
                        ? Icons.check_circle
                        : Icons.pending,
                    color: e.status == ExamStatus.completed
                        ? Colors.green
                        : Colors.orange,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.status == ExamStatus.completed
                            ? 'Résultat disponible'
                            : 'En attente des résultats',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: e.status == ExamStatus.completed
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                      Text(
                        'Réalisé le ${DateFormat('dd/MM/yyyy').format(e.date)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Informations générales
          _sectionTitle('Informations'),
          const SizedBox(height: 8),
          _infoRow('Examen', e.examName),
          _infoRow('Date', DateFormat('dd/MM/yyyy à HH:mm').format(e.date)),
          _infoRow('Statut', e.status.name),
          if (e.result != null) _infoRow('Résultat', e.result!),
          if (e.comments != null) _infoRow('Commentaires', e.comments!),

          const SizedBox(height: 20),

          // Documents joints
          if (e.pdfUrl != null || e.imageUrl != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Documents'),
                const SizedBox(height: 8),
                if (e.pdfUrl != null)
                  ListTile(
                    leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    title: const Text('Voir le PDF'),
                    onTap: () {
                      // TODO: Ouvrir le PDF (via un viewer ou un navigateur)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ouverture PDF à implémenter'),
                        ),
                      );
                    },
                  ),
                if (e.imageUrl != null)
                  ListTile(
                    leading: const Icon(Icons.image, color: Colors.blue),
                    title: const Text('Voir l\'image'),
                    onTap: () {
                      // TODO: Afficher l'image en plein écran
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Affichage image à implémenter'),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 20),
              ],
            ),

          // Bouton de retour
          OutlinedButton(
            onPressed: () => context.pop(),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Retour'),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
