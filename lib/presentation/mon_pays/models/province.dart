// lib/presentation/mon_pays/models/province.dart

class Province {
  final String id;
  final String name;
  final String code;
  final String capital;
  final String region;
  final int? area;
  final int? population;
  final String? description;
  
  // Nouveaux champs institutionnels et historiques
  final String? history;
  final String? climate;
  final String? infrastructure;
  final String? education;

  final String? coverImageUrl;
  final String? coatOfArmsUrl;
  final String? mapUrl;
  final String? website;
  final String? governor;
  final String? governorPhotoUrl;
  final String? viceGovernor;
  final String? viceGovernorPhotoUrl;
  final List<dynamic>? ministers;
  final List<dynamic>? cities;
  final List<dynamic>? economicResources;
  final List<dynamic>? tourismSites;
  final List<dynamic>? emergencyContacts;
  final List<dynamic>? administrativeDivisions;
  final List<Map<String, dynamic>>? achievements;
  final List<Map<String, dynamic>>? tribes;
  final List<Map<String, dynamic>>? galleryMedia;
  final String? languages;
  final String? resources;
  final int? territoriesCount;

  const Province({
    required this.id,
    required this.name,
    required this.code,
    required this.capital,
    required this.region,
    this.area,
    this.population,
    this.description,
    this.history,
    this.climate,
    this.infrastructure,
    this.education,
    this.coverImageUrl,
    this.coatOfArmsUrl,
    this.mapUrl,
    this.website,
    this.governor,
    this.governorPhotoUrl,
    this.viceGovernor,
    this.viceGovernorPhotoUrl,
    this.ministers,
    this.cities,
    this.economicResources,
    this.tourismSites,
    this.emergencyContacts,
    this.administrativeDivisions,
    this.achievements,
    this.tribes,
    this.galleryMedia,
    this.languages,
    this.resources,
    this.territoriesCount,
  });

  Province copyWith({
    String? id,
    String? name,
    String? code,
    String? capital,
    String? region,
    int? area,
    int? population,
    String? description,
    String? history,
    String? climate,
    String? infrastructure,
    String? education,
    String? coverImageUrl,
    String? coatOfArmsUrl,
    String? mapUrl,
    String? website,
    String? governor,
    String? governorPhotoUrl,
    String? viceGovernor,
    String? viceGovernorPhotoUrl,
    List<dynamic>? ministers,
    List<dynamic>? cities,
    List<dynamic>? economicResources,
    List<dynamic>? tourismSites,
    List<dynamic>? emergencyContacts,
    List<dynamic>? administrativeDivisions,
    List<Map<String, dynamic>>? achievements,
    List<Map<String, dynamic>>? tribes,
    List<Map<String, dynamic>>? galleryMedia,
    String? languages,
    String? resources,
    int? territoriesCount,
  }) {
    return Province(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      capital: capital ?? this.capital,
      region: region ?? this.region,
      area: area ?? this.area,
      population: population ?? this.population,
      description: description ?? this.description,
      history: history ?? this.history,
      climate: climate ?? this.climate,
      infrastructure: infrastructure ?? this.infrastructure,
      education: education ?? this.education,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      coatOfArmsUrl: coatOfArmsUrl ?? this.coatOfArmsUrl,
      mapUrl: mapUrl ?? this.mapUrl,
      website: website ?? this.website,
      governor: governor ?? this.governor,
      governorPhotoUrl: governorPhotoUrl ?? this.governorPhotoUrl,
      viceGovernor: viceGovernor ?? this.viceGovernor,
      viceGovernorPhotoUrl: viceGovernorPhotoUrl ?? this.viceGovernorPhotoUrl,
      ministers: ministers ?? this.ministers,
      cities: cities ?? this.cities,
      economicResources: economicResources ?? this.economicResources,
      tourismSites: tourismSites ?? this.tourismSites,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      administrativeDivisions: administrativeDivisions ?? this.administrativeDivisions,
      achievements: achievements ?? this.achievements,
      tribes: tribes ?? this.tribes,
      galleryMedia: galleryMedia ?? this.galleryMedia,
      languages: languages ?? this.languages,
      resources: resources ?? this.resources,
      territoriesCount: territoriesCount ?? this.territoriesCount,
    );
  }

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      capital: json['capital']?.toString() ?? '',
      region: json['region']?.toString() ?? '',
      area: json['area'] != null ? int.tryParse(json['area'].toString()) : null,
      population: json['population'] != null ? int.tryParse(json['population'].toString()) : null,
      description: json['description']?.toString(),
      history: json['history']?.toString(),
      climate: json['climate']?.toString(),
      infrastructure: json['infrastructure']?.toString(),
      education: json['education']?.toString(),
      coverImageUrl: json['cover_image_url']?.toString() ?? json['coverImageUrl']?.toString(),
      coatOfArmsUrl: json['coat_of_arms_url']?.toString() ?? json['coatOfArmsUrl']?.toString(),
      mapUrl: json['map_url']?.toString() ?? json['mapUrl']?.toString(),
      website: json['website']?.toString(),
      governor: json['governor']?.toString(),
      governorPhotoUrl: json['governor_photo_url']?.toString() ?? json['governorPhotoUrl']?.toString(),
      viceGovernor: json['vice_governor']?.toString() ?? json['viceGovernor']?.toString(),
      viceGovernorPhotoUrl: json['vice_governor_photo_url']?.toString() ?? json['viceGovernorPhotoUrl']?.toString(),
      ministers: json['ministers'] is List ? json['ministers'] : null,
      cities: json['cities'] is List ? json['cities'] : null,
      economicResources: json['economic_resources'] is List ? json['economic_resources'] : null,
      tourismSites: json['tourism_sites'] is List ? json['tourism_sites'] : null,
      emergencyContacts: json['emergency_contacts'] is List ? json['emergency_contacts'] : null,
      administrativeDivisions: json['administrative_divisions'] is List ? json['administrative_divisions'] : null,
      achievements: json['achievements'] != null ? List<Map<String, dynamic>>.from(json['achievements']) : null,
      tribes: json['tribes'] != null ? List<Map<String, dynamic>>.from(json['tribes']) : null,
      galleryMedia: json['gallery_media'] != null ? List<Map<String, dynamic>>.from(json['gallery_media']) : null,
      languages: json['languages']?.toString(),
      resources: json['resources']?.toString(),
      territoriesCount: json['territories_count'] != null ? int.tryParse(json['territories_count'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id.isEmpty ? null : id,
    'name': name,
    'code': code,
    'capital': capital,
    'region': region,
    'area': area,
    'population': population,
    'description': description,
    'history': history,
    'climate': climate,
    'infrastructure': infrastructure,
    'education': education,
    'cover_image_url': coverImageUrl,
    'coat_of_arms_url': coatOfArmsUrl,
    'map_url': mapUrl,
    'website': website,
    'governor': governor,
    'governor_photo_url': governorPhotoUrl,
    'vice_governor': viceGovernor,
    'vice_governor_photo_url': viceGovernorPhotoUrl,
    'ministers': ministers,
    'cities': cities?.map((c) => c is Object && c.runtimeType.toString().contains('City') ? (c as dynamic).toJson() : c).toList(),
    'economic_resources': economicResources,
    'tourism_sites': tourismSites,
    'emergency_contacts': emergencyContacts,
    'administrative_divisions': administrativeDivisions,
    'achievements': achievements,
    'tribes': tribes,
    'gallery_media': galleryMedia,
    'languages': languages,
    'resources': resources,
    'territories_count': territoriesCount,
  };
}
