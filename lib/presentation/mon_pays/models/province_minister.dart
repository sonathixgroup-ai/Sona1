// lib/presentation/mon_pays/models/province_minister.dart

class ProvinceMinister {
  final String id;
  final String governmentId;
  final String? authorityId;
  final String portfolio;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProvinceMinister({
    required this.id,
    required this.governmentId,
    this.authorityId,
    required this.portfolio,
    this.createdAt,
    this.updatedAt,
  });

  factory ProvinceMinister.fromJson(Map<String, dynamic> json) {
    return ProvinceMinister(
      id: json['id'] as String,
      governmentId: json['government_id'] as String,
      authorityId: json['authority_id'] as String?,
      portfolio: json['portfolio'] as String,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'government_id': governmentId,
    'authority_id': authorityId,
    'portfolio': portfolio,
  };
}
