// lib/presentation/mon_pays/models/citizen_model.dart

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'citizen_model.g.dart';

@JsonSerializable()
class ExemplaryCitizen extends Equatable {
  final String id;
  final String name;
  final String occupation;
  final String? photoUrl;
  final String? quote;
  final String? city;
  final int? score;

  const ExemplaryCitizen({
    required this.id,
    required this.name,
    required this.occupation,
    this.photoUrl,
    this.quote,
    this.city,
    this.score,
  });

  ExemplaryCitizen copyWith({...}) => ...;

  factory ExemplaryCitizen.fromJson(Map<String, dynamic> json) => _$ExemplaryCitizenFromJson(json);
  Map<String, dynamic> toJson() => _$ExemplaryCitizenToJson(this);

  @override
  List<Object?> get props => [id, name, occupation, photoUrl, quote, city, score];
}
