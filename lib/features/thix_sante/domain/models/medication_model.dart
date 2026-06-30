import 'package:equatable/equatable.dart';
import 'package:thix_id/features/thix_sante/domain/models/thix_datetime.dart';

class MedicationModel extends Equatable {
  final String id;
  final String userId;
  final String patientId;
  final String name;
  final String? dosage;
  final String? frequency;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MedicationModel({
    required this.id,
    required this.userId,
    required this.patientId,
    required this.name,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.dosage,
    this.frequency,
    this.startsAt,
    this.endsAt,
    this.notes,
  });

  MedicationModel copyWith({
    String? id,
    String? userId,
    String? patientId,
    String? name,
    String? dosage,
    String? frequency,
    DateTime? startsAt,
    DateTime? endsAt,
    bool? isActive,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      patientId: patientId ?? this.patientId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory MedicationModel.fromJson(Map<String, dynamic> json) {
    return MedicationModel(
      id: (json['id'] ?? '') as String,
      userId: (json['user_id'] ?? '') as String,
      patientId: (json['patient_id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      dosage: json['dosage'] as String?,
      frequency: json['frequency'] as String?,
      startsAt: parseDateTime(json['starts_at']),
      endsAt: parseDateTime(json['ends_at']),
      isActive: (json['is_active'] ?? false) as bool,
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
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'starts_at': toIsoString(startsAt),
      'ends_at': toIsoString(endsAt),
      'is_active': isActive,
      'notes': notes,
      'created_at': toIsoString(createdAt),
      'updated_at': toIsoString(updatedAt),
    };
  }

  @override
  List<Object?> get props => [id, userId, patientId, name, dosage, frequency, startsAt, endsAt, isActive, notes, createdAt, updatedAt];
}
