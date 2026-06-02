import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/models/app_user.dart';
import 'package:thix_id/models/thix_profile.dart';
import 'package:thix_id/services/local_profile_store.dart';
import 'package:thix_id/services/supabase_safe_write.dart';
import 'package:thix_id/supabase/supabase_config.dart';

class ProfileService {
  static const String table = 'profiles';
  static const String formationsTable = 'formations';
  static const String experiencesTable = 'experiences';
  static const String emergencyContactsTable = 'contacts_urgence';
  static const String credentialsBucket = 'thix-credentials';

  static final Set<String> _disabledOptionalTables = <String>{};
  static bool _isMissingTableError(Object e) => e is PostgrestException && (e.code == 'PGRST205' || e.message.contains('Could not find the table'));
  static bool _isUnknownColumnError(Object e) {
    if (e is! PostgrestException) return false;
    return e.code == 'PGRST204' || e.code == '42703' || e.message.contains("Could not find the '") || e.message.toLowerCase().contains('does not exist');
  }

  final LocalProfileStore _local = LocalProfileStore();

  Future<void> _reloadSchemaCache() async {
    try {
      try {
        await SupabaseConfig.client.rpc('pgrst_schema_reload');
        debugPrint('ProfileService: requested PostgREST schema reload via RPC');
        return;
      } catch (e) {
        debugPrint('ProfileService: schema reload RPC failed (will try edge function) err=$e');
      }
      await SupabaseConfig.client.functions.invoke('pgrst_schema_reload', body: const {});
      debugPrint('ProfileService: requested PostgREST schema reload via edge function');
    } catch (e) {
      debugPrint('ProfileService: schema reload invoke failed err=$e');
      rethrow;
    }
  }

  String? _normalizeDateOrNull(String? raw) {
    if (raw == null) return null;
    final t = raw.trim();
    if (t.isEmpty) return null;
    if (RegExp(r'^\d{4}$').hasMatch(t)) return '$t-01-01';
    if (RegExp(r'^\d{4}-\d{2}$').hasMatch(t)) return '$t-01';
    return t;
  }

  Future<List<ThixProfile>> fetchPublicSuggestions({int limit = 12}) async {
    try {
      final res = await SupabaseConfig.client.from(table).select().order('updated_at', ascending: false).limit(limit);
      final rows = (res is List) ? res.cast<Map<String, dynamic>>() : const <Map<String, dynamic>>[];
      return rows.map(ThixProfile.fromPrivateRow).where((p) => p.thixId.trim().isNotEmpty).toList(growable: false);
    } catch (e) {
      debugPrint('ProfileService.fetchPublicSuggestions failed err=$e');
      return const [];
    }
  }

  Future<void> ensureProfileExists({required AppUser user}) async {
    final base = ThixProfile.fallback(userId: user.id, thixId: user.thixId, displayName: user.displayName);
    try {
      await SupabaseSafeWrite.upsert(
        client: SupabaseConfig.client,
        table: table,
        payload: {
          'id': base.userId,
          'thix_id': base.thixId,
          'avatar_url': user.photoUrl,
        },
        onUnknownColumn: _reloadSchemaCache,
      );
    } catch (e) {
      debugPrint('ProfileService.ensureProfileExists failed err=$e');
    }
  }

