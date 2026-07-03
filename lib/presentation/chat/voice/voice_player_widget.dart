// lib/presentation/chat/voice/voice_player_widget.dart
// Lecteur audio pour les messages vocaux (play/pause, slider)

import 'package:flutter/material.dart';

class VoicePlayerWidget extends StatefulWidget {
  final String url;
  final int durationSeconds;

  const VoicePlayerWidget({Key? key, required this.url, required this.durationSeconds}) : super(key: key);

  @override
  State<VoicePlayerWidget> createState() => _VoicePlayerWidgetState();
}

class _VoicePlayerWidgetState extends State<VoicePlayerWidget> {
  bool _isPlaying = false;
  Duration _position = Duration.zero;

  void _play() {
    setState(() => _isPlaying = true);
  }

  void _pause() {
    setState(() => _isPlaying = false);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: _isPlaying ? _pause : _play,
        ),
        Expanded(
          child: Slider(
            value: _position.inSeconds.toDouble(),
            max: widget.durationSeconds.toDouble(),
            onChanged: (val) {
              setState(() => _position = Duration(seconds: val.toInt()));
            },
          ),
        ),
        Text(
          '${_position.inSeconds ~/ 60}:${(_position.inSeconds % 60).toString().padLeft(2, '0')} / ${widget.durationSeconds ~/ 60}:${(widget.durationSeconds % 60).toString().padLeft(2, '0')}',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
