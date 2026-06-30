import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/nav.dart';
import 'package:thix_id/supabase/supabase_config.dart';

class DoctorPrescriptionListPage extends StatefulWidget {
  const DoctorPrescriptionListPage({super.key});

  @override
  State<DoctorPrescriptionListPage> createState() => _DoctorPrescriptionListPageState();
}

class _DoctorPrescriptionListPageState extends State<DoctorPrescriptionListPage> {
  Future<List<Map<String, dynamic>>> _load() async {
    final doctorId = AuthController.instance.currentUser?.id;
    if (doctorId == null) return const [];
    try {
      final res = await SupabaseConfig.client
          .from('health_prescriptions')
          .select('*')
          .eq('doctor_id', doctorId)
          .order('issued_at', ascending: false);
      if (res is List) return res.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    } catch (e, st) {
      debugPrint('DoctorPrescriptionListPage load failed: $e');
      debugPrint(st.toString());
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes ordonnances'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.popOrGo('/sante/doctor/dashboard'),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _load(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          final items = snap.data ?? const [];
          if (items.isEmpty) return const Center(child: Text('Aucune ordonnance.'));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final m = items[i];
              final id = (m['id'] as String?) ?? '';
              final patientName = (m['patient_name'] as String?)?.trim() ?? 'Patient';
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                tileColor: Theme.of(context).colorScheme.surface,
                title: Text(patientName),
                subtitle: Text(id.isEmpty ? '' : 'ID: $id'),
                trailing: const Icon(Icons.chevron_right),
                onTap: id.isEmpty ? null : () => context.push('/sante/doctor/prescription/$id'),
              );
            },
          );
        },
      ),
    );
  }
}
