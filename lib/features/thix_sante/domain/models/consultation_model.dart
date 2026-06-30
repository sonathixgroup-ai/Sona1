import 'package:equatable/equatable.dart';
import 'package:thix_id/features/thix_sante/domain/models/thix_datetime.dart';

class ConsultationModel extends Equatable {
  final String id;
  final String userId;
  final String patientId;
  final DateTime occurredAt;
  final String? specialty;
  final String? doctorName;
  final String? diagnosis;
  final String? doctorNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ConsultationModel({
    required this.id,
    required this.userId,
    required this.patientId,
    required this.occurredAt,
    required this.createdAt,
    required this.updatedAt,
    this.specialty,
    this.doctorName,
    this.diagnosis,
    this.doctorNotes,
  });

  ConsultationModel copyWith({
    String? id,
    String? userId,
    String? patientId,
    DateTime? occurredAt,
    String? specialty,
    String? doctorName,
    String? diagnosis,
    String? doctorNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConsultationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      patientId: patientId ?? this.patientId,
      occurredAt: occurredAt ?? this.occurredAt,
      specialty: specialty ?? this.specialty,
      doctorName: doctorName ?? this.doctorName,
      diagnosis: diagnosis ?? this.diagnosis,
      doctorNotes: doctorNotes ?? this.doctorNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ConsultationModel.fromJson(Map<String, dynamic> json) {
    return ConsultationModel(
      id: (json['id'] ?? '') as String,
      userId: (json['user_id'] ?? '') as String,
      patientId: (json['patient_id'] ?? '') as String,
      occurredAt: parseDateTime(json['occurred_at']) ?? DateTime.now().toUtc(),
      specialty: json['specialty'] as String?,
      doctorName: json['doctor_name'] as String?,
      diagnosis: json['diagnosis'] as String?,
      doctorNotes: json['doctor_notes'] as String?,
      createdAt: parseDateTime(json['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt: parseDateTime(json['updated_at']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'patient_id': patientId,
      'occurred_at': toIsoString(occurredAt),
      'specialty': specialty,
      'doctor_name': doctorName,
      'diagnosis': diagnosis,
      'doctor_notes': doctorNotes,
      'created_at': toIsoString(createdAt),
      'updated_at': toIsoString(updatedAt),
    };
  }

  @override
  List<Object?> get props => [id, userId, patientId, occurredAt, specialty, doctorName, diagnosis, doctorNotes, createdAt, updatedAt];
}
