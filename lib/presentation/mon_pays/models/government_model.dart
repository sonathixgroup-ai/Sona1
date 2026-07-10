// models/government_model.dart

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'government_model.g.dart';

@JsonSerializable()
class Government extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final String? website;
  final String? type; // "central", "provincial", "local"

  const Government({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    this.website,
    this.type,
  });

  Government copyWith({
    String? id,
    String? name,
    String? description,
    String? logoUrl,
    String? website,
    String? type,
  }) {
    return Government(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      website: website ?? this.website,
      type: type ?? this.type,
    );
  }

  factory Government.fromJson(Map<String, dynamic> json) => _$GovernmentFromJson(json);
  Map<String, dynamic> toJson() => _$GovernmentToJson(this);

  @override
  List<Object?> get props => [id, name, description, logoUrl, website, type];
}
