// lib/presentation/chat/video_message/video_message_widget.dart
// Widget pour enregistrer/envoyer un message vidéo (court, type TikTok)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';

class VideoMessageWidget extends StatefulWidget {
  final Function(File videoFile, int durationSeconds) onVideoRecorded;

  const VideoMessageWidget({Key? key, required this.onVideoRecorded}) : super(key: key);

  @override
  State<VideoMessageWidget> createState() => _VideoMessageWidgetState();
}

class _VideoMessageWidgetState extends State<VideoMessageWidget> {
  final ImagePicker _picker = ImagePicker();
  File? _videoFile;
  VideoPlayerController? _controller;
  bool _isPlaying = false;

  Future<void> _recordVideo() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: 60),
    );
    if (video != null) {
      final file = File(video.path);
      setState(() => _videoFile = file);
      _controller = VideoPlayerController.file(file);
      await _controller!.initialize();
      setState(() {});
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      final file = File(video.path);
      setState(() => _videoFile = file);
      _controller = VideoPlayerController.file(file);
      await _controller!.initialize();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Message vidéo')),
      body: Center(
        child: _videoFile == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _recordVideo,
                    icon: const Icon(Icons.videocam),
                    label: const Text('Enregistrer une vidéo'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _pickVideo,
                    icon: const Icon(Icons.folder),
                    label: const Text('Choisir dans la galerie'),
                  ),
                ],
              )
            : Column(
                children: [
                  AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                        onPressed: () {
                          setState(() {
                            if (_isPlaying) {
                              _controller!.pause();
                            } else {
                              _controller!.play();
                            }
                            _isPlaying = !_isPlaying;
                          });
                        },
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: () {
                          final duration = _controller!.value.duration.inSeconds;
                          widget.onVideoRecorded(_videoFile!, duration);
                          Navigator.pop(context);
                        },
                        child: const Text('Envoyer'),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
