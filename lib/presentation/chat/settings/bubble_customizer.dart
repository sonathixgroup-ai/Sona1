// lib/presentation/chat/settings/bubble_customizer.dart
import 'package:flutter/material.dart';

class BubbleCustomizer extends StatefulWidget {
  const BubbleCustomizer({super.key});

  @override
  State<BubbleCustomizer> createState() => _BubbleCustomizerState();
}

class _BubbleCustomizerState extends State<BubbleCustomizer> {
  // Exemple : couleur et forme de bulle
  Color _bubbleColor = Colors.blue;
  double _borderRadius = 16.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personnalisation des bulles')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Aperçu
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _bubbleColor,
                borderRadius: BorderRadius.circular(_borderRadius),
              ),
              child: const Text(
                'Aperçu du message',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            // Sélecteur de couleur
            Row(
              children: [
                const Text('Couleur :'),
                const SizedBox(width: 12),
                DropdownButton<Color>(
                  value: _bubbleColor,
                  items: const [
                    DropdownMenuItem(value: Colors.blue, child: Text('Bleu')),
                    DropdownMenuItem(value: Colors.green, child: Text('Vert')),
                    DropdownMenuItem(value: Colors.orange, child: Text('Orange')),
                    DropdownMenuItem(value: Colors.purple, child: Text('Violet')),
                  ],
                  onChanged: (color) {
                    if (color != null) setState(() => _bubbleColor = color);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Curseur pour le rayon
            Row(
              children: [
                const Text('Arrondi :'),
                Expanded(
                  child: Slider(
                    value: _borderRadius,
                    min: 0,
                    max: 30,
                    onChanged: (val) => setState(() => _borderRadius = val),
                  ),
                ),
                Text('${_borderRadius.toInt()} px'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
