// presentation/thix_sante/shared/models/health_models.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ============================================================
// ÉNUMÉRATIONS GLOBALES
// ============================================================

enum AppointmentType { inPerson, teleconsultation, teleexpertise }

enum AppointmentStatus { scheduled, confirmed, completed, cancelled, missed }

enum PrescriptionStatus { active, expired, completed, cancelled }

enum ExamStatus { pending, completed, cancelled }

enum OrderStatus { pending, validated, prepared, delivered, cancelled }

enum AlertSeverity { info, warning, critical }

enum NotificationType { alert, appointment, medication, general }

// ============================================================
// 1. RÉSUMÉ DE SANTÉ (Dashboard)
// ============================================================

class HealthSummary {
  final int consultationsThisYear;
  final int examsCompleted;
  final int activeMedications;
  final int upcomingAppointments;
  final int healthScore; // 0-100
  final DateTime lastUpdate;
  final List<Appointment> upcomingAppointmentsList;
  final List<Medication> currentMedications;
  final List<HealthArticle> articles;

  HealthSummary({
    required this.consultationsThisYear,
    required this.examsCompleted,
    required this.activeMedications,
    required this.upcomingAppointments,
    required this.healthScore,
    required this.lastUpdate,
    this.upcomingAppointmentsList = const [],
    this.currentMedications = const [],
    this.articles = const [],
  });

  factory HealthSummary.empty() => HealthSummary(
        consultationsThisYear: 0,
        examsCompleted: 0,
        activeMedications: 0,
        upcomingAppointments: 0,
        healthScore: 0,
        lastUpdate: DateTime.now(),
      );
}

// ============================================================
// 2. RENDEZ-VOUS
// ============================================================

class Appointment {
  final String id;
  final String doctorId;
  final String doctorName;
  final String? doctorSpecialty;
  final String? patientId;
  final String? patientName;
  final DateTime date;
  final AppointmentType type;
  final AppointmentStatus status;
  final String? notes;
  final String? teleconsultationLink;
  final Duration? duration;
  final bool isEmergency;

  Appointment({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    this.doctorSpecialty,
    this.patientId,
    this.patientName,
    required this.date,
    required this.type,
    required this.status,
    this.notes,
    this.teleconsultationLink,
    this.duration,
    this.isEmergency = false,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String,
      doctorId: json['doctorId'] as String,
      doctorName: json['doctorName'] as String,
      doctorSpecialty: json['doctorSpecialty'] as String?,
      patientId: json['patientId'] as String?,
      patientName: json['patientName'] as String?,
      date: DateTime.parse(json['date'] as String),
      type: AppointmentType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => AppointmentType.inPerson),
      status: AppointmentStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => AppointmentStatus.scheduled),
      notes: json['notes'] as String?,
      teleconsultationLink: json['teleconsultationLink'] as String?,
      duration: json['duration'] != null
          ? Duration(minutes: json['duration'] as int)
          : null,
      isEmergency: json['isEmergency'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'doctorSpecialty': doctorSpecialty,
        'patientId': patientId,
        'patientName': patientName,
        'date': date.toIso8601String(),
        'type': type.name,
        'status': status.name,
        'notes': notes,
        'teleconsultationLink': teleconsultationLink,
        'duration': duration?.inMinutes,
        'isEmergency': isEmergency,
      };

  String get formattedDate =>
      '${date.day}/${date.month}/${date.year} à ${date.hour}h${date.minute.toString().padLeft(2, '0')}';

  String get relativeDate {
    final now = DateTime.now();
    final diff = date.difference(now);
    if (diff.inDays == 0) return "Aujourd'hui";
    if (diff.inDays == 1) return 'Demain';
    if (diff.inDays < 7) return 'Dans ${diff.inDays} jours';
    return formattedDate;
  }
}

// ============================================================
// 3. MÉDICAMENTS & RAPPELS
// ============================================================

class Medication {
  final String id;
  final String? patientId; // nullable pour les mock-ups
  final String name;
  final String dosage;
  final String frequency;
  final String? duration;
  final String? instructions;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final String? prescriptionId;
  final String? prescribedBy;
  final List<MedicationReminder> reminders;

