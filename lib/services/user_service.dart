// services/user_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';

class UserService {
  final SupabaseClient _supabase;

  UserService(this._supabase);

  // =========================================================
  // USER HELPERS
  // =========================================================

  User? get currentAuthUser =>
      _supabase.auth.currentUser;

  String get currentUserId =>
      currentAuthUser?.id ?? '';

  // =========================================================
  // PROFILE UPDATE
  // =========================================================

  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? fullName,
    String? photoUrl,
    String? registrationStatus,
    String? thixChat,
    String? bio,
    String? competence,
    String? countryOrOrigin,
    String? contactPhone,
    String? dateOfBirth,
    String? placeOfBirth,
    String? nationality,
    String? maritalStatus,
    String? gender,
    String? occupation,
    String? profession,
    String? address,
    String? fatherName,
    String? motherName,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelation,
    List<Map<String, dynamic>>? education,
    List<Map<String, dynamic>>? experience,
    List<String>? languages,
    bool? biometricsEnabled,
    bool? twoFaEnabled,
  }) async {
    final updates = <String, dynamic>{};

    if (displayName != null) {
      updates['display_name'] = displayName;
    }

    if (fullName != null) {
      updates['full_name'] = fullName;
    }

    if (photoUrl != null) {
      updates['photo_url'] = photoUrl;
    }

    if (registrationStatus != null) {
      updates['registration_status'] =
          registrationStatus;
    }

    if (thixChat != null) {
      updates['thix_chat'] =
          thixChat.toLowerCase();
    }

    if (bio != null) {
      updates['bio'] = bio;
    }

    if (competence != null) {
      updates['competence'] = competence;
    }

    if (countryOrOrigin != null) {
      updates['country_or_origin'] =
          countryOrOrigin;
    }

    if (contactPhone != null) {
      updates['contact_phone'] =
          contactPhone;
    }

    if (dateOfBirth != null) {
      updates['date_of_birth'] =
          dateOfBirth;
    }

    if (placeOfBirth != null) {
      updates['place_of_birth'] =
          placeOfBirth;
    }

    if (nationality != null) {
      updates['nationality'] =
          nationality;
    }

    if (maritalStatus != null) {
      updates['marital_status'] =
          maritalStatus;
    }

    if (gender != null) {
      updates['gender'] = gender;
    }

    if (occupation != null) {
      updates['occupation'] =
          occupation;
    }

    if (profession != null) {
      updates['profession'] =
          profession;
    }

    if (address != null) {
      updates['address'] = address;
    }

    if (fatherName != null) {
      updates['father_name'] =
          fatherName;
    }

    if (motherName != null) {
      updates['mother_name'] =
          motherName;
    }

    if (emergencyContactName != null) {
      updates['emergency_contact_name'] =
          emergencyContactName;
    }

    if (emergencyContactPhone != null) {
      updates['emergency_contact_phone'] =
          emergencyContactPhone;
    }

    if (emergencyContactRelation != null) {
      updates['emergency_contact_relation'] =
          emergencyContactRelation;
    }

    if (education != null) {
      updates['education'] = education;
    }

    if (experience != null) {
      updates['experience'] = experience;
    }

    if (languages != null) {
      updates['languages'] = languages;
    }

    if (biometricsEnabled != null) {
      updates['biometrics_enabled'] =
          biometricsEnabled;
    }

    if (twoFaEnabled != null) {
      updates['two_fa_enabled'] =
          twoFaEnabled;
    }

    if (updates.isEmpty) return;

    updates['updated_at'] =
        DateTime.now().toIso8601String();

    await _supabase
        .from('profiles')
        .update(updates)
        .eq('id', uid);
  }

  // =========================================================
  // GET USERS
  // =========================================================

  Future<AppUser?> getUserById(
    String uid,
  ) async {
    final row = await _supabase
        .from('profiles')
        .select()
        .eq('id', uid)
        .maybeSingle();

    if (row == null) return null;

    return _mapToAppUser(
      row as Map<String, dynamic>,
    );
  }

  Future<AppUser?> getUserByThixId(
    String thixId,
  ) async {
    final row = await _supabase
        .from('profiles')
        .select()
        .eq('thix_id', thixId)
        .maybeSingle();

    if (row == null) return null;

    return _mapToAppUser(
      row as Map<String, dynamic>,
    );
  }

  Future<AppUser?> getUserByChatId(
    String chatId,
  ) async {
    final row = await _supabase
        .from('profiles')
        .select()
        .eq(
          'thix_chat',
          chatId.toLowerCase(),
        )
        .maybeSingle();

    if (row == null) return null;

    return _mapToAppUser(
      row as Map<String, dynamic>,
    );
  }

  // =========================================================
  // THIX ID
  // =========================================================

  Future<String> ensureThixId({
    required String uid,
  }) async {
    final row = await _supabase
        .from('profiles')
        .select('thix_id')
        .eq('id', uid)
        .maybeSingle();

    final existing =
        (row?['thix_id'] ?? '')
            .toString()
            .trim();

    if (existing.isNotEmpty &&
        existing != 'THIX-PENDING') {
      return existing;
    }

    final candidate =
        'THIX-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    await _supabase
        .from('profiles')
        .update({
      'thix_id': candidate,
    }).eq('id', uid);

    return candidate;
  }

  Future<String> ensureThixChat({
    required String uid,
    required String desired,
  }) async {
    final normalized =
        desired.trim().toLowerCase();

    await _supabase
        .from('profiles')
        .update({
      'thix_chat': normalized,
    }).eq('id', uid);

    return normalized;
  }

  // =========================================================
  // CHAT METHODS
  // =========================================================

  Future<void> sendMessage({
    required String senderId,
    required String recipientId,
    required String content,
  }) async {
    await _supabase
        .from('health_messages')
        .insert({
      'sender_id': senderId,
      'recipient_id': recipientId,
      'content': content,
      'is_read': false,
      'created_at':
          DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>>
      getConversationMessages({
    required String currentUserId,
    required String otherUserId,
  }) async {
    final response = await _supabase
        .from('health_messages')
        .select()
        .or(
          'and(sender_id.eq.$currentUserId,recipient_id.eq.$otherUserId),'
          'and(sender_id.eq.$otherUserId,recipient_id.eq.$currentUserId)',
        )
        .order(
          'created_at',
          ascending: true,
        );

    return response
        .map<Map<String, dynamic>>(
          (e) =>
              Map<String, dynamic>.from(e),
        )
        .toList();
  }

  Stream<List<Map<String, dynamic>>>
      streamConversation({
    required String currentUserId,
    required String otherUserId,
  }) {
    return _supabase
        .from('health_messages')
        .stream(primaryKey: ['id'])
        .order(
          'created_at',
          ascending: true,
        )
        .map((messages) {
          return messages.where((msg) {
            final sender =
                msg['sender_id'];

            final recipient =
                msg['recipient_id'];

            return (
                    sender ==
                        currentUserId &&
                    recipient ==
                        otherUserId) ||
                (
                    sender ==
                        otherUserId &&
                    recipient ==
                        currentUserId);
          }).toList();
        });
  }

  Future<void> markMessagesAsRead({
    required String currentUserId,
    required String otherUserId,
  }) async {
    await _supabase
        .from('health_messages')
        .update({
      'is_read': true,
    })
        .match({
      'sender_id': otherUserId,
      'recipient_id': currentUserId,
    });
  }

  // =========================================================
  // PAYMENTS
  // =========================================================

  Future<void> addPaymentTransaction({
    required String uid,
    required String title,
    required double amount,
    required String currency,
    required String method,
    required String status,
  }) async {
    await _supabase
        .from('thix_payments')
        .insert({
      'user_id': uid,
      'title': title,
      'amount': amount,
      'currency': currency,
      'method': method,
      'status': status,
      'tx_ref':
          'TX-${DateTime.now().millisecondsSinceEpoch}',
      'created_at':
          DateTime.now().toIso8601String(),
    });
  }

  Stream<List<Map<String, dynamic>>>
      streamPayments(String uid) {
    return _supabase
        .from('thix_payments')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .order(
          'created_at',
          ascending: false,
        )
        .map(
          (list) => list
              .cast<Map<String, dynamic>>(),
        );
  }

  // =========================================================
  // SECURITY
  // =========================================================

  Future<void> logSecurityEvent({
    required String uid,
    required String type,
    required String label,
  }) async {
    await _supabase
        .from('security_events')
        .insert({
      'user_id': uid,
      'type': type,
      'label': label,
      'created_at':
          DateTime.now().toIso8601String(),
    });
  }

  Stream<List<Map<String, dynamic>>>
      streamSecurityEvents(String uid) {
    return _supabase
        .from('security_events')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .order(
          'created_at',
          ascending: false,
        )
        .map(
          (list) => list
              .cast<Map<String, dynamic>>(),
        );
  }

  // =========================================================
  // APP USER MAPPING
  // =========================================================

  AppUser _mapToAppUser(
    Map<String, dynamic> row,
  ) {
    DateTime parseDate(
      dynamic value,
    ) {
      if (value is DateTime) {
        return value;
      }

      if (value is String) {
        return DateTime.tryParse(value) ??
            DateTime.now();
      }

      return DateTime.now();
    }

    List<Map<String, dynamic>>
        mapList(dynamic value) {
      if (value is List) {
        return value
            .map(
              (e) => e is Map
                  ? Map<String, dynamic>.from(
                      e,
                    )
                  : <String, dynamic>{},
            )
            .toList();
      }

      return [];
    }

    List<String> stringList(
      dynamic value,
    ) {
      if (value is List) {
        return value
            .whereType<String>()
            .toList();
      }

      return [];
    }

    int thixScore = 0;

    if (row['thix_score'] is num) {
      thixScore =
          (row['thix_score'] as num)
              .toInt();
    }

    return AppUser(
      id: row['id'] ?? '',
      thixId:
          row['thix_id'] ??
              'THIX-PENDING',
      thixChat:
          row['thix_chat'] ?? '',
      thixScore: thixScore,
      email: row['email'] ?? '',
      phone: row['phone'] ?? '',
      displayName:
          row['display_name'] ??
              'Utilisateur',
      accountType:
          (row['account_type'] ??
                      'personal') ==
                  'enterprise'
              ? AccountType.enterprise
              : AccountType.personal,
      photoUrl: row['photo_url'],
      bio: row['bio'],
      occupation: row['occupation'],
      countryOrOrigin:
          row['country_or_origin'],
      contactPhone:
          row['contact_phone'],
      maritalStatus:
          row['marital_status'],
      gender: row['gender'],
      profession:
          row['profession'],
      dateOfBirth:
          row['date_of_birth'],
      placeOfBirth:
          row['place_of_birth'],
      nationality:
          row['nationality'],
      address: row['address'],
      fatherName:
          row['father_name'],
      motherName:
          row['mother_name'],
      emergencyContactName:
          row[
              'emergency_contact_name'],
      emergencyContactPhone:
          row[
              'emergency_contact_phone'],
      emergencyContactRelation:
          row[
              'emergency_contact_relation'],
      registrationStatus:
          row['registration_status'],
      education:
          mapList(row['education']),
      experience:
          mapList(row['experience']),
      skills:
          mapList(row['skills']),
      enrollments:
          mapList(row['enrollments']),
      languages:
          stringList(row['languages']),
      biometricsEnabled:
          row['biometrics_enabled'] ??
              true,
      twoFaEnabled:
          row['two_fa_enabled'] ??
              false,
      createdAt: parseDate(
        row['created_at'],
      ),
      updatedAt: parseDate(
        row['updated_at'],
      ),
    );
  }
}
