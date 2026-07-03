// lib/presentation/chat/data_saver/low_data_mode_toggle.dart
// Hub central du mode économie de données : accès aux sous-réglages

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data_saver_settings.dart';
import 'data_usage_stats.dart';
import 'image_quality_selector.dart';
import 'video_quality_selector.dart';
import 'media_auto_download.dart';

class LowDataModeToggle extends StatefulWidget {
  const LowDataModeToggle({Key? key}) : super(key: key);

  @override
  State<LowDataModeToggle> createState() => _LowDataModeToggleState();
}

class _LowDataModeToggleState extends State<LowDataModeToggle> {
  bool _isEnabled = false;
  static const String _keyEnabled = 'data_saver_enabled';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isEnabled = prefs.getBool(_keyEnabled) ?? false);
  }

  Future<void> _toggle(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, value);
    setState(() => _isEnabled = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mode économie de données')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Activer le mode économie de données'),
            subtitle: const Text('Réduit la consommation des médias sur le réseau mobile'),
            value: _isEnabled,
            onChanged: _toggle,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Réglages avancés'),
            subtitle: const Text('Taille des fichiers, compression automatique'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DataSaverSettings()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.image_outlined),
            title: const Text('Qualité des images'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ImageQualitySelector()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.videocam_outlined),
            title: const Text('Qualité des vidéos'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VideoQualitySelector()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Téléchargement automatique'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MediaAutoDownloadSettings()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.bar_chart_outlined),
            title: const Text('Statistiques d\'utilisation'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DataUsageStats()),
            ),
          ),
        ],
      ),
    );
  }
}
