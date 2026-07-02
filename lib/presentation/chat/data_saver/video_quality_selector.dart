// lib/presentation/chat/data_saver/video_quality_selector.dart
// Sélecteur de qualité vidéo (résolution, bitrate)

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum VideoQuality {
  low,     // 480p, ~500 kbps
  medium,  // 720p, ~1.5 Mbps
  high,    // 1080p, ~3 Mbps
  original,
}

class VideoQualitySelector extends StatefulWidget {
  const VideoQualitySelector({Key? key}) : super(key: key);

  @override
  State<VideoQualitySelector> createState() => _VideoQualitySelectorState();
}

class _VideoQualitySelectorState extends State<VideoQualitySelector> {
  VideoQuality _quality = VideoQuality.medium;

  static const String _key = 'video_quality';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_key) ?? 1;
    setState(() => _quality = VideoQuality.values[index]);
  }

  Future<void> _save(VideoQuality q) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, q.index);
    setState(() => _quality = q);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Qualité des vidéos')),
      body: ListView(
        children: [
          RadioListTile<VideoQuality>(
            title: const Text('Basse (480p)'),
            subtitle: const Text('Jusqu’à 500 kbps'),
            value: VideoQuality.low,
            groupValue: _quality,
            onChanged: (val) => _save(val!),
          ),
          RadioListTile<VideoQuality>(
            title: const Text('Moyenne (720p)'),
            subtitle: const Text('~1.5 Mbps'),
            value: VideoQuality.medium,
            groupValue: _quality,
            onChanged: (val) => _save(val!),
          ),
          RadioListTile<VideoQuality>(
            title: const Text('Haute (1080p)'),
            subtitle: const Text('~3 Mbps'),
            value: VideoQuality.high,
            groupValue: _quality,
            onChanged: (val) => _save(val!),
          ),
          RadioListTile<VideoQuality>(
            title: const Text('Originale'),
            subtitle: const Text('Taille réelle'),
            value: VideoQuality.original,
            groupValue: _quality,
            onChanged: (val) => _save(val!),
          ),
        ],
      ),
    );
  }
}
