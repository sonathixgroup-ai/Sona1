// lib/presentation/mon_pays/models/province_minister.dart

class ProvinceMinister {
  final String name;
  final String role;

  ProvinceMinister({required this.name, required this.role});

  factory ProvinceMinister.fromJson(Map<String, dynamic> json) {
    return ProvinceMinister(
      name: json['name'] ?? '',
      role: json['role'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name, 
    'role': role,
  };
}
