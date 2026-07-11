import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget d'enregistrement audio avec appui long et timer.
/// Utilise [AudioService] pour l'enregistrement.
class AudioRecorderWidget extends StatefulWidget {
  /// Callback appelé lorsque l'enregistrement est terminé avec le chemin du fichier
  final void Function(String filePath, int durationSeconds)? onRecordingComplete;

  /// Callback appelé lorsque l'enregistrement est annulé
  final VoidCallback? onRecordingCanceled;

  /// Callback pour l'état d'enregistrement (true = en cours)
  final void Function(bool isRecording)? onRecordingStateChanged;

  /// Durée maximale d'enregistrement en secondes (défaut: 120s = 2min)
  final int maxDuration;

  /// Taille du bouton d'enregistrement
  final double buttonSize;

  const AudioRecorderWidget({
    super.key,
    this.onRecordingComplete,
    this.onRecordingCanceled,
    this.onRecordingStateChanged,
    this.maxDuration = 120,
    this.buttonSize = 56,
  });

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget>
    with TickerProviderStateMixin {
  bool _isRecording = false;
  bool _isUploading = false;
  int _currentDuration = 0;
  Timer? _timer;
  double _slideOffset = 0.0;
  bool _isCanceling = false;

  // Animation du pulse
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Animation du timer
  late AnimationController _timerController;
  late Animation<double> _timerAnimation;

  // Référence aux services (passés via le parent ou créés ici)
  // Pour cet exemple, on utilise un callback pour les actions

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
    _timerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _timerController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _timerController.dispose();
    super.dispose();
  }

  /// Démarre l'enregistrement (appelé par le parent)
  void startRecording() {
    if (_isRecording) return;
    setState(() {
      _isRecording = true;
      _currentDuration = 0;
      _slideOffset = 0.0;
      _isCanceling = false;
    });
    widget.onRecordingStateChanged?.call(true);

    // Démarrer le timer
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentDuration++;
      });
      if (_currentDuration >= widget.maxDuration) {
        _completeRecording();
      }
    });
  }

  /// Arrête et envoie l'enregistrement
  void _completeRecording() {
    if (!_isRecording) return;
    _timer?.cancel();
    _timer = null;
    setState(() {
      _isRecording = false;
      _isUploading = true;
    });
    widget.onRecordingStateChanged?.call(false);

    // Le parent doit fournir le chemin du fichier via un callback
    // Pour l'exemple, on simule un fichier
    // Dans la pratique, le parent appelle stopRecording() du service
  }

  /// Annule l'enregistrement
  void _cancelRecording() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _isRecording = false;
      _isCanceling = true;
    });
    widget.onRecordingStateChanged?.call(false);
    widget.onRecordingCanceled?.call();

    // Revenir à l'état initial après un court délai
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isCanceling = false);
      }
    });
  }

  /// Formate la durée en mm:ss
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Couleurs THIX ID
    const gold = Color(0xFFE3B23C);
    const navyDeep = Color(0xFF0A1F44);
    const danger = Color(0xFFD64545);

    if (_isCanceling) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timer d'enregistrement
          if (_isRecording || _isUploading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: navyDeep,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  // Point rouge clignotant
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: danger,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: danger.withOpacity(0.5 * _pulseAnimation.value),
                              blurRadius: 8,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDuration(_currentDuration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_isRecording)
                    GestureDetector(
                      onTap: _cancelRecording,
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ),
                ],
              ),
            ),

          // Bouton d'enregistrement
          if (!_isUploading)
            GestureDetector(
              onLongPress: startRecording,
              onLongPressUp: _completeRecording,
              onPanUpdate: (details) {
                if (_isRecording) {
                  // Glisser vers la gauche pour annuler (seuil de -80px)
                  setState(() {
                    _slideOffset = details.delta.dx.clamp(-100.0, 0.0);
                  });
                  if (_slideOffset <= -80) {
                    _cancelRecording();
                  }
                }
              },
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  final isActive = _isRecording;
                  final scale = isActive ? _pulseAnimation.value : 1.0;
                  final color = isActive ? danger : gold;

                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: widget.buttonSize,
                      height: widget.buttonSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive ? danger.withOpacity(0.15) : color.withOpacity(0.15),
                        border: Border.all(
                          color: color,
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        _isRecording ? Icons.mic : Icons.mic_none,
                        color: _isRecording ? danger : color,
                        size: widget.buttonSize * 0.45,
                      ),
                    ),
                  );
                },
              ),
            ),

          // Indicateur d'upload
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFFE3B23C),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Méthode pour définir l'état d'upload (à appeler par le parent)
  void setUploading(bool uploading) {
    if (mounted) {
      setState(() => _isUploading = uploading);
    }
  }
}
