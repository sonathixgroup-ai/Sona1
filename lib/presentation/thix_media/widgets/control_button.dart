import 'package:flutter/material.dart';

/// Widget pour un bouton de contrôle dans les appels vidéo
class ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final String? tooltip;
  final bool isEnabled;

  const ControlButton({
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.tooltip,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: FloatingActionButton(
        onPressed: isEnabled ? onPressed : null,
        backgroundColor: isEnabled
            ? (backgroundColor ?? Theme.of(context).primaryColor)
            : Colors.grey[400],
        child: Icon(
          icon,
          color: iconColor ?? Colors.white,
        ),
      ),
    );
  }
}
