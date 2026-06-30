// presentation/thix_sante/shared/services/health_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/supabase/supabase_config.dart';

/// Service principal pour le module THIX Santé.
/// Gère les appels API, la persistance et la logique métier.
class HealthService {
  // Singleton
  HealthService._internal();
  static final HealthService _instance = HealthService._internal();
  static HealthService get instance => _instance;

  SupabaseClient get _db => SupabaseConfig.client;

  // Noms des tables (configurables)
  static const _tAppointments = 'health_appointments';
  static const _tVitals = 'health_vitals';
  static const _tMedications = 'health_medications';
  static const _tMedicationReminders = 'health_medication_reminders';
  static const _tPrescriptions = 'health_prescriptions';
  static const _tExams = 'health_exams';
  static const _tVaccines = 'health_vaccines';
  static const _tTeleexpertise = 'health_teleexpertise_requests';
  static const _tPharmacies = 'health_pharmacies';
  static const _tDoctorSlots = 'health_doctor_slots';
  static const _tHealthAlerts = 'health_alerts';
  static const _tPharmacyOrders = 'health_pharmacy_orders';
  static const _tPharmacyInventory = 'health_pharmacy_inventory_items';

  // Helpers pour extraire des valeurs sécurisées
  String _s(Map<String, dynamic> m, String k, [String d = '']) =>
      (m[k] as String?)?.trim().isNotEmpty == true ? (m[k] as String).trim() : d;

  double _d(Map<String, dynamic> m, String k, [double d = 0]) {
    final v = m[k];
    if (v is num) return v.toDouble();
    return d;
  }

  DateTime _dt(Map<String, dynamic> m, String k, [DateTime? d]) {
    final v = m[k];
    if (v is String) return DateTime.tryParse(v) ?? (d ?? DateTime.now());
    return d ?? DateTime.now();
  }

  Future<List<Map<String, dynamic>>> _safeSelect(
    String table, {
    String columns = '*',
    Map<String, dynamic>? eq,
    int? limit,
    List<String>? orderBy,
    bool ascending = false,
  }) async {
    try {
      dynamic q = _db.from(table).select(columns);
      if (eq != null) {
        for (final e in eq.entries) {
          q = q.eq(e.key, e.value);
        }
      }
      if (orderBy != null) {
        for (final k in orderBy) {
          q = q.order(k, ascending: ascending);
        }
      }
      if (limit != null) q = q.limit(limit);
      final res = await q;
      if (res is List) {
        return res.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
      }
      return const [];
    } catch (e, st) {
      debugPrint('HealthService: select failed table=$table err=$e');
      debugPrint(st.toString());
      return const [];
    }
  }

  Future<Map<String, dynamic>?> _safeSingle(
    String table, {
    String columns = '*',
    required Map<String, dynamic> eq,
  }) async {
    try {
      dynamic q = _db.from(table).select(columns);
      for (final e in eq.entries) {
        q = q.eq(e.key, e.value);
      }
      final res = await q.maybeSingle();
      if (res is Map) return res.cast<String, dynamic>();
      return null;
    } catch (e, st) {
      debugPrint('HealthService: single failed table=$table err=$e');
      debugPrint(st.toString());
      return null;
    }
  }

  // ============================================================
  // RÉSUMÉ DE SANTÉ
  // ============================================================

  Future<HealthSummary> fetchHealthSummary(String patientId) async {
    final appts = await fetchUpcomingAppointments(patientId);
    final meds = await fetchMedications(patientId, activeOnly: true);
    final exams = await fetchExamResults(patientId);
    final score = (50 + meds.length * 5 + appts.length * 3).clamp(0, 100);
    return HealthSummary(
      consultationsThisYear: 0,
      examsCompleted: exams.where((e) => e.status == ExamStatus.completed).length,
      activeMedications: meds.length,
      upcomingAppointments: appts.length,
      healthScore: score,
      lastUpdate: DateTime.now(),
      upcomingAppointmentsList: appts.take(3).toList(),
      currentMedications: meds,
      articles: await fetchHealthArticles(limit: 4),
    );
  }

  // ============================================================
  // RENDEZ-VOUS
  // ============================================================

