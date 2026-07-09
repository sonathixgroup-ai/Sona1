// models/wanted_person_model.dart

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import '../enums/wanted_status.dart';

part 'wanted_person_model.g.dart';

@JsonSerializable()
class WantedPerson extends Equatable {
  final String id;
  final String name;
  final String? alias;
  final WantedStatus status;
  final String reason;
  final String province;
  final String date;
  final int alertLevel; // 1-5
  final String? photoUrl;
  final String? description;

  const WantedPerson({
    required this.id,
    required this.name,
    this.alias,
    required this.status,
    required this.reason,
    required this.province,
    required this.date,
    required this.alertLevel,
    this.photoUrl,
    this.description,
  });

  WantedPerson copyWith({
    String? id,
    String? name,
    String? alias,
    WantedStatus? status,
    String? reason,
    String? province,
    String? date,
    int? alertLevel,
    String? photoUrl,
    String? description,
  }) {
    return WantedPerson(
      id: id ?? this.id,
      name: name ?? this.name,
      alias: alias ?? this.alias,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      province: province ?? this.province,
      date: date ?? this.date,
      alertLevel: alertLevel ?? this.alertLevel,
      photoUrl: photoUrl ?? this.photoUrl,
      description: description ?? this.description,
    );
  }

  factory WantedPerson.fromJson(Map<String, dynamic> json) => _$WantedPersonFromJson(json);
  Map<String, dynamic> toJson() => _$WantedPersonToJson(this);

  @override
  List<Object?> get props => [id, name, alias, status, reason, province, date, alertLevel, photoUrl, description];
}
