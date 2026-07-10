import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/nav.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';

class DoctorSlotManagementPage extends StatefulWidget {
  const DoctorSlotManagementPage({super.key});

  @override
  State<DoctorSlotManagementPage> createState() => _DoctorSlotManagementPageState();
}

class _DoctorSlotManagementPageState extends State<DoctorSlotManagementPage> {
  bool _loading = false;
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() {
    final doctorId = AuthController.instance.currentUser?.id;
    return doctorId == null ? Future.value(const []) : HealthService.instance.fetchDoctorSlots(doctorId);
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _addSlot() async {
    final doctorId = AuthController.instance.currentUser?.id;
    if (doctorId == null) return;

    final now = DateTime.now();
    DateTime start = DateTime(now.year, now.month, now.day, now.hour, 0).add(const Duration(hours: 1));
    DateTime end = start.add(const Duration(minutes: 30));

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final viewInsets = MediaQuery.viewInsetsOf(context);
        return Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Nouveau créneau', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Début'),
                subtitle: Text(start.toString()),
                trailing: const Icon(Icons.schedule),
                onTap: () async {
                  final d = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 60)), initialDate: start);
                  if (d == null) return;
                  final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(start));
                  if (t == null) return;
                  start = DateTime(d.year, d.month, d.day, t.hour, t.minute);
                  end = start.add(const Duration(minutes: 30));
                  // ignore: use_build_context_synchronously
                  (context as Element).markNeedsBuild();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fin'),
                subtitle: Text(end.toString()),
                trailing: const Icon(Icons.schedule_outlined),
                onTap: () async {
                  final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(end));
                  if (t == null) return;
                  end = DateTime(start.year, start.month, start.day, t.hour, t.minute);
                  // ignore: use_build_context_synchronously
                  (context as Element).markNeedsBuild();
                },
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Créer'),
              ),
            ],
          ),
        );
      },
    );
    if (ok != true) return;

    setState(() => _loading = true);
    try {
      await HealthService.instance.createDoctorSlot(doctorId: doctorId, startAt: start, endAt: end);
      _reload();
    } catch (e, st) {
      debugPrint('DoctorSlotManagementPage add failed: $e');
      debugPrint(st.toString());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de la création.')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des créneaux'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/sante/doctor/agenda'),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) {
            debugPrint('DoctorSlotManagementPage error: ${snap.error}');
            return const Center(child: Text('Impossible de charger les créneaux.'));
          }
          final items = snap.data ?? const [];
          if (items.isEmpty) return const Center(child: Text('Aucun créneau.'));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final m = items[i];
              final start = (m['start_at'] as String?) ?? '';
              final end = (m['end_at'] as String?) ?? '';
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                tileColor: Theme.of(context).colorScheme.surface,
                title: Text(start),
                subtitle: Text(end.isEmpty ? '' : '→ $end'),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _addSlot,
        icon: const Icon(Icons.add),
        label: const Text('Créer'),
      ),
    );
  }
}
