// lib/presentation/thix_sante/patient/models/doctor_profile_model.dart
// =============================================================================
// Model: DoctorProfileModel
// Role: Represente un medecin identifiable par THIX ID UID
// Source: table public.profiles where role = 'doctor'
// =============================================================================

import 'package:flutter/foundation.dart';

/// Profil medecin immutable, lie par THIX ID.
/// Utilise pour l'affichage dans Mon Medecin Traitant et Second Avis.
@immutable
class DoctorProfileModel {
  final String uid;
  final String thixId;
  final String fullName;
  final String? avatarUrl;
  final String? speciality;
  final String? thixChat;
  final String? country;
  final bool isVerified;
  final String? licenseNumber;
  final String? phone;
  final double? rating;

  const DoctorProfileModel({
    required this.uid,
    required this.thixId,
    required this.fullName,
    this.avatarUrl,
    this.speciality,
    this.thixChat,
    this.country,
    this.isVerified = true,
    this.licenseNumber,
    this.phone,
    this.rating,
  });

  /// Factory depuis Supabase profiles.
  /// Gere les champs nullable avec fallback securise.
  factory DoctorProfileModel.fromJson(Map<String, dynamic> json) {
    return DoctorProfileModel(
      uid: json['uid'] as String,
      thixId: (json['thix_id'] as String?)?? '',
      fullName: (json['full_name'] as String?)?? 'Docteur',
      avatarUrl: json['avatar_url'] as String?,
      speciality: (json['speciality'] as String?)??
          (json['occupation'] as String?),
      thixChat: json['thix_chat'] as String?,
      country: json['country_or_origin'] as String?,
      isVerified: (json['is_verified'] as bool?)?? true,
      licenseNumber: json['license_number'] as String?,
      phone: json['phone'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'thix_id': thixId,
        'full_name': fullName,
        'avatar_url': avatarUrl,
        'speciality': speciality,
        'thix_chat': thixChat,
      };

  /// Initiales pour Avatar fallback.
  String get initials {
    final List<String> parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty? fullName[0].toUpperCase() : 'D';
  }

  String get displaySpeciality => speciality?? 'Medecine Generale';
  bool get hasAvatar => avatarUrl!= null && avatarUrl!.isNotEmpty;

  DoctorProfileModel copyWith({
    String? speciality,
    String? avatarUrl,
    bool? isVerified,
  }) {
    return DoctorProfileModel(
      uid: uid,
      thixId: thixId,
      fullName: fullName,
      avatarUrl: avatarUrl?? this.avatarUrl,
      speciality: speciality?? this.speciality,
      thixChat: thixChat,
      country: country,
      isVerified: isVerified?? this.isVerified,
      licenseNumber: licenseNumber,
      phone: phone,
      rating: rating,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoctorProfileModel &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          thixId == other.thixId;

  @override
  int get hashCode => uid.hashCode ^ thixId.hashCode;
}
