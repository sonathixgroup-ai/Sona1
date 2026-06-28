import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupCallScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String conversationName;
  final List<String> participantNames;

  const GroupCallScreen({
    Key? key,
    required this.conversationId,
    required this.conversationName,
    required this.participantNames,
  }) : super(key: key);

  @override
  ConsumerState<GroupCallScreen> createState() => _GroupCallScreenState();
}

class _GroupCallScreenState extends ConsumerState<GroupCallScreen> {
  bool _isCameraOn = true;
  bool _isMuted = false;
  String _viewMode = 'grid'; // grid or focus
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
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.conversationName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${widget.participantNames.length} participants - ${_formatDuration(_callDuration)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _viewMode == 'grid'
                ? _buildGridView()
                : _buildFocusView(),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildGroupCallButton(
              icon: _isMuted ? Icons.mic_off : Icons.mic,
              onTap: () => setState(() => _isMuted = !_isMuted),
              color: _isMuted ? Colors.red : const Color(0xFF5A67D8),
            ),
            const SizedBox(width: 24),
            _buildGroupCallButton(
              icon: _isCameraOn ? Icons.videocam : Icons.videocam_off,
              onTap: () => setState(() => _isCameraOn = !_isCameraOn),
              color: _isCameraOn ? const Color(0xFF5A67D8) : Colors.red,
            ),
            const SizedBox(width: 24),
            _buildGroupCallButton(
              icon: _viewMode == 'grid' ? Icons.dashboard : Icons.person,
              onTap: () => setState(
                  () => _viewMode = _viewMode == 'grid' ? 'focus' : 'grid'),
            ),
            const SizedBox(width: 24),
            _buildGroupCallButton(
              icon: Icons.call_end,
              onTap: () => Navigator.pop(context),
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: widget.participantNames.length,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
            border: index == 0
                ? Border.all(color: const Color(0xFF5A67D8), width: 2)
                : null,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF5A67D8),
                  ),
                  child: Center(
                    child: Text(
                      widget.participantNames[index][0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.participantNames[index],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFocusView() {
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF5A67D8),
                ),
                child: Center(
                  child: Text(
                    widget.participantNames[0][0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.participantNames[0],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 16,
          left: 16,
          child: SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.participantNames.length - 1,
              itemBuilder: (context, index) {
                final name = widget.participantNames[index + 1];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF5A67D8),
                          ),
                          child: Center(
                            child: Text(
                              name[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          name.split(' ')[0],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupCallButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = const Color(0xFF5A67D8),
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
