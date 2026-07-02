// lib/presentation/chat/widgets/audio_message.dart
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioMessage extends StatefulWidget {
  final String url;
  final int durationSeconds;

  const AudioMessage({Key? key, required this.url, required this.durationSeconds}) : super(key: key);

  @override
  State<AudioMessage> createState() => _AudioMessageState();
}

class _AudioMessageState extends State<AudioMessage> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.onPositionChanged.listen((p) => setState(() => _position = p));
    _player.onPlayerComplete.listen((_) => setState(() => _isPlaying = false));
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: () async {
            if (_isPlaying) {
              await _player.pause();
            } else {
              await _player.play(UrlSource(widget.url));
            }
            setState(() => _isPlaying = !_isPlaying);
          },
        ),
        Expanded(
          child: Slider(
            value: _position.inSeconds.toDouble(),
            max: widget.durationSeconds.toDouble(),
            onChanged: (val) async {
              await _player.seek(Duration(seconds: val.toInt()));
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
