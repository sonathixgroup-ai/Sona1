// lib/presentation/mon_pays/utils/mon_pays_icons.dart

import 'package:flutter/material.dart';
import 'mon_pays_colors.dart';

/// Centralisation des icônes utilisées dans le module Mon Pays
class MonPaysIcons {
  // Icônes pour les sections principales
  static const IconData authorities = Icons.person;
  static const IconData government = Icons.account_balance;
  static const IconData ministries = Icons.business_center;
  static const IconData agencies = Icons.account_balance;
  static const IconData history = Icons.history;
  static const IconData news = Icons.newspaper;
  static const IconData values = Icons.library_books;
  static const IconData videos = Icons.video_library;
  static const IconData documentaries = Icons.movie;
  static const IconData wanted = Icons.warning_amber;
  static const IconData citizens = Icons.people;
  static const IconData consultations = Icons.poll;
  static const IconData emergency = Icons.emergency_rounded;

  // Icônes pour les actions
  static const IconData add = Icons.add;
  static const IconData edit = Icons.edit;
  static const IconData delete = Icons.delete_outline;
  static const IconData refresh = Icons.refresh;
  static const IconData search = Icons.search;
  static const IconData close = Icons.close;
  static const IconData arrowForward = Icons.arrow_forward_ios;
  static const IconData arrowBack = Icons.arrow_back_ios;
  static const IconData menu = Icons.menu;

  // Icônes pour les rôles
  static const IconData admin = Icons.admin_panel_settings;
  static const IconData user = Icons.person_outline;
  static const IconData moderator = Icons.verified;

  // Icônes pour les statuts
  static const IconData active = Icons.check_circle;
  static const IconData inactive = Icons.cancel;
  static const IconData warning = Icons.warning_amber_rounded;

  // Icônes pour les valeurs & lois
  static const Map<String, IconData> lawsIcons = {
    'Constitution': Icons.gavel,
    'Institutions': Icons.account_balance,
    'Symboles Nationaux': Icons.flag,
    'Codes et Lois': Icons.book,
    'Droits du Citoyen': Icons.verified_user,
    'Devoirs du Citoyen': Icons.assignment,
    'Justice': Icons.scale,
    'Administration': Icons.business_center,
  };

  /// Retourne l'icône pour une catégorie de loi donnée
  static IconData getLawIcon(String category) {
    return lawsIcons[category] ?? Icons.library_books;
  }

  /// Retourne une icône colorée avec le style institutionnel
  static Widget iconWithColor(
    IconData icon, {
    double size = 24,
    Color? color,
    Color? backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor ?? MonPaysColors.primaryRed.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: size,
        color: color ?? MonPaysColors.primaryRed,
      ),
    );
  }
}
