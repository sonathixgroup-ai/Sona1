import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart' as crypto;

class EncryptionService {
  static const int _saltLength = 16;
  static const int _ivLength = 16;

  static String encryptMessage(String plainText, String password) {
    if (plainText.isEmpty) return '';
    if (password.isEmpty) throw Exception('Le mot de passe est requis');

    final salt = encrypt.IV.fromSecureRandom(_saltLength);
    final key = _deriveKey(password, salt.bytes);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final iv = encrypt.IV.fromSecureRandom(_ivLength);
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    final hmac = crypto.Hmac(crypto.sha256, key.bytes);
    final mac = hmac.convert(encrypted.bytes);

    final combined = Uint8List(salt.bytes.length + iv.bytes.length + encrypted.bytes.length + mac.bytes.length);
    combined.setAll(0, salt.bytes);
    combined.setAll(salt.bytes.length, iv.bytes);
    combined.setAll(salt.bytes.length + iv.bytes.length, encrypted.bytes);
    combined.setAll(salt.bytes.length + iv.bytes.length + encrypted.bytes.length, mac.bytes);
    return base64.encode(combined);
  }

  static String decryptMessage(String cipherTextBase64, String password) {
    if (cipherTextBase64.isEmpty) return '';
    if (password.isEmpty) throw Exception('Le mot de passe est requis');

    try {
      final combined = base64.decode(cipherTextBase64);
      final saltBytes = combined.sublist(0, _saltLength);
      final ivBytes = combined.sublist(_saltLength, _saltLength + _ivLength);
      final cipherStart = _saltLength + _ivLength;
      final cipherEnd = combined.length - 32;
      final ciphertextBytes = combined.sublist(cipherStart, cipherEnd);
      final macBytes = combined.sublist(cipherEnd);

      final key = _deriveKey(password, saltBytes);
      final hmac = crypto.Hmac(crypto.sha256, key.bytes);
      final expectedMac = hmac.convert(ciphertextBytes);
      if (!_compareBytes(macBytes, expectedMac.bytes)) {
        throw Exception('Intégrité du message compromise');
      }

      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
      final decrypted = encrypter.decrypt(
        encrypt.Encrypted.fromBase64(base64.encode(ciphertextBytes)),
        iv: encrypt.IV(Uint8List.fromList(ivBytes)),
      );
      return decrypted;
    } catch (e) {
      throw Exception('Mot de passe incorrect ou message corrompu');
    }
  }

  static bool _compareBytes(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static encrypt.Key _deriveKey(String password, Uint8List salt) {
    final bytes = utf8.encode(password) + salt;
    final digest = crypto.sha256.convert(bytes);
    final keyBytes = Uint8List(32);
    keyBytes.setRange(0, 32, digest.bytes);
    return encrypt.Key(Uint8List.fromList(keyBytes));
  }

  static bool isEncrypted(String content) {
    return content.startsWith('🔒') || content.contains('base64');
  }
}
