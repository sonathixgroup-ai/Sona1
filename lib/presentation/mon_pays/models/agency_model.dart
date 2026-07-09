// lib/presentation/mon_pays/models/agency_model.dart

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'agency_model.g.dart';

/// Modèle représentant une agence ou institution
@JsonSerializable()
class Agency extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;

  const Agency({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
  });

  Agency copyWith({
    String? id,
    String? name,
    String? description,
    String? logoUrl,
  }) {
    return Agency(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
    );
  }

  factory Agency.fromJson(Map<String, dynamic> json) => _$AgencyFromJson(json);

  Map<String, dynamic> toJson() => _$AgencyToJson(this);

  @override
  List<Object?> get props => [id, name, description, logoUrl];
}
