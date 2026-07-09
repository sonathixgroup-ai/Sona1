// lib/presentation/mon_pays/utils/extensions/context_extensions.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

extension ContextExtensions on BuildContext {
  /// Taille de l'écran
  Size get screenSize => MediaQuery.sizeOf(this);

  /// Largeur de l'écran
  double get screenWidth => screenSize.width;

  /// Hauteur de l'écran
  double get screenHeight => screenSize.height;

  /// Vérifie si l'écran est en mode paysage
  bool get isLandscape => screenWidth > screenHeight;

  /// Vérifie si l'appareil est un mobile (largeur < 600)
  bool get isMobile => screenWidth < 600;

  /// Vérifie si l'appareil est une tablette (largeur >= 600)
  bool get isTablet => screenWidth >= 600;

  /// Vérifie si le clavier est ouvert
  bool get isKeyboardOpen => MediaQuery.viewInsetsOf(this).bottom > 0;

  /// Affiche un snackbar
  void showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? Theme.of(this).primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Affiche un snackbar de succès
  void showSuccessSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.green);
  }

  /// Affiche un snackbar d'erreur
  void showErrorSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.red);
  }

  /// Navigue vers une page avec animation
  Future<T?> pushPage<T>(Widget page) {
    return Navigator.push<T>(
      this,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  /// Pop avec retour
  void pop([dynamic result]) => Navigator.pop(this, result);

  /// Vérifie le thème sombre
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Retourne la couleur du thème
  Color get primaryColor => Theme.of(this).primaryColor;

  /// Retourne la couleur de fond
  Color get backgroundColor => Theme.of(this).scaffoldBackgroundColor;

  /// Retourne la couleur du texte
  Color get textColor => Theme.of(this).textTheme.bodyLarge?.color ?? Colors.black;
}