  Stream<ThixProfile?> streamMyProfile(String userId) {
    final controller = StreamController<ThixProfile?>.broadcast();
    Timer? pollTimer;
    var didEmitCached = false;
    var didRunBeforeFetch = false;

    Future<ThixProfile?> loadCached() => _local.loadMyProfile(userId);

    Future<void> emitCached() async {
      if (didEmitCached) return;
      didEmitCached = true;
      try {
        final cached = await loadCached();
        if (cached != null) controller.add(cached);
      } catch (e) {
        debugPrint('ProfileService.streamMyProfile emitCached failed userId=$userId err=$e');
      }
    }

    Future<void> emitLatest() async {
      try {
        if (!didRunBeforeFetch) {
          didRunBeforeFetch = true;
          await flushPendingProfileWrites(userId);
        }
        final row = await SupabaseService.selectSingle(table, filters: {'id': userId});
        if (row == null) {
          if (!didEmitCached) controller.add(null);
          return;
        }
        final cached = await loadCached();
        final merged = <String, dynamic>{...?(cached?.toPrivateRowJson()), ...row};
        final mapped = ThixProfile.fromPrivateRow(merged);
        controller.add(mapped);
        unawaited(() async {
          await _local.saveMyProfile(mapped);
          if (mapped.thixId.trim().isNotEmpty) await _local.savePublicProfile(mapped);
        }());
      } catch (e) {
        debugPrint('ProfileService.streamMyProfile emitLatest failed userId=$userId err=$e');
        if (!didEmitCached) controller.add(null);
      }
    }

    controller.onListen = () {
      unawaited(emitCached());
      unawaited(emitLatest());
      pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => unawaited(emitLatest()));
    };

    controller.onCancel = () {
      pollTimer?.cancel();
      controller.close();
    };

