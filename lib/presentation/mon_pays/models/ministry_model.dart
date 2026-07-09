// models/ministry_model.dart

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ministry_model.g.dart';

@JsonSerializable()
class Ministry extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? ministerId;
  final String? logoUrl;
  final String? website;

  const Ministry({
    required this.id,
    required this.name,
    this.description,
    this.ministerId,
    this.logoUrl,
    this.website,
  });

  Ministry copyWith({
    String? id,
    String? name,
    String? description,
    String? ministerId,
    String? logoUrl,
    String? website,
  }) {
    return Ministry(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ministerId: ministerId ?? this.ministerId,
      logoUrl: logoUrl ?? this.logoUrl,
      website: website ?? this.website,
    );
  }

  factory Ministry.fromJson(Map<String, dynamic> json) => _$MinistryFromJson(json);
  Map<String, dynamic> toJson() => _$MinistryToJson(this);

  @override
  List<Object?> get props => [id, name, description, ministerId, logoUrl, website];
}
