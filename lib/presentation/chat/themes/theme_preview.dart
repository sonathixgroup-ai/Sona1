// lib/presentation/chat/themes/theme_preview.dart
import 'package:flutter/material.dart';

class ThemePreview extends StatelessWidget {
  const ThemePreview({super.key});

  @override
  Widget build(BuildContext context) {
    // Exemple d’aperçu de thème (couleurs, polices, bulles)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aperçu du thème'),
        backgroundColor: const Color(0xFF0B1B3D),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Messages',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // Bulle envoyée
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Coucou ! Comment ça va ?',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Bulle reçue
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Super, et toi ?',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Couleurs du thème',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildColorSample(const Color(0xFF0B1B3D), 'Fond'),
                _buildColorSample(const Color(0xFFD4AF37), 'Accent'),
                _buildColorSample(Colors.green, 'En ligne'),
                _buildColorSample(Colors.grey, 'Hors ligne'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSample(Color color, String label) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black12),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
