// models/search_result_model.dart

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'search_result_model.g.dart';

@JsonSerializable()
class SearchResult extends Equatable {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String type; // 'authority', 'news', 'agency', etc.
  final String? route;

  const SearchResult({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.type,
    this.route,
  });

  SearchResult copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? type,
    String? route,
  }) {
    return SearchResult(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      route: route ?? this.route,
    );
  }

  factory SearchResult.fromJson(Map<String, dynamic> json) => _$SearchResultFromJson(json);
  Map<String, dynamic> toJson() => _$SearchResultToJson(this);

  @override
  List<Object?> get props => [id, title, description, imageUrl, type, route];
}
