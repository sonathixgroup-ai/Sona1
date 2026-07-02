// lib/presentation/chat/core/chat_utils.dart
// [PARTIE] Fonctions utilitaires

import 'package:intl/intl.dart';

class ChatUtils {
  // Formater l'heure d'affichage d'un message
  static String formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inDays == 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (diff.inDays == 1) {
      return 'Hier';
    } else if (diff.inDays < 7) {
      return DateFormat('EEEE').format(dateTime);
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  // Tronquer un texte
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // ID temporaire pour les messages optimistes
  static String generateTempId() {
    return 'temp_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch}';
  }

  // Vérifier si un message est confidentiel
  static bool isConfidentialMessage(Message message) {
    return message.type == ChatConstants.messageTypeConfidential;
  }

  // Vérifier si un message est éphémère
  static bool isEphemeralMessage(Message message) {
    return message.type == ChatConstants.messageTypeEphemeral;
  }

  // Obtenir les secondes restantes d'un message éphémère (s'il n'a pas été ouvert)
  static int getRemainingEphemeralSeconds(DateTime sentAt, int durationSeconds, {DateTime? openedAt}) {
    final start = openedAt ?? sentAt;
    final elapsed = DateTime.now().difference(start).inSeconds;
    return (durationSeconds - elapsed).clamp(0, durationSeconds);
  }

  // Formater la taille d'un fichier
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Hasher un code (simplifié – en prod utiliser sha256)
  static String hashCode(String code) {
    return code.hashCode.toString();
  }
}