  Medication({
    required this.id,
    this.patientId,
    required this.name,
    required this.dosage,
    required this.frequency,
    this.duration,
    this.instructions,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.prescriptionId,
    this.prescribedBy,
    this.reminders = const [],
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] as String,
      patientId: json['patientId'] as String?,
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      frequency: json['frequency'] as String,
      duration: json['duration'] as String?,
      instructions: json['instructions'] as String?,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      prescriptionId: json['prescriptionId'] as String?,
      prescribedBy: json['prescribedBy'] as String?,
      reminders: (json['reminders'] as List<dynamic>?)
              ?.map((e) => MedicationReminder.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'name': name,
        'dosage': dosage,
        'frequency': frequency,
        'duration': duration,
        'instructions': instructions,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'isActive': isActive,
        'prescriptionId': prescriptionId,
        'prescribedBy': prescribedBy,
        'reminders': reminders.map((e) => e.toJson()).toList(),
      };

  Medication copyWith({
    String? id,
    String? patientId,
    String? name,
    String? dosage,
    String? frequency,
    String? duration,
    String? instructions,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? prescriptionId,
    String? prescribedBy,
    List<MedicationReminder>? reminders,
  }) {
    return Medication(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
      instructions: instructions ?? this.instructions,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      prescribedBy: prescribedBy ?? this.prescribedBy,
      reminders: reminders ?? this.reminders,
    );
  }
}

class MedicationReminder {
  final String id;
  final String medicationId;
  final TimeOfDay time;
  final bool isEnabled;
  final List<int> daysOfWeek; // 0=Sunday, 6=Saturday

  MedicationReminder({
    required this.id,
    required this.medicationId,
    required this.time,
    this.isEnabled = true,
    this.daysOfWeek = const [0, 1, 2, 3, 4, 5, 6],
  });

