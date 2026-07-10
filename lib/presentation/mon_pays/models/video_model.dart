// models/video_model.dart

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'video_model.g.dart';

@JsonSerializable()
class Video extends Equatable {
  final String id;
  final String title;
  final String duration;
  final String thumbnailUrl;
  final String? url;
  final String? description;
  final String? category;
  final int? views;

  const Video({
    required this.id,
    required this.title,
    required this.duration,
    required this.thumbnailUrl,
    this.url,
    this.description,
    this.category,
    this.views,
  });

  Video copyWith({
    String? id,
    String? title,
    String? duration,
    String? thumbnailUrl,
    String? url,
    String? description,
    String? category,
    int? views,
  }) {
    return Video(
      id: id ?? this.id,
      title: title ?? this.title,
      duration: duration ?? this.duration,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      url: url ?? this.url,
      description: description ?? this.description,
      category: category ?? this.category,
      views: views ?? this.views,
    );
  }

  factory Video.fromJson(Map<String, dynamic> json) => _$VideoFromJson(json);
  Map<String, dynamic> toJson() => _$VideoToJson(this);

  @override
  List<Object?> get props => [id, title, duration, thumbnailUrl, url, description, category, views];
}
