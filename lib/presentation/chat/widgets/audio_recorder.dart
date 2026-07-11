import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/chat/audio_service.dart';

/// Widget d'enregistrement audio avec appui long, timer et annulation par glissement.
/// Nécessite une instance de [AudioService] passée en paramètre.
class AudioRecorderWidget extends StatefulWidget {
  final AudioService audioService;
  final void Function(String filePath, int durationSeconds)? onRecordingComplete;
  final VoidCallback? onRecordingCanceled;
  final void Function(bool isRecording)? onRecordingStateChanged;
  final int maxDuration; // en secondes
  final double buttonSize;

  const AudioRecorderWidget({
    super.key,
    required this.audioService,
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
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startRecording() async {
    if (_isRecording) return;
    try {
      await widget.audioService.startRecording();
      setState(() {
        _isRecording = true;
        _currentDuration = 0;
        _slideOffset = 0.0;
        _isCanceling = false;
      });
      widget.onRecordingStateChanged?.call(true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _currentDuration++);
        if (_currentDuration >= widget.maxDuration) {
          _completeRecording();
        }
      });
    } catch (e) {
      debugPrint('❌ Erreur startRecording: $e');
    }
  }

  void _completeRecording() async {
    if (!_isRecording) return;
    _timer?.cancel();
    _timer = null;
    setState(() {
      _isRecording = false;
      _isUploading = true;
    });
    widget.onRecordingStateChanged?.call(false);

    final filePath = await widget.audioService.stopRecording();
    if (filePath != null) {
      final duration = widget.audioService.currentRecordingDuration;
      widget.onRecordingComplete?.call(filePath, duration);
    } else {
      setState(() => _isUploading = false);
      widget.onRecordingCanceled?.call();
    }
  }

  void _cancelRecording() async {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _isRecording = false;
      _isCanceling = true;
    });
    widget.onRecordingStateChanged?.call(false);
    await widget.audioService.cancelRecording();
    widget.onRecordingCanceled?.call();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _isCanceling = false);
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remaining.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFE3B23C);
    const navyDeep = Color(0xFF0A1F44);
    const danger = Color(0xFFD64545);

    if (_isCanceling) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isRecording || _isUploading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: navyDeep,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) => Container(
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
                    ),
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
                      child: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                    ),
                ],
              ),
            ),
          if (!_isUploading)
            GestureDetector(
              onLongPress: _startRecording,
              onLongPressUp: _completeRecording,
              onPanUpdate: (details) {
                if (_isRecording) {
                  setState(() => _slideOffset = (details.delta.dx + _slideOffset).clamp(-100.0, 0.0));
                  if (_slideOffset <= -80) _cancelRecording();
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
                        color: (isActive ? danger : gold).withOpacity(0.15),
                        border: Border.all(color: color, width: 3),
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
}