  Future<List<Appointment>> fetchAppointments(
    String patientId, {
    int? limit,
    AppointmentStatus? status,
  }) async {
    final rows = await _safeSelect(
      _tAppointments,
      eq: {
        'patient_id': patientId,
        if (status != null) 'status': status.name,
      },
      limit: limit,
      orderBy: const ['scheduled_at'],
      ascending: true,
    );
    return rows.map((m) {
      final typeName = _s(m, 'type', AppointmentType.inPerson.name);
      final statusName = _s(m, 'status', AppointmentStatus.scheduled.name);
      return Appointment(
        id: _s(m, 'id'),
        doctorId: _s(m, 'doctor_id'),
        doctorName: _s(m, 'doctor_name', 'Médecin'),
        doctorSpecialty: (m['doctor_specialty'] as String?)?.trim(),
        patientId: _s(m, 'patient_id', patientId),
        patientName: (m['patient_name'] as String?)?.trim(),
        date: _dt(m, 'scheduled_at'),
        type: AppointmentType.values.firstWhere((e) => e.name == typeName, orElse: () => AppointmentType.inPerson),
        status: AppointmentStatus.values.firstWhere((e) => e.name == statusName, orElse: () => AppointmentStatus.scheduled),
        notes: (m['notes'] as String?)?.trim(),
        teleconsultationLink: (m['teleconsultation_link'] as String?)?.trim(),
        isEmergency: (m['is_emergency'] as bool?) ?? false,
      );
    }).toList();
  }

  Future<List<Appointment>> fetchUpcomingAppointments(String patientId) async {
    final all = await fetchAppointments(patientId);
    return all.where((a) => a.status == AppointmentStatus.scheduled || a.status == AppointmentStatus.confirmed).toList();
  }

