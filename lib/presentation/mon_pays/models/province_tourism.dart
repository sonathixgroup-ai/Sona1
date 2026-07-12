// lib/presentation/mon_pays/models/province_tourism.dart

class ProvinceTourism {
  final String id;
  final String provinceId;
  final String type; // 'parc_national', 'site_historique', 'monument', 'musee', 'evenement'
  final String name;
  final String? description;
  final String? location;
  final String? imageUrl;
  final String? website;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProvinceTourism({
    required this.id,
    required this.provinceId,
    required this.type,
    required this.name,
    this.description,
    this.location,
    this.imageUrl,
    this.website,
    this.createdAt,
    this.updatedAt,
  });

  factory ProvinceTourism.fromJson(Map<String, dynamic> json) {
    return ProvinceTourism(
      id: json['id'] as String,
      provinceId: json['province_id'] as String,
      type: json['type'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      imageUrl: json['image_url'] as String?,
      website: json['website'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'province_id': provinceId,
    'type': type,
    'name': name,
    'description': description,
    'location': location,
    'image_url': imageUrl,
    'website': website,
  };
}
