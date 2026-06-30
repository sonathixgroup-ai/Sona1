 // presentation/thix_sante/patient/details/patient_medication_reminders_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';

class PatientMedicationRemindersPage extends StatefulWidget {
  final String medicationId;

  const PatientMedicationRemindersPage({
    super.key,
    required this.medicationId,
  });

  @override
  State<PatientMedicationRemindersPage> createState() =>
      _PatientMedicationRemindersPageState();
}

class _PatientMedicationRemindersPageState
    extends State<PatientMedicationRemindersPage> {
  final HealthService _healthService = HealthService.instance;
  List<MedicationReminder> _reminders = [];
  bool _isLoading = true;
  String? _error;
  String? _medicationName;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Récupérer les rappels
      final reminders = await _healthService.fetchMedicationReminders(
        widget.medicationId,
      );
      
      // Récupérer le nom du médicament (depuis le service ou via une requête)
      // Pour l'instant on le récupère depuis la liste des médicaments du patient
      // On pourrait aussi avoir une méthode getMedicationById
      final user = AuthController.instance.currentUser;
      if (user != null) {
        final medications = await _healthService.fetchMedications(
          user.id,
          activeOnly: false,
        );
        final med = medications.firstWhere(
          (m) => m.id == widget.medicationId,
          orElse: () => throw Exception('Médicament introuvable'),
        );
        _medicationName = med.name;
      }

      setState(() {
        _reminders = reminders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addReminder() async {
    // Sélectionner l'heure
    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (selectedTime == null) return;

    // Sélectionner les jours (tous par défaut)
    final List<int> selectedDays = await _showDayPicker(context);
    if (selectedDays.isEmpty) {
      // Si aucun jour sélectionné, on annule l'ajout
      return;
    }

    try {
      final newReminder = await _healthService.addMedicationReminder(
        medicationId: widget.medicationId,
        time: selectedTime,
        daysOfWeek: selectedDays,
        isEnabled: true,
      );
      setState(() {
        _reminders.add(newReminder);
        // Trier par heure
        _reminders.sort((a, b) => a.time.hour.compareTo(b.time.hour));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rappel ajouté avec succès.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<List<int>> _showDayPicker(BuildContext context) async {
    final List<String> dayLabels = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final List<int> days = [1, 2, 3, 4, 5, 6, 0]; // 0 = Dimanche
    final List<bool> selected = List.filled(7, true); // Tous sélectionnés par défaut

    return showDialog<List<int>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              title: const Text('Jours de rappel'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(7, (index) {
                  return CheckboxListTile(
                    title: Text(dayLabels[index]),
                    value: selected[index],
                    onChanged: (value) {
                      setStateDialog(() {
                        selected[index] = value!;
                      });
                    },
                  );
                }),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () {
                    final result = <int>[];
                    for (int i = 0; i < 7; i++) {
                      if (selected[i]) result.add(days[i]);
                    }
                    Navigator.pop(ctx, result);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    ).then((value) => value ?? []);
  }

  Future<void> _toggleReminder(MedicationReminder reminder) async {
    try {
      await _healthService.setMedicationReminderEnabled(
        reminderId: reminder.id,
        isEnabled: !reminder.isEnabled,
      );
      setState(() {
        final index = _reminders.indexWhere((r) => r.id == reminder.id);
        if (index != -1) {
          _reminders[index] = MedicationReminder(
            id: reminder.id,
            medicationId: reminder.medicationId,
            time: reminder.time,
            isEnabled: !reminder.isEnabled,
            daysOfWeek: reminder.daysOfWeek,
          );
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reminder.isEnabled ? 'Rappel désactivé' : 'Rappel activé',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteReminder(MedicationReminder reminder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le rappel ?'),
        content: const Text('Cette action est définitive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Oui'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _healthService.deleteMedicationReminder(reminder.id);
      setState(() {
        _reminders.removeWhere((r) => r.id == reminder.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rappel supprimé.'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDays(List<int> days) {
    if (days.length == 7) return 'Tous les jours';
    final Map<int, String> labels = {
      1: 'Lun',
      2: 'Mar',
      3: 'Mer',
      4: 'Jeu',
      5: 'Ven',
      6: 'Sam',
      0: 'Dim',
    };
    final sorted = List<int>.from(days)..sort();
    return sorted.map((d) => labels[d] ?? '').join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_medicationName != null
            ? 'Rappels - $_medicationName'
            : 'Gestion des rappels'),
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
                        onPressed: _loadData,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Liste des rappels
                    Expanded(
                      child: _reminders.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'Aucun rappel configuré.\nAppuyez sur le bouton + pour en ajouter.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _reminders.length,
                              itemBuilder: (context, index) {
                                final reminder = _reminders[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ListTile(
                                    leading: Icon(
                                      reminder.isEnabled
                                          ? Icons.notifications_active
                                          : Icons.notifications_off,
                                      color: reminder.isEnabled
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                    title: Text(
                                      reminder.timeString,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      _formatDays(reminder.daysOfWeek),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            reminder.isEnabled
                                                ? Icons.pause_circle_outline
                                                : Icons.play_circle_outline,
                                            color: reminder.isEnabled
                                                ? Colors.orange
                                                : Colors.green,
                                          ),
                                          onPressed: () =>
                                              _toggleReminder(reminder),
                                          tooltip: reminder.isEnabled
                                              ? 'Désactiver'
                                              : 'Activer',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline,
                                              color: Colors.red),
                                          onPressed: () =>
                                              _deleteReminder(reminder),
                                          tooltip: 'Supprimer',
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    // Bouton ajouter
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton.icon(
                        onPressed: _addReminder,
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter un rappel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563FF),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
