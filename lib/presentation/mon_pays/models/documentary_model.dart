// lib/presentation/mon_pays/models/documentary_model.dart

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'documentary_model.g.dart';

/// Modèle représentant un documentaire ou archive
@JsonSerializable()
class Documentary extends Equatable {
  final String id;
  final String title;
  final String duration; // format "45:00"
  final String thumbnailUrl;
  final String category; // Histoire, Culture, etc.
  final String? url;

  const Documentary({
    required this.id,
    required this.title,
    required this.duration,
    required this.thumbnailUrl,
    required this.category,
    this.url,
  });

  Documentary copyWith({
    String? id,
    String? title,
    String? duration,
    String? thumbnailUrl,
    String? category,
    String? url,
  }) {
    return Documentary(
      id: id ?? this.id,
      title: title ?? this.title,
      duration: duration ?? this.duration,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      category: category ?? this.category,
      url: url ?? this.url,
    );
  }

  factory Documentary.fromJson(Map<String, dynamic> json) =>
      _$DocumentaryFromJson(json);

  Map<String, dynamic> toJson() => _$DocumentaryToJson(this);

  @override
  List<Object?> get props => [id, title, duration, thumbnailUrl, category, url];
}
