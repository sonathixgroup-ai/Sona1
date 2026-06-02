import 'dart:convert';

/// Represents a certificate issued to a user for completing a training.
class TrainingCertificate {
  final String id;
  final String userId;
  final String trainingId;
  final String certificateNumber;
  final DateTime issuedAt;
  final DateTime? expiresAt;
  final String? certificateUrl;
  final String? qrCodeUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TrainingCertificate({
    required this.id,
    required this.userId,
    required this.trainingId,
    required this.certificateNumber,
    required this.issuedAt,
    required this.expiresAt,
    required this.certificateUrl,
    required this.qrCodeUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TrainingCertificate.fromJson(Map<String, dynamic> json) {
    return TrainingCertificate(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      trainingId: (json['training_id'] ?? '').toString(),
      certificateNumber: (json['certificate_number'] ?? '').toString(),
      issuedAt: DateTime.tryParse((json['issued_at'] ?? '').toString()) ?? DateTime.now(),
      expiresAt: DateTime.tryParse((json['expires_at'] ?? '').toString()),
      certificateUrl: (json['certificate_url'] ?? '').toString().trim().isEmpty ? null : (json['certificate_url'] ?? '').toString(),
      qrCodeUrl: (json['qr_code_url'] ?? '').toString().trim().isEmpty ? null : (json['qr_code_url'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ?? DateTime.now(),
      updatedAt: DateTime.tryParse((json['updated_at'] ?? '').toString()) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'training_id': trainingId,
      'certificate_number': certificateNumber,
      'issued_at': issuedAt.toUtc().toIso8601String(),
      'expires_at': expiresAt?.toUtc().toIso8601String(),
      'certificate_url': certificateUrl,
      'qr_code_url': qrCodeUrl,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }
}
