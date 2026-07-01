// presentation/thix_sante/patient/details/patient_teleconsultation_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/supabase/supabase_config.dart';

class PatientTeleconsultationPage extends StatefulWidget {
  final String? consultationId;
  final bool isEditing;

  const PatientTeleconsultationPage({
    super.key,
    this.consultationId,
    this.isEditing = false,
  });

  @override
  State<PatientTeleconsultationPage> createState() =>
      _PatientTeleconsultationPageState();
}

class _PatientTeleconsultationPageState
    extends State<PatientTeleconsultationPage> {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final _formKey = GlobalKey<FormState>();

  final _doctorNameController = TextEditingController();
  final _doctorSpecialtyController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  Appointment? _consultation;
  List<Doctor> _doctors = [];

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
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      final response = await _supabase
          .from('health_appointments')
          .select('doctor_id, doctor_name, doctor_specialty')
          .eq('patient_id', user.id)
          .limit(20);

      if (response is List) {
        final seen = <String>{};
        for (final row in response) {
          final id = row['doctor_id'] as String?;
          final name = row['doctor_name'] as String? ?? 'Médecin';
          if (id != null && !seen.contains(id)) {
            seen.add(id);
            _doctors.add(Doctor(
              id: id,
              firstName: name.split(' ').first,
              lastName: name.split(' ').length > 1 ? name.split(' ').last : '',
              specialty: row['doctor_specialty'] as String? ?? 'Généraliste',
            ));
          }
        }
      }

      if (widget.consultationId != null) {
        final consultationData = await _supabase
            .from('health_appointments')
            .select('*')
            .eq('id', widget.consultationId)
            .maybeSingle();

        if (consultationData == null) {
          throw Exception('Consultation introuvable');
        }

        final typeName = (consultationData['type'] as String?) ??
            AppointmentType.teleconsultation.name;
        final statusName = (consultationData['status'] as String?) ??
            AppointmentStatus.scheduled.name;

        _consultation = Appointment(
          id: consultationData['id'] as String,
          doctorId: consultationData['doctor_id'] as String? ?? '',
          doctorName: consultationData['doctor_name'] as String? ?? 'Médecin',
          doctorSpecialty: consultationData['doctor_specialty'] as String?,
          patientId: consultationData['patient_id'] as String? ?? user.id,
          patientName: consultationData['patient_name'] as String?,
          date: DateTime.parse(consultationData['scheduled_at'] as String),
          type: AppointmentType.values.firstWhere(
            (e) => e.name == typeName,
            orElse: () => AppointmentType.teleconsultation,
          ),
          status: AppointmentStatus.values.firstWhere(
            (e) => e.name == statusName,
            orElse: () => AppointmentStatus.scheduled,
          ),
          notes: consultationData['notes'] as String?,
          teleconsultationLink: consultationData['teleconsultation_link']
              as String?,
          isEmergency: consultationData['is_emergency'] as bool? ?? false,
        );

        _doctorNameController.text = _consultation!.doctorName;
        _doctorSpecialtyController.text =
            _consultation!.doctorSpecialty ?? '';
        _selectedDate = _consultation!.date;
        _selectedTime =
            TimeOfDay(hour: _consultation!.date.hour, minute: _consultation!.date.minute);
        _notesController.text = _consultation!.notes ?? '';
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final doctorName = _doctorNameController.text.trim();
    if (doctorName.isEmpty) {
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

      final link = 'https://meet.jit.si/thix_${DateTime.now().millisecondsSinceEpoch}';

      final payload = {
        'doctor_id': '',
        'doctor_name': doctorName,
        'doctor_specialty': _doctorSpecialtyController.text.trim().isNotEmpty
            ? _doctorSpecialtyController.text.trim()
            : null,
        'patient_id': user.id,
        'patient_name': user.displayName,
        'scheduled_at': dateTime.toIso8601String(),
        'type': AppointmentType.teleconsultation.name,
        'status': AppointmentStatus.scheduled.name,
        'notes': _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        'teleconsultation_link': link,
        'is_emergency': false,
      };

      if (widget.consultationId == null) {
        final created = await _supabase
            .from('health_appointments')
            .insert(payload)
            .select()
            .single();

        // ✅ Correction : convertir en String non nullable
        final createdId = created['id'] as String;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Téléconsultation créée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        if (!mounted) return;
        context.push('/sante/patient/teleconsultation/$createdId');
      } else {
        await _supabase
            .from('health_appointments')
            .update({
              'doctor_name': doctorName,
              'doctor_specialty': _doctorSpecialtyController.text.trim(),
              'scheduled_at': dateTime.toIso8601String(),
              'notes': _notesController.text.trim(),
            })
            .eq('id', widget.consultationId!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Téléconsultation mise à jour'),
            backgroundColor: Colors.green,
          ),
        );
        if (!mounted) return;
        await _loadData();
        context.pop(true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _cancelConsultation() async {
    if (_consultation == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler la téléconsultation ?'),
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
      await _supabase
          .from('health_appointments')
          .update({'status': AppointmentStatus.cancelled.name})
          .eq('id', _consultation!.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Téléconsultation annulée'),
          backgroundColor: Colors.orange,
        ),
      );
      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.consultationId == null;
    final title = isNew
        ? 'Nouvelle téléconsultation'
        : (widget.isEditing ? 'Modifier' : 'Détail téléconsultation');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF2563FF),
        foregroundColor: Colors.white,
        actions: [
          if (!isNew && !widget.isEditing &&
              _consultation!.status != AppointmentStatus.cancelled &&
              _consultation!.status != AppointmentStatus.completed)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                if (_consultation != null) {
                  context.push('/sante/patient/teleconsultation/${_consultation!.id}?edit=true');
                }
              },
            ),
        ],
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
                          onPressed: _cancelConsultation,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          child: const Text('Annuler la consultation'),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDetailView() {
    final c = _consultation!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow(Icons.person, 'Médecin', c.doctorName),
        _infoRow(Icons.medical_services, 'Spécialité',
            c.doctorSpecialty ?? 'Généraliste'),
        _infoRow(Icons.calendar_today, 'Date', c.formattedDate),
        _infoRow(Icons.videocam, 'Type', c.type.name),
        _infoRow(Icons.info, 'Statut', c.status.name),
        if (c.notes != null) _infoRow(Icons.note, 'Notes', c.notes!),
        if (c.teleconsultationLink != null) ...[
          const SizedBox(height: 12),
          Card(
            color: Colors.blue[50],
            child: ListTile(
              leading: const Icon(Icons.video_call, color: Colors.blue),
              title: const Text('Lien de consultation'),
              subtitle: Text(c.teleconsultationLink!),
              trailing: ElevatedButton(
                onPressed: () {
                  context.push(
                    '/sante/patient/teleconsultation/jitsi',
                    extra: c.teleconsultationLink,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Rejoindre'),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextField(
            controller: _doctorNameController,
            decoration: const InputDecoration(
              labelText: 'Nom du médecin *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _doctorSpecialtyController,
            decoration: const InputDecoration(
              labelText: 'Spécialité (optionnel)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.medical_services),
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
                      labelText: 'Date *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
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
                      labelText: 'Heure *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.access_time),
                    ),
                    child: Text(_selectedTime.format(context)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (optionnel)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.note),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
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
