// models/consultation_model.dart

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'consultation_model.g.dart';

@JsonSerializable()
class Consultation extends Equatable {
  final String id;
  final String title;
  final String description;
  final String startDate;
  final String endDate;
  final bool isActive;
  final String? link;
  final int? participants;

  const Consultation({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    this.link,
    this.participants,
  });

  Consultation copyWith({
    String? id,
    String? title,
    String? description,
    String? startDate,
    String? endDate,
    bool? isActive,
    String? link,
    int? participants,
  }) {
    return Consultation(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      link: link ?? this.link,
      participants: participants ?? this.participants,
    );
  }

  factory Consultation.fromJson(Map<String, dynamic> json) => _$ConsultationFromJson(json);
  Map<String, dynamic> toJson() => _$ConsultationToJson(this);

  @override
  List<Object?> get props => [id, title, description, startDate, endDate, isActive, link, participants];
}