  Future<Appointment> createAppointment(Appointment appointment) async {
    try {
      final payload = {
        'doctor_id': appointment.doctorId,
        'doctor_name': appointment.doctorName,
        'doctor_specialty': appointment.doctorSpecialty,
        'patient_id': appointment.patientId,
        'patient_name': appointment.patientName,
        'scheduled_at': appointment.date.toIso8601String(),
        'type': appointment.type.name,
        'status': appointment.status.name,
        'notes': appointment.notes,
        'teleconsultation_link': appointment.teleconsultationLink,
        'is_emergency': appointment.isEmergency,
      };
      final res = await _db.from(_tAppointments).insert(payload).select('*').single();
      final m = (res as Map).cast<String, dynamic>();
      return Appointment(
        id: _s(m, 'id', appointment.id),
        doctorId: _s(m, 'doctor_id', appointment.doctorId),
        doctorName: _s(m, 'doctor_name', appointment.doctorName),
        doctorSpecialty: (m['doctor_specialty'] as String?)?.trim(),
        patientId: _s(m, 'patient_id', appointment.patientId ?? ''),
        patientName: (m['patient_name'] as String?)?.trim(),
        date: _dt(m, 'scheduled_at', appointment.date),
        type: appointment.type,
        status: appointment.status,
        notes: (m['notes'] as String?)?.trim() ?? appointment.notes,
        teleconsultationLink: (m['teleconsultation_link'] as String?)?.trim() ?? appointment.teleconsultationLink,
        isEmergency: (m['is_emergency'] as bool?) ?? appointment.isEmergency,
      );
    } catch (e, st) {
      debugPrint('HealthService: createAppointment failed err=$e');
      debugPrint(st.toString());
      rethrow;
    }
  }

  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await _db.from(_tAppointments).update({'status': AppointmentStatus.cancelled.name}).eq('id', appointmentId);
    } catch (e, st) {
      debugPrint('HealthService: cancelAppointment failed err=$e');
      debugPrint(st.toString());
      rethrow;
    }
  }

  // ============================================================
  // MÉDICAMENTS
  // ============================================================

  Future<List<Medication>> fetchMedications(
    String patientId, {
    bool activeOnly = true,
  }) async {
    final rows = await _safeSelect(
      _tMedications,
      eq: {
        'patient_id': patientId,
        if (activeOnly) 'is_active': true,
      },
      orderBy: const ['start_date'],
      ascending: false,
    );

    final ids = rows.map((e) => _s(e, 'id')).where((e) => e.isNotEmpty).toList();
    final remindersByMed = <String, List<MedicationReminder>>{};
    if (ids.isNotEmpty) {
      try {
        final remRows = await _db
            .from(_tMedicationReminders)
            .select('*')
            .inFilter('medication_id', ids)
            .order('time', ascending: true);
        if (remRows is List) {
          for (final raw in remRows.whereType<Map>()) {
            final m = raw.cast<String, dynamic>();
            final mid = _s(m, 'medication_id');
            if (mid.isEmpty) continue;
            final timeStr = _s(m, 'time', '08:00');
            final parts = timeStr.split(':');
            final h = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 8;
            final min = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
            (remindersByMed[mid] ??= []).add(
              MedicationReminder(
                id: _s(m, 'id'),
                medicationId: mid,
                time: TimeOfDay(hour: h.clamp(0, 23), minute: min.clamp(0, 59)),
                isEnabled: (m['is_enabled'] as bool?) ?? true,
                daysOfWeek: (m['days_of_week'] as List?)?.whereType<num>().map((e) => e.toInt()).toList() ?? const [0, 1, 2, 3, 4, 5, 6],
              ),
            );
          }
        }
      } catch (e, st) {
        debugPrint('HealthService: fetch reminders failed err=$e');
        debugPrint(st.toString());
      }
    }

    return rows.map((m) {
      final id = _s(m, 'id');
      return Medication(
        id: id,
        name: _s(m, 'name', 'Médicament'),
        dosage: _s(m, 'dosage', ''),
        frequency: _s(m, 'frequency', ''),
        duration: (m['duration'] as String?)?.trim(),
        instructions: (m['instructions'] as String?)?.trim(),
        startDate: _dt(m, 'start_date'),
        endDate: (m['end_date'] is String) ? DateTime.tryParse(m['end_date'] as String) : null,
        isActive: (m['is_active'] as bool?) ?? true,
        prescriptionId: (m['prescription_id'] as String?)?.trim(),
        prescribedBy: (m['prescribed_by'] as String?)?.trim(),
        reminders: remindersByMed[id] ?? const [],
      );
    }).toList();
  }

  Future<Medication> addMedication(Medication medication) async {
    try {
      final payload = {
        'patient_id': medication.patientId,
        'name': medication.name,
        'dosage': medication.dosage,
        'frequency': medication.frequency,
        'duration': medication.duration,
        'instructions': medication.instructions,
        'start_date': medication.startDate.toIso8601String(),
        'end_date': medication.endDate?.toIso8601String(),
        'is_active': medication.isActive,
        'prescription_id': medication.prescriptionId,
        'prescribed_by': medication.prescribedBy,
      };
      final res = await _db.from(_tMedications).insert(payload).select('*').single();
      final m = (res as Map).cast<String, dynamic>();
      return medication.copyWith(id: _s(m, 'id', medication.id));
    } catch (e, st) {
      debugPrint('HealthService: addMedication failed err=$e');
      debugPrint(st.toString());
      rethrow;
    }
  }

  Future<Medication> updateMedication(Medication medication) async {
    try {
      final payload = {
        'name': medication.name,
        'dosage': medication.dosage,
        'frequency': medication.frequency,
        'duration': medication.duration,
        'instructions': medication.instructions,
        'start_date': medication.startDate.toIso8601String(),
        'end_date': medication.endDate?.toIso8601String(),
        'is_active': medication.isActive,
      };
      await _db.from(_tMedications).update(payload).eq('id', medication.id);
      return medication;
    } catch (e, st) {
      debugPrint('HealthService: updateMedication failed err=$e');
      debugPrint(st.toString());
      rethrow;
    }
  }

  // ============================================================
  // SYMPTÔMES
  // ============================================================

  Future<List<Symptom>> fetchSymptoms(String patientId) async {
    // Table optionnelle, pour l'instant retourne vide
    return const [];
  }

  Future<Symptom> addSymptom(Symptom symptom) async {
    // À implémenter ultérieurement
    throw UnimplementedError('Symptom persistence is not configured yet.');
  }

  // ============================================================
  // CONSTANTES VITALES
  // ============================================================

  Future<List<VitalSign>> fetchVitalSigns(String patientId) async {
    final rows = await _safeSelect(
      _tVitals,
      eq: {'patient_id': patientId},
      orderBy: const ['measured_at'],
      ascending: false,
    );
    return rows.map((m) {
      final typeName = _s(m, 'type', VitalType.weight.name);
      final type = VitalType.values.firstWhere((e) => e.name == typeName, orElse: () => VitalType.weight);
      return VitalSign(
        id: _s(m, 'id'),
        patientId: _s(m, 'patient_id', patientId),
        type: type,
        value: _d(m, 'value'),
        unit: _s(m, 'unit', ''),
        date: _dt(m, 'measured_at'),
      );
    }).toList();
  }

  Future<VitalSign> addVitalSign(VitalSign vital) async {
    try {
      final payload = {
        'patient_id': vital.patientId,
        'type': vital.type.name,
        'value': vital.value,
        'unit': vital.unit,
        'measured_at': vital.date.toIso8601String(),
      };
      final res = await _db.from(_tVitals).insert(payload).select('*').single();
      final m = (res as Map).cast<String, dynamic>();
      return vital.copyWith(id: _s(m, 'id', vital.id));
    } catch (e, st) {
      debugPrint('HealthService: addVitalSign failed err=$e');
      debugPrint(st.toString());
      rethrow;
    }
  }

  // ============================================================
  // ORDONNANCES
  // ============================================================

  Future<List<Prescription>> fetchPrescriptions(String patientId) async {
    final rows = await _safeSelect(
      _tPrescriptions,
      eq: {'patient_id': patientId},
      orderBy: const ['issued_at'],
      ascending: false,
    );
    final meds = await fetchMedications(patientId, activeOnly: false);
    return rows.map((m) {
      final statusName = _s(m, 'status', PrescriptionStatus.active.name);
      return Prescription(
        id: _s(m, 'id'),
        patientId: _s(m, 'patient_id', patientId),
        patientName: _s(m, 'patient_name', ''),
        doctorId: _s(m, 'doctor_id', ''),
        doctorName: _s(m, 'doctor_name', 'Médecin'),
        date: _dt(m, 'issued_at'),
        validUntil: (m['valid_until'] is String) ? DateTime.tryParse(m['valid_until'] as String) : null,
        status: PrescriptionStatus.values.firstWhere((e) => e.name == statusName, orElse: () => PrescriptionStatus.active),
        medications: meds.where((x) => x.prescriptionId == _s(m, 'id')).toList(),
        notes: (m['notes'] as String?)?.trim(),
      );
    }).toList();
  }

  Future<Prescription> createPrescription(Prescription prescription) async {
    try {
      final payload = {
        'patient_id': prescription.patientId,
        'patient_name': prescription.patientName,
        'doctor_id': prescription.doctorId,
        'doctor_name': prescription.doctorName,
        'issued_at': prescription.date.toIso8601String(),
        'valid_until': prescription.validUntil?.toIso8601String(),
        'status': prescription.status.name,
        'notes': prescription.notes,
      };
      final res = await _db.from(_tPrescriptions).insert(payload).select('*').single();
      final m = (res as Map).cast<String, dynamic>();
      return prescription.copyWith(id: _s(m, 'id', prescription.id));
    } catch (e, st) {
      debugPrint('HealthService: createPrescription failed err=$e');
      debugPrint(st.toString());
      rethrow;
    }
  }

  // ============================================================
  // EXAMENS
  // ============================================================

  Future<List<ExamResult>> fetchExamResults(String patientId) async {
    final rows = await _safeSelect(
      _tExams,
      eq: {'patient_id': patientId},
      orderBy: const ['performed_at'],
      ascending: false,
    );
    return rows.map((m) {
      final statusName = _s(m, 'status', ExamStatus.pending.name);
      return ExamResult(
        id: _s(m, 'id'),
        patientId: _s(m, 'patient_id', patientId),
        examName: _s(m, 'exam_name', 'Examen'),
        date: _dt(m, 'performed_at'),
        result: (m['result'] as String?)?.trim(),
        status: ExamStatus.values.firstWhere((e) => e.name == statusName, orElse: () => ExamStatus.pending),
        comments: (m['comments'] as String?)?.trim(),
      );
    }).toList();
  }

  // ============================================================
  // VACCINS
  // ============================================================

  Future<List<Vaccine>> fetchVaccines(String patientId) async {
    final rows = await _safeSelect(
      _tVaccines,
      eq: {'patient_id': patientId},
      orderBy: const ['date_administered'],
      ascending: false,
    );
    return rows.map((m) {
      return Vaccine(
        id: _s(m, 'id'),
        patientId: _s(m, 'patient_id', patientId),
        name: _s(m, 'name', 'Vaccin'),
        dateAdministered: _dt(m, 'date_administered'),
        boosterDate: (m['booster_date'] is String) ? DateTime.tryParse(m['booster_date'] as String) : null,
        batchNumber: (m['batch_number'] as String?)?.trim(),
        administeredBy: (m['administered_by'] as String?)?.trim(),
      );
    }).toList();
  }

  Future<Vaccine> addVaccine(Vaccine vaccine) async {
    try {
      final payload = {
        'patient_id': vaccine.patientId,
        'name': vaccine.name,
        'date_administered': vaccine.dateAdministered.toIso8601String(),
        'booster_date': vaccine.boosterDate?.toIso8601String(),
        'batch_number': vaccine.batchNumber,
        'administered_by': vaccine.administeredBy,
      };
      final res = await _db.from(_tVaccines).insert(payload).select('*').single();
      final m = (res as Map).cast<String, dynamic>();
      return vaccine.copyWith(id: _s(m, 'id', vaccine.id));
    } catch (e, st) {
      debugPrint('HealthService: addVaccine failed err=$e');
      debugPrint(st.toString());
      rethrow;
    }
  }

  // ============================================================
  // ARTICLES DE SANTÉ
  // ============================================================

  Future<List<HealthArticle>> fetchHealthArticles({int limit = 10}) async {
    // Table optionnelle, retourne vide par défaut
    // Implémentez la requête si la table existe
    return const [];
  }

  // ============================================================
  // ALERTES SANITAIRES
  // ============================================================

  Future<List<HealthAlert>> fetchHealthAlerts(String patientId) async {
    // Table optionnelle, retourne vide par défaut
    // Implémentez la requête si la table existe
    return const [];
  }

  // ============================================================
  // PHARMACIES
  // ============================================================

  Future<List<Pharmacy>> findNearbyPharmacies(double lat, double lng) async {
    final rows = await _safeSelect(
      _tPharmacies,
      limit: 30,
    );
    final mapped = rows
        .map((m) => Pharmacy(
              id: _s(m, 'id'),
              name: _s(m, 'name', 'Pharmacie'),
              address: _s(m, 'address', ''),
              phone: (m['phone'] as String?)?.trim(),
              latitude: _d(m, 'lat'),
              longitude: _d(m, 'lng'),
              isOpen: (m['is_open'] as bool?) ?? true,
            ))
        .toList();
    mapped.sort((a, b) {
      final da = ((a.latitude ?? lat) - lat).abs() + ((a.longitude ?? lng) - lng).abs();
      final db = ((b.latitude ?? lat) - lat).abs() + ((b.longitude ?? lng) - lng).abs();
      return da.compareTo(db);
    });
    return mapped.take(10).toList();
  }

  Future<Pharmacy?> fetchPharmacyById(String pharmacyId) async {
    final m = await _safeSingle(_tPharmacies, eq: {'id': pharmacyId});
    if (m == null) return null;
    return Pharmacy(
      id: _s(m, 'id', pharmacyId),
      name: _s(m, 'name', 'Pharmacie'),
      address: _s(m, 'address', ''),
      phone: (m['phone'] as String?)?.trim(),
      latitude: _d(m, 'lat'),
      longitude: _d(m, 'lng'),
      isOpen: (m['is_open'] as bool?) ?? true,
    );
  }

  // ============================================================
  // TÉLÉEXPERTISE
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchTeleexpertiseRequests({required String patientId}) =>
      _safeSelect(_tTeleexpertise, eq: {'patient_id': patientId}, orderBy: const ['created_at'], ascending: false);

  Future<Map<String, dynamic>?> fetchTeleexpertiseRequestById(String id) =>
      _safeSingle(_tTeleexpertise, eq: {'id': id});

  Future<String> createTeleexpertiseRequest({required String patientId, required String subject, String? description}) async {
    try {
      final res = await _db
          .from(_tTeleexpertise)
          .insert({'patient_id': patientId, 'subject': subject, 'description': description})
          .select('id')
          .single();
      final m = (res as Map).cast<String, dynamic>();
      return _s(m, 'id');
    } catch (e, st) {
      debugPrint('HealthService: createTeleexpertiseRequest failed err=$e');
      debugPrint(st.toString());
      rethrow;
    }
  }

  // ============================================================
  // MÉDICAMENTS - RAPPELS (CRUD)
  // ============================================================

  Future<List<MedicationReminder>> fetchMedicationReminders(String medicationId) async {
    final rows = await _safeSelect(
      _tMedicationReminders,
      eq: {'medication_id': medicationId},
      orderBy: const ['time'],
      ascending: true,
    );
    return rows.map((m) {
      final timeStr = _s(m, 'time', '08:00');
      final parts = timeStr.split(':');
      final h = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 8;
      final min = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
      return MedicationReminder(
        id: _s(m, 'id'),
        medicationId: _s(m, 'medication_id', medicationId),
        time: TimeOfDay(hour: h.clamp(0, 23), minute: min.clamp(0, 59)),
        isEnabled: (m['is_enabled'] as bool?) ?? true,
        daysOfWeek: (m['days_of_week'] as List?)?.whereType<num>().map((e) => e.toInt()).toList() ?? const [0, 1, 2, 3, 4, 5, 6],
      );
    }).toList();
  }

  Future<MedicationReminder> addMedicationReminder({
    required String medicationId,
    required TimeOfDay time,
    List<int> daysOfWeek = const [0, 1, 2, 3, 4, 5, 6],
    bool isEnabled = true,
  }) async {
    try {
      final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      final res = await _db
          .from(_tMedicationReminders)
          .insert({'medication_id': medicationId, 'time': timeStr, 'days_of_week': daysOfWeek, 'is_enabled': isEnabled})
          .select('*')
          .single();
      final m = (res as Map).cast<String, dynamic>();
      return (await fetchMedicationReminders(_s(m, 'medication_id', medicationId))).firstWhere(
        (e) => e.id == _s(m, 'id'),
        orElse: () => MedicationReminder(id: _s(m, 'id'), medicationId: medicationId, time: time, isEnabled: isEnabled, daysOfWeek: daysOfWeek),
      );
    } catch (e, st) {
      debugPrint('HealthService: addMedicationReminder failed err=$e');
      debugPrint(st.toString());
      rethrow;
    }
  }

  Future<void> setMedicationReminderEnabled({required String reminderId, required bool isEnabled}) async {
    try {
      await _db.from(_tMedicationReminders).update({'is_enabled': isEnabled}).eq('id', reminderId);
    } catch (e, st) {
      debugPrint('HealthService: setMedicationReminderEnabled failed err=$e');
      debugPrint(st.toString());
      rethrow;
    }
  }

  Future<void> deleteMedicationReminder(String reminderId) async {
    try {
      await _db.from(_tMedicationReminders).delete().eq('id', reminderId);
    } catch (e, st) {
      debugPrint('HealthService: deleteMedicationReminder failed err=$e');
      debugPrint(st.toString());
      rethrow;
    }
  }

  // ============================================================
  // DOCTOR SLOTS
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchDoctorSlots(String doctorId) =>
      _safeSelect(_tDoctorSlots, eq: {'doctor_id': doctorId}, orderBy: const ['start_at'], ascending: true);

  Future<void> createDoctorSlot({required String doctorId, required DateTime startAt, required DateTime endAt}) async {
    try {
      await _db.from(_tDoctorSlots).insert({'doctor_id': doctorId, 'start_at': startAt.toIso8601String(), 'end_at': endAt.toIso8601String()});
    } catch (e, st) {
      debugPrint('HealthService: createDoctorSlot failed err=$e');
      debugPrint(st.toString());
      rethrow;
    }
  }

  // ============================================================
  // DOCTOR DASHBOARD HELPERS
  // ============================================================

  Future<List<Appointment>> fetchDoctorAppointmentsForDay(String doctorId, DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    try {
      dynamic q = _db.from(_tAppointments).select('*').eq('doctor_id', doctorId);
      q = q.gte('scheduled_at', start.toIso8601String());
      q = q.lt('scheduled_at', end.toIso8601String());
      q = q.order('scheduled_at', ascending: true);
      final res = await q;
      final rows = (res is List)
          ? res.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList()
          : const <Map<String, dynamic>>[];
      return rows.map((m) {
        final typeName = _s(m, 'type', AppointmentType.inPerson.name);
        final statusName = _s(m, 'status', AppointmentStatus.scheduled.name);
        return Appointment(
          id: _s(m, 'id'),
          doctorId: _s(m, 'doctor_id', doctorId),
          doctorName: _s(m, 'doctor_name', 'Médecin'),
          doctorSpecialty: (m['doctor_specialty'] as String?)?.trim(),
          patientId: (m['patient_id'] as String?)?.trim(),
          patientName: (m['patient_name'] as String?)?.trim(),
          date: _dt(m, 'scheduled_at'),
          type: AppointmentType.values.firstWhere((e) => e.name == typeName, orElse: () => AppointmentType.inPerson),
          status: AppointmentStatus.values.firstWhere((e) => e.name == statusName, orElse: () => AppointmentStatus.scheduled),
          notes: (m['notes'] as String?)?.trim(),
          teleconsultationLink: (m['teleconsultation_link'] as String?)?.trim(),
          isEmergency: (m['is_emergency'] as bool?) ?? false,
        );
      }).toList();
    } catch (e, st) {
      debugPrint('HealthService: fetchDoctorAppointmentsForDay failed err=$e');
      debugPrint(st.toString());
      return const [];
    }
  }

  Future<int> fetchDoctorDistinctPatientsCount(String doctorId) async {
    try {
      final rows = await _safeSelect(_tAppointments, columns: 'patient_id', eq: {'doctor_id': doctorId}, limit: 500);
      final ids = <String>{};
      for (final r in rows) {
        final pid = (r['patient_id'] as String?)?.trim();
        if (pid != null && pid.isNotEmpty) ids.add(pid);
      }
      return ids.length;
    } catch (e, st) {
      debugPrint('HealthService: fetchDoctorDistinctPatientsCount failed err=$e');
      debugPrint(st.toString());
      return 0;
    }
  }

  Future<int> fetchDoctorPendingTeleexpertiseCount(String doctorId) async {
    try {
      final rows = await _safeSelect(
        _tTeleexpertise,
        columns: 'id',
        eq: {'doctor_id': doctorId, 'status': 'pending'},
        limit: 200,
      );
      return rows.length;
    } catch (e, st) {
      debugPrint('HealthService: fetchDoctorPendingTeleexpertiseCount failed err=$e');
      debugPrint(st.toString());
      return 0;
    }
  }

  Future<int> fetchDoctorCriticalAlertsCount(String doctorId) async {
    try {
      final rows = await _safeSelect(
        _tHealthAlerts,
        columns: 'id',
        eq: {'doctor_id': doctorId, 'severity': 'critical'},
        limit: 200,
      );
      return rows.length;
    } catch (e, st) {
      debugPrint('HealthService: fetchDoctorCriticalAlertsCount failed err=$e');
      debugPrint(st.toString());
      return 0;
    }
  }

  // ============================================================
  // PHARMACY DASHBOARD HELPERS
  // ============================================================

  Future<Map<String, int>> fetchPharmacyDashboardStats(String pharmacyId) async {
    try {
      final pending = (await _safeSelect(_tPharmacyOrders, columns: 'id', eq: {'pharmacy_id': pharmacyId, 'status': 'pending'}, limit: 500)).length;
      final inProgress = (await _safeSelect(_tPharmacyOrders, columns: 'id', eq: {'pharmacy_id': pharmacyId, 'status': 'in_progress'}, limit: 500)).length;
      final criticalStock = (await _safeSelect(_tPharmacyInventory, columns: 'id', eq: {'pharmacy_id': pharmacyId, 'is_critical': true}, limit: 500)).length;

      final start = DateTime.now();
      final dayStart = DateTime(start.year, start.month, start.day);
      dynamic q = _db.from(_tPharmacyOrders).select('id').eq('pharmacy_id', pharmacyId).eq('status', 'out_for_delivery');
      q = q.gte('updated_at', dayStart.toIso8601String());
      final res = await q;
      final deliveriesToday = (res is List) ? res.length : 0;
      return {
        'pending': pending,
        'in_progress': inProgress,
        'critical_stock': criticalStock,
        'deliveries_today': deliveriesToday,
      };
    } catch (e, st) {
      debugPrint('HealthService: fetchPharmacyDashboardStats failed err=$e');
      debugPrint(st.toString());
      return const {'pending': 0, 'in_progress': 0, 'critical_stock': 0, 'deliveries_today': 0};
    }
  }

  Future<List<Map<String, dynamic>>> fetchPharmacyRecentOrders(String pharmacyId, {int limit = 5}) async {
    return _safeSelect(
      _tPharmacyOrders,
      columns: '*',
      eq: {'pharmacy_id': pharmacyId},
      limit: limit,
      orderBy: const ['created_at'],
      ascending: false,
    );
  }
}