  factory MedicationReminder.fromJson(Map<String, dynamic> json) {
    final timeParts = (json['time'] as String).split(':');
    return MedicationReminder(
      id: json['id'] as String,
      medicationId: json['medicationId'] as String,
      time: TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      ),
      isEnabled: json['isEnabled'] as bool? ?? true,
      daysOfWeek: (json['daysOfWeek'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          const [0, 1, 2, 3, 4, 5, 6],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'medicationId': medicationId,
        'time': '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
        'isEnabled': isEnabled,
        'daysOfWeek': daysOfWeek,
      };

  String get timeString =>
      '${time.hour}h${time.minute.toString().padLeft(2, '0')}';

  bool shouldRemindToday() => daysOfWeek.contains(DateTime.now().weekday % 7);
}

// ============================================================
// 4. SYMPTÔMES
// ============================================================

class Symptom {
  final String id;
  final String name;
  final int intensity; // 1-5
  final DateTime date;
  final String? notes;
  final List<String>? triggers;
  final List<String>? relievers;
  final String? location;
  final Duration? duration;

  Symptom({
    required this.id,
    required this.name,
    required this.intensity,
    required this.date,
    this.notes,
    this.triggers,
    this.relievers,
    this.location,
    this.duration,
  });

  factory Symptom.fromJson(Map<String, dynamic> json) {
    return Symptom(
      id: json['id'] as String,
      name: json['name'] as String,
      intensity: json['intensity'] as int,
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String?,
      triggers: (json['triggers'] as List<dynamic>?)?.cast<String>(),
      relievers: (json['relievers'] as List<dynamic>?)?.cast<String>(),
      location: json['location'] as String?,
      duration: json['duration'] != null
          ? Duration(minutes: json['duration'] as int)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'intensity': intensity,
        'date': date.toIso8601String(),
        'notes': notes,
        'triggers': triggers,
        'relievers': relievers,
        'location': location,
        'duration': duration?.inMinutes,
      };

  Color get intensityColor {
    switch (intensity) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.deepOrange;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// ============================================================
// 5. CONSTANTES VITALES
// ============================================================

enum VitalType {
  bloodPressureSystolic,
  bloodPressureDiastolic,
  heartRate,
  temperature,
  weight,
  height,
  bmi,
  glucose,
  oxygenSaturation,
  respiratoryRate,
}

class VitalSign {
  final String id;
  final String patientId;
  final VitalType type;
  final double value;
  final String? unit;
  final DateTime date;
  final String? notes;
  final String? deviceUsed;

  VitalSign({
    required this.id,
    required this.patientId,
    required this.type,
    required this.value,
    this.unit,
    required this.date,
    this.notes,
    this.deviceUsed,
  });

  factory VitalSign.fromJson(Map<String, dynamic> json) {
    return VitalSign(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      type: VitalType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => VitalType.heartRate),
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String?,
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String?,
      deviceUsed: json['deviceUsed'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'type': type.name,
        'value': value,
        'unit': unit,
        'date': date.toIso8601String(),
        'notes': notes,
        'deviceUsed': deviceUsed,
      };

  String get displayValue => '$value${unit ?? ''}';

  VitalSign copyWith({
    String? id,
    String? patientId,
    VitalType? type,
    double? value,
    String? unit,
    DateTime? date,
    String? notes,
    String? deviceUsed,
  }) {
    return VitalSign(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      type: type ?? this.type,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      deviceUsed: deviceUsed ?? this.deviceUsed,
    );
  }

  static String getVitalLabel(VitalType type) {
    switch (type) {
      case VitalType.bloodPressureSystolic:
        return 'Tension systolique';
      case VitalType.bloodPressureDiastolic:
        return 'Tension diastolique';
      case VitalType.heartRate:
        return 'Fréquence cardiaque';
      case VitalType.temperature:
        return 'Température';
      case VitalType.weight:
        return 'Poids';
      case VitalType.height:
        return 'Taille';
      case VitalType.bmi:
        return 'IMC';
      case VitalType.glucose:
        return 'Glycémie';
      case VitalType.oxygenSaturation:
        return 'Saturation O2';
      case VitalType.respiratoryRate:
        return 'Fréquence respiratoire';
    }
  }

  static IconData getVitalIcon(VitalType type) {
    switch (type) {
      case VitalType.bloodPressureSystolic:
      case VitalType.bloodPressureDiastolic:
        return Icons.monitor_heart;
      case VitalType.heartRate:
        return Icons.favorite;
      case VitalType.temperature:
        return Icons.thermostat;
      case VitalType.weight:
        return Icons.fitness_center;
      case VitalType.height:
        return Icons.height;
      case VitalType.bmi:
        return Icons.calculate;
      case VitalType.glucose:
        return Icons.bloodtype;
      case VitalType.oxygenSaturation:
        return Icons.air;
      case VitalType.respiratoryRate:
        return Icons.air;
    }
  }
}

// ============================================================
// 6. ORDONNANCES
// ============================================================

class Prescription {
  final String id;
  final String patientId;
  final String? patientName;
  final String doctorId;
  final String doctorName;
  final DateTime date;
  final DateTime? validUntil;
  final PrescriptionStatus status;
  final List<Medication> medications;
  final String? notes;

  Prescription({
    required this.id,
    required this.patientId,
    this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.date,
    this.validUntil,
    required this.status,
    this.medications = const [],
    this.notes,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      patientName: json['patientName'] as String?,
      doctorId: json['doctorId'] as String,
      doctorName: json['doctorName'] as String,
      date: DateTime.parse(json['date'] as String),
      validUntil: json['validUntil'] != null
          ? DateTime.parse(json['validUntil'] as String)
          : null,
      status: PrescriptionStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => PrescriptionStatus.active),
      medications: (json['medications'] as List<dynamic>?)
              ?.map((e) => Medication.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'patientName': patientName,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'date': date.toIso8601String(),
        'validUntil': validUntil?.toIso8601String(),
        'status': status.name,
        'medications': medications.map((e) => e.toJson()).toList(),
        'notes': notes,
      };

  bool get isExpired => validUntil != null && validUntil!.isBefore(DateTime.now());

  Prescription copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? doctorId,
    String? doctorName,
    DateTime? date,
    DateTime? validUntil,
    PrescriptionStatus? status,
    List<Medication>? medications,
    String? notes,
  }) {
    return Prescription(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      date: date ?? this.date,
      validUntil: validUntil ?? this.validUntil,
      status: status ?? this.status,
      medications: medications ?? this.medications,
      notes: notes ?? this.notes,
    );
  }
}

// ============================================================
// 7. EXAMENS
// ============================================================

class ExamResult {
  final String id;
  final String patientId;
  final String examName;
  final DateTime date;
  final String? result;
  final ExamStatus status;
  final String? comments;
  final String? pdfUrl;
  final String? imageUrl;

  ExamResult({
    required this.id,
    required this.patientId,
    required this.examName,
    required this.date,
    this.result,
    required this.status,
    this.comments,
    this.pdfUrl,
    this.imageUrl,
  });

  factory ExamResult.fromJson(Map<String, dynamic> json) {
    return ExamResult(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      examName: json['examName'] as String,
      date: DateTime.parse(json['date'] as String),
      result: json['result'] as String?,
      status: ExamStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => ExamStatus.pending),
      comments: json['comments'] as String?,
      pdfUrl: json['pdfUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'examName': examName,
        'date': date.toIso8601String(),
        'result': result,
        'status': status.name,
        'comments': comments,
        'pdfUrl': pdfUrl,
        'imageUrl': imageUrl,
      };
}

// ============================================================
// 8. VACCINS
// ============================================================

class Vaccine {
  final String id;
  final String patientId;
  final String name;
  final DateTime dateAdministered;
  final DateTime? boosterDate;
  final String? batchNumber;
  final String? administeredBy;

  Vaccine({
    required this.id,
    required this.patientId,
    required this.name,
    required this.dateAdministered,
    this.boosterDate,
    this.batchNumber,
    this.administeredBy,
  });

  factory Vaccine.fromJson(Map<String, dynamic> json) {
    return Vaccine(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      name: json['name'] as String,
      dateAdministered: DateTime.parse(json['dateAdministered'] as String),
      boosterDate: json['boosterDate'] != null
          ? DateTime.parse(json['boosterDate'] as String)
          : null,
      batchNumber: json['batchNumber'] as String?,
      administeredBy: json['administeredBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'name': name,
        'dateAdministered': dateAdministered.toIso8601String(),
        'boosterDate': boosterDate?.toIso8601String(),
        'batchNumber': batchNumber,
        'administeredBy': administeredBy,
      };

  bool get isBoosterDue {
    if (boosterDate == null) return false;
    return boosterDate!.isBefore(DateTime.now());
  }

  Vaccine copyWith({
    String? id,
    String? patientId,
    String? name,
    DateTime? dateAdministered,
    DateTime? boosterDate,
    String? batchNumber,
    String? administeredBy,
  }) {
    return Vaccine(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      name: name ?? this.name,
      dateAdministered: dateAdministered ?? this.dateAdministered,
      boosterDate: boosterDate ?? this.boosterDate,
      batchNumber: batchNumber ?? this.batchNumber,
      administeredBy: administeredBy ?? this.administeredBy,
    );
  }
}

// ============================================================
// 9. GROSSESSE
// ============================================================

class Pregnancy {
  final String id;
  final String patientId;
  final DateTime conceptionDate;
  final DateTime? dueDate;
  final int? weekOfPregnancy;
  final double? weightGain;
  final List<String>? symptoms;
  final String? notes;

  Pregnancy({
    required this.id,
    required this.patientId,
    required this.conceptionDate,
    this.dueDate,
    this.weekOfPregnancy,
    this.weightGain,
    this.symptoms,
    this.notes,
  });

  factory Pregnancy.fromJson(Map<String, dynamic> json) {
    return Pregnancy(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      conceptionDate: DateTime.parse(json['conceptionDate'] as String),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      weekOfPregnancy: json['weekOfPregnancy'] as int?,
      weightGain: (json['weightGain'] as num?)?.toDouble(),
      symptoms: (json['symptoms'] as List<dynamic>?)?.cast<String>(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'conceptionDate': conceptionDate.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'weekOfPregnancy': weekOfPregnancy,
        'weightGain': weightGain,
        'symptoms': symptoms,
        'notes': notes,
      };

  int get weeksElapsed {
    return DateTime.now().difference(conceptionDate).inDays ~/ 7;
  }
}

// ============================================================
// 10. MEMBRE DE LA FAMILLE
// ============================================================

class FamilyMember {
  final String id;
  final String patientId;
  final String firstName;
  final String lastName;
  final String relationship;
  final DateTime? dateOfBirth;
  final String? healthNotes;
  final bool shareAccess;

  FamilyMember({
    required this.id,
    required this.patientId,
    required this.firstName,
    required this.lastName,
    required this.relationship,
    this.dateOfBirth,
    this.healthNotes,
    this.shareAccess = false,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      relationship: json['relationship'] as String,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'] as String)
          : null,
      healthNotes: json['healthNotes'] as String?,
      shareAccess: json['shareAccess'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'firstName': firstName,
        'lastName': lastName,
        'relationship': relationship,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'healthNotes': healthNotes,
        'shareAccess': shareAccess,
      };

  String get fullName => '$firstName $lastName';
}

// ============================================================
// 11. ALERTES SANITAIRES
// ============================================================

class HealthAlert {
  final String id;
  final String title;
  final String description;
  final AlertSeverity severity;
  final DateTime date;
  final bool isRead;
  final String? actionUrl;
  final String? source;

  HealthAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.date,
    this.isRead = false,
    this.actionUrl,
    this.source,
  });

  factory HealthAlert.fromJson(Map<String, dynamic> json) {
    return HealthAlert(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      severity: AlertSeverity.values.firstWhere(
          (e) => e.name == json['severity'],
          orElse: () => AlertSeverity.info),
      date: DateTime.parse(json['date'] as String),
      isRead: json['isRead'] as bool? ?? false,
      actionUrl: json['actionUrl'] as String?,
      source: json['source'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'severity': severity.name,
        'date': date.toIso8601String(),
        'isRead': isRead,
        'actionUrl': actionUrl,
        'source': source,
      };

  Color get severityColor {
    switch (severity) {
      case AlertSeverity.info:
        return Colors.blue;
      case AlertSeverity.warning:
        return Colors.orange;
      case AlertSeverity.critical:
        return Colors.red;
    }
  }

  IconData get severityIcon {
    switch (severity) {
      case AlertSeverity.info:
        return Icons.info_outline;
      case AlertSeverity.warning:
        return Icons.warning_amber_outlined;
      case AlertSeverity.critical:
        return Icons.crisis_alert;
    }
  }
}

// ============================================================
// 12. ARTICLES DE SANTÉ
// ============================================================

class HealthArticle {
  final String id;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final int readTime; // minutes
  final String? author;
  final DateTime publishDate;
  final List<String> tags;
  final String content;

  HealthArticle({
    required this.id,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.readTime,
    this.author,
    required this.publishDate,
    this.tags = const [],
    required this.content,
  });

  factory HealthArticle.fromJson(Map<String, dynamic> json) {
    return HealthArticle(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      imageUrl: json['imageUrl'] as String?,
      readTime: json['readTime'] as int,
      author: json['author'] as String?,
      publishDate: DateTime.parse(json['publishDate'] as String),
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      content: json['content'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'imageUrl': imageUrl,
        'readTime': readTime,
        'author': author,
        'publishDate': publishDate.toIso8601String(),
        'tags': tags,
        'content': content,
      };
}

// ============================================================
// 13. CONSENTEMENTS
// ============================================================

class Consent {
  final String id;
  final String patientId;
  final String type; // ex: "data_sharing", "marketing"
  final bool granted;
  final DateTime date;
  final DateTime? expiryDate;

  Consent({
    required this.id,
    required this.patientId,
    required this.type,
    required this.granted,
    required this.date,
    this.expiryDate,
  });

  factory Consent.fromJson(Map<String, dynamic> json) {
    return Consent(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      type: json['type'] as String,
      granted: json['granted'] as bool,
      date: DateTime.parse(json['date'] as String),
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'type': type,
        'granted': granted,
        'date': date.toIso8601String(),
        'expiryDate': expiryDate?.toIso8601String(),
      };

  bool get isExpired => expiryDate != null && expiryDate!.isBefore(DateTime.now());

  Consent copyWith({
    String? id,
    String? patientId,
    String? type,
    bool? granted,
    DateTime? date,
    DateTime? expiryDate,
  }) {
    return Consent(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      type: type ?? this.type,
      granted: granted ?? this.granted,
      date: date ?? this.date,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }
}

// ============================================================
// 14. MÉDECIN (profil simplifié)
// ============================================================

class Doctor {
  final String id;
  final String firstName;
  final String lastName;
  final String specialty;
  final String? phone;
  final String? email;
  final String? address;
  final double? rating;
  final String? photoUrl;

  Doctor({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.specialty,
    this.phone,
    this.email,
    this.address,
    this.rating,
    this.photoUrl,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      specialty: json['specialty'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      photoUrl: json['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'specialty': specialty,
        'phone': phone,
        'email': email,
        'address': address,
        'rating': rating,
        'photoUrl': photoUrl,
      };

  String get fullName => '$firstName $lastName';
}

// ============================================================
// 15. PHARMACIE (profil simplifié)
// ============================================================

class Pharmacy {
  final String id;
  final String name;
  final String address;
  final String? phone;
  final String? email;
  final double? latitude;
  final double? longitude;
  final bool isOpen;

  Pharmacy({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    this.email,
    this.latitude,
    this.longitude,
    this.isOpen = false,
  });

  factory Pharmacy.fromJson(Map<String, dynamic> json) {
    return Pharmacy(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isOpen: json['isOpen'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'phone': phone,
        'email': email,
        'latitude': latitude,
        'longitude': longitude,
        'isOpen': isOpen,
      };
}

// ============================================================
// 16. COMMANDES (PHARMACIE)
// ============================================================

class Order {
  final String id;
  final String pharmacyId;
  final String? patientId;
  final String? patientName;
  final List<OrderItem> items;
  final OrderStatus status;
  final DateTime orderDate;
  final DateTime? deliveryDate;
  final double totalAmount;
  final String? notes;

  Order({
    required this.id,
    required this.pharmacyId,
    this.patientId,
    this.patientName,
    required this.items,
    required this.status,
    required this.orderDate,
    this.deliveryDate,
    required this.totalAmount,
    this.notes,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      pharmacyId: json['pharmacyId'] as String,
      patientId: json['patientId'] as String?,
      patientName: json['patientName'] as String?,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      status: OrderStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => OrderStatus.pending),
      orderDate: DateTime.parse(json['orderDate'] as String),
      deliveryDate: json['deliveryDate'] != null
          ? DateTime.parse(json['deliveryDate'] as String)
          : null,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pharmacyId': pharmacyId,
        'patientId': patientId,
        'patientName': patientName,
        'items': items.map((e) => e.toJson()).toList(),
        'status': status.name,
        'orderDate': orderDate.toIso8601String(),
        'deliveryDate': deliveryDate?.toIso8601String(),
        'totalAmount': totalAmount,
        'notes': notes,
      };
}

class OrderItem {
  final String id;
  final String productName;
  final int quantity;
  final double unitPrice;
  final String? dosage;

  OrderItem({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.dosage,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      productName: json['productName'] as String,
      quantity: json['quantity'] as int,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      dosage: json['dosage'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'productName': productName,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'dosage': dosage,
      };

  double get totalPrice => quantity * unitPrice;
}

// ============================================================
// 17. INVENTAIRE (PHARMACIE)
// ============================================================

class InventoryItem {
  final String id;
  final String pharmacyId;
  final String productName;
  final String? dosage;
  final int quantity;
  final int threshold; // seuil d'alerte
  final String? batchNumber;
  final DateTime? expiryDate;
  final double unitPrice;

  InventoryItem({
    required this.id,
    required this.pharmacyId,
    required this.productName,
    this.dosage,
    required this.quantity,
    required this.threshold,
    this.batchNumber,
    this.expiryDate,
    required this.unitPrice,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as String,
      pharmacyId: json['pharmacyId'] as String,
      productName: json['productName'] as String,
      dosage: json['dosage'] as String?,
      quantity: json['quantity'] as int,
      threshold: json['threshold'] as int,
      batchNumber: json['batchNumber'] as String?,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
      unitPrice: (json['unitPrice'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pharmacyId': pharmacyId,
        'productName': productName,
        'dosage': dosage,
        'quantity': quantity,
        'threshold': threshold,
        'batchNumber': batchNumber,
        'expiryDate': expiryDate?.toIso8601String(),
        'unitPrice': unitPrice,
      };

  bool get isLowStock => quantity <= threshold;
  bool get isExpired => expiryDate != null && expiryDate!.isBefore(DateTime.now());
}

// ============================================================
// 18. NOUVEAUX MODÈLES AJOUTÉS
// ============================================================

/// Modèle pour une offre d'assurance (utilisé dans patient_insurance_page)
class InsuranceOffer {
  final String id;
  final String title;
  final String description;
  final String coverage;
  final double monthlyPrice;
  final double annualPrice;
  final List<String> benefits;
  final bool isPopular;

  InsuranceOffer({
    required this.id,
    required this.title,
    required this.description,
    required this.coverage,
    required this.monthlyPrice,
    required this.annualPrice,
    this.benefits = const [],
    this.isPopular = false,
  });

  factory InsuranceOffer.fromJson(Map<String, dynamic> json) {
    return InsuranceOffer(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      coverage: json['coverage'] as String,
      monthlyPrice: (json['monthly_price'] as num).toDouble(),
      annualPrice: (json['annual_price'] as num).toDouble(),
      benefits: (json['benefits'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isPopular: json['is_popular'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'coverage': coverage,
        'monthly_price': monthlyPrice,
        'annual_price': annualPrice,
        'benefits': benefits,
        'is_popular': isPopular,
      };
}

/// Modèle pour un programme bien-être (utilisé dans patient_wellness_page)
class WellnessProgram {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String? imageUrl;
  final int totalSteps;
  final int completedSteps;
  final String category; // 'stress', 'nutrition', 'fitness', 'stop_smoking'
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;

  WellnessProgram({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    this.imageUrl,
    required this.totalSteps,
    required this.completedSteps,
    required this.category,
    required this.startDate,
    this.endDate,
    this.isActive = true,
  });

  factory WellnessProgram.fromJson(Map<String, dynamic> json) {
    return WellnessProgram(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      description: json['description'] as String,
      imageUrl: json['image_url'] as String?,
      totalSteps: json['total_steps'] as int,
      completedSteps: json['completed_steps'] as int,
      category: json['category'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'description': description,
        'image_url': imageUrl,
        'total_steps': totalSteps,
        'completed_steps': completedSteps,
        'category': category,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'is_active': isActive,
      };

  double get progress => totalSteps > 0 ? completedSteps / totalSteps : 0;
  String get progressLabel => '${(progress * 100).toInt()}%';
}

/// Modèle pour un partage de dossier sécurisé (utilisé dans patient_sharing_page)
class Share {
  final String id;
  final String patientId;
  final String recipientName;
  final String recipientEmail;
  final String accessLevel; // 'complet' ou 'limite'
  final DateTime expiresAt;
  final DateTime createdAt;

  Share({
    required this.id,
    required this.patientId,
    required this.recipientName,
    required this.recipientEmail,
    required this.accessLevel,
    required this.expiresAt,
    required this.createdAt,
  });

  factory Share.fromJson(Map<String, dynamic> json) {
    return Share(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      recipientName: json['recipient_name'] as String,
      recipientEmail: json['recipient_email'] as String,
      accessLevel: json['access_level'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'recipient_name': recipientName,
        'recipient_email': recipientEmail,
        'access_level': accessLevel,
        'expires_at': expiresAt.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  bool get isExpired => expiresAt.isBefore(DateTime.now());
}

/// Modèle pour une notification (utilisé dans patient_notifications_page)
class NotificationItem {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime date;
  final bool isRead;
  final String? action;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.date,
    this.isRead = false,
    this.action,
  });

  factory NotificationItem.fromHealthAlert(HealthAlert alert) {
    return NotificationItem(
      id: alert.id,
      title: alert.title,
      body: alert.description,
      type: NotificationType.alert,
      date: alert.date,
      isRead: alert.isRead,
      action: alert.actionUrl,
    );
  }

  NotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? date,
    bool? isRead,
    String? action,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      date: date ?? this.date,
      isRead: isRead ?? this.isRead,
      action: action ?? this.action,
    );
  }
}
