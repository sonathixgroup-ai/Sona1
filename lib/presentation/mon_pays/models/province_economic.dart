// lib/presentation/mon_pays/models/province_economic.dart

class ProvinceEconomicResource {
  final String id;
  final String provinceId;
  final String name;
  final String? description;
  final String? imageUrl;

  const ProvinceEconomicResource({
    required this.id,
    required this.provinceId,
    required this.name,
    this.description,
    this.imageUrl,
  });

  factory ProvinceEconomicResource.fromJson(Map<String, dynamic> json) {
    return ProvinceEconomicResource(
      id: json['id']?.toString() ?? '',
      provinceId: json['province_id']?.toString() ?? json['provinceId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      imageUrl: json['image_url'] ?? json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id.isEmpty ? null : id,
    'province_id': provinceId,
    'name': name,
    'description': description,
    'image_url': imageUrl,
  };
}
