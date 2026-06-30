import 'package:equatable/equatable.dart';
import 'package:thix_id/features/thix_sante/domain/models/thix_datetime.dart';

class ArticleModel extends Equatable {
  final String id;
  final String title;
  final String? category;
  final String? coverUrl;
  final String content;
  final DateTime publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ArticleModel({
    required this.id,
    required this.title,
    required this.content,
    required this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.coverUrl,
  });

  ArticleModel copyWith({
    String? id,
    String? title,
    String? category,
    String? coverUrl,
    String? content,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ArticleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      coverUrl: coverUrl ?? this.coverUrl,
      content: content ?? this.content,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    return ArticleModel(
      id: (json['id'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      category: json['category'] as String?,
      coverUrl: json['cover_url'] as String?,
      content: (json['content'] ?? '') as String,
      publishedAt: parseDateTime(json['published_at']) ?? DateTime.now().toUtc(),
      createdAt: parseDateTime(json['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt: parseDateTime(json['updated_at']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'cover_url': coverUrl,
      'content': content,
      'published_at': toIsoString(publishedAt),
      'created_at': toIsoString(createdAt),
      'updated_at': toIsoString(updatedAt),
    };
  }

  @override
  List<Object?> get props => [id, title, category, coverUrl, content, publishedAt, createdAt, updatedAt];
}
