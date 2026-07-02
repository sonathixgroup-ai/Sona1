// lib/presentation/chat/security_advanced/secret_chat.dart
// Mode de discussion secrète (chiffrement de bout en bout, pas de serveur)

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class SecretChatManager {
  // Générer une clé éphémère (diffie-hellman simplifié, ici on utilise RSA-like)
  static String generateSecretKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64.encode(bytes);
  }

  static String encryptMessage(String message, String keyBase64) {
    final key = encrypt.Key.fromBase64(keyBase64);
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encrypt(message, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  static String decryptMessage(String data, String keyBase64) {
    final parts = data.split(':');
    if (parts.length != 2) throw Exception('Invalid format');
    final iv = encrypt.IV.fromBase64(parts[0]);
    final encrypted = encrypt.Encrypted.fromBase64(parts[1]);
    final key = encrypt.Key.fromBase64(keyBase64);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    return encrypter.decrypt(encrypted, iv: iv);
  }

  static void startSecretChat(BuildContext context, String peerId) {
    // Générer et échanger les clés via un canal sécurisé (ex: signalement hors ligne)
    // Ici on navigue vers un écran de chat secret
    Navigator.pushNamed(context, '/secret_chat', arguments: peerId);
  }
}
