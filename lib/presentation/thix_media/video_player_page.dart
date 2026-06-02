import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerPage extends StatefulWidget {
  final String title;
  final String videoUrl;

  const VideoPlayerPage({super.key, required this.title, required this.videoUrl});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isError = false;
  bool _isFullscreen = false;
  double _progress = 0.0;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      _controller.addListener(_videoListener);
      await _controller.initialize();
      setState(() {
        _isInitialized = true;
        _duration = _controller.value.duration;
      });
      _controller.play();
    } catch (e) {
      setState(() {
        _isError = true;
      });
    }
  }

  void _videoListener() {
    if (!_controller.value.isInitialized) return;
    setState(() {
      _duration = _controller.value.duration;
      _position = _controller.value.position;
      _progress = _position.inMilliseconds / _duration.inMilliseconds;
    });
  }

  void _togglePlayPause() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  void _seekTo(double value) {
    final newPosition = Duration(milliseconds: (value * _duration.inMilliseconds).round());
    _controller.seekTo(newPosition);
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
    // Forcer l'orientation en mode plein écran
    if (_isFullscreen) {
      // Utiliser SystemChrome (nécessite services.dart)
      // Pour simplifier, on change juste le style de l'AppBar
      // Une meilleure solution: utiliser un widget FullscreenDialog ou un package
      // Mais ici on simule avec un simple changement d'état
      // Dans une vraie implémentation, on utiliserait SystemChrome.setPreferredOrientations
    } else {
      // Retour aux orientations normales
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(_isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen),
            onPressed: _toggleFullscreen,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isError) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text('Impossible de charger la vidéo', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement de la vidéo...'),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(_controller),
                if (!_controller.value.isPlaying && _isInitialized)
                  GestureDetector(
                    onTap: _togglePlayPause,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow, size: 64, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              Slider(
                value: _progress,
                onChanged: (value) {
                  _seekTo(value);
                },
                min: 0,
                max: 1,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(_position)),
                  IconButton(
                    icon: Icon(
                      _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    ),
                    onPressed: _togglePlayPause,
                  ),
                  Text(_formatDuration(_duration)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
