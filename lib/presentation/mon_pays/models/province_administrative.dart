// lib/presentation/mon_pays/models/province_administrative.dart

class ProvinceAdministrativeDivision {
  final String id;
  final String provinceId;
  final String type; // 'territoire', 'secteur', 'chefferie'
  final String name;
  final int? population;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProvinceAdministrativeDivision({
    required this.id,
    required this.provinceId,
    required this.type,
    required this.name,
    this.population,
    this.createdAt,
    this.updatedAt,
  });

  factory ProvinceAdministrativeDivision.fromJson(Map<String, dynamic> json) {
    return ProvinceAdministrativeDivision(
      id: json['id'] as String,
      provinceId: json['province_id'] as String,
      type: json['type'] as String,
      name: json['name'] as String,
      population: json['population'] as int?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'province_id': provinceId,
    'type': type,
    'name': name,
    'population': population,
  };
}
