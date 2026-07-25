// lib/presentation/mon_pays/models/province.dart

import 'city.dart';
import 'province_economic.dart';
import 'province_tourism.dart';
import 'province_emergency.dart';
import 'province_administrative.dart';

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
  
  // NOUVEAU CHAMP : Ajout de 'government' pour correspondre au service
  final Map<String, dynamic>? government;
  
  // Listes fortement typées pour éviter les erreurs de compilation
  final List<City> cities;
  final List<ProvinceEconomicResource> economicResources;
  final List<ProvinceTourism> tourismSites;
  final List<ProvinceEmergencyContact> emergencyContacts;
  final List<ProvinceAdministrativeDivision> administrativeDivisions;
  
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
    this.government,
    this.cities = const [],
    this.economicResources = const [],
    this.tourismSites = const [],
    this.emergencyContacts = const [],
    this.administrativeDivisions = const [],
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
    Map<String, dynamic>? government,
    List<City>? cities,
    List<ProvinceEconomicResource>? economicResources,
    List<ProvinceTourism>? tourismSites,
    List<ProvinceEmergencyContact>? emergencyContacts,
    List<ProvinceAdministrativeDivision>? administrativeDivisions,
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
      government: government ?? this.government,
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
      government: json['government'] is Map<String, dynamic> ? json['government'] : null,
      cities: json['cities'] is List 
          ? (json['cities'] as List).map((c) => c is City ? c : City.fromJson(c is Map<String, dynamic> ? c : {})).toList()
          : [],
      economicResources: json['economic_resources'] is List 
          ? (json['economic_resources'] as List).map((e) => e is ProvinceEconomicResource ? e : ProvinceEconomicResource.fromJson(e is Map<String, dynamic> ? e : {})).toList() 
          : [],
      tourismSites: json['tourism_sites'] is List 
          ? (json['tourism_sites'] as List).map((t) => t is ProvinceTourism ? t : ProvinceTourism.fromJson(t is Map<String, dynamic> ? t : {})).toList() 
          : [],
      emergencyContacts: json['emergency_contacts'] is List 
          ? (json['emergency_contacts'] as List).map((e) => e is ProvinceEmergencyContact ? e : ProvinceEmergencyContact.fromJson(e is Map<String, dynamic> ? e : {})).toList() 
          : [],
      administrativeDivisions: json['administrative_divisions'] is List 
          ? (json['administrative_divisions'] as List).map((a) => a is ProvinceAdministrativeDivision ? a : ProvinceAdministrativeDivision.fromJson(a is Map<String, dynamic> ? a : {})).toList() 
          : [],
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
    'government': government,
    'cities': cities.map((c) => c.toJson()).toList(),
    'economic_resources': economicResources.map((e) => e.toJson()).toList(),
    'tourism_sites': tourismSites.map((t) => t.toJson()).toList(),
    'emergency_contacts': emergencyContacts.map((e) => e.toJson()).toList(),
    'administrative_divisions': administrativeDivisions.map((a) => a.toJson()).toList(),
    'achievements': achievements,
    'tribes': tribes,
    'gallery_media': galleryMedia,
    'languages': languages,
    'resources': resources,
    'territories_count': territoriesCount,
  };
}
