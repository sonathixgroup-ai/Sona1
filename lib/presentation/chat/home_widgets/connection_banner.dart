// lib/presentation/chat/home_widgets/connection_banner.dart
// Bannière affichée en haut de l'écran en cas de perte de connexion

import 'package:flutter/material.dart';

enum ConnectionStatus {
  online,
  offline,
  reconnecting,
}

class ConnectionBanner extends StatelessWidget {
  final ConnectionStatus status;

  const ConnectionBanner({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (status == ConnectionStatus.online) return const SizedBox.shrink();

    String message;
    Color backgroundColor;
    IconData icon;

    switch (status) {
      case ConnectionStatus.offline:
        message = 'Aucune connexion Internet. Les messages seront envoyés plus tard.';
        backgroundColor = Colors.red;
        icon = Icons.wifi_off;
        break;
      case ConnectionStatus.reconnecting:
        message = 'Reconnexion en cours...';
        backgroundColor = Colors.orange;
        icon = Icons.sync;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
