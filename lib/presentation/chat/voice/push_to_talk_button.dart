// lib/presentation/chat/voice/push_to_talk_button.dart
// Bouton poussoir pour envoi de message vocal (maintenir pour enregistrer)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class PushToTalkButton extends StatefulWidget {
  final Function(File recordingFile, int durationSeconds) onSendVoice;

  const PushToTalkButton({Key? key, required this.onSendVoice}) : super(key: key);

  @override
  State<PushToTalkButton> createState() => _PushToTalkButtonState();
}

class _PushToTalkButtonState extends State<PushToTalkButton> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _filePath;
  int _recordDuration = 0;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return;
    final dir = await getTemporaryDirectory();
    _filePath = '${dir.path}/ptt_${DateTime.now().millisecondsSinceEpoch}.m4a';
  }

  Future<void> _startRecording() async {
    if (_filePath == null) return;
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: _filePath!,
    );
    setState(() => _isRecording = true);
    _recordDuration = 0;
    _updateDuration();
  }

  Future<void> _updateDuration() async {
    while (_isRecording) {
      await Future.delayed(const Duration(seconds: 1));
      final duration = await _recorder.getDuration();
      if (mounted && duration != null) {
        setState(() => _recordDuration = duration.inSeconds);
      }
    }
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    setState(() => _isRecording = false);
    if (path != null && _recordDuration > 0) {
      widget.onSendVoice(File(path), _recordDuration);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _startRecording(),
      onLongPressEnd: (_) => _stopRecording(),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: _isRecording ? Colors.red : Theme.of(context).primaryColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: _isRecording
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.mic, color: Colors.white),
                    Text(
                      '$_recordDuration s',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                )
              : const Icon(Icons.mic, color: Colors.white),
        ),
      ),
    );
  }
}
