// lib/presentation/chat/themes/font_size_selector.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontSizeSelector extends StatefulWidget {
  const FontSizeSelector({super.key});

  @override
  State<FontSizeSelector> createState() => _FontSizeSelectorState();
}

class _FontSizeSelectorState extends State<FontSizeSelector> {
  double _fontSize = 14;

  @override
  void initState() {
    super.initState();
    _loadFontSize();
  }

  Future<void> _loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getDouble('chat_font_size') ?? 14;
    });
  }

  Future<void> _saveFontSize(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('chat_font_size', value);
    setState(() => _fontSize = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Taille de police')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Aperçu', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Ceci est un exemple de texte',
                style: TextStyle(fontSize: _fontSize),
              ),
            ),
            const SizedBox(height: 24),
            Slider(
              value: _fontSize,
              min: 10,
              max: 24,
              divisions: 14,
              onChanged: _saveFontSize,
              activeColor: const Color(0xFFD4AF37),
            ),
            Text('Taille actuelle : ${_fontSize.toStringAsFixed(0)}px'),
          ],
        ),
      ),
    );
  }
}
