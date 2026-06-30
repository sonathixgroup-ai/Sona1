import 'package:equatable/equatable.dart';
import 'package:thix_id/features/thix_sante/domain/models/thix_datetime.dart';

enum ExamStatus { pending, available, reviewed }

ExamStatus examStatusFromString(String? value) {
  switch ((value ?? '').toLowerCase()) {
    case 'available':
      return ExamStatus.available;
    case 'reviewed':
      return ExamStatus.reviewed;
    case 'pending':
    default:
      return ExamStatus.pending;
  }
}

String examStatusToString(ExamStatus value) => value.name;

class ExamModel extends Equatable {
  final String id;
  final String userId;
  final String patientId;
  final String title;
  final ExamStatus status;
  final DateTime? occurredAt;
  final String? resultSummary;
  final String? pdfPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExamModel({
    required this.id,
    required this.userId,
    required this.patientId,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.occurredAt,
    this.resultSummary,
    this.pdfPath,
  });

  ExamModel copyWith({
    String? id,
    String? userId,
    String? patientId,
    String? title,
    ExamStatus? status,
    DateTime? occurredAt,
    String? resultSummary,
    String? pdfPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExamModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      patientId: patientId ?? this.patientId,
      title: title ?? this.title,
      status: status ?? this.status,
      occurredAt: occurredAt ?? this.occurredAt,
      resultSummary: resultSummary ?? this.resultSummary,
      pdfPath: pdfPath ?? this.pdfPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    return ExamModel(
      id: (json['id'] ?? '') as String,
      userId: (json['user_id'] ?? '') as String,
      patientId: (json['patient_id'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      status: examStatusFromString(json['status'] as String?),
      occurredAt: parseDateTime(json['occurred_at']),
      resultSummary: json['result_summary'] as String?,
      pdfPath: json['pdf_path'] as String?,
      createdAt: parseDateTime(json['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt: parseDateTime(json['updated_at']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'patient_id': patientId,
      'title': title,
      'status': examStatusToString(status),
      'occurred_at': toIsoString(occurredAt),
      'result_summary': resultSummary,
      'pdf_path': pdfPath,
      'created_at': toIsoString(createdAt),
      'updated_at': toIsoString(updatedAt),
    };
  }

  @override
  List<Object?> get props => [id, userId, patientId, title, status, occurredAt, resultSummary, pdfPath, createdAt, updatedAt];
}
