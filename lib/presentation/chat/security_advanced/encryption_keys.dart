// lib/presentation/chat/security_advanced/encryption_keys.dart
// Gestion des clés de chiffrement (stockage sécurisé, rotation)

import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionKeys {
  static const String _keyStoreKey = 'user_master_key';
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Générer une clé maître aléatoire (256 bits)
  static Future<String> generateMasterKey() async {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final key = base64.encode(bytes);
    await _storage.write(key: _keyStoreKey, value: key);
    return key;
  }

  static Future<String?> getMasterKey() async {
    return await _storage.read(key: _keyStoreKey);
  }

  static Future<bool> hasMasterKey() async {
    return (await _storage.read(key: _keyStoreKey)) != null;
  }

  static Future<void> rotateMasterKey() async {
    await generateMasterKey(); // regénère et remplace
  }

  static Future<void> deleteMasterKey() async {
    await _storage.delete(key: _keyStoreKey);
  }
}
