// models/agency_model.dart

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import '../enums/agency_type.dart';

part 'agency_model.g.dart';

@JsonSerializable()
class Agency extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final AgencyType type;
  final String? website;
  final String? email;
  final String? phone;

  const Agency({
    required this.id,
    required this.name,
    required this.type,
    this.description,
    this.logoUrl,
    this.website,
    this.email,
    this.phone,
  });

  Agency copyWith({
    String? id,
    String? name,
    String? description,
    String? logoUrl,
    AgencyType? type,
    String? website,
    String? email,
    String? phone,
  }) {
    return Agency(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      type: type ?? this.type,
      website: website ?? this.website,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }

  factory Agency.fromJson(Map<String, dynamic> json) => _$AgencyFromJson(json);
  Map<String, dynamic> toJson() => _$AgencyToJson(this);

  @override
  List<Object?> get props => [id, name, description, logoUrl, type, website, email, phone];
}
