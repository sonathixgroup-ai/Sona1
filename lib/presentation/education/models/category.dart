// ------------------------------------------------------------------
// Fichier : models/category.dart
// Rôle : Catégorie de formations (ex: "Développement", "Design", etc.)
// Permet de regrouper et filtrer les formations.
// ------------------------------------------------------------------
import 'formation.dart';
class Category {
  final String id;
  final String name;
  final String description;
  final String? parentId; // pour une hiérarchie de catégories
  final DateTime createdAt;

  // Relation
  List<Formation>? formations;

  Category({
    required this.id,
    required this.name,
    required this.description,
    this.parentId,
    required this.createdAt,
    this.formations,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'parent_id': parentId,
        'created_at': createdAt.toIso8601String(),
      };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        parentId: json['parent_id'],
        createdAt: DateTime.parse(json['created_at']),
      );

  Category copyWith({
    String? name,
    String? description,
    String? parentId,
    List<Formation>? formations,
  }) =>
      Category(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        parentId: parentId ?? this.parentId,
        createdAt: createdAt,
        formations: formations ?? this.formations,
      );
}
