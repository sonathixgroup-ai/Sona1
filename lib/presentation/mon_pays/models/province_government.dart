// lib/presentation/mon_pays/models/province_government.dart

import 'province_minister.dart';

class ProvinceGovernment {
  final String id;
  final String provinceId;
  final String? governorId;
  final String? viceGovernorId;
  final List<ProvinceMinister> ministers;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProvinceGovernment({
    required this.id,
    required this.provinceId,
    this.governorId,
    this.viceGovernorId,
    this.ministers = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory ProvinceGovernment.fromJson(Map<String, dynamic> json) {
    return ProvinceGovernment(
      id: json['id'] as String,
      provinceId: json['province_id'] as String,
      governorId: json['governor_id'] as String?,
      viceGovernorId: json['vice_governor_id'] as String?,
      ministers: (json['ministers'] as List?)
          ?.map((e) => ProvinceMinister.fromJson(e))
          .toList() ?? [],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'province_id': provinceId,
    'governor_id': governorId,
    'vice_governor_id': viceGovernorId,
    'ministers': ministers.map((e) => e.toJson()).toList(),
  };
}
