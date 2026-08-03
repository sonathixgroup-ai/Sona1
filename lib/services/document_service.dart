// Ajoutez ces méthodes dans la classe DocumentService

/// Génère un ID unique côté DB et retourne le doc_id généré
Future<String> generateDocumentId(String uid) async {
  final res = await _db.rpc('generate_thix_doc_id', params: {'p_user_id': uid});
  return (res as String?) ?? 'THIX-DOC-ERR';
}

/// Upload simplifié : on ne demande plus docId / title manuels
Future<String> uploadPickedFileSimple({
  required String uid,
  required PlatformFile file,
  required String docType,
  DateTime? expiresAt,
  String? title,
}) async {
  if (file.size > 15 * 1024 * 1024) throw Exception('Fichier > 15 Mo');

  final generatedId = await generateDocumentId(uid);
  final safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  final path = 'users/$uid/\( generatedId/ \){DateTime.now().millisecondsSinceEpoch}_$safeName';

  await uploadPickedFileToBucket(
    bucketName: bucket,
    uid: uid,
    objectPath: path,
    file: file,
  );

  try {
    await _db.from(table).insert({
      'user_id': uid,
      'doc_id': generatedId,                 // on garde aussi dans doc_id pour compat
      'generated_doc_id': generatedId,
      'title': (title?.trim().isNotEmpty == true) ? title!.trim() : file.name,
      'doc_type': docType,
      'status': 'uploaded',
      'file_name': file.name,
      'mime_type': _mime(file),
      'size_bytes': file.size,
      'storage_path': path,
      'expires_at': expiresAt?.toIso8601String(),
      'country_code': generatedId.split('/').last,
    });
  } catch (e) {
    await _db.storage.from(bucket).remove([path]).catchError((_) => []);
    rethrow;
  }
  return generatedId;
}

/// Envoi d'un document à un ou plusieurs destinataires (par THIX ID)
Future<void> shareDocument({
  required String senderId,
  required String documentId,
  required List<String> recipientThixIds,
  String? subject,
  String? body,
  String? password,                 // en clair → on hash côté client ou via edge function
  DateTime? availableFrom,
  DateTime? autoDestructAt,
}) async {
  // Résoudre les user_id des destinataires si possible
  final profiles = await _db
      .from('profiles')
      .select('id, thix_id')
      .inFilter('thix_id', recipientThixIds.map((e) => e.trim().toUpperCase()).toList());

  final mapThixToUid = {
    for (final p in (profiles as List))
      (p['thix_id'] as String).toUpperCase(): p['id'] as String
  };

  final rows = <Map<String, dynamic>>[];
  for (final thix in recipientThixIds) {
    final clean = thix.trim().toUpperCase();
    if (clean.isEmpty) continue;
    rows.add({
      'document_id': documentId,
      'sender_id': senderId,
      'recipient_user_id': mapThixToUid[clean],
      'recipient_thix_id': clean,
      'subject': subject,
      'body': body,
      'password_hash': password != null && password.isNotEmpty
          ? _simpleHash(password) // ou mieux : bcrypt côté edge function
          : null,
      'available_from': availableFrom?.toIso8601String(),
      'auto_destruct_at': autoDestructAt?.toIso8601String(),
      'status': availableFrom != null && availableFrom.isAfter(DateTime.now())
          ? 'pending'
          : 'available',
    });
  }

  if (rows.isEmpty) throw Exception('Aucun destinataire valide');
  await _db.from('document_shares').insert(rows);
}

/// Stream des documents reçus
Stream<List<Map<String, dynamic>>> streamReceivedShares(String uid, String thixId) {
  return _db
      .from('document_shares')
      .stream(primaryKey: ['id'])
      .or('recipient_user_id.eq.\( uid,recipient_thix_id.eq. \){thixId.toUpperCase()}')
      .order('created_at', ascending: false)
      .map((rows) => rows.cast<Map<String, dynamic>>());
}

/// Enregistrer une capture d'écran
Future<void> reportScreenshot({
  required String shareId,
  required String capturedBy,
  String? storagePath,
}) async {
  await _db.from('document_share_screenshots').insert({
    'share_id': shareId,
    'captured_by': capturedBy,
    'storage_path': storagePath,
  });
  // Incrémenter le compteur
  await _db.rpc('increment_screenshot_count', params: {'p_share_id': shareId});
}

// Hash simple (à remplacer par une vraie solution sécurisée)
String _simpleHash(String input) {
  // Utilisez crypto package en production
  return input; // placeholder
}
