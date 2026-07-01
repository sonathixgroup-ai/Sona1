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
  final SupabaseClient _supabase =
      SupabaseConfig.client;

  final _formKey = GlobalKey<FormState>();

  final _doctorNameController =
      TextEditingController();

  final _doctorSpecialtyController =
      TextEditingController();

  final _notesController =
      TextEditingController();

  DateTime _selectedDate =
      DateTime.now().add(
    const Duration(days: 1),
  );

  TimeOfDay _selectedTime =
      TimeOfDay.now();

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
      final user =
          AuthController
              .instance
              .currentUser;

      if (user == null) {
        throw Exception(
          'Utilisateur non connecté',
        );
      }

      final response = await _supabase
          .from('health_appointments')
          .select(
            'doctor_id, doctor_name, doctor_specialty',
          )
          .eq('patient_id', user.id)
          .limit(20);

      if (response is List) {
        final seen = <String>{};

        for (final row in response) {
          final id =
              row['doctor_id']
                  as String?;

          final name =
              row['doctor_name']
                      as String? ??
                  'Médecin';

          if (id != null &&
              !seen.contains(id)) {
            seen.add(id);

            _doctors.add(
              Doctor(
                id: id,
                firstName:
                    name
                        .split(' ')
                        .first,
                lastName:
                    name.split(' ')
                                .length >
                            1
                        ? name
                            .split(' ')
                            .last
                        : '',
                specialty:
                    row['doctor_specialty']
                            as String? ??
                        'Généraliste',
              ),
            );
          }
        }
      }

      // ✅ CORRECTION ICI
      if (widget.consultationId != null) {
        final consultationData =
            await _supabase
                .from(
                  'health_appointments',
                )
                .select('*')
                .eq(
                  'id',
                  widget.consultationId!,
                )
                .maybeSingle();

        if (consultationData ==
            null) {
          throw Exception(
            'Consultation introuvable',
          );
        }

        final typeName =
            (consultationData['type']
                    as String?) ??
                AppointmentType
                    .teleconsultation
                    .name;

        final statusName =
            (consultationData['status']
                    as String?) ??
                AppointmentStatus
                    .scheduled
                    .name;

        _consultation =
            Appointment(
          id:
              consultationData['id']
                  as String,
          doctorId:
              consultationData[
                          'doctor_id']
                      as String? ??
                  '',
          doctorName:
              consultationData[
                          'doctor_name']
                      as String? ??
                  'Médecin',
          doctorSpecialty:
              consultationData[
                      'doctor_specialty']
                  as String?,
          patientId:
              consultationData[
                          'patient_id']
                      as String? ??
                  user.id,
          patientName:
              consultationData[
                      'patient_name']
                  as String?,
          date: DateTime.parse(
            consultationData[
                    'scheduled_at']
                as String,
          ),
          type: AppointmentType
              .values
              .firstWhere(
            (e) =>
                e.name ==
                typeName,
            orElse:
                () =>
                    AppointmentType
                        .teleconsultation,
          ),
          status:
              AppointmentStatus
                  .values
                  .firstWhere(
            (e) =>
                e.name ==
                statusName,
            orElse:
                () =>
                    AppointmentStatus
                        .scheduled,
          ),
          notes:
              consultationData[
                  'notes'] as String?,
          teleconsultationLink:
              consultationData[
                      'teleconsultation_link']
                  as String?,
          isEmergency:
              consultationData[
                          'is_emergency']
                      as bool? ??
                  false,
        );

        _doctorNameController
                .text =
            _consultation!
                .doctorName;

        _doctorSpecialtyController
                .text =
            _consultation!
                    .doctorSpecialty ??
                '';

        _selectedDate =
            _consultation!.date;

        _selectedTime = TimeOfDay(
          hour:
              _consultation!
                  .date
                  .hour,
          minute:
              _consultation!
                  .date
                  .minute,
        );

        _notesController.text =
            _consultation!.notes ??
                '';
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
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    final doctorName =
        _doctorNameController.text
            .trim();

    if (doctorName.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Veuillez entrer le nom du médecin',
          ),
          backgroundColor:
              Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final user =
          AuthController
              .instance
              .currentUser;

      if (user == null) {
        throw Exception(
          'Utilisateur non connecté',
        );
      }

      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final link =
          'https://meet.jit.si/thix_${DateTime.now().millisecondsSinceEpoch}';

      final payload = {
        'doctor_id': '',
        'doctor_name': doctorName,
        'doctor_specialty':
            _doctorSpecialtyController
                    .text
                    .trim()
                    .isNotEmpty
                ? _doctorSpecialtyController
                    .text
                    .trim()
                : null,
        'patient_id': user.id,
        'patient_name':
            user.displayName,
        'scheduled_at':
            dateTime
                .toIso8601String(),
        'type':
            AppointmentType
                .teleconsultation
                .name,
        'status':
            AppointmentStatus
                .scheduled
                .name,
        'notes':
            _notesController.text
                    .trim()
                    .isNotEmpty
                ? _notesController.text
                    .trim()
                : null,
        'teleconsultation_link':
            link,
        'is_emergency': false,
      };

      if (widget.consultationId ==
          null) {
        final created =
            await _supabase
                .from(
                  'health_appointments',
                )
                .insert(payload)
                .select()
                .single();

        final createdId =
            created['id']
                as String;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Téléconsultation créée avec succès',
            ),
            backgroundColor:
                Colors.green,
          ),
        );

        if (!mounted) return;

        context.push(
          '/sante/patient/teleconsultation/$createdId',
        );
      } else {
        await _supabase
            .from(
              'health_appointments',
            )
            .update({
              'doctor_name':
                  doctorName,
              'doctor_specialty':
                  _doctorSpecialtyController
                      .text
                      .trim(),
              'scheduled_at':
                  dateTime
                      .toIso8601String(),
              'notes':
                  _notesController
                      .text
                      .trim(),
            })
            .eq(
              'id',
              widget.consultationId!,
            );

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Téléconsultation mise à jour',
            ),
            backgroundColor:
                Colors.green,
          ),
        );

        if (!mounted) return;

        await _loadData();

        context.pop(true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Erreur : $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
