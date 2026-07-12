// lib/presentation/thix_sante/patient/models/patient_link_model.dart
// =============================================================================
// Model: PatientLinkModel
// Role: Liaison Docteur-Patient par THIX ID UID - Table health_links
// Fonction critique du memoire: recherche et liaison par UID
// =============================================================================

import 'package:flutter/foundation.dart';
import 'doctor_profile_model.dart';

/// Statut de la liaison, conforme au workflow metier.
enum LinkStatus {
  pending,
  active,
  revoked,
  blocked;

  static LinkStatus fromString(String? value) {
    switch (value) {
      case 'active':
        return LinkStatus.active;
      case 'revoked':
        return LinkStatus.revoked;
      case 'blocked':
        return LinkStatus.blocked;
      case 'pending':
      default:
        return LinkStatus.pending;
    }
  }
}

/// Niveau d'acces au dossier medical.
enum AccessLevel {
  full,
  limited,
  emergencyOnly;

  static AccessLevel fromString(String? value) {
    switch (value) {
      case 'limited':
        return AccessLevel.limited;
      case 'emergency_only':
        return AccessLevel.emergencyOnly;
      case 'full':
      default:
        return AccessLevel.full;
    }
  }
}

/// Liaison immutable entre un patient et un medecin via THIX ID.
/// Represente une ligne de la table public.health_links.
@immutable
class PatientLinkModel {
  final String id;
  final String doctorUid;
  final String patientUid;
  final String doctorThixId;
  final String patientThixId;
  final LinkStatus status;
  final AccessLevel accessLevel;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DoctorProfileModel? doctorProfile;

  const PatientLinkModel({
    required this.id,
    required this.doctorUid,
    required this.patientUid,
    required this.doctorThixId,
    required this.patientThixId,
    required this.status,
    required this.accessLevel,
    required this.createdAt,
    this.acceptedAt,
    this.doctorProfile,
  });

  factory PatientLinkModel.fromJson(Map<String, dynamic> json) {
    return PatientLinkModel(
      id: json['id'] as String,
      doctorUid: json['doctor_uid'] as String,
      patientUid: json['patient_uid'] as String,
      doctorThixId: json['doctor_thix_id'] as String,
      patientThixId: json['patient_thix_id'] as String,
      status: LinkStatus.fromString(json['status'] as String?),
      accessLevel: AccessLevel.fromString(json['access_level'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
      acceptedAt: json['accepted_at']!= null
         ? DateTime.tryParse(json['accepted_at'] as String)
          : null,
      doctorProfile: json['doctor_profile']!= null
         ? DoctorProfileModel.fromJson(
              json['doctor_profile'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  /// Payload pour insertion Supabase.
  Map<String, dynamic> toInsertJson() => {
        'doctor_uid': doctorUid,
        'patient_uid': patientUid,
        'doctor_thix_id': doctorThixId,
        'patient_thix_id': patientThixId,
        'status': status.name,
        'access_level': accessLevel.name,
      };

  bool get isActive => status == LinkStatus.active;
  bool get isPending => status == LinkStatus.pending;
  bool get isRevoked => status == LinkStatus.revoked;

  String get statusLabel {
    switch (status) {
      case LinkStatus.active:
        return 'Actif';
      case LinkStatus.pending:
        return 'En attente';
      case LinkStatus.revoked:
        return 'Revoque';
      case LinkStatus.blocked:
        return 'Bloque';
    }
  }

  String get accessLabel {
    switch (accessLevel) {
      case AccessLevel.full:
        return 'Acces complet';
      case AccessLevel.limited:
        return 'Acces limite';
      case AccessLevel.emergencyOnly:
        return 'Urgence uniquement';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatientLinkModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
