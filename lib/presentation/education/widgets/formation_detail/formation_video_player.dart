// lib/presentation/education/widgets/formation_detail/formation_video_player.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/video.dart';

class FormationVideoPlayer extends StatefulWidget {
  final Video video;
  final Function(double)? onProgress;
  final VoidCallback? onComplete;

  const FormationVideoPlayer({
    super.key,
    required this.video,
    this.onProgress,
    this.onComplete,
  });

  @override
  State<FormationVideoPlayer> createState() => _FormationVideoPlayerState();
}

class _FormationVideoPlayerState extends State<FormationVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _hasCompleted = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.video.url))
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
          _duration = _controller.value.duration;
        });
        // Restaurer la position (optionnel)
        _controller.addListener(() {
          setState(() {
            _position = _controller.value.position;
            final progress = _duration.inSeconds > 0
                ? _position.inSeconds / _duration.inSeconds
                : 0.0;
            widget.onProgress?.call(progress.clamp(0.0, 1.0));
            // Détection de la fin de la vidéo
            if (progress >= 0.95 && !_hasCompleted) {
              _hasCompleted = true;
              widget.onComplete?.call();
            }
          });
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
      }
    });
  }

  void _seekTo(Duration position) {
    _controller.seekTo(position);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F7FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A1F44).withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Lecteur vidéo
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: GestureDetector(
              onTap: _togglePlayPause,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(_controller),
                  // Bouton play/pause central (quand en pause)
                  if (!_controller.value.isPlaying)
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  // Barre de progression
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: VideoProgressIndicator(
                      _controller,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: Color(0xFF2D6CDF),
                        bufferedColor: Colors.grey,
                        backgroundColor: Colors.white38,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Contrôles
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                IconButton(
                  onPressed: _togglePlayPause,
                  icon: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: VideoProgressIndicator(
                    _controller,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Color(0xFF2D6CDF),
                      bufferedColor: Colors.grey,
                      backgroundColor: Colors.white38,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_duration.inMinutes}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                IconButton(
                  onPressed: () {
                    _controller.setVolume(_controller.value.volume == 0 ? 1 : 0);
                  },
                  icon: Icon(
                    _controller.value.volume == 0
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // Plein écran (à implémenter avec un package)
                  },
                  icon: const Icon(
                    Icons.fullscreen_rounded,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