    return controller.stream;
  }

  Stream<ThixProfile?> streamPublicProfileByThixId(String thixId) {
    final normalized = thixId.trim().toUpperCase();
    return _streamSingleByEq(
      table,
      key: 'thix_id',
      value: normalized,
      mapper: ThixProfile.fromPrivateRow,
      loadCached: () => _local.loadPublicProfile(normalized),
      saveCached: (p) => _local.savePublicProfile(p),
    );
  }

  Stream<ThixProfile?> streamPublicProfileByUserId(String userId) {
    final uid = userId.trim();
    if (uid.isEmpty) return const Stream<ThixProfile?>.empty();
    return _streamSingleByEq(
      table,
      key: 'id',
      value: uid,
      mapper: ThixProfile.fromPrivateRow,
    );
  }

  Future<ThixProfile?> fetchPublicProfileByUserId(String userId) async {
    final uid = userId.trim();
    if (uid.isEmpty) return null;
    try {
      final row = await SupabaseService.selectSingle(table, filters: {'id': uid});
      if (row == null) return null;
      return ThixProfile.fromPrivateRow(row);
    } catch (e) {
      debugPrint('ProfileService.fetchPublicProfileByUserId failed uid=$uid err=$e');
      return null;
    }
  }

  Future<ThixProfile?> fetchPublicProfileByThixId(String thixId) async {
    final normalized = thixId.trim().toUpperCase();
    if (normalized.isEmpty) return null;
    try {
      final row = await SupabaseService.selectSingle(table, filters: {'thix_id': normalized});
      if (row == null) return null;
      final p = ThixProfile.fromPrivateRow(row);
      unawaited(_local.savePublicProfile(p));
      return p;
    } catch (e) {
      debugPrint('ProfileService.fetchPublicProfileByThixId failed err=$e');
      return _local.loadPublicProfile(normalized);
    }
  }

  Future<void> flushPendingProfileWrites(String userId) async {
    final patches = await _local.loadPendingPatches(userId);
    if (patches.isEmpty) return;

    final remaining = <Map<String, dynamic>>[];
    for (final patch in patches) {
      try {
        await SupabaseSafeWrite.update(
          client: SupabaseConfig.client,
          table: table,
          patch: patch,
          filters: {'id': userId},
          onUnknownColumn: _reloadSchemaCache,
        );
      } catch (e) {
        debugPrint('ProfileService.flushPendingProfileWrites failed userId=$userId err=$e');
        remaining.add(patch);
        final idx = patches.indexOf(patch);
        if (idx + 1 < patches.length) {
          remaining.addAll(patches.sublist(idx + 1));
        }
        break;
      }
    }
    await _local.setPendingPatches(userId, remaining);
  }

  Future<void> updateProfile({
    required String userId,
    String? displayName,
    String? fullName,
    String? photoUrl,
    String? bio,
    String? profession,
    String? occupation,
    String? countryOrOrigin,
    String? maritalStatus,
    String? gender,
    String? thixChat,
    String? contactPhone,
    String? dateOfBirth,
    String? placeOfBirth,
    String? nationality,
    String? address,
    String? fatherName,
    String? motherName,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelation,
    String? originProvince,
    String? originTerritory,
    String? originSector,
    String? residenceCountry,
    String? residenceProvince,
    String? residenceTerritory,
    String? residenceCity,
    String? residenceCommune,
    String? residenceQuarter,
    String? residenceAvenue,
    String? residenceNumber,
    List<Map<String, dynamic>>? emergencyContacts,
    String? height,
    String? weight,
    String? bloodGroup,
    bool? hasPhysicalDisability,
    String? physicalDisabilityDescription,
    String? nationalIdNumber,
    String? idDocumentType,
    String? idDocumentIssueDate,
    String? idDocumentExpiryDate,
    String? idDocumentIssuePlace,
    String? idDocumentFrontDocId,
    String? idDocumentBackDocId,
    String? idDocumentSelfieDocId,
    String? idVerificationStatus,
    String? competence,
    List<Map<String, dynamic>>? languagesDetailed,
    List<Map<String, dynamic>>? trainings,
    List<String>? languages,
    List<Map<String, dynamic>>? education,
    List<Map<String, dynamic>>? experience,
    List<Map<String, dynamic>>? skills,
    List<Map<String, dynamic>>? certifications,
    List<Map<String, dynamic>>? documents,
    List<Map<String, dynamic>>? contacts,
    ThixVisibilitySettings? visibility,
  }) async {
    final authedUid = SupabaseConfig.client.auth.currentUser?.id;
    final effectiveUserId = (authedUid != null && authedUid.trim().isNotEmpty) ? authedUid : userId;

    final data = <String, dynamic>{};
    void put(String k, Object? v) {
      if (v == null) return;
      if (v is String) {
        data[k] = v.trim();
      } else {
        data[k] = v;
      }
    }

    void putAliases(List<String> keys, Object? v) {
      for (final k in keys) {
        put(k, v);
      }
    }

    double? _parseDoubleOrNull(String? s) {
      if (s == null) return null;
      final t = s.trim().replaceAll(',', '.');
      if (t.isEmpty) return null;
      return double.tryParse(t);
    }

    put('full_name', fullName ?? displayName);
    put('avatar_url', photoUrl);
    put('bio', bio);
    put('profession', profession);
    put('occupation', occupation);
    put('country_or_origin', countryOrOrigin);
    put('marital_status', maritalStatus);
    put('gender', gender);
    put('thix_chat', thixChat);
    put('contact_phone', contactPhone);
    put('date_of_birth', dateOfBirth);
    put('place_of_birth', placeOfBirth);
    put('nationality', nationality);
    put('address', address);
    put('father_name', fatherName);
    put('mother_name', motherName);
    put('emergency_contact_name', emergencyContactName);
    put('emergency_contact_phone', emergencyContactPhone);
    put('emergency_contact_relation', emergencyContactRelation);
    putAliases(['origin_province'], originProvince);
    putAliases(['origin_territory'], originTerritory);
    putAliases(['origin_sector'], originSector);
    putAliases(['residence_country', 'pays_residence'], residenceCountry);
    putAliases(['residence_province', 'province_residence'], residenceProvince);
    putAliases(['residence_territory', 'territoire_residence'], residenceTerritory);
    putAliases(['residence_city', 'ville_residence'], residenceCity);
    putAliases(['residence_commune', 'commune_residence'], residenceCommune);
    putAliases(['residence_quarter', 'quartier_residence'], residenceQuarter);
    putAliases(['residence_avenue', 'avenue_residence'], residenceAvenue);
    putAliases(['residence_number', 'numero_residence'], residenceNumber);
    put('emergency_contacts', emergencyContacts);
    put('height', height);
    put('weight', weight);
    final heightNum = _parseDoubleOrNull(height);
    if (heightNum != null) data['height_cm'] = heightNum;
    final weightNum = _parseDoubleOrNull(weight);
    if (weightNum != null) data['weight_kg'] = weightNum;
    put('blood_group', bloodGroup);
    if (hasPhysicalDisability != null) data['has_physical_disability'] = hasPhysicalDisability;
    put('physical_disability_description', physicalDisabilityDescription);
    put('national_id_number', nationalIdNumber);
    put('id_document_type', idDocumentType);
    put('id_document_issue_date', idDocumentIssueDate);
    put('id_document_expiry_date', idDocumentExpiryDate);
    put('id_document_issue_place', idDocumentIssuePlace);
    put('id_document_front_doc_id', idDocumentFrontDocId);
    put('id_document_back_doc_id', idDocumentBackDocId);
    put('id_document_selfie_doc_id', idDocumentSelfieDocId);
    put('id_verification_status', idVerificationStatus);
    put('competence', competence);
    put('languages_detailed', languagesDetailed);
    put('trainings', trainings);
    put('languages', languages);
    put('education', education);
    put('experience', experience);
    put('skills', skills);
    put('certifications', certifications);
    put('documents', documents);
    put('contacts', contacts);
    if (visibility != null) data['visibility_settings'] = visibility.toJson();

    try {
      final cur = await _local.loadMyProfile(effectiveUserId);
      if (cur != null) {
        final next = ThixProfile.fromPrivateRow({...cur.toPrivateRowJson(), ...data});
        await _local.saveMyProfile(next);
        if (next.thixId.trim().isNotEmpty) await _local.savePublicProfile(next);
      }
    } catch (e) {
      debugPrint('ProfileService.updateProfile local optimistic update failed userId=$effectiveUserId err=$e');
    }

    try {
      await SupabaseSafeWrite.update(
        client: SupabaseConfig.client,
        table: table,
        patch: data,
        filters: {'id': effectiveUserId},
        onUnknownColumn: _reloadSchemaCache,
      );
      unawaited(flushPendingProfileWrites(effectiveUserId));

      if (trainings != null || education != null) {
        unawaited(() async {
          try {
            final cur = await _local.loadMyProfile(effectiveUserId);
            final merged = <Map<String, dynamic>>[];
            merged.addAll(trainings ?? cur?.trainings ?? const []);
            merged.addAll(education ?? cur?.education ?? const []);
            await replaceFormations(userId: effectiveUserId, entries: merged);
          } catch (e) {
            debugPrint('ProfileService: failed to mirror formations (merged) userId=$effectiveUserId err=$e');
          }
        }());
      }
      if (experience != null) unawaited(replaceExperiences(userId: effectiveUserId, entries: experience));
      if (emergencyContacts != null) unawaited(replaceEmergencyContacts(userId: effectiveUserId, entries: emergencyContacts));
    } catch (e) {
      await _local.enqueuePendingPatch(effectiveUserId, data);
      debugPrint('ProfileService.updateProfile queued patch for later userId=$effectiveUserId err=$e');
      return;
    }
  }

  Stream<List<Map<String, dynamic>>> streamFormations(String userId) => _streamListByEq(
        formationsTable,
        key: 'user_id',
        value: userId,
        orderBy: null,
      );

  Stream<List<Map<String, dynamic>>> streamExperiences(String userId) => _streamListByEq(
        experiencesTable,
        key: 'user_id',
        value: userId,
        orderBy: null,
      );

  Stream<List<Map<String, dynamic>>> streamEmergencyContacts(String userId) => _streamListByEq(
        emergencyContactsTable,
        key: 'user_id',
        value: userId,
        orderBy: null,
      );

  Future<void> replaceFormations({required String userId, required List<Map<String, dynamic>> entries}) async => _replaceLinked(
        tableName: formationsTable,
        userId: userId,
        entries: entries,
      );

  Future<void> replaceExperiences({required String userId, required List<Map<String, dynamic>> entries}) async => _replaceLinked(
        tableName: experiencesTable,
        userId: userId,
        entries: entries,
      );

  Future<void> replaceEmergencyContacts({required String userId, required List<Map<String, dynamic>> entries}) async => _replaceLinked(
        tableName: emergencyContactsTable,
        userId: userId,
        entries: entries,
      );

  Future<void> _replaceLinked({required String tableName, required String userId, required List<Map<String, dynamic>> entries}) async {
    final uid = SupabaseConfig.client.auth.currentUser?.id;
    if (uid == null) return;
    if (_disabledOptionalTables.contains(tableName)) return;
    if (uid != userId) return;

    try {
      await SupabaseConfig.client.from(tableName).delete().eq('user_id', userId);
      if (entries.isEmpty) return;

      if (tableName == formationsTable) {
        await _insertFormations(userId: userId, entries: entries);
        return;
      }
      if (tableName == experiencesTable) {
        await _insertExperiences(userId: userId, entries: entries);
        return;
      }

      final payload = <Map<String, dynamic>>[];
      for (var i = 0; i < entries.length; i++) {
        payload.add({'user_id': userId, 'payload': entries[i]});
      }
      await SupabaseConfig.client.from(tableName).insert(payload);
    } catch (e) {
      if (_isMissingTableError(e)) {
        _disabledOptionalTables.add(tableName);
        debugPrint('ProfileService: optional table missing ($tableName). Disabling linked writes for it.');
        return;
      }
      if (_isUnknownColumnError(e)) {
        debugPrint('ProfileService: linked table schema mismatch (ignored) table=$tableName err=$e');
        return;
      }
      debugPrint('ProfileService._replaceLinked failed table=$tableName userId=$userId err=$e');
    }
  }

  Map<String, dynamic> _trainingEntryToFormationRow(Map<String, dynamic> entry) {
    final title = (entry['title'] ?? entry['name'] ?? entry['degree'] ?? entry['level'] ?? '').toString().trim();
    var type = (entry['type'] ?? entry['category'] ?? '').toString().trim();
    final organizer = (entry['organizer'] ?? entry['organized_by'] ?? entry['provider'] ?? entry['institution'] ?? '').toString().trim();
    final startDate = _normalizeDateOrNull((entry['start_date'] ?? entry['start'] ?? entry['startYear'] ?? '').toString());
    final endDate = _normalizeDateOrNull((entry['end_date'] ?? entry['end'] ?? entry['endYear'] ?? '').toString());
    final duration = (entry['duration'] ?? entry['period'] ?? '').toString().trim();
    final skills = (entry['skills'] ?? entry['skills_acquired'] ?? entry['competences'] ?? '').toString().trim();

    if (type.isEmpty && entry.containsKey('institution')) type = 'Études';

    return {
      'title': title.isEmpty ? null : title,
      'name': title.isEmpty ? null : title,
      'type': type.isEmpty ? null : type,
      'organizer': organizer.isEmpty ? null : organizer,
      'organized_by': organizer.isEmpty ? null : organizer,
      'start_date': (startDate == null || startDate.isEmpty) ? null : startDate,
      'end_date': (endDate == null || endDate.isEmpty) ? null : endDate,
      'duration': duration.isEmpty ? null : duration,
      'skills': skills.isEmpty ? null : skills,
      'skills_acquired': skills.isEmpty ? null : skills,
      'description': (entry['description'] ?? entry['details'] ?? '').toString().trim().isEmpty ? null : (entry['description'] ?? entry['details']).toString().trim(),
      'verification_status': (entry['verification_status'] ?? entry['verificationStatus'] ?? 'pending').toString(),
      'evidence': entry['evidence'],
    }..removeWhere((k, v) => v == null);
  }

  Map<String, dynamic> _experienceEntryToRow(Map<String, dynamic> entry) {
    final companyName = (entry['company_name'] ?? entry['company'] ?? entry['employer'] ?? entry['org'] ?? '').toString().trim();
    final position = (entry['position'] ?? entry['title'] ?? entry['role'] ?? entry['poste'] ?? '').toString().trim();
    final startDate = _normalizeDateOrNull((entry['start_date'] ?? entry['start'] ?? entry['startYear'] ?? '').toString());
    final endDate = _normalizeDateOrNull((entry['end_date'] ?? entry['end'] ?? entry['endYear'] ?? '').toString());

    final missions = (entry['description'] ?? entry['missions'] ?? entry['tasks'] ?? '').toString().trim();
    final sector = (entry['sector'] ?? entry['industry'] ?? '').toString().trim();
    final city = (entry['city'] ?? '').toString().trim();
    final descParts = <String>[];
    if (missions.isNotEmpty) descParts.add(missions);
    if (sector.isNotEmpty) descParts.add('Secteur: $sector');
    if (city.isNotEmpty) descParts.add('Ville: $city');
    final description = descParts.join('\n');

    return {
      'company_name': companyName.isEmpty ? null : companyName,
      'company': companyName.isEmpty ? null : companyName,
      'employer': companyName.isEmpty ? null : companyName,
      'position': position.isEmpty ? null : position,
      'title': position.isEmpty ? null : position,
      'start_date': (startDate == null || startDate.isEmpty) ? null : startDate,
      'end_date': (endDate == null || endDate.isEmpty) ? null : endDate,
      'description': description.isEmpty ? null : description,
      'missions': missions.isEmpty ? null : missions,
      'sector': sector.isEmpty ? null : sector,
      'city': city.isEmpty ? null : city,
      'verification_status': (entry['verification_status'] ?? entry['verificationStatus'] ?? 'pending').toString(),
      'evidence': entry['evidence'],
    }..removeWhere((k, v) => v == null);
  }

  Future<void> _insertFormations({required String userId, required List<Map<String, dynamic>> entries}) async {
    final tableName = formationsTable;
    if (_disabledOptionalTables.contains(tableName)) return;

    final rows = entries
        .map(_trainingEntryToFormationRow)
        .where((m) => m.isNotEmpty)
        .map((m) => {'user_id': userId, ...m})
        .toList(growable: false);
    if (rows.isEmpty) return;

    try {
      await SupabaseSafeWrite.insertMany(client: SupabaseConfig.client, table: tableName, rows: rows, onUnknownColumn: _reloadSchemaCache);
    } catch (e) {
      if (_isUnknownColumnError(e)) {
        debugPrint('ProfileService: formations schema mismatch; falling back to payload rows. err=$e');
        final legacy = entries.map((m) => {'user_id': userId, 'payload': m}).toList(growable: false);
        await SupabaseSafeWrite.insertMany(client: SupabaseConfig.client, table: tableName, rows: legacy, onUnknownColumn: _reloadSchemaCache);
        return;
      }
      rethrow;
    }
  }

  Future<void> _insertExperiences({required String userId, required List<Map<String, dynamic>> entries}) async {
    final tableName = experiencesTable;
    if (_disabledOptionalTables.contains(tableName)) return;

    final rows = entries
        .map(_experienceEntryToRow)
        .where((m) => m.isNotEmpty)
        .map((m) => {'user_id': userId, ...m})
        .toList(growable: false);
    if (rows.isEmpty) return;

    try {
      await SupabaseSafeWrite.insertMany(client: SupabaseConfig.client, table: tableName, rows: rows, onUnknownColumn: _reloadSchemaCache);
    } catch (e) {
      if (_isUnknownColumnError(e)) {
        debugPrint('ProfileService: experiences schema mismatch; falling back to payload rows. err=$e');
        final legacy = entries.map((m) => {'user_id': userId, 'payload': m}).toList(growable: false);
        await SupabaseSafeWrite.insertMany(client: SupabaseConfig.client, table: tableName, rows: legacy, onUnknownColumn: _reloadSchemaCache);
        return;
      }
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> _streamListByEq(
    String table, {
    required String key,
    required String value,
    String? orderBy,
  }) {
    if (_disabledOptionalTables.contains(table)) return const Stream<List<Map<String, dynamic>>>.empty();
    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();
    Timer? pollTimer;
    var didEmitOnce = false;

    Future<void> emitLatest() async {
      try {
        final rows = await SupabaseService.select(
          table,
          filters: {key: value},
          orderBy: orderBy,
          ascending: true,
        );
        controller.add(rows);
        didEmitOnce = true;
      } catch (e) {
        if (_isMissingTableError(e)) {
          _disabledOptionalTables.add(table);
          debugPrint('ProfileService: optional table missing ($table). Disabling its stream.');
          if (!didEmitOnce) controller.add(const []);
          await controller.close();
          return;
        }
        debugPrint('ProfileService._streamListByEq emitLatest failed table=$table err=$e');
        if (!didEmitOnce) controller.add(const []);
      }
    }

    controller.onListen = () {
      unawaited(emitLatest());
      if (_disabledOptionalTables.contains(table)) return;
      pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => unawaited(emitLatest()));
    };

    controller.onCancel = () {
      pollTimer?.cancel();
      controller.close();
    };

    return controller.stream;
  }

  Future<void> updateVisibility({required String userId, required ThixVisibilitySettings visibility}) async {
    await updateProfile(userId: userId, visibility: visibility);
  }

  Future<String> activateAccountAfterPayment({
    required String userId,
    required String countryCode,
    required String displayName,
    required String txRef,
    required String method,
    required num amount,
    required String currency,
    String? photoUrl,
  }) async {
    try {
      final res = await SupabaseConfig.client.rpc(
        'thix_activate_account_after_payment',
        params: {
          'p_user_id': userId,
          'p_country_code': countryCode,
          'p_display_name': displayName,
          'p_photo_url': photoUrl,
          'p_method': method,
          'p_tx_ref': txRef,
          'p_amount': amount,
          'p_currency': currency,
        },
      );
      final thixId = (res is String) ? res : (res?.toString() ?? '').trim();
      if (thixId.isEmpty) throw Exception('Activation RPC returned empty THIX UID.');
      return thixId;
    } catch (e) {
      debugPrint('ProfileService.activateAccountAfterPayment failed uid=$userId err=$e');
      rethrow;
    }
  }

  Stream<T?> _streamSingleByEq<T>(
    String table, {
    required String key,
    required String value,
    required T Function(Map<String, dynamic>) mapper,
    Future<T?> Function()? loadCached,
    Future<void> Function(T value)? saveCached,
    Future<void> Function()? onBeforeFirstRemoteFetch,
  }) {
    final controller = StreamController<T?>.broadcast();
    Timer? pollTimer;
    var didEmitCached = false;
    var didRunBeforeFetch = false;

    Future<void> emitCached() async {
      if (loadCached == null || didEmitCached) return;
      didEmitCached = true;
      try {
        final cached = await loadCached();
        if (cached != null) controller.add(cached);
      } catch (e) {
        debugPrint('ProfileService.streamSingle emitCached failed table=$table err=$e');
      }
    }

    Future<void> emitLatest() async {
      try {
        if (!didRunBeforeFetch && onBeforeFirstRemoteFetch != null) {
          didRunBeforeFetch = true;
          await onBeforeFirstRemoteFetch();
        }
        final row = await SupabaseService.selectSingle(table, filters: {key: value});
        if (row == null) {
          controller.add(null);
          return;
        }
        final mapped = mapper(row);
        controller.add(mapped);
        if (saveCached != null) unawaited(saveCached(mapped));
      } catch (e) {
        debugPrint('ProfileService.streamSingle emitLatest failed table=$table err=$e');
        if (!didEmitCached) controller.add(null);
      }
    }

    controller.onListen = () {
      unawaited(emitCached());
      unawaited(emitLatest());
      pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => unawaited(emitLatest()));
    };

    controller.onCancel = () {
      pollTimer?.cancel();
      controller.close();
    };

    return controller.stream;
  }
}
