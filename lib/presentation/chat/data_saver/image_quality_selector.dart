// lib/presentation/chat/data_saver/image_quality_selector.dart
// Sélecteur de qualité d'image pour l'envoi (compression)

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ImageQuality {
  low,    // 50-100 Ko
  medium, // 200-300 Ko
  high,   // 500-800 Ko
  original,
}

class ImageQualitySelector extends StatefulWidget {
  const ImageQualitySelector({Key? key}) : super(key: key);

  @override
  State<ImageQualitySelector> createState() => _ImageQualitySelectorState();
}

class _ImageQualitySelectorState extends State<ImageQualitySelector> {
  ImageQuality _quality = ImageQuality.medium;

  static const String _key = 'image_quality';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_key) ?? 1;
    setState(() => _quality = ImageQuality.values[index]);
  }

  Future<void> _save(ImageQuality q) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, q.index);
    setState(() => _quality = q);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Qualité des images')),
      body: ListView(
        children: [
          RadioListTile<ImageQuality>(
            title: const Text('Basse (~50-100 Ko)'),
            subtitle: const Text('Économie maximale'),
            value: ImageQuality.low,
            groupValue: _quality,
            onChanged: (val) => _save(val!),
          ),
          RadioListTile<ImageQuality>(
            title: const Text('Moyenne (~200-300 Ko)'),
            subtitle: const Text('Bon compromis'),
            value: ImageQuality.medium,
            groupValue: _quality,
            onChanged: (val) => _save(val!),
          ),
          RadioListTile<ImageQuality>(
            title: const Text('Haute (~500-800 Ko)'),
            subtitle: const Text('Bonne qualité'),
            value: ImageQuality.high,
            groupValue: _quality,
            onChanged: (val) => _save(val!),
          ),
          RadioListTile<ImageQuality>(
            title: const Text('Originale (aucune compression)'),
            subtitle: const Text('Utilisation données mobiles élevée'),
            value: ImageQuality.original,
            groupValue: _quality,
            onChanged: (val) => _save(val!),
          ),
        ],
      ),
    );
  }

  // Méthode utilitaire pour obtenir le facteur de compression (0-100)
  static Future<int> getCompressionPercent() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_key) ?? 1;
    switch (ImageQuality.values[index]) {
      case ImageQuality.low: return 30;
      case ImageQuality.medium: return 60;
      case ImageQuality.high: return 85;
      case ImageQuality.original: return 100;
    }
  }
}
