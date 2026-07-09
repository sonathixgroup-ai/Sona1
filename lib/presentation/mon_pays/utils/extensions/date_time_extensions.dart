// lib/presentation/mon_pays/utils/extensions/date_time_extensions.dart

import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  /// Formate une date en français (ex: 27 Mai 2025)
  String toFrenchDate() {
    return DateFormat('d MMMM yyyy', 'fr').format(this);
  }

  /// Formate avec l'heure (ex: 27 Mai 2025 à 14:30)
  String toFrenchDateTime() {
    return DateFormat('d MMMM yyyy à HH:mm', 'fr').format(this);
  }

  /// Retourne une chaîne relative (ex: "Il y a 3 jours")
  String toRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return 'Il y a $years an${years > 1 ? 's' : ''}';
    }
    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return 'Il y a $months mois';
    }
    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    }
    if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    }
    if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    }
    return 'À l\'instant';
  }

  /// Retourne le jour de la semaine en français
  String get weekDayFrench {
    const days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    return days[weekday - 1];
  }

  /// Retourne le mois en français
  String get monthFrench {
    const months = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre'
    ];
    return months[month - 1];
  }

  /// Vérifie si la date est aujourd'hui
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Vérifie si la date est dans le passé
  bool get isPast => isBefore(DateTime.now());

  /// Vérifie si la date est dans le futur
  bool get isFuture => isAfter(DateTime.now());
}
