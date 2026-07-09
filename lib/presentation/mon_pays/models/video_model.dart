// lib/presentation/mon_pays/models/video_model.dart

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'video_model.g.dart';

/// Modèle représentant une vidéo officielle
@JsonSerializable()
class Video extends Equatable {
  final String id;
  final String title;
  final String duration; // format "12:30"
  final String thumbnailUrl;
  final String? url; // lien vers la vidéo (YouTube, Vimeo...)

  const Video({
    required this.id,
    required this.title,
    required this.duration,
    required this.thumbnailUrl,
    this.url,
  });

  Video copyWith({
    String? id,
    String? title,
    String? duration,
    String? thumbnailUrl,
    String? url,
  }) {
    return Video(
      id: id ?? this.id,
      title: title ?? this.title,
      duration: duration ?? this.duration,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      url: url ?? this.url,
    );
  }

  factory Video.fromJson(Map<String, dynamic> json) => _$VideoFromJson(json);

  Map<String, dynamic> toJson() => _$VideoToJson(this);

  @override
  List<Object?> get props => [id, title, duration, thumbnailUrl, url];
}
