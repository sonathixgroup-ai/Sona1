import 'package:flutter/material.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';

class ExamResultDetailPage extends StatelessWidget {
  final ExamResult exam;
  const ExamResultDetailPage({super.key, required this.exam});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(exam.examName)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date : ${exam.date.toLocal()}'),
            Text('Statut : ${exam.status.name}'),
            if (exam.result != null) Text('Résultat : ${exam.result}'),
            if (exam.comments != null) Text('Commentaires : ${exam.comments}'),
            if (exam.pdfUrl != null) ElevatedButton(onPressed: () {}, child: const Text('Voir PDF')),
          ],
        ),
      ),
    );
  }
}
