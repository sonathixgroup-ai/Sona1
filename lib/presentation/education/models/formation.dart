import 'category.dart';
import 'module.dart';
import 'enrollment.dart';

class Formation {
  final String id;
  final String title;
  final String description;
  final String categoryId;
  final String instructorId;
  final String? instructorName;
  final String level; // beginner, intermediate, advanced
  final int duration; // minutes total
  final double price;
  final String currency; // USD, FC
  final double rating;
  final int reviewsCount;
  final String? imageUrl;
  final bool isFree;
  final bool isCertifying;
  final String status; // draft, published, archived
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

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
    this.instructorName,
    this.level = 'beginner',
    this.duration = 0,
    this.price = 0.0,
    this.currency = 'USD',
    this.rating = 0.0,
    this.reviewsCount = 0,
    this.imageUrl,
    this.isFree = false,
    this.isCertifying = false,
    this.status = 'draft',
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.modules,
    this.enrollments,
  });

  factory Formation.fromJson(Map<String, dynamic> json) => Formation(
        id: json['id'],
        title: json['title'],
        description: json['description'] ?? '',
        categoryId: json['category_id'] ?? '',
        instructorId: json['instructor_id'] ?? '',
        instructorName: json['instructor_name'],
        level: json['level'] ?? 'beginner',
        duration: json['duration'] ?? 0,
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        currency: json['currency'] ?? 'USD',
        rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
        reviewsCount: json['reviews_count'] ?? 0,
        imageUrl: json['image_url'],
        isFree: json['is_free'] ?? false,
        isCertifying: json['is_certifying'] ?? false,
        status: json['status'] ?? 'draft',
        tags: List<String>.from(json['tags'] ?? []),
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
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
        'instructor_name': instructorName,
        'level': level,
        'duration': duration,
        'price': price,
        'currency': currency,
        'rating': rating,
        'reviews_count': reviewsCount,
        'image_url': imageUrl,
        'is_free': isFree,
        'is_certifying': isCertifying,
        'status': status,
        'tags': tags,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
