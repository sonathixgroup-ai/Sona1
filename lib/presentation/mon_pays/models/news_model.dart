// lib/presentation/mon_pays/models/news_model.dart

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'news_model.g.dart';

/// Modèle représentant une actualité officielle
@JsonSerializable()
class News extends Equatable {
  final String id;
  final String title;
  final String category; // "OFFICIEL", "COMMUNIQUÉ", "NATIONAL"
  final String date; // format "27 Mai 2025" ou ISO
  final String content;

  const News({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.content,
  });

  News copyWith({
    String? id,
    String? title,
    String? category,
    String? date,
    String? content,
  }) {
    return News(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      date: date ?? this.date,
      content: content ?? this.content,
    );
  }

  factory News.fromJson(Map<String, dynamic> json) => _$NewsFromJson(json);

  Map<String, dynamic> toJson() => _$NewsToJson(this);

  @override
  List<Object?> get props => [id, title, category, date, content];
}
