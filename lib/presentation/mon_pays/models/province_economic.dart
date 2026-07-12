// lib/presentation/mon_pays/models/province_economic.dart

class ProvinceEconomicResource {
  final String id;
  final String provinceId;
  final String category; // 'minerais', 'agriculture', 'hydrographie', 'energie', 'industrie', 'services'
  final String name;
  final String? description;
  final String? iconUrl;
  final bool isKeySector; // secteur clé pour l'investissement
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProvinceEconomicResource({
    required this.id,
    required this.provinceId,
    required this.category,
    required this.name,
    this.description,
    this.iconUrl,
    this.isKeySector = false,
    this.createdAt,
    this.updatedAt,
  });

  factory ProvinceEconomicResource.fromJson(Map<String, dynamic> json) {
    return ProvinceEconomicResource(
      id: json['id'] as String,
      provinceId: json['province_id'] as String,
      category: json['category'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      iconUrl: json['icon_url'] as String?,
      isKeySector: json['is_key_sector'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'province_id': provinceId,
    'category': category,
    'name': name,
    'description': description,
    'icon_url': iconUrl,
    'is_key_sector': isKeySector,
  };
}
