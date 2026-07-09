// lib/presentation/mon_pays/models/exemplary_citizen_model.dart

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'exemplary_citizen_model.g.dart';

/// Modèle représentant un citoyen exemplaire
@JsonSerializable()
class ExemplaryCitizen extends Equatable {
  final String id;
  final String name;
  final String occupation;
  final String? quote;
  final String? photoUrl;

  const ExemplaryCitizen({
    required this.id,
    required this.name,
    required this.occupation,
    this.quote,
    this.photoUrl,
  });

  ExemplaryCitizen copyWith({
    String? id,
    String? name,
    String? occupation,
    String? quote,
    String? photoUrl,
  }) {
    return ExemplaryCitizen(
      id: id ?? this.id,
      name: name ?? this.name,
      occupation: occupation ?? this.occupation,
      quote: quote ?? this.quote,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  factory ExemplaryCitizen.fromJson(Map<String, dynamic> json) =>
      _$ExemplaryCitizenFromJson(json);

  Map<String, dynamic> toJson() => _$ExemplaryCitizenToJson(this);

  @override
  List<Object?> get props => [id, name, occupation, quote, photoUrl];
}
