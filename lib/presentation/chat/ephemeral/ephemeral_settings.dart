// lib/presentation/chat/ephemeral/ephemeral_settings.dart
// Feuille de paramètres pour choisir la durée d'autodestruction

import 'package:flutter/material.dart';
import '../core/chat_constants.dart';

class EphemeralSettings extends StatefulWidget {
  final ValueChanged<int> onDurationSelected;

  const EphemeralSettings({Key? key, required this.onDurationSelected}) : super(key: key);

  @override
  State<EphemeralSettings> createState() => _EphemeralSettingsState();
}

class _EphemeralSettingsState extends State<EphemeralSettings> {
  int _selectedSeconds = ChatConstants.ephemeralDefaultSeconds;
  final List<int> _presetDurations = [5, 10, 30, 60, 300, 3600, 86400];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Durée d\'autodestruction',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presetDurations.map((seconds) {
              final label = _formatDuration(seconds);
              return FilterChip(
                label: Text(label),
                selected: _selectedSeconds == seconds,
                onSelected: (_) {
                  setState(() => _selectedSeconds = seconds);
                  widget.onDurationSelected(seconds);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('Personnalisé', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Secondes',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                    final seconds = int.tryParse(value);
                    if (seconds != null && seconds > 0 && seconds <= ChatConstants.ephemeralMaxSeconds) {
                      widget.onDurationSelected(seconds);
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  // Optionnel : valider le champ personnalisé
                },
                child: const Text('Appliquer'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '$seconds s';
    if (seconds < 3600) return '${seconds ~/ 60} min';
    if (seconds < 86400) return '${seconds ~/ 3600} h';
    return '${seconds ~/ 86400} j';
  }
}
