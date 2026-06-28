import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VideoCallScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String recipientName;
  final String? recipientAvatar;
  final bool isIncoming;

  const VideoCallScreen({
    Key? key,
    required this.conversationId,
    required this.recipientName,
    this.recipientAvatar,
    this.isIncoming = false,
  }) : super(key: key);

  @override
  ConsumerState<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends ConsumerState<VideoCallScreen> {
  bool _isCameraOn = true;
  bool _isMuted = false;
  bool _isScreenSharing = false;
  Duration _callDuration = Duration.zero;
  late DateTime _callStartTime;

  @override
  void initState() {
    super.initState();
    _callStartTime = DateTime.now();
    _startCallTimer();
  }

  void _startCallTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _callDuration = DateTime.now().difference(_callStartTime);
        });
        _startCallTimer();
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote Video (or placeholder)
          Container(
            color: Colors.grey[900],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF5A67D8),
                      image: widget.recipientAvatar != null
                          ? DecorationImage(
                              image: NetworkImage(widget.recipientAvatar!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: widget.recipientAvatar == null
                        ? Center(
                            child: Text(
                              widget.recipientName[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.recipientName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDuration(_callDuration),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Local Video Preview (top-right)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              width: 100,
              height: 140,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[800],
              ),
              child: _isCameraOn
                  ? const Icon(Icons.videocam, color: Colors.white, size: 40)
                  : const Icon(Icons.videocam_off, color: Colors.grey, size: 40),
            ),
          ),
          // Controls at bottom
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildVideoControlButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    onTap: () => setState(() => _isMuted = !_isMuted),
                    color: _isMuted ? Colors.red : const Color(0xFF5A67D8),
                  ),
                  const SizedBox(width: 24),
                  _buildVideoControlButton(
                    icon: _isCameraOn ? Icons.videocam : Icons.videocam_off,
                    onTap: () => setState(() => _isCameraOn = !_isCameraOn),
                    color: _isCameraOn ? const Color(0xFF5A67D8) : Colors.red,
                  ),
                  const SizedBox(width: 24),
                  _buildVideoControlButton(
                    icon: Icons.screen_share,
                    onTap: () => setState(() => _isScreenSharing = !_isScreenSharing),
                    color: _isScreenSharing
                        ? const Color(0xFF5A67D8)
                        : Colors.grey[700]!,
                  ),
                  const SizedBox(width: 24),
                  _buildVideoControlButton(
                    icon: Icons.call_end,
                    onTap: () => Navigator.pop(context),
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
