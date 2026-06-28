import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/presentation/network/network_view_model.dart';

class ShortFullscreenScreen extends StatefulWidget {
  final List<Short> shorts;
  final int initialIndex;

  const ShortFullscreenScreen({
    super.key,
    required this.shorts,
    this.initialIndex = 0,
  });

  @override
  State<ShortFullscreenScreen> createState() => _ShortFullscreenScreenState();
}

class _ShortFullscreenScreenState extends State<ShortFullscreenScreen> {
  late PageController _pageController;
  late int _currentIndex;
  VideoPlayerController? _videoController;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _loadShort(_currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _loadShort(int index) {
    final short = widget.shorts[index];
    _videoController?.dispose();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(short.videoUrl))
      ..initialize().then((_) {
        setState(() {});
        if (_isPlaying) _videoController!.play();
      });
  }

  void _togglePlayPause() {
    if (_videoController == null || !_videoController!.value.isInitialized) return;
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _videoController!.play();
      } else {
        _videoController!.pause();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: widget.shorts.length,
            onPageChanged: (index) {
              _currentIndex = index;
              _loadShort(index);
            },
            itemBuilder: (context, index) {
              final short = widget.shorts[index];
              return GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  color: Colors.black,
                  child: Center(
                    child: _videoController != null && _videoController!.value.isInitialized
                        ? AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          )
                        : const CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              );
            },
          ),
          // Info overlay (en bas)
          Positioned(
            bottom: 40,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: widget.shorts[_currentIndex].userAvatarUrl != null
                          ? NetworkImage(widget.shorts[_currentIndex].userAvatarUrl!)
                          : null,
                      child: widget.shorts[_currentIndex].userAvatarUrl == null
                          ? Text(widget.shorts[_currentIndex].userName[0].toUpperCase())
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.shorts[_currentIndex].userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (widget.shorts[_currentIndex].userTitle != null)
                            Text(
                              widget.shorts[_currentIndex].userTitle!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.shorts[_currentIndex].description,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: widget.shorts[_currentIndex].hashtags.map((tag) {
                    return Text(
                      tag,
                      style: const TextStyle(color: Colors.blue, fontSize: 13),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _actionIcon(Icons.favorite_border, widget.shorts[_currentIndex].likes),
                    const SizedBox(width: 20),
                    _actionIcon(Icons.comment_outlined, widget.shorts[_currentIndex].comments),
                    const SizedBox(width: 20),
                    _actionIcon(Icons.share_outlined, 0),
                  ],
                ),
              ],
            ),
          ),
          // Bouton fermer
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionIcon(IconData icon, int count) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        if (count > 0)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              count.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
      ],
    );
  }
}
