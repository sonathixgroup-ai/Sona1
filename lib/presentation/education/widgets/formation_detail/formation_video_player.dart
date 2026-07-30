// lib/presentation/education/widgets/formation_detail/formation_video_player.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:thix_id/presentation/education/models/video.dart';

class _C {
  static const primary = Color(0xFF2D6CDF);
  static const bgDark = Color(0xFF0F172A);
  static const textWhite = Colors.white;
}

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

// Ajout de WidgetsBindingObserver pour gérer le cycle de vie de l'app
class _FormationVideoPlayerState extends State<FormationVideoPlayer> with WidgetsBindingObserver {
  late VideoPlayerController _controller;
  
  bool _isInitialized = false;
  bool _hasError = false;
  bool _hasCompleted = false;
  
  // Optimisation: Empêche de spammer Supabase
  double _lastReportedProgress = 0.0;
  
  // UI UX: Auto-hide controls
  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Écoute la mise en arrière-plan
    _initPlayer();
  }

  // Met la vidéo en pause si l'utilisateur quitte l'application
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_isInitialized && _controller.value.isPlaying) {
        _controller.pause();
        setState(() => _showControls = true);
      }
    }
  }

  Future<void> _initPlayer() async {
    try {
      // Sécurisation du parsing de l'URL
      final uri = Uri.tryParse(widget.video.url);
      if (uri == null) throw Exception('URL de la vidéo invalide');

      _controller = VideoPlayerController.networkUrl(uri);
      await _controller.initialize();
      
      if (mounted) {
        setState(() => _isInitialized = true);
        _startHideTimer();
        _controller.addListener(_videoListener);
      }
    } catch (e) {
      debugPrint('Erreur d\'initialisation vidéo : $e');
      if (mounted) setState(() => _hasError = true);
    }
  }

  void _videoListener() {
    if (!_controller.value.isInitialized) return;

    final duration = _controller.value.duration.inMilliseconds;
    final position = _controller.value.position.inMilliseconds;
    
    if (duration > 0) {
      final progress = position / duration;
      
      // 1. Détection de fin (à 95% pour être tolérant)
      if (progress >= 0.95 && !_hasCompleted) {
        _hasCompleted = true;
        widget.onComplete?.call();
      }

      // 2. Throttle (Limiteur) pour la base de données : 5% de progression minimum
      if ((progress - _lastReportedProgress).abs() > 0.05 || progress >= 0.95) {
        _lastReportedProgress = progress;
        widget.onProgress?.call(progress.clamp(0.0, 1.0));
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideTimer?.cancel();
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  // --- GESTION DES CONTRÔLES UI ---

  void _togglePlayPause() {
    if (_controller.value.isPlaying) {
      _controller.pause();
      _showControls = true;
      _hideTimer?.cancel();
    } else {
      _controller.play();
      _startHideTimer();
    }
    setState(() {}); // Met à jour l'icône Play/Pause principale
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    setState(() => _showControls = true);
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _onScreenTap() {
    if (_showControls) {
      setState(() => _showControls = false);
    } else {
      _startHideTimer();
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // --- CONSTRUCTION DE L'UI ---

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorState();
    }

    if (!_isInitialized) {
      return _buildLoadingState();
    }

    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: GestureDetector(
        onTap: _onScreenTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Lecteur Vidéo
            VideoPlayer(_controller),

            // 2. Calque assombri quand les contrôles sont visibles
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(color: Colors.black45),
            ),

            // 3. Bouton Play/Pause central
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                  child: Icon(
                    _controller.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),

            // 4. Barre de contrôles inférieure
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black87, Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                  child: ValueListenableBuilder<VideoPlayerValue>(
                    valueListenable: _controller,
                    builder: (context, value, child) {
                      return Row(
                        children: [
                          Text(_formatDuration(value.position), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 12),
                          
                          // Slider personnalisé pour un meilleur contrôle tactile
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 4.0,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
                                activeTrackColor: _C.primary,
                                inactiveTrackColor: Colors.white.withOpacity(0.2),
                                thumbColor: _C.primary,
                                overlayColor: _C.primary.withOpacity(0.2),
                              ),
                              child: Slider(
                                min: 0.0,
                                max: value.duration.inMilliseconds > 0 
                                    ? value.duration.inMilliseconds.toDouble() 
                                    : 1.0,
                                value: value.position.inMilliseconds.toDouble().clamp(
                                      0.0,
                                      value.duration.inMilliseconds > 0 
                                          ? value.duration.inMilliseconds.toDouble() 
                                          : 1.0,
                                    ),
                                onChangeStart: (_) {
                                  _hideTimer?.cancel();
                                  setState(() => _showControls = true);
                                },
                                onChanged: (newPosition) {
                                  _controller.seekTo(Duration(milliseconds: newPosition.toInt()));
                                },
                                onChangeEnd: (_) {
                                  _startHideTimer();
                                },
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 12),
                          Text(_formatDuration(value.duration), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(width: 8),
                          
                          // Gestion du volume
                          GestureDetector(
                            onTap: () {
                              _controller.setVolume(value.volume == 0 ? 1.0 : 0.0);
                              _startHideTimer();
                            },
                            child: Icon(
                              value.volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: _C.bgDark,
        child: Center(
          child: CircularProgressIndicator(color: _C.primary),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return const AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: _C.bgDark,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white54, size: 40),
              SizedBox(height: 12),
              Text(
                'Impossible de charger la vidéo',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
