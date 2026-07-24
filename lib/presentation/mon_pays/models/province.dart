// lib/presentation/mon_pays/models/province.dart

import 'province_government.dart';
import 'province_economic.dart';
import 'province_tourism.dart';
import 'province_emergency.dart';
import 'province_administrative.dart';
import 'province_budget.dart';
import 'city.dart';

class Province {
  final String id;
  final String name;
  final String code;
  final String capital;
  final String region;
  final int? area;
  final int? population;
  final String? description;
  final String? coverImageUrl;
  final String? coatOfArmsUrl;
  final String? mapUrl;
  final String? website;
  
  // Nouveaux champs ajoutés :
  final String? governor;
  final String? viceGovernor;
  final String? languages;
  final String? resources;
  final int? territoriesCount;

  final ProvinceGovernment? government; // relation 1-1
  final List<City> cities; // villes
  final List<ProvinceEconomicResource> economicResources; // ressources économiques
  final List<ProvinceBudgetPriority> budgetPriorities; // priorités budgétaires
  final List<ProvinceTourism> tourismSites; // tourisme & culture
  final List<ProvinceEmergencyContact> emergencyContacts; // numéros d'urgence
  final List<ProvinceAdministrativeDivision> administrativeDivisions; // découpage
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Province({
    required this.id,
    required this.name,
    required this.code,
    required this.capital,
    required this.region,
    this.area,
    this.population,
    this.description,
    this.coverImageUrl,
    this.coatOfArmsUrl,
    this.mapUrl,
    this.website,
    this.governor,
    this.viceGovernor,
    this.languages,
    this.resources,
    this.territoriesCount,
    this.government,
    this.cities = const [],
    this.economicResources = const [],
    this.budgetPriorities = const [],
    this.tourismSites = const [],
    this.emergencyContacts = const [],
    this.administrativeDivisions = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      capital: json['capital'] as String,
      region: json['region'] as String,
      area: json['area'] as int?,
      population: json['population'] as int?,
      description: json['description'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      coatOfArmsUrl: json['coat_of_arms_url'] as String?,
      mapUrl: json['map_url'] as String?,
      website: json['website'] as String?,
      
      // Prise en charge du camelCase (Formulaire App) et du snake_case (Supabase)
      governor: json['governor'] as String?,
      viceGovernor: json['viceGovernor'] as String? ?? json['vice_governor'] as String?,
      languages: json['languages'] as String?,
      resources: json['resources'] as String?,
      territoriesCount: json['territoriesCount'] as int? ?? json['territories_count'] as int?,

      government: json['government'] != null
          ? ProvinceGovernment.fromJson(json['government'])
          : null,
      cities: (json['cities'] as List?)?.map((e) => City.fromJson(e)).toList() ?? [],
      economicResources: (json['economic_resources'] as List?)?.map((e) => ProvinceEconomicResource.fromJson(e)).toList() ?? [],
      budgetPriorities: (json['budget_priorities'] as List?)?.map((e) => ProvinceBudgetPriority.fromJson(e)).toList() ?? [],
      tourismSites: (json['tourism_sites'] as List?)?.map((e) => ProvinceTourism.fromJson(e)).toList() ?? [],
      emergencyContacts: (json['emergency_contacts'] as List?)?.map((e) => ProvinceEmergencyContact.fromJson(e)).toList() ?? [],
      administrativeDivisions: (json['administrative_divisions'] as List?)?.map((e) => ProvinceAdministrativeDivision.fromJson(e)).toList() ?? [],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'capital': capital,
    'region': region,
    'area': area,
    'population': population,
    'description': description,
    'cover_image_url': coverImageUrl,
    'coat_of_arms_url': coatOfArmsUrl,
    'map_url': mapUrl,
    'website': website,
    
    // Enregistrement en snake_case pour la BDD Supabase
    'governor': governor,
    'vice_governor': viceGovernor,
    'languages': languages,
    'resources': resources,
    'territories_count': territoriesCount,

    'government': government?.toJson(),
    'cities': cities.map((e) => e.toJson()).toList(),
    'economic_resources': economicResources.map((e) => e.toJson()).toList(),
    'budget_priorities': budgetPriorities.map((e) => e.toJson()).toList(),
    'tourism_sites': tourismSites.map((e) => e.toJson()).toList(),
    'emergency_contacts': emergencyContacts.map((e) => e.toJson()).toList(),
    'administrative_divisions': administrativeDivisions.map((e) => e.toJson()).toList(),
  };

  Province copyWith({
    String? governor,
    String? viceGovernor,
    String? languages,
    String? resources,
    int? territoriesCount,
    ProvinceGovernment? government,
    List<City>? cities,
    List<ProvinceEconomicResource>? economicResources,
    List<ProvinceBudgetPriority>? budgetPriorities,
    List<ProvinceTourism>? tourismSites,
    List<ProvinceEmergencyContact>? emergencyContacts,
    List<ProvinceAdministrativeDivision>? administrativeDivisions,
  }) {
    return Province(
      id: id,
      name: name,
      code: code,
      capital: capital,
      region: region,
      area: area,
      population: population,
      description: description,
      coverImageUrl: coverImageUrl,
      coatOfArmsUrl: coatOfArmsUrl,
      mapUrl: mapUrl,
      website: website,
      
      governor: governor ?? this.governor,
      viceGovernor: viceGovernor ?? this.viceGovernor,
      languages: languages ?? this.languages,
      resources: resources ?? this.resources,
      territoriesCount: territoriesCount ?? this.territoriesCount,

      government: government ?? this.government,
      cities: cities ?? this.cities,
      economicResources: economicResources ?? this.economicResources,
      budgetPriorities: budgetPriorities ?? this.budgetPriorities,
      tourismSites: tourismSites ?? this.tourismSites,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      administrativeDivisions: administrativeDivisions ?? this.administrativeDivisions,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
