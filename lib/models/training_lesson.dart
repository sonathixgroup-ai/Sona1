import 'dart:convert';

/// Represents a single lesson within a training course.
class TrainingLesson {
  final String id;
  final String trainingId;
  final int moduleIndex;
  final int lessonIndex;
  final String title;
  final String? description;
  final String contentType; // video | document | quiz | assignment
  final String? videoUrl;
  final String? videoStoragePath;
  final String? documentUrl;
  final String? documentStoragePath;
  final int? durationMinutes;
  final int? orderIndex;
  final bool isPreview;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TrainingLesson({
    required this.id,
    required this.trainingId,
    required this.moduleIndex,
    required this.lessonIndex,
    required this.title,
    required this.description,
    required this.contentType,
    required this.videoUrl,
    required this.videoStoragePath,
    required this.documentUrl,
    required this.documentStoragePath,
    required this.durationMinutes,
    required this.orderIndex,
    required this.isPreview,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TrainingLesson.fromJson(Map<String, dynamic> json) {
    return TrainingLesson(
      id: (json['id'] ?? '').toString(),
      trainingId: (json['training_id'] ?? '').toString(),
      moduleIndex: (json['module_index'] as num?)?.toInt() ?? 0,
      lessonIndex: (json['lesson_index'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString().trim().isEmpty ? null : (json['description'] ?? '').toString(),
      contentType: (json['content_type'] ?? 'video').toString(),
      videoUrl: (json['video_url'] ?? '').toString().trim().isEmpty ? null : (json['video_url'] ?? '').toString(),
      videoStoragePath: (json['video_storage_path'] ?? '').toString().trim().isEmpty ? null : (json['video_storage_path'] ?? '').toString(),
      documentUrl: (json['document_url'] ?? '').toString().trim().isEmpty ? null : (json['document_url'] ?? '').toString(),
      documentStoragePath: (json['document_storage_path'] ?? '').toString().trim().isEmpty ? null : (json['document_storage_path'] ?? '').toString(),
      durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
      orderIndex: (json['order_index'] as num?)?.toInt(),
      isPreview: (json['is_preview'] ?? false) == true,
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ?? DateTime.now(),
      updatedAt: DateTime.tryParse((json['updated_at'] ?? '').toString()) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'training_id': trainingId,
      'module_index': moduleIndex,
      'lesson_index': lessonIndex,
      'title': title,
      'description': description,
      'content_type': contentType,
      'video_url': videoUrl,
      'video_storage_path': videoStoragePath,
      'document_url': documentUrl,
      'document_storage_path': documentStoragePath,
      'duration_minutes': durationMinutes,
      'order_index': orderIndex,
      'is_preview': isPreview,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }
}
