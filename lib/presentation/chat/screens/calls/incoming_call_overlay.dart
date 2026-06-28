import 'package:flutter/material.dart';

class IncomingCallOverlay extends StatefulWidget {
  final String callerName;
  final String? callerAvatar;
  final bool isVideo;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const IncomingCallOverlay({
    Key? key,
    required this.callerName,
    this.callerAvatar,
    this.isVideo = false,
    required this.onAccept,
    required this.onReject,
  }) : super(key: key);

  @override
  State<IncomingCallOverlay> createState() => _IncomingCallOverlayState();
}

class _IncomingCallOverlayState extends State<IncomingCallOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  const Color(0xFF5A67D8).withOpacity(0.3),
                ],
              ),
            ),
          ),
          // Call info
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Avatar
                ScaleTransition(
                  scale: Tween<double>(begin: 0.8, end: 1.0)
                      .animate(_pulseController),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF5A67D8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5A67D8).withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                      image: widget.callerAvatar != null
                          ? DecorationImage(
                              image: NetworkImage(widget.callerAvatar!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: widget.callerAvatar == null
                        ? Center(
                            child: Text(
                              widget.callerName[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 24),
                // Caller name
                Text(
                  widget.callerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Call type
                Text(
                  widget.isVideo ? 'Appel vidéo entrant' : 'Appel entrant',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          // Action buttons at bottom
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Reject button
                GestureDetector(
                  onTap: widget.onReject,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                    ),
                    child: const Icon(
                      Icons.call_end,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
                // Accept button
                GestureDetector(
                  onTap: widget.onAccept,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green,
                    ),
                    child: Icon(
                      widget.isVideo ? Icons.videocam : Icons.call,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
