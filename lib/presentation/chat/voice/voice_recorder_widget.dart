// lib/presentation/chat/voice/voice_recorder_widget.dart
// Widget d'enregistrement vocal (avec visualisation du niveau sonore)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class VoiceRecorderWidget extends StatefulWidget {
  final Function(File recordingFile, int durationSeconds) onRecordingComplete;

  const VoiceRecorderWidget({Key? key, required this.onRecordingComplete}) : super(key: key);

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _isPaused = false;
  int _recordDuration = 0;
  late String _filePath;
  double _amplitude = 0.0;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return;
    final dir = await getTemporaryDirectory();
    _filePath = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
  }

  Future<void> _startRecording() async {
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: _filePath,
    );
    setState(() {
      _isRecording = true;
      _recordDuration = 0;
    });
    _updateDuration();
    _updateAmplitude();
  }

  Future<void> _updateDuration() async {
    while (_isRecording && !_isPaused) {
      await Future.delayed(const Duration(seconds: 1));
      final duration = await _recorder.getDuration();
      if (mounted && duration != null) {
        setState(() => _recordDuration = duration.inSeconds);
      }
    }
  }

  Future<void> _updateAmplitude() async {
    while (_isRecording && !_isPaused) {
      await Future.delayed(const Duration(milliseconds: 100));
      final amp = await _recorder.getAmplitude();
      if (mounted) {
        setState(() => _amplitude = amp.current);
      }
    }
  }

  Future<void> _pauseRecording() async {
    await _recorder.pause();
    setState(() => _isPaused = true);
  }

  Future<void> _resumeRecording() async {
    await _recorder.resume();
    setState(() => _isPaused = false);
    _updateDuration();
    _updateAmplitude();
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    setState(() => _isRecording = false);
    if (path != null && _recordDuration > 0) {
      widget.onRecordingComplete(File(path), _recordDuration);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: _amplitude / 100,
            backgroundColor: Colors.grey[300],
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            '${_recordDuration ~/ 60}:${(_recordDuration % 60).toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isRecording && !_isPaused)
                IconButton(
                  icon: const Icon(Icons.pause, size: 48),
                  onPressed: _pauseRecording,
                ),
              if (_isRecording && _isPaused)
                IconButton(
                  icon: const Icon(Icons.mic, size: 48, color: Colors.red),
                  onPressed: _resumeRecording,
                ),
              IconButton(
                icon: Icon(_isRecording ? Icons.stop : Icons.mic, size: 48),
                onPressed: _isRecording ? _stopRecording : _startRecording,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Appuyez pour enregistrer', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
