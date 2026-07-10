// lib/presentation/mon_pays/models/consultation_model.dart
part 'consultation_model.g.dart';  // 👈 LA LIGNE MANQUANTE

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class Consultation extends Equatable {
  final String id;
  final String title;
  final String? description;
  final DateTime? date;
  final String? status; // exemple: 'pending', 'ongoing', 'completed'
  final String? createdBy;
  final List<String>? participants;

  const Consultation({
    required this.id,
    required this.title,
    this.description,
    this.date,
    this.status,
    this.createdBy,
    this.participants,
  });

  Consultation copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    String? status,
    String? createdBy,
    List<String>? participants,
  }) {
    return Consultation(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      participants: participants ?? this.participants,
    );
  }

  factory Consultation.fromJson(Map<String, dynamic> json) =>
      _$ConsultationFromJson(json);  // ✅ Maintenant défini

  Map<String, dynamic> toJson() => _$ConsultationToJson(this);  // ✅ Maintenant défini

  @override
  List<Object?> get props => [id, title, description, date, status, createdBy, participants];
}
