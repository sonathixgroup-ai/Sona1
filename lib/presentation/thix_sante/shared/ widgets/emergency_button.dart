// presentation/thix_sante/shared/widgets/emergency_button.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Bouton d'urgence (appel 15 en France, personnalisable)
class EmergencyButton extends StatelessWidget {
  final String phoneNumber;
  final String label;
  final Color? color;
  final VoidCallback? onPressed;

  const EmergencyButton({
    super.key,
    this.phoneNumber = '15',
    this.label = 'Appeler le 15',
    this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        onPressed: onPressed ?? _makeCall,
        icon: const Icon(Icons.emergency, size: 28),
        label: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Colors.redAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  void _makeCall() async {
    final url = 'tel:$phoneNumber';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      // Gérer l'erreur (par exemple, afficher un snackbar)
    }
  }
}
