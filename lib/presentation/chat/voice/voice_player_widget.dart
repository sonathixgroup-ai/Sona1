// lib/presentation/chat/voice/voice_player_widget.dart
// Lecteur audio pour les messages vocaux (play/pause, slider)

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VoicePlayerWidget extends StatefulWidget {
  final String url;
  final int durationSeconds;

  const VoicePlayerWidget({Key? key, required this.url, required this.durationSeconds}) : super(key: key);

  @override
  State<VoicePlayerWidget> createState() => _VoicePlayerWidgetState();
}

class _VoicePlayerWidgetState extends State<VoicePlayerWidget> {
  late final VideoPlayerController _controller;
  bool _hasControllerListener = false;
  bool _isInitialized = false;
  bool _hasInitError = false;
  bool _isPlaying = false;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller.initialize().then((_) {
      if (!mounted) return;
      _controller.addListener(_syncState);
      _hasControllerListener = true;
      setState(() {
        _isInitialized = true;
        _position = _controller.value.position;
        _isPlaying = _controller.value.isPlaying;
      });
    }).catchError((_) {
      if (!mounted) return;
      setState(() {
        _hasInitError = true;
      });
    });
  }

  void _syncState() {
    if (!mounted) return;
    final value = _controller.value;
    setState(() {
      _isPlaying = value.isPlaying;
      _position = value.position;
    });
  }

  Future<void> _play() async {
    if (!_isInitialized) return;
    await _controller.play();
  }

  Future<void> _pause() async {
    if (!_isInitialized) return;
    await _controller.pause();
  }

  Future<void> _seek(double seconds) async {
    if (!_isInitialized) return;
    await _controller.seekTo(Duration(seconds: seconds.toInt()));
  }

  @override
  void dispose() {
    if (_hasControllerListener) {
      _controller.removeListener(_syncState);
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasInitError) {
      return const Text(
        'Lecture audio indisponible',
        style: TextStyle(fontSize: 12),
      );
    }

    final maxSeconds = widget.durationSeconds.toDouble();
    final currentSeconds = _position.inSeconds.toDouble().clamp(0.0, maxSeconds);

    return Row(
      children: [
        IconButton(
          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: _isInitialized ? (_isPlaying ? _pause : _play) : null,
        ),
        Expanded(
          child: Slider(
            value: currentSeconds,
            max: maxSeconds,
            onChanged: _isInitialized ? _seek : null,
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
