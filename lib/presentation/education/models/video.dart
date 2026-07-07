// ------------------------------------------------------------------
// Fichier : models/video.dart
// Rôle : Vidéo associée à une leçon. Contient l'URL de la vidéo, sa
// durée et une miniature.
// ------------------------------------------------------------------

class Video {
  final String id;
  final String lessonId;
  final String url;
  final int duration; // en secondes
  final String? thumbnail;

  Video({
    required this.id,
    required this.lessonId,
    required this.url,
    required this.duration,
    this.thumbnail,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'lesson_id': lessonId,
        'url': url,
        'duration': duration,
        'thumbnail': thumbnail,
      };

  factory Video.fromJson(Map<String, dynamic> json) => Video(
        id: json['id'],
        lessonId: json['lesson_id'],
        url: json['url'],
        duration: json['duration'],
        thumbnail: json['thumbnail'],
      );

  Video copyWith({
    String? url,
    int? duration,
    String? thumbnail,
  }) =>
      Video(
        id: id,
        lessonId: lessonId,
        url: url ?? this.url,
        duration: duration ?? this.duration,
        thumbnail: thumbnail ?? this.thumbnail,
      );
}
