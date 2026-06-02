import 'package:flutter/material.dart';

/// Widget pour le bouton de fin d'appel
class HangupButton extends StatelessWidget {
  final VoidCallback onHangup;
  final String? tooltip;
  final bool isEnabled;

  const HangupButton({
    required this.onHangup,
    this.tooltip,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? 'Terminer l\'appel',
      child: FloatingActionButton(
        onPressed: isEnabled ? onHangup : null,
        backgroundColor: isEnabled ? Colors.red : Colors.red[200],
        child: const Icon(
          Icons.call_end,
          color: Colors.white,
        ),
      ),
    );
  }
}
