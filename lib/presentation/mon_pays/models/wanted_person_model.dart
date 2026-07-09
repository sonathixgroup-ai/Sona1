// lib/presentation/mon_pays/models/wanted_person_model.dart

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'wanted_person_model.g.dart';

/// Type de recherche
enum WantedType {
  @JsonValue('dangerous')
  dangerous,
  @JsonValue('missing')
  missing,
}

/// Modèle représentant une personne recherchée
@JsonSerializable()
class WantedPerson extends Equatable {
  final String id;
  final String name;
  final String? alias;
  final WantedType type;
  final String reason;
  final String province;
  final String date; // format "25 Mai 2025"
  final int alertLevel; // 1 à 5
  final String? photoUrl;

  const WantedPerson({
    required this.id,
    required this.name,
    this.alias,
    required this.type,
    required this.reason,
    required this.province,
    required this.date,
    required this.alertLevel,
    this.photoUrl,
  });

  WantedPerson copyWith({
    String? id,
    String? name,
    String? alias,
    WantedType? type,
    String? reason,
    String? province,
    String? date,
    int? alertLevel,
    String? photoUrl,
  }) {
    return WantedPerson(
      id: id ?? this.id,
      name: name ?? this.name,
      alias: alias ?? this.alias,
      type: type ?? this.type,
      reason: reason ?? this.reason,
      province: province ?? this.province,
      date: date ?? this.date,
      alertLevel: alertLevel ?? this.alertLevel,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  factory WantedPerson.fromJson(Map<String, dynamic> json) =>
      _$WantedPersonFromJson(json);

  Map<String, dynamic> toJson() => _$WantedPersonToJson(this);

  @override
  List<Object?> get props => [
        id,
        name,
        alias,
        type,
        reason,
        province,
        date,
        alertLevel,
        photoUrl,
      ];
}
