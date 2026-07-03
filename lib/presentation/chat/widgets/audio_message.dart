// lib/presentation/chat/widgets/audio_message.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class AudioMessage extends StatefulWidget {
  final String url;
  final int durationSeconds;

  const AudioMessage({Key? key, required this.url, required this.durationSeconds}) : super(key: key);

  @override
  State<AudioMessage> createState() => _AudioMessageState();
}

class _AudioMessageState extends State<AudioMessage> {
  // Uses video_player for audio playback support without audioplayers.
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

  Future<void> _playOrPause() async {
    if (!_isInitialized) return;
    if (_isPlaying) {
      await _controller.pause();
    } else {
      await _controller.play();
    }
  }

  Future<void> _seek(double seconds) async {
    if (!_isInitialized || !_controller.value.isInitialized) return;
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
          onPressed: _isInitialized ? _playOrPause : null,
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
