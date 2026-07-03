// lib/presentation/chat/widgets/audio_message.dart
import 'package:flutter/material.dart';

class AudioMessage extends StatefulWidget {
  final String url;
  final int durationSeconds;

  const AudioMessage({Key? key, required this.url, required this.durationSeconds}) : super(key: key);

  @override
  State<AudioMessage> createState() => _AudioMessageState();
}

class _AudioMessageState extends State<AudioMessage> {
  bool _isPlaying = false;
  Duration _position = Duration.zero;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: () {
            setState(() => _isPlaying = !_isPlaying);
          },
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
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }
}
