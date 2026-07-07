// ------------------------------------------------------------------
// Fichier : models/lesson.dart
// Rôle : Leçon d'un module. Chaque leçon peut être de type vidéo,
// texte ou quiz. Elle est liée à une vidéo ou à une évaluation.
// ------------------------------------------------------------------

class Lesson {
  final String id;
  final String moduleId;
  final String title;
  final String description;
  final String type; // 'video', 'text', 'quiz'
  final int order;
  final String? videoId; // si type == 'video'
  final String? evaluationId; // si type == 'quiz'

  // Relations
  Video? video;
  Evaluation? evaluation;

  Lesson({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.description,
    required this.type,
    required this.order,
    this.videoId,
    this.evaluationId,
    this.video,
    this.evaluation,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'module_id': moduleId,
        'title': title,
        'description': description,
        'type': type,
        'order': order,
        'video_id': videoId,
        'evaluation_id': evaluationId,
      };

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
        id: json['id'],
        moduleId: json['module_id'],
        title: json['title'],
        description: json['description'],
        type: json['type'],
        order: json['order'],
        videoId: json['video_id'],
        evaluationId: json['evaluation_id'],
      );

  Lesson copyWith({
    String? title,
    String? description,
    int? order,
    Video? video,
    Evaluation? evaluation,
  }) =>
      Lesson(
        id: id,
        moduleId: moduleId,
        title: title ?? this.title,
        description: description ?? this.description,
        type: type,
        order: order ?? this.order,
        videoId: videoId,
        evaluationId: evaluationId,
        video: video ?? this.video,
        evaluation: evaluation ?? this.evaluation,
      );
}
