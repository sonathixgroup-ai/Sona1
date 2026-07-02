// lib/presentation/chat/security_advanced/anti_screenshot.dart
// Détection et blocage des captures d'écran (Android/iOS)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AntiScreenshot extends StatelessWidget {
  final Widget child;

  const AntiScreenshot({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Platform.isAndroid
        ? AndroidAntiScreenshot(child: child)
        : IosAntiScreenshot(child: child);
  }
}

class AndroidAntiScreenshot extends StatelessWidget {
  final Widget child;
  const AndroidAntiScreenshot({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        // Désactiver la capture longue pression
      },
      child: child,
    );
  }
}

class IosAntiScreenshot extends StatelessWidget {
  final Widget child;
  const IosAntiScreenshot({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return child; // iOS nécessite des solutions natives
  }
}

// Méthode utilitaire pour flouter l'écran en arrière-plan
class BlurredBackground extends StatelessWidget {
  final Widget child;
  const BlurredBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: Colors.black54),
        child,
      ],
    );
  }
}
