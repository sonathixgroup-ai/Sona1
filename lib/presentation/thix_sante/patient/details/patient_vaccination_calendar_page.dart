import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/nav.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';

class PatientVaccinationCalendarPage extends StatefulWidget {
  const PatientVaccinationCalendarPage({super.key});

  @override
  State<PatientVaccinationCalendarPage> createState() => _PatientVaccinationCalendarPageState();
}

class _PatientVaccinationCalendarPageState extends State<PatientVaccinationCalendarPage> {
  bool _loading = false;

  Future<List<Vaccine>> _load() {
    final uid = AuthController.instance.currentUser?.id;
    return uid == null ? Future.value(const []) : HealthService.instance.fetchVaccines(uid);
  }

  Future<void> _add() async {
    final uid = AuthController.instance.currentUser?.id;
    if (uid == null) return;

    final nameCtrl = TextEditingController();
    DateTime date = DateTime.now();
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
              Text('Ajouter un vaccin', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nom du vaccin')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Text('Date: ${date.day}/${date.month}/${date.year}')),
                  TextButton(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        initialDate: date,
                      );
                      if (d == null) return;
                      date = d;
                      // ignore: use_build_context_synchronously
                      (context as Element).markNeedsBuild();
                    },
                    child: const Text('Choisir'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Ajouter'),
              ),
            ],
          ),
        );
      },
    );
    if (ok != true) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _loading = true);
    try {
      await HealthService.instance.addVaccine(Vaccine(id: '', patientId: uid, name: name, dateAdministered: date));
      if (mounted) setState(() {});
    } catch (e, st) {
      debugPrint('PatientVaccinationCalendarPage add failed: $e');
      debugPrint(st.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vaccinations'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.popOrGo('/sante/patient/dashboard'),
        ),
      ),
      body: FutureBuilder<List<Vaccine>>(
        future: _load(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) {
            debugPrint('PatientVaccinationCalendarPage error: ${snap.error}');
            return const Center(child: Text('Impossible de charger les vaccins.'));
          }
          final items = snap.data ?? const [];
          if (items.isEmpty) return const Center(child: Text('Aucun vaccin enregistré.'));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final v = items[i];
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                tileColor: Theme.of(context).colorScheme.surface,
                title: Text(v.name),
                subtitle: Text('Reçu le ${v.dateAdministered.day}/${v.dateAdministered.month}/${v.dateAdministered.year}'),
                trailing: const Icon(Icons.shield_outlined),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _add,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }
}
