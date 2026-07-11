import 'package:flutter/material.dart';
import 'package:flutter_audio_waveforms/flutter_audio_waveforms.dart';

/// Widget de visualisation d'onde sonore (waveform) avec barres de progression.
class AudioWaveformWidget extends StatefulWidget {
  final String? audioUrl;
  final String? filePath;
  final Color waveformColor;
  final Color progressColor;
  final double height;
  final double width;
  final int numberOfBars;
  final double progress;

  const AudioWaveformWidget({
    super.key,
    this.audioUrl,
    this.filePath,
    this.waveformColor = Colors.blue,
    this.progressColor = Colors.green,
    this.height = 48,
    this.width = double.infinity,
    this.numberOfBars = 40,
    this.progress = 0.0,
  }) : assert(
         audioUrl != null || filePath != null,
         'audioUrl or filePath must be provided',
       );

  @override
  State<AudioWaveformWidget> createState() => _AudioWaveformWidgetState();
}

class _AudioWaveformWidgetState extends State<AudioWaveformWidget> {
  final PlayerController _controller = PlayerController();
  bool _isLoading = true;
  bool _hasError = false;

  static const gold = Color(0xFFE3B23C);
  static const mutedText = Color(0xFF6B7690);

  @override
  void initState() {
    super.initState();
    _loadWaveform();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadWaveform() async {
    setState(() => _isLoading = true);
    try {
      if (widget.audioUrl != null) {
        await _controller.preparePlayer(
          widget.audioUrl!,
          noOfSamples: widget.numberOfBars,
        );
      } else if (widget.filePath != null) {
        await _controller.preparePlayerFromFile(
          widget.filePath!,
          noOfSamples: widget.numberOfBars,
        );
      }
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Erreur chargement waveform: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }
    if (_hasError) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            'Impossible de charger l\'onde sonore',
            style: TextStyle(fontSize: 11, color: mutedText, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: AudioFileWaveforms(
        controller: _controller,
        size: Size(widget.width, widget.height),
        playerWaveStyle: PlayerWaveStyle(
          fixedWaveColor: widget.waveformColor.withOpacity(0.3),
          liveWaveColor: widget.progressColor,
          scaleFactor: 0.8,
          showSeekLine: true,
          seekLineColor: gold,
          seekLineWidth: 2,
          showDurationLabel: false,
        ),
        enableScrolling: false,
        onCurrentPosition: (position) {},
      ),
    );
  }

  Future<void> play() async => await _controller.startPlayer();
  Future<void> pause() async => await _controller.pausePlayer();
  Future<void> stop() async => await _controller.stopPlayer();
  Future<void> seekTo(double progress) async {
    final duration = await _controller.getDuration();
    if (duration != null) {
      final position = Duration(milliseconds: (duration.inMilliseconds * progress).round());
      await _controller.seekTo(position);
    }
  }
}

/// Widget d'onde simplifié pour les miniatures dans une bulle.
class MiniAudioWaveform extends StatelessWidget {
  final List<double>? waveformData;
  final double progress;
  final Color color;
  final double height;
  final int barCount;

  const MiniAudioWaveform({
    super.key,
    required this.waveformData,
    required this.progress,
    required this.color,
    this.height = 24,
    this.barCount = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (waveformData == null || waveformData!.isEmpty) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Center(child: Text('🎵 Audio', style: TextStyle(fontSize: 11, color: Colors.grey))),
      );
    }
    final data = waveformData!;
    final progressIndex = (data.length * progress).floor();
    return SizedBox(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(barCount, (index) {
          final value = data[index % data.length];
          final barHeight = (value * height).clamp(2.0, height);
          final isProgress = index <= progressIndex;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: Container(
              width: 3,
              height: barHeight,
              decoration: BoxDecoration(
                color: isProgress ? color : color.withOpacity(0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}
