// presentation/thix_sante/patient/details/patient_appointment_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';
import 'package:thix_id/supabase/supabase_config.dart';

class PatientAppointmentPage extends StatefulWidget {
  final String? appointmentId; // null = création
  final bool isEditing;

  const PatientAppointmentPage({
    super.key,
    this.appointmentId,
    this.isEditing = false,
  });

  @override
  State<PatientAppointmentPage> createState() => _PatientAppointmentPageState();
}

class _PatientAppointmentPageState extends State<PatientAppointmentPage> {
  final HealthService _healthService = HealthService.instance;
  final SupabaseClient _supabase = SupabaseConfig.client;

  bool _isLoading = true;
  bool _isSaving = false;
  Appointment? _appointment;

  // Contrôleurs du formulaire
  final _doctorNameController = TextEditingController();
  final _doctorSpecialtyController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  AppointmentType _selectedType = AppointmentType.inPerson;
  AppointmentStatus _selectedStatus = AppointmentStatus.scheduled;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _doctorNameController.dispose();
    _doctorSpecialtyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (widget.appointmentId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Récupérer le patientId depuis AuthController
      final user = AuthController.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }
      final patientId = user.id;

      // Récupérer tous les rendez-vous du patient et filtrer par ID
      final appointments = await _healthService.fetchAppointments(patientId);
      final found = appointments.firstWhere(
        (a) => a.id == widget.appointmentId,
        orElse: () => throw Exception('Rendez-vous introuvable'),
      );

      setState(() {
        _appointment = found;
        _fillControllersFromAppointment(found);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de chargement : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _fillControllersFromAppointment(Appointment a) {
    _doctorNameController.text = a.doctorName;
    _doctorSpecialtyController.text = a.doctorSpecialty ?? '';
    _selectedDate = a.date;
    _selectedTime = TimeOfDay(hour: a.date.hour, minute: a.date.minute);
    _selectedType = a.type;
    _selectedStatus = a.status;
    _notesController.text = a.notes ?? '';
  }

  Future<void> _save() async {
    if (_doctorNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer le nom du médecin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final appointment = Appointment(
        id: widget.appointmentId ?? '',
        doctorId: '',
        doctorName: _doctorNameController.text.trim(),
        doctorSpecialty: _doctorSpecialtyController.text.trim().isNotEmpty
            ? _doctorSpecialtyController.text.trim()
            : null,
        patientId: user.id,
        patientName: user.displayName ?? '',
        date: dateTime,
        type: _selectedType,
        status: _selectedStatus,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        isEmergency: false,
      );

      if (widget.appointmentId == null) {
        // Création
        final created = await _healthService.createAppointment(appointment);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rendez-vous créé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        context.push('/sante/patient/appointment/${created.id}');
      } else {
        // Mise à jour
        await _updateAppointment(appointment);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rendez-vous mis à jour'),
            backgroundColor: Colors.green,
          ),
        );
        // Recharger les données
        await _loadData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _updateAppointment(Appointment updated) async {
    try {
      await _supabase.from('health_appointments').update({
        'doctor_name': updated.doctorName,
        'doctor_specialty': updated.doctorSpecialty,
        'scheduled_at': updated.date.toIso8601String(),
        'type': updated.type.name,
        'status': updated.status.name,
        'notes': updated.notes,
      }).eq('id', widget.appointmentId!);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _cancelAppointment() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler le rendez-vous ?'),
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
    if (confirm == true && widget.appointmentId != null) {
      try {
        await _healthService.cancelAppointment(widget.appointmentId!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rendez-vous annulé'),
            backgroundColor: Colors.orange,
          ),
        );
        context.pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isNew = widget.appointmentId == null;
    final String title = isNew
        ? 'Nouveau rendez-vous'
        : (widget.isEditing ? 'Modifier rendez-vous' : 'Détail rendez-vous');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (!isNew && !widget.isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                context.push('/sante/patient/appointment/${widget.appointmentId}?edit=true');
              },
            ),
          if (!isNew && !widget.isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _cancelAppointment,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (!isNew && !widget.isEditing)
                    _buildDetailView()
                  else
                    _buildFormView(),
                  const SizedBox(height: 24),
                  if (widget.isEditing || isNew)
                    ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563FF),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(isNew ? 'Créer' : 'Enregistrer'),
                    ),
                  if (!isNew && !widget.isEditing)
                    OutlinedButton(
                      onPressed: () => _cancelAppointment(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text('Annuler le rendez-vous'),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow(Icons.person, 'Médecin', _appointment!.doctorName),
        _infoRow(
            Icons.medical_services, 'Spécialité', _appointment!.doctorSpecialty ?? 'Généraliste'),
        _infoRow(Icons.calendar_today, 'Date', _appointment!.formattedDate),
        _infoRow(Icons.videocam, 'Type', _appointment!.type.name),
        _infoRow(Icons.info, 'Statut', _appointment!.status.name),
        if (_appointment!.notes != null)
          _infoRow(Icons.note, 'Notes', _appointment!.notes!),
        if (_appointment!.teleconsultationLink != null)
          ListTile(
            leading: const Icon(Icons.link, color: Colors.blue),
            title: const Text('Lien de consultation'),
            subtitle: Text(_appointment!.teleconsultationLink!),
            onTap: () {
              context.push(
                '/sante/patient/teleconsultation/${_appointment!.id}',
                extra: _appointment!.teleconsultationLink,
              );
            },
          ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormView() {
    return Column(
      children: [
        TextField(
          controller: _doctorNameController,
          decoration: const InputDecoration(
            labelText: 'Nom du médecin *',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _doctorSpecialtyController,
          decoration: const InputDecoration(
            labelText: 'Spécialité (optionnel)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) setState(() => _selectedDate = date);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(_selectedDate),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime,
                  );
                  if (time != null) setState(() => _selectedTime = time);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Heure',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _selectedTime.format(context),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<AppointmentType>(
          value: _selectedType,
          items: AppointmentType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type.name),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedType = value!),
          decoration: const InputDecoration(
            labelText: 'Type de consultation',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<AppointmentStatus>(
          value: _selectedStatus,
          items: AppointmentStatus.values.map((status) {
            return DropdownMenuItem(
              value: status,
              child: Text(status.name),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedStatus = value!),
          decoration: const InputDecoration(
            labelText: 'Statut',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Notes (optionnel)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }
}
