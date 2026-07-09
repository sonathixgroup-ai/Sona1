import 'package:flutter/material.dart';

class UserStatus {
  // Constantes de statut
  static const String online = 'online';
  static const String busy = 'busy';
  static const String away = 'away';
  static const String doNotDisturb = 'do_not_disturb';
  static const String offline = 'offline';

  // Liste de tous les statuts
  static const List<String> all = [
    online,
    busy,
    away,
    doNotDisturb,
    offline,
  ];

  // Obtenir le libellé affichable
  static String getLabel(String status) {
    switch (status) {
      case online:
        return 'En ligne';
      case busy:
        return 'Occupé';
      case away:
        return 'Absent';
      case doNotDisturb:
        return 'Ne pas déranger';
      case offline:
        return 'Hors ligne';
      default:
        return 'Inconnu';
    }
  }

  // Obtenir l'icône
  static IconData getIcon(String status) {
    switch (status) {
      case online:
        return Icons.circle;
      case busy:
        return Icons.do_not_disturb;
      case away:
        return Icons.timer;
      case doNotDisturb:
        return Icons.phone_android;
      case offline:
        return Icons.circle_outlined;
      default:
        return Icons.help_outline;
    }
  }

  // Obtenir la couleur
  static Color getColor(String status) {
    switch (status) {
      case online:
        return Colors.green;
      case busy:
        return Colors.orange;
      case away:
        return Colors.amber;
      case doNotDisturb:
        return Colors.red;
      case offline:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // Indicateur de présence (petit cercle)
  static Widget presenceIndicator(String status, {double size = 12}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: getColor(status),
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}
