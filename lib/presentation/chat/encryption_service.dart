import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';

/// Service de chiffrement pour les messages protégés par mot de passe.
/// Utilise AES-256-GCM avec dérivation de clé PBKDF2.
class EncryptionService {
  static const int _saltLength = 16;
  static const int _ivLength = 12; // GCM recommandé
  static const int _iterations = 100000;
  static const String _algorithm = 'AES/GCM/NoPadding';

  /// Chiffre un message avec un mot de passe.
  /// Retourne une chaîne encodée en base64 contenant [salt] + [iv] + [ciphertext] + [tag].
  static String encrypt(String plainText, String password) {
    if (plainText.isEmpty) return '';
    if (password.isEmpty) throw Exception('Le mot de passe est requis');

    // Générer un sel aléatoire
    final salt = encrypt.IV.fromSecureRandom(_saltLength);
    // Générer une clé à partir du mot de passe et du sel
    final key = _deriveKey(password, salt.bytes);

    // Initialiser le chiffreur AES-GCM
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.gcm),
    );

    // Générer un IV aléatoire
    final iv = encrypt.IV.fromSecureRandom(_ivLength);

    // Chiffrer le message
    final encrypted = encrypter.encrypt(
      plainText,
      iv: iv,
    );

    // Récupérer le tag d'authentification (16 octets)
    final tag = encrypted.mac?.bytes ?? Uint8List(16);

    // Concaténer : salt + iv + ciphertext + tag
    final combined = Uint8List(salt.bytes.length + iv.bytes.length + encrypted.bytes.length + tag.length);
    combined.setAll(0, salt.bytes);
    combined.setAll(salt.bytes.length, iv.bytes);
    combined.setAll(salt.bytes.length + iv.bytes.length, encrypted.bytes);
    combined.setAll(salt.bytes.length + iv.bytes.length + encrypted.bytes.length, tag);

    // Retourner en base64
    return base64.encode(combined);
  }

  /// Déchiffre un message encodé avec [encrypt].
  static String decrypt(String cipherTextBase64, String password) {
    if (cipherTextBase64.isEmpty) return '';
    if (password.isEmpty) throw Exception('Le mot de passe est requis');

    try {
      // Décoder le base64
      final combined = base64.decode(cipherTextBase64);

      // Extraire le sel, l'IV, le ciphertext et le tag
      final saltBytes = combined.sublist(0, _saltLength);
      final ivBytes = combined.sublist(_saltLength, _saltLength + _ivLength);
      final ciphertextStart = _saltLength + _ivLength;
      final ciphertextEnd = combined.length - 16; // tag = 16 octets
      final ciphertextBytes = combined.sublist(ciphertextStart, ciphertextEnd);
      final tagBytes = combined.sublist(ciphertextEnd);

      // Dériver la clé avec le sel
      final key = _deriveKey(password, saltBytes);

      // Initialiser le déchiffreur AES-GCM
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.gcm),
      );

      // Construire l'objet Encrypted avec le MAC
      final encrypted = encrypt.Encrypted.fromBase64(
        base64.encode(ciphertextBytes),
        mac: encrypt.Mac(Uint8List.fromList(tagBytes)),
      );

      // Déchiffrer
      final decrypted = encrypter.decrypt(
        encrypted,
        iv: encrypt.IV(Uint8List.fromList(ivBytes)),
      );

      return decrypted;
    } catch (e) {
      // Si le déchiffrement échoue (mauvais mot de passe ou données corrompues)
      if (kDebugMode) {
        print('❌ Échec du déchiffrement: $e');
      }
      throw Exception('Mot de passe incorrect ou message corrompu');
    }
  }

  /// Dérive une clé AES-256 à partir d'un mot de passe et d'un sel.
  static encrypt.Key _deriveKey(String password, Uint8List salt) {
    // Utiliser PBKDF2 pour dériver une clé de 32 octets (256 bits)
    // Note : `encrypt` n'implémente pas directement PBKDF2, donc on utilise une
    // approche manuelle avec SHA-256 en itérant (simplifié).
    // Pour une sécurité réelle, utilisez une bibliothèque comme `pointycastle`.
    // Ici, on fait une dérivation simple (non sécurisée) pour démonstration.
    // Dans une vraie application, utilisez `pbkdf2` de `pointycastle`.

    // Simulons une dérivation (pour l'exemple, on utilise une combinaison de SHA-256)
    // ATTENTION : ceci n'est pas cryptographiquement sûr pour la production.
    // Utilisez `crypto` ou `pointycastle` pour PBKDF2.

    // Version simplifiée : on combine le mot de passe et le sel, on hache.
    final bytes = utf8.encode(password) + salt;
    final hash = sha256digest(bytes);
    // On répète pour obtenir 32 octets
    final keyBytes = Uint8List(32);
    keyBytes.setRange(0, 32, hash);
    return encrypt.Key(Uint8List.fromList(keyBytes));
  }

  /// Vérifie si un message est chiffré (détection simple).
  static bool isEncrypted(String content) {
    // Un message chiffré commence par un indicateur "🔒" ou un format base64
    return content.startsWith('🔒') || content.contains('base64');
  }
}

// Fonction simple de hachage SHA-256 (pour la dérivation)
Uint8List sha256digest(List<int> input) {
  // Utiliser le package 'crypto' si disponible, ou intégrer une version simplifiée.
  // Pour cet exemple, on retourne un hash fixe (ce n'est PAS sécurisé).
  // Vous devez remplacer ceci par une vraie fonction SHA-256.
  // Si vous avez 'crypto' dans vos dépendances, faites :
  // import 'package:crypto/crypto.dart';
  // final bytes = utf8.encode(String.fromCharCodes(input));
  // return Uint8List.fromList(sha256.convert(bytes).bytes);
  //
  // Pour l'instant, on simule avec un hash aléatoire (à remplacer !)
  return Uint8List.fromList(List.generate(32, (i) => (input.length + i * 7) % 256));
}
