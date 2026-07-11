import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

/// Widget de lecture audio avec progression, durée et contrôle de vitesse.
class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final int? totalDuration; // secondes (optionnel)
  final Color? primaryColor;
  final Color? accentColor;
  final VoidCallback? onPlay;
  final VoidCallback? onComplete;
  final void Function(double progress)? onProgressChanged;

  const AudioPlayerWidget({
    super.key,
    required this.audioUrl,
    this.totalDuration,
    this.primaryColor,
    this.accentColor,
    this.onPlay,
    this.onComplete,
    this.onProgressChanged,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _player;
  bool _isPlaying = false;
  bool _isLoading = true;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _playbackRate = 1.0;
  final List<double> _playbackRates = [1.0, 1.5, 2.0];
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _stateSub;

  static const gold = Color(0xFFE3B23C);
  static const navy = Color(0xFF123B7A);
  static const navyDeep = Color(0xFF0A1F44);
  static const mutedText = Color(0xFF6B7690);

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initPlayer();
    _positionSub = _player.onPositionChanged.listen((pos) {
      if (mounted) {
        setState(() => _position = pos);
        final progress = _duration.inMilliseconds > 0
            ? pos.inMilliseconds / _duration.inMilliseconds
            : 0.0;
        widget.onProgressChanged?.call(progress);
      }
    });
    _durationSub = _player.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    });
    _stateSub = _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
        if (state == PlayerState.completed) {
          widget.onComplete?.call();
          _player.seek(Duration.zero);
        }
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _stateSub?.cancel();
    super.dispose();
  }

  Future<void> _initPlayer() async {
    setState(() => _isLoading = true);
    try {
      await _player.setSourceUrl(widget.audioUrl);
      final dur = await _player.getDuration();
      if (dur != null) setState(() => _duration = dur);
    } catch (e) {
      debugPrint('Erreur chargement audio: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _togglePlay() async {
    if (_isLoading) return;
    if (_isPlaying) {
      await _player.pause();
    } else {
      if (_position >= _duration && _duration.inMilliseconds > 0) {
        await _player.seek(Duration.zero);
      }
      await _player.resume();
      widget.onPlay?.call();
    }
  }

  void _changePlaybackRate() async {
    final currentIndex = _playbackRates.indexOf(_playbackRate);
    final nextIndex = (currentIndex + 1) % _playbackRates.length;
    setState(() => _playbackRate = _playbackRates[nextIndex]);
    await _player.setPlaybackRate(_playbackRate);
  }

  void _seekTo(double progress) {
    final position = Duration(milliseconds: (_duration.inMilliseconds * progress).round());
    _player.seek(position);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor ?? navy;
    final accentColor = widget.accentColor ?? gold;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isPlaying ? accentColor : primaryColor,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(
                      _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: accentColor,
                    inactiveTrackColor: Colors.grey[300],
                    thumbColor: accentColor,
                    overlayColor: accentColor.withOpacity(0.2),
                  ),
                  child: Slider(
                    value: _duration.inMilliseconds > 0
                        ? (_position.inMilliseconds / _duration.inMilliseconds)
                        : 0.0,
                    min: 0.0,
                    max: 1.0,
                    onChanged: _seekTo,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: const TextStyle(fontSize: 10, color: mutedText, fontFeatures: [FontFeature.tabularFigures()]),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _changePlaybackRate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: navyDeep.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${_playbackRate}x',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: navyDeep),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDuration(_duration),
                          style: const TextStyle(fontSize: 10, color: mutedText, fontFeatures: [FontFeature.tabularFigures()]),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
