// models/news_model.dart

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import '../enums/news_type.dart';

part 'news_model.g.dart';

@JsonSerializable()
class News extends Equatable {
  final String id;
  final String title;
  final String content;
  final NewsType type;
  final String date;
  final String? imageUrl;
  final String? author;
  final int? views;

  const News({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.date,
    this.imageUrl,
    this.author,
    this.views,
  });

  News copyWith({
    String? id,
    String? title,
    String? content,
    NewsType? type,
    String? date,
    String? imageUrl,
    String? author,
    int? views,
  }) {
    return News(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      date: date ?? this.date,
      imageUrl: imageUrl ?? this.imageUrl,
      author: author ?? this.author,
      views: views ?? this.views,
    );
  }

  factory News.fromJson(Map<String, dynamic> json) => _$NewsFromJson(json);
  Map<String, dynamic> toJson() => _$NewsToJson(this);

  @override
  List<Object?> get props => [id, title, content, type, date, imageUrl, author, views];
}
