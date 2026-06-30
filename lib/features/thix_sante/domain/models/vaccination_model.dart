import 'package:equatable/equatable.dart';
import 'package:thix_id/features/thix_sante/domain/models/thix_datetime.dart';

class VaccinationModel extends Equatable {
  final String id;
  final String userId;
  final String patientId;
  final String vaccineName;
  final DateTime administeredAt;
  final DateTime? nextDoseAt;
  final String? certificatePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VaccinationModel({
    required this.id,
    required this.userId,
    required this.patientId,
    required this.vaccineName,
    required this.administeredAt,
    required this.createdAt,
    required this.updatedAt,
    this.nextDoseAt,
    this.certificatePath,
  });

  VaccinationModel copyWith({
    String? id,
    String? userId,
    String? patientId,
    String? vaccineName,
    DateTime? administeredAt,
    DateTime? nextDoseAt,
    String? certificatePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VaccinationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      patientId: patientId ?? this.patientId,
      vaccineName: vaccineName ?? this.vaccineName,
      administeredAt: administeredAt ?? this.administeredAt,
      nextDoseAt: nextDoseAt ?? this.nextDoseAt,
      certificatePath: certificatePath ?? this.certificatePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory VaccinationModel.fromJson(Map<String, dynamic> json) {
    return VaccinationModel(
      id: (json['id'] ?? '') as String,
      userId: (json['user_id'] ?? '') as String,
      patientId: (json['patient_id'] ?? '') as String,
      vaccineName: (json['vaccine_name'] ?? '') as String,
      administeredAt: parseDateTime(json['administered_at']) ?? DateTime.now().toUtc(),
      nextDoseAt: parseDateTime(json['next_dose_at']),
      certificatePath: json['certificate_path'] as String?,
      createdAt: parseDateTime(json['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt: parseDateTime(json['updated_at']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'patient_id': patientId,
      'vaccine_name': vaccineName,
      'administered_at': toIsoString(administeredAt),
      'next_dose_at': toIsoString(nextDoseAt),
      'certificate_path': certificatePath,
      'created_at': toIsoString(createdAt),
      'updated_at': toIsoString(updatedAt),
    };
  }

  @override
  List<Object?> get props => [id, userId, patientId, vaccineName, administeredAt, nextDoseAt, certificatePath, createdAt, updatedAt];
}
