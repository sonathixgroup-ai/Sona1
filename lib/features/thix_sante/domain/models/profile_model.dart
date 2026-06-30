import 'package:equatable/equatable.dart';
import 'package:thix_id/features/thix_sante/domain/models/thix_datetime.dart';

class ProfileModel extends Equatable {
  final String id;
  final String userId;
  final String? patientId;
  final String? firstName;
  final String? lastName;
  final String? avatarUrl;
  final String? phone;
  final String? bloodGroup;
  final List<String> allergies;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProfileModel({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.patientId,
    this.firstName,
    this.lastName,
    this.avatarUrl,
    this.phone,
    this.bloodGroup,
    this.allergies = const [],
  });

  String get displayName {
    final fn = (firstName ?? '').trim();
    final ln = (lastName ?? '').trim();
    final name = [fn, ln].where((e) => e.isNotEmpty).join(' ');
    return name.isEmpty ? 'Utilisateur' : name;
  }

  ProfileModel copyWith({
    String? id,
    String? userId,
    String? patientId,
    String? firstName,
    String? lastName,
    String? avatarUrl,
    String? phone,
    String? bloodGroup,
    List<String>? allergies,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      patientId: patientId ?? this.patientId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: (json['id'] ?? '') as String,
      userId: (json['user_id'] ?? '') as String,
      patientId: json['patient_id'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      phone: json['phone'] as String?,
      bloodGroup: json['blood_group'] as String?,
      allergies: (json['allergies'] is List)
          ? List<String>.from((json['allergies'] as List).whereType<String>())
          : const [],
      createdAt: parseDateTime(json['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt: parseDateTime(json['updated_at']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'patient_id': patientId,
      'first_name': firstName,
      'last_name': lastName,
      'avatar_url': avatarUrl,
      'phone': phone,
      'blood_group': bloodGroup,
      'allergies': allergies,
      'created_at': toIsoString(createdAt),
      'updated_at': toIsoString(updatedAt),
    };
  }

  @override
  List<Object?> get props => [id, userId, patientId, firstName, lastName, avatarUrl, phone, bloodGroup, allergies, createdAt, updatedAt];
}
