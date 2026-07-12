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
    'government': government?.toJson(),
    'cities': cities.map((e) => e.toJson()).toList(),
    'economic_resources': economicResources.map((e) => e.toJson()).toList(),
    'budget_priorities': budgetPriorities.map((e) => e.toJson()).toList(),
    'tourism_sites': tourismSites.map((e) => e.toJson()).toList(),
    'emergency_contacts': emergencyContacts.map((e) => e.toJson()).toList(),
    'administrative_divisions': administrativeDivisions.map((e) => e.toJson()).toList(),
  };

  Province copyWith({
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
