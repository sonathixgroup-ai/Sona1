import 'category.dart';
import 'module.dart';
import 'enrollment.dart';

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

  // ========== Champs ajoutés pour l'affichage ==========
  final String? instructor;       // Nom du formateur (peut être déduit de instructorId)
  final double rating;            // Note moyenne
  final int reviewsCount;         // Nombre d'avis
  final String? imageUrl;         // URL de l'image de couverture
  final bool isFree;              // Indique si gratuit (déduit de price)
  final bool isCertifying;        // Formation certifiante
  final int durationHours;        // Durée en heures (déduit de duration)
  final String difficulty;        // Déjà level

  // Relations
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
    this.instructor,
    this.rating = 0.0,
    this.reviewsCount = 0,
    this.imageUrl,
    this.isFree = false,
    this.isCertifying = false,
    this.durationHours = 0,
    this.difficulty = 'beginner',
    this.category,
    this.modules,
    this.enrollments,
  });

  factory Formation.fromJson(Map<String, dynamic> json) => Formation(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        categoryId: json['category_id'],
        instructorId: json['instructor_id'],
        level: json['level'] ?? json['difficulty'] ?? 'beginner',
        duration: json['duration'] ?? 0,
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        status: json['status'] ?? 'published',
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
        instructor: json['instructor'],
        rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
        reviewsCount: json['reviews_count'] ?? 0,
        imageUrl: json['image_url'],
        isFree: json['is_free'] ?? (json['price'] == 0),
        isCertifying: json['is_certifying'] ?? false,
        durationHours: json['duration_hours'] ?? (json['duration'] ~/ 60),
        difficulty: json['difficulty'] ?? json['level'] ?? 'beginner',
        category: json['category'] != null ? Category.fromJson(json['category']) : null,
        modules: json['modules'] != null
            ? (json['modules'] as List).map((m) => Module.fromJson(m)).toList()
            : null,
        enrollments: json['enrollments'] != null
            ? (json['enrollments'] as List).map((e) => Enrollment.fromJson(e)).toList()
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category_id': categoryId,
        'instructor_id': instructorId,
        'level': level,
        'difficulty': difficulty,
        'duration': duration,
        'duration_hours': durationHours,
        'price': price,
        'status': status,
        'instructor': instructor,
        'rating': rating,
        'reviews_count': reviewsCount,
        'image_url': imageUrl,
        'is_free': isFree,
        'is_certifying': isCertifying,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

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
    String? instructor,
    double? rating,
    int? reviewsCount,
    String? imageUrl,
    bool? isFree,
    bool? isCertifying,
    int? durationHours,
    String? difficulty,
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
        instructor: instructor ?? this.instructor,
        rating: rating ?? this.rating,
        reviewsCount: reviewsCount ?? this.reviewsCount,
        imageUrl: imageUrl ?? this.imageUrl,
        isFree: isFree ?? this.isFree,
        isCertifying: isCertifying ?? this.isCertifying,
        durationHours: durationHours ?? this.durationHours,
        difficulty: difficulty ?? this.difficulty,
        category: category ?? this.category,
        modules: modules ?? this.modules,
        enrollments: enrollments ?? this.enrollments,
      );
}
