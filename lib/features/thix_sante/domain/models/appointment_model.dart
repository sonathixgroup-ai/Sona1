import 'package:equatable/equatable.dart';
import 'package:thix_id/features/thix_sante/domain/models/thix_datetime.dart';

enum AppointmentStatus { pending, confirmed, cancelled, completed }

AppointmentStatus appointmentStatusFromString(String? value) {
  switch ((value ?? '').toLowerCase()) {
    case 'confirmed':
      return AppointmentStatus.confirmed;
    case 'cancelled':
      return AppointmentStatus.cancelled;
    case 'completed':
      return AppointmentStatus.completed;
    case 'pending':
    default:
      return AppointmentStatus.pending;
  }
}

String appointmentStatusToString(AppointmentStatus value) => value.name;

class AppointmentModel extends Equatable {
  final String id;
  final String userId;
  final String patientId;
  final DateTime scheduledAt;
  final String? doctorName;
  final String? specialty;
  final String? location;
  final AppointmentStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppointmentModel({
    required this.id,
    required this.userId,
    required this.patientId,
    required this.scheduledAt,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.doctorName,
    this.specialty,
    this.location,
    this.notes,
  });

  AppointmentModel copyWith({
    String? id,
    String? userId,
    String? patientId,
    DateTime? scheduledAt,
    String? doctorName,
    String? specialty,
    String? location,
    AppointmentStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      patientId: patientId ?? this.patientId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      doctorName: doctorName ?? this.doctorName,
      specialty: specialty ?? this.specialty,
      location: location ?? this.location,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: (json['id'] ?? '') as String,
      userId: (json['user_id'] ?? '') as String,
      patientId: (json['patient_id'] ?? '') as String,
      scheduledAt: parseDateTime(json['scheduled_at']) ?? DateTime.now().toUtc(),
      doctorName: json['doctor_name'] as String?,
      specialty: json['specialty'] as String?,
      location: json['location'] as String?,
      status: appointmentStatusFromString(json['status'] as String?),
      notes: json['notes'] as String?,
      createdAt: parseDateTime(json['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt: parseDateTime(json['updated_at']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'patient_id': patientId,
      'scheduled_at': toIsoString(scheduledAt),
      'doctor_name': doctorName,
      'specialty': specialty,
      'location': location,
      'status': appointmentStatusToString(status),
      'notes': notes,
      'created_at': toIsoString(createdAt),
      'updated_at': toIsoString(updatedAt),
    };
  }

  @override
  List<Object?> get props => [id, userId, patientId, scheduledAt, doctorName, specialty, location, status, notes, createdAt, updatedAt];
}
