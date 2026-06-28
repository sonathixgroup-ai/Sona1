import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/call_model.dart';

class AudioCallScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String recipientName;
  final String? recipientAvatar;
  final bool isIncoming;

  const AudioCallScreen({
    Key? key,
    required this.conversationId,
    required this.recipientName,
    this.recipientAvatar,
    this.isIncoming = false,
  }) : super(key: key);

  @override
  ConsumerState<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends ConsumerState<AudioCallScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isMuted = false;
  bool _isOnSpeaker = false;
  Duration _callDuration = Duration.zero;
  late DateTime _callStartTime;

  @override
  void initState() {
    super.initState();
    _callStartTime = DateTime.now();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _startCallTimer();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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
      backgroundColor: Colors.black87,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Recipient Avatar
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
            const SizedBox(height: 24),
            // Recipient Name
            Text(
              widget.recipientName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Call Status
            Text(
              widget.isIncoming ? 'Appel entrant...' : 'Appel en cours',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            // Call Duration
            Text(
              _formatDuration(_callDuration),
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 48),
            // Control Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildControlButton(
                  icon: _isMuted ? Icons.mic_off : Icons.mic,
                  label: _isMuted ? 'Activer' : 'Couper',
                  onTap: () => setState(() => _isMuted = !_isMuted),
                  color: _isMuted ? Colors.red : const Color(0xFF5A67D8),
                ),
                const SizedBox(width: 24),
                _buildControlButton(
                  icon: _isOnSpeaker ? Icons.volume_up : Icons.volume_down,
                  label: _isOnSpeaker ? 'Écouteur' : 'HP',
                  onTap: () => setState(() => _isOnSpeaker = !_isOnSpeaker),
                ),
                const SizedBox(width: 24),
                _buildControlButton(
                  icon: Icons.call_end,
                  label: 'Raccrocher',
                  onTap: () => Navigator.pop(context),
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = const Color(0xFF5A67D8),
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
