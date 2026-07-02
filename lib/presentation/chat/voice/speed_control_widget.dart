// lib/presentation/chat/voice/speed_control_widget.dart
// Contrôle de vitesse de lecture (0.5x, 1x, 1.5x, 2x)

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class SpeedControlWidget extends StatelessWidget {
  final AudioPlayer player;
  final double currentSpeed;

  const SpeedControlWidget({
    Key? key,
    required this.player,
    required this.currentSpeed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    return PopupMenuButton<double>(
      icon: const Icon(Icons.speed),
      tooltip: 'Vitesse de lecture',
      initialValue: currentSpeed,
      onSelected: (speed) => player.setPlaybackRate(speed),
      itemBuilder: (context) => speeds.map((speed) {
        return PopupMenuItem(
          value: speed,
          child: Text('${speed}x'),
        );
      }).toList(),
    );
  }
}
