import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class VoiceChatWidget extends StatefulWidget {
  final String conversationId;
  final String receiverId;
  final Function(File)? onAudioRecorded;

  const VoiceChatWidget({
    super.key,
    required this.conversationId,
    required this.receiverId,
    this.onAudioRecorded,
  });

  @override
  State<VoiceChatWidget> createState() => _VoiceChatWidgetState();
}

class _VoiceChatWidgetState extends State<VoiceChatWidget> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;
  Duration _playbackPosition = Duration.zero;
  Timer? _recordingTimer;
  Timer? _playbackTimer;
  AudioPlayer? _audioPlayer;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _playbackTimer?.cancel();
    _recorder.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
    await Permission.storage.request();
  }

  Future<void> _startRecording() async {
    if (await _recorder.hasPermission()) {
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      
      await _recorder.start(
        RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000,
          sampleRate: 44100,
        ),
        path: path,
      );
      
      setState(() {
        _isRecording = true;
        _recordingPath = path;
        _recordingDuration = Duration.zero;
      });
      
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration += const Duration(seconds: 1);
        });
      });
    }
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    _recordingTimer?.cancel();
    
    setState(() {
      _isRecording = false;
    });
    
    if (path != null && mounted) {
      final file = File(path);
      widget.onAudioRecorded?.call(file);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message vocal enregistré')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _playRecording(File audioFile) async {
    if (_isPlaying) {
      await _audioPlayer?.stop();
      _playbackTimer?.cancel();
      setState(() {
        _isPlaying = false;
        _playbackPosition = Duration.zero;
      });
      return;
    }
    
    _audioPlayer = AudioPlayer();
    _audioPlayer?.setSourceUrl(audioFile.path);
    
    _audioPlayer?.setPlaybackRate(1.0);
    await _audioPlayer?.play();
    
    setState(() {
      _isPlaying = true;
      _playbackPosition = Duration.zero;
    });
    
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final position = _audioPlayer?.getCurrentPosition() ?? Duration.zero;
      final duration = _audioPlayer?.getDuration() ?? Duration.zero;
      
      setState(() {
        _playbackPosition = position;
      });
      
      if (position >= duration && duration > Duration.zero) {
        timer.cancel();
        setState(() {
          _isPlaying = false;
          _playbackPosition = Duration.zero;
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const Text(
            'Message vocal temporaire',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Votre message sera supprimé après écoute',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          
          // Recording UI
          if (_isRecording)
            Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic, size: 30, color: Colors.red),
                ),
                const SizedBox(height: 12),
                Text(
                  _formatDuration(_recordingDuration),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildWaveAnimation(),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _stopRecording,
                  icon: const Icon(Icons.stop),
                  label: const Text('Arrêter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ],
            )
          else if (_recordingPath != null)
            Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5592F).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () => _playRecording(File(_recordingPath!)),
                    icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow, size: 30),
                    color: const Color(0xFFE5592F),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${_formatDuration(_playbackPosition)} / ${_formatDuration(_recordingDuration)}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: _recordingDuration.inSeconds > 0
                      ? _playbackPosition.inSeconds / _recordingDuration.inSeconds
                      : 0,
                  backgroundColor: Colors.grey[200],
                  color: const Color(0xFFE5592F),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_recordingPath != null) {
                            widget.onAudioRecorded?.call(File(_recordingPath!));
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE5592F),
                        ),
                        child: const Text('Envoyer'),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Column(
              children: [
                GestureDetector(
                  onLongPress: _startRecording,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5592F).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mic, size: 40, color: Color(0xFFE5592F)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Maintenez enfoncé pour enregistrer',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildWaveAnimation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return Container(
          width: 4,
          height: 20 + (index * 5),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFE5592F),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}

// Simple audio player class (simplified)
class AudioPlayer {
  dynamic _player;
  
  Future<void> setSourceUrl(String path) async {
    // In real implementation, use audio player package
  }
  
  Future<void> play() async {}
  
  Future<void> stop() async {}
  
  Future<void> setPlaybackRate(double rate) async {}
  
  Duration getCurrentPosition() => Duration.zero;
  
  Duration getDuration() => Duration.zero;
  
  void dispose() {}
}
