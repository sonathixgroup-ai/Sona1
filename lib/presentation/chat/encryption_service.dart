import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart' as crypto;

class EncryptionService {
  static const int _saltLength = 16;
  static const int _ivLength = 16;
  static const int _hmacLength = 32;
  static const int _pbkdf2Iterations = 15000; // scalable: 15k = ~80ms mobile, anti-bruteforce pour 1M+ users
  static const int _keyLength = 32;
  static const String _prefix = 'ENCv1:'; // detection rapide + migration future

  // API gardée identique
  static String encryptMessage(String plainText, String password) {
    if (plainText.isEmpty) return '';
    if (password.isEmpty) throw Exception('Le mot de passe est requis');

    final salt = _secureRandomBytes(_saltLength);
    final iv = _secureRandomBytes(_ivLength);
    final key = _deriveKeyPBKDF2(password, salt);

    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'));
    final encrypted = encrypter.encrypt(plainText, iv: encrypt.IV(iv));

    // HMAC sur IV + ciphertext pour auth-then-encrypt
    final hmac = crypto.Hmac(crypto.sha256, key.bytes);
    final macData = Uint8List.fromList([...iv,...encrypted.bytes]);
    final mac = hmac.convert(macData).bytes;

    final combined = Uint8List.fromList([...salt,...iv,...encrypted.bytes,...mac]);
    return '$_prefix${base64.encode(combined)}';
  }

  static String decryptMessage(String cipherTextBase64, String password) {
    if (cipherTextBase64.isEmpty) return '';
    if (password.isEmpty) throw Exception('Le mot de passe est requis');

    try {
      String b64 = cipherTextBase64;
      if (b64.startsWith(_prefix)) b64 = b64.substring(_prefix.length);
      // compat ancien format sans prefix
      b64 = b64.replaceAll('🔒', '').trim();

      final combined = base64.decode(b64);
      if (combined.length < _saltLength + _ivLength + _hmacLength + 1) throw Exception('Message trop court');

      final salt = combined.sublist(0, _saltLength);
      final iv = combined.sublist(_saltLength, _saltLength + _ivLength);
      final cipherEnd = combined.length - _hmacLength;
      final ciphertext = combined.sublist(_saltLength + _ivLength, cipherEnd);
      final macReceived = combined.sublist(cipherEnd);

      final key = _deriveKeyPBKDF2(password, Uint8List.fromList(salt));

      // verify HMAC constant-time
      final hmac = crypto.Hmac(crypto.sha256, key.bytes);
      final macExpected = hmac.convert(Uint8List.fromList([...iv,...ciphertext])).bytes;
      if (!_constantTimeEquals(macReceived, macExpected)) throw Exception('Intégrité compromise');

      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'));
      final decrypted = encrypter.decrypt(encrypt.Encrypted(Uint8List.fromList(ciphertext)), iv: encrypt.IV(Uint8List.fromList(iv)));
      return decrypted;
    } catch (e) {
      // ne pas leak la raison exacte en prod
      throw Exception('Mot de passe incorrect ou message corrompu');
    }
  }

  // Detection scalable: prefix + longueur base64
  static bool isEncrypted(String content) {
    if (content.isEmpty) return false;
    final t = content.trim();
    if (t.startsWith(_prefix)) return true;
    if (t.startsWith('🔒')) return true;
    // ancien format: base64 long sans espace
    if (t.length > 40 &&!t.contains(' ') && _isBase64(t)) return true;
    return false;
  }

  // PBKDF2-HMAC-SHA256
  static encrypt.Key _deriveKeyPBKDF2(String password, Uint8List salt) {
    final pwdBytes = Uint8List.fromList(utf8.encode(password));
    final block = Uint8List(_keyLength);
    var u = Uint8List.fromList([...salt, 0, 0, 0, 1]);
    var hmac = crypto.Hmac(crypto.sha256, pwdBytes);
    var result = hmac.convert(u).bytes;
    var temp = Uint8List.fromList(result);
    for (int i = 1; i < _pbkdf2Iterations; i++) {
      hmac = crypto.Hmac(crypto.sha256, pwdBytes);
      result = hmac.convert(temp).bytes;
      temp = Uint8List.fromList(result);
      for (int j = 0; j < _keyLength; j++) block[j] ^= temp[j % temp.length];
      if (i == 1) block.setAll(0, result);
    }
    // Si iter=1 cas, sinon on a déjà XOR
    if (_pbkdf2Iterations == 1) return encrypt.Key(Uint8List.fromList(result.sublist(0, _keyLength)));
    // Pour 15k iter, on refait propre: implémentation simple mais constante
    return _pbkdf2Simple(pwdBytes, salt);
  }

  // Implémentation PBKDF2 simple, sûre et lisible pour millions users
  static encrypt.Key _pbkdf2Simple(Uint8List password, Uint8List salt) {
    final hLen = 32;
    final l = (_keyLength / hLen).ceil();
    final dk = Uint8List(_keyLength);
    for (int i = 1; i <= l; i++) {
      final block = _f(password, salt, _pbkdf2Iterations, i);
      final offset = (i - 1) * hLen;
      final len = min(hLen, _keyLength - offset);
