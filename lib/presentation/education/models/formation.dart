// ------------------------------------------------------------------
// Fichier : models/formation.dart
// Rôle : Représente une formation (cours) proposée sur la plateforme.
// Une formation contient plusieurs modules, est associée à une catégorie
// et à un formateur (instructor). Elle peut être suivie par plusieurs
// utilisateurs (via Enrollment).
// ------------------------------------------------------------------

class Formation {
  final String id;
  final String title;
  final String description;
  final String categoryId;
  final String instructorId;
  final String level; // beginner, intermediate, advanced
  final int duration; // en minutes
  final double price;
  final String status; // draft, published, archived
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relations (non persistées, pour faciliter l'affichage)
  // Ces getters seront remplis par le provider ou le service.
  Category? category;
  List<Module>? modules;
  List<Enrollment>? enrollments;

  Formation({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.instructorId,
    required this.level,
    required this.duration,
    required this.price,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.modules,
    this.enrollments,
  });

  // Sérialisation JSON (Supabase)
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category_id': categoryId,
        'instructor_id': instructorId,
        'level': level,
        'duration': duration,
        'price': price,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Formation.fromJson(Map<String, dynamic> json) => Formation(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        categoryId: json['category_id'],
        instructorId: json['instructor_id'],
        level: json['level'],
        duration: json['duration'],
        price: (json['price'] as num).toDouble(),
        status: json['status'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
        // Les relations ne sont pas incluses par défaut, on les ajoute via des méthodes séparées.
      );

  Formation copyWith({
    String? title,
    String? description,
    String? status,
    double? price,
    int? duration,
    String? level,
    Category? category,
    List<Module>? modules,
    List<Enrollment>? enrollments,
  }) =>
      Formation(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        categoryId: categoryId,
        instructorId: instructorId,
        level: level ?? this.level,
        duration: duration ?? this.duration,
        price: price ?? this.price,
        status: status ?? this.status,
        createdAt: createdAt,
        updatedAt: updatedAt,
        category: category ?? this.category,
        modules: modules ?? this.modules,
        enrollments: enrollments ?? this.enrollments,
      );
}
