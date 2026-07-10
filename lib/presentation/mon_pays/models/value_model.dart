// lib/presentation/mon_pays/models/value_model.dart

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'value_model.g.dart';

@JsonSerializable()
class Value extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String? iconCode;
  final String? category;
  final String? content;
  final List<Article>? articles;        // ✅ rendu nullable
  final String? summary;
  final String? name;
  final List<Organization>? organizations;  // ✅ rendu nullable

  const Value({
    required this.id,
    required this.title,
    this.description,
    this.iconCode,
    this.category,
    this.content,
    this.articles,
    this.summary,
    this.name,
    this.organizations,
  });

  Value copyWith({
    String? id,
    String? title,
    String? description,
    String? iconCode,
    String? category,
    String? content,
    List<Article>? articles,
    String? summary,
    String? name,
    List<Organization>? organizations,
  }) {
    return Value(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconCode: iconCode ?? this.iconCode,
      category: category ?? this.category,
      content: content ?? this.content,
      articles: articles ?? this.articles,
      summary: summary ?? this.summary,
      name: name ?? this.name,
      organizations: organizations ?? this.organizations,
    );
  }

  factory Value.fromJson(Map<String, dynamic> json) => _$ValueFromJson(json);
  Map<String, dynamic> toJson() => _$ValueToJson(this);

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        iconCode,
        category,
        content,
        articles,
        summary,
        name,
        organizations,
      ];
}

// Modèle Article (pour la Constitution)
@JsonSerializable()
class Article extends Equatable {
  final String number;
  final String title;
  final String content;

  const Article({
    required this.number,
    required this.title,
    required this.content,
  });

  factory Article.fromJson(Map<String, dynamic> json) => _$ArticleFromJson(json);
  Map<String, dynamic> toJson() => _$ArticleToJson(this);

  @override
  List<Object?> get props => [number, title, content];
}

// Modèle Organization (pour la Justice)
@JsonSerializable()
class Organization extends Equatable {
  final String id;
  final String name;
  final String? description;

  const Organization({
    required this.id,
    required this.name,
    this.description,
  });

  factory Organization.fromJson(Map<String, dynamic> json) => _$OrganizationFromJson(json);
  Map<String, dynamic> toJson() => _$OrganizationToJson(this);

  @override
  List<Object?> get props => [id, name, description];
}
