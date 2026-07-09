// models/documentary_model.dart

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'documentary_model.g.dart';

@JsonSerializable()
class Documentary extends Equatable {
  final String id;
  final String title;
  final String duration;
  final String thumbnailUrl;
  final String category;
  final String? url;
  final String? description;
  final String? year;

  const Documentary({
    required this.id,
    required this.title,
    required this.duration,
    required this.thumbnailUrl,
    required this.category,
    this.url,
    this.description,
    this.year,
  });

  Documentary copyWith({
    String? id,
    String? title,
    String? duration,
    String? thumbnailUrl,
    String? category,
    String? url,
    String? description,
    String? year,
  }) {
    return Documentary(
      id: id ?? this.id,
      title: title ?? this.title,
      duration: duration ?? this.duration,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      category: category ?? this.category,
      url: url ?? this.url,
      description: description ?? this.description,
      year: year ?? this.year,
    );
  }

  factory Documentary.fromJson(Map<String, dynamic> json) => _$DocumentaryFromJson(json);
  Map<String, dynamic> toJson() => _$DocumentaryToJson(this);

  @override
  List<Object?> get props => [id, title, duration, thumbnailUrl, category, url, description, year];
}
