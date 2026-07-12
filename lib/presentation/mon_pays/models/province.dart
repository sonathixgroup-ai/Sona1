// lib/presentation/mon_pays/models/province.dart

class Province {
  final String id;
  final String name;
  final String code;
  final String capital;
  final String? region;
  final String? surfaceArea;
  final String? population;
  final String? description;
  final String? coatOfArmsUrl;
  final String? coverUrl;
  final String? economyTourism;
  final List<Map<String, String>> emergencyContacts;
  final List<Map<String, String>> cities;
  final List<Map<String, String>> provincialMinisters;
  final List<String> mediaGallery;
  final String? governorId;

  Province({
    required this.id,
    required this.name,
    required this.code,
    required this.capital,
    this.region,
    this.surfaceArea,
    this.population,
    this.description,
    this.coatOfArmsUrl,
    this.coverUrl,
    this.economyTourism,
    this.emergencyContacts = const [],
    this.cities = const [],
    this.provincialMinisters = const [],
    this.mediaGallery = const [],
    this.governorId,
  });

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      capital: json['capital'] as String,
      region: json['region'] as String?,
      surfaceArea: json['surface_area'] as String?,
      population: json['population'] as String?,
      description: json['description'] as String?,
      coatOfArmsUrl: json['coat_of_arms_url'] as String?,
      coverUrl: json['cover_url'] as String?,
      economyTourism: json['economy_tourism'] as String?,
      emergencyContacts: (json['emergency_contacts'] as List?)?.map((e) => Map<String, String>.from(e)).toList() ?? [],
      cities: (json['cities'] as List?)?.map((e) => Map<String, String>.from(e)).toList() ?? [],
      provincialMinisters: (json['provincial_ministers'] as List?)?.map((e) => Map<String, String>.from(e)).toList() ?? [],
      mediaGallery: List<String>.from(json['media_gallery'] ?? []),
      governorId: json['governor_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name,
      'code': code,
      'capital': capital,
      'region': region,
      'surface_area': surfaceArea,
      'population': population,
      'description': description,
      'coat_of_arms_url': coatOfArmsUrl,
      'cover_url': coverUrl,
      'economy_tourism': economyTourism,
      'emergency_contacts': emergencyContacts,
      'cities': cities,
      'provincial_ministers': provincialMinisters,
      'media_gallery': mediaGallery,
      'governor_id': governorId,
    };
  }
}
