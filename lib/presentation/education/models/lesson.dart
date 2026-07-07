import 'video.dart';
import 'evaluation.dart';

class Lesson {
  final String id;
  final String moduleId;
  final String title;
  final String? description;
  final String type; // 'video', 'text', 'quiz', 'assignment'
  final int durationMinutes;
  final int order;
  final String? content;
  final Video? video;
  final Evaluation? evaluation;
  final DateTime? createdAt;

  Lesson({
    required this.id,
    required this.moduleId,
    required this.title,
    this.description,
    required this.type,
    this.durationMinutes = 0,
    this.order = 0,
    this.content,
    this.video,
    this.evaluation,
    this.createdAt,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
        id: json['id'],
        moduleId: json['module_id'],
        title: json['title'],
        description: json['description'],
        type: json['type'],
        durationMinutes: json['duration_minutes'] ?? 0,
        order: json['order'] ?? 0,
        content: json['content'],
        video: json['video'] != null ? Video.fromJson(json['video']) : null,
        evaluation: json['evaluation'] != null ? Evaluation.fromJson(json['evaluation']) : null,
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'module_id': moduleId,
        'title': title,
        'description': description,
        'type': type,
        'duration_minutes': durationMinutes,
        'order': order,
        'content': content,
        'video': video?.toJson(),
        'evaluation': evaluation?.toJson(),
        'created_at': createdAt?.toIso8601String(),
      };
}
