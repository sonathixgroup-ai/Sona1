import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/nav.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';

class PatientExamsListPage extends StatefulWidget {
  const PatientExamsListPage({super.key});

  @override
  State<PatientExamsListPage> createState() => _PatientExamsListPageState();
}

class _PatientExamsListPageState extends State<PatientExamsListPage> {
  late final Future<List<ExamResult>> _future;

  @override
  void initState() {
    super.initState();
    final uid = AuthController.instance.currentUser?.id;
    _future = uid == null ? Future.value(const []) : HealthService.instance.fetchExamResults(uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Examens'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.popOrGo('/sante/patient/dashboard'),
        ),
      ),
      body: FutureBuilder<List<ExamResult>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            debugPrint('PatientExamsListPage error: ${snap.error}');
            return const Center(child: Text("Impossible de charger les examens."));
          }
          final items = snap.data ?? const [];
          if (items.isEmpty) {
            return const Center(child: Text('Aucun examen pour le moment.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final e = items[i];
              final status = e.status.name;
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                tileColor: Theme.of(context).colorScheme.surface,
                title: Text(e.examName),
                subtitle: Text('${e.date.day}/${e.date.month}/${e.date.year} • $status'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/sante/patient/exam/${Uri.encodeComponent(e.id)}'),
              );
            },
          );
        },
      ),
    );
  }
}
