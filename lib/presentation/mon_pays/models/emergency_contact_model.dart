// lib/presentation/mon_pays/models/emergency_contact_model.dart

import 'package:equatable/equatable.dart';

class EmergencyContact extends Equatable {
  final String id;
  final String name;
  final String phoneNumber;
  final String? description;
  final String? category;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.description,
    this.category,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phone_number'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
      'description': description,
      'category': category,
    };
  }

  @override
  List<Object?> get props => [id, name, phoneNumber, description, category];
}
