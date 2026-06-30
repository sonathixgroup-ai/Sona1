import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/nav.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';

class PatientMedicationRemindersPage extends StatefulWidget {
  final String medicationId;
  const PatientMedicationRemindersPage({super.key, required this.medicationId});

  @override
  State<PatientMedicationRemindersPage> createState() => _PatientMedicationRemindersPageState();
}

class _PatientMedicationRemindersPageState extends State<PatientMedicationRemindersPage> {
  bool _loading = false;
  late Future<List<MedicationReminder>> _future;

  @override
  void initState() {
    super.initState();
    _future = HealthService.instance.fetchMedicationReminders(widget.medicationId);
  }

  void _reload() => setState(() => _future = HealthService.instance.fetchMedicationReminders(widget.medicationId));

  Future<void> _addReminder() async {
    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 8, minute: 0));
    if (t == null) return;
    setState(() => _loading = true);
    try {
      await HealthService.instance.addMedicationReminder(medicationId: widget.medicationId, time: t);
      _reload();
    } catch (e, st) {
      debugPrint('PatientMedicationRemindersPage add failed: $e');
      debugPrint(st.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de l\'ajout du rappel.')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(MedicationReminder r, bool v) async {
    setState(() => _loading = true);
    try {
      await HealthService.instance.setMedicationReminderEnabled(reminderId: r.id, isEnabled: v);
      _reload();
    } catch (e, st) {
      debugPrint('PatientMedicationRemindersPage toggle failed: $e');
      debugPrint(st.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(MedicationReminder r) async {
    setState(() => _loading = true);
    try {
      await HealthService.instance.deleteMedicationReminder(r.id);
      _reload();
    } catch (e, st) {
      debugPrint('PatientMedicationRemindersPage delete failed: $e');
      debugPrint(st.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rappels médicament'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.popOrGo('/sante/patient/medication/${Uri.encodeComponent(widget.medicationId)}'),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _addReminder,
            icon: const Icon(Icons.add_alarm),
          ),
        ],
      ),
      body: FutureBuilder<List<MedicationReminder>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            debugPrint('PatientMedicationRemindersPage error: ${snap.error}');
            return const Center(child: Text('Impossible de charger les rappels.'));
          }
          final items = snap.data ?? const [];
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.alarm, size: 44),
                    const SizedBox(height: 12),
                    const Text('Aucun rappel configuré.'),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _loading ? null : _addReminder,
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter un rappel'),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final r = items[i];
              final timeStr = r.time.format(context);
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                tileColor: Theme.of(context).colorScheme.surface,
                title: Text(timeStr),
                subtitle: Text(r.daysOfWeek.length == 7 ? 'Tous les jours' : 'Jours: ${r.daysOfWeek.join(', ')}'),
                leading: Switch(value: r.isEnabled, onChanged: _loading ? null : (v) => _toggle(r, v)),
                trailing: IconButton(
                  onPressed: _loading ? null : () => _delete(r),
                  icon: const Icon(Icons.delete_outline),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _addReminder,
        icon: const Icon(Icons.add),
        label: const Text('Rappel'),
      ),
    );
  }
}
