// lib/presentation/chat/data_saver/data_usage_stats.dart
// Statistiques d'utilisation des données (messages, médias)

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataUsageStats extends StatefulWidget {
  const DataUsageStats({Key? key}) : super(key: key);

  @override
  State<DataUsageStats> createState() => _DataUsageStatsState();
}

class _DataUsageStatsState extends State<DataUsageStats> {
  int _totalSent = 0;
  int _totalReceived = 0;
  int _imagesSent = 0;
  int _videosSent = 0;
  int _audioSent = 0;

  static const String _keyTotalSent = 'data_sent_total';
  static const String _keyTotalReceived = 'data_received_total';
  static const String _keyImagesSent = 'data_sent_images';
  static const String _keyVideosSent = 'data_sent_videos';
  static const String _keyAudioSent = 'data_sent_audio';

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _totalSent = prefs.getInt(_keyTotalSent) ?? 0;
      _totalReceived = prefs.getInt(_keyTotalReceived) ?? 0;
      _imagesSent = prefs.getInt(_keyImagesSent) ?? 0;
      _videosSent = prefs.getInt(_keyVideosSent) ?? 0;
      _audioSent = prefs.getInt(_keyAudioSent) ?? 0;
    });
  }

  Future<void> _resetStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyTotalSent);
    await prefs.remove(_keyTotalReceived);
    await prefs.remove(_keyImagesSent);
    await prefs.remove(_keyVideosSent);
    await prefs.remove(_keyAudioSent);
    _loadStats();
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques données')),
      body: ListView(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _statRow('Total envoyé', _formatBytes(_totalSent)),
                  _statRow('Total reçu', _formatBytes(_totalReceived)),
                  const Divider(),
                  _statRow('Images envoyées', _formatBytes(_imagesSent)),
                  _statRow('Vidéos envoyées', _formatBytes(_videosSent)),
                  _statRow('Audio envoyé', _formatBytes(_audioSent)),
                ],
              ),
            ),
          ),
          Center(
            child: TextButton.icon(
              onPressed: _resetStats,
              icon: const Icon(Icons.delete),
              label: const Text('Réinitialiser les stats'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  // Méthode utilitaire pour enregistrer l'envoi (à appeler depuis le repository)
  static Future<void> recordSent(int bytes, {bool isImage = false, bool isVideo = false, bool isAudio = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final totalSent = (prefs.getInt(_keyTotalSent) ?? 0) + bytes;
    await prefs.setInt(_keyTotalSent, totalSent);
    if (isImage) {
      final images = (prefs.getInt(_keyImagesSent) ?? 0) + bytes;
      await prefs.setInt(_keyImagesSent, images);
    }
    if (isVideo) {
      final videos = (prefs.getInt(_keyVideosSent) ?? 0) + bytes;
      await prefs.setInt(_keyVideosSent, videos);
    }
    if (isAudio) {
      final audios = (prefs.getInt(_keyAudioSent) ?? 0) + bytes;
      await prefs.setInt(_keyAudioSent, audios);
    }
  }

  static Future<void> recordReceived(int bytes) async {
    final prefs = await SharedPreferences.getInstance();
    final totalReceived = (prefs.getInt(_keyTotalReceived) ?? 0) + bytes;
    await prefs.setInt(_keyTotalReceived, totalReceived);
  }
}
