// ------------------------------------------------------------------
// Fichier : models/certificate.dart
// Rôle : Certificat délivré à un utilisateur lorsqu'il termine une
// formation avec succès. Contient l'URL du PDF ou de l'image.
// ------------------------------------------------------------------

class Certificate {
  final String id;
  final String enrollmentId;
  final String userId;
  final String formationId;
  final DateTime issuedAt;
  final String certificateUrl;

  Certificate({
    required this.id,
    required this.enrollmentId,
    required this.userId,
    required this.formationId,
    required this.issuedAt,
    required this.certificateUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'enrollment_id': enrollmentId,
        'user_id': userId,
        'formation_id': formationId,
        'issued_at': issuedAt.toIso8601String(),
        'certificate_url': certificateUrl,
      };

  factory Certificate.fromJson(Map<String, dynamic> json) => Certificate(
        id: json['id'],
        enrollmentId: json['enrollment_id'],
        userId: json['user_id'],
        formationId: json['formation_id'],
        issuedAt: DateTime.parse(json['issued_at']),
        certificateUrl: json['certificate_url'],
      );

  Certificate copyWith({
    String? certificateUrl,
  }) =>
      Certificate(
        id: id,
        enrollmentId: enrollmentId,
        userId: userId,
        formationId: formationId,
        issuedAt: issuedAt,
        certificateUrl: certificateUrl ?? this.certificateUrl,
      );
}
