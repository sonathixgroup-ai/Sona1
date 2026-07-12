// lib/presentation/mon_pays/models/city.dart

class City {
  final String id;
  final String provinceId;
  final String name;
  final String type; // Ville, Territoire...
  final bool isCapital;
  final String? population;
  final String? description;

  City({
    required this.id,
    required this.provinceId,
    required this.name,
    required this.type,
    this.isCapital = false,
    this.population,
    this.description,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'],
      provinceId: json['province_id'],
      name: json['name'],
      type: json['type'],
      isCapital: json['capital_status'] ?? false,
      population: json['population'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() => {
    'province_id': provinceId,
    'name': name,
    'type': type,
    'capital_status': isCapital,
    'population': population,
    'description': description,
  };
}
