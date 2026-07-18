import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

const Color kViolet = Color(0xFF7C5CFC);
const Color kBgBlack = Color(0xFF080610);

class VideoPlayerPage extends StatefulWidget {
  final String title;
  final String videoUrl;
  const VideoPlayerPage({super.key, required this.title, required this.videoUrl});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isError = false;
  bool _showControls = true;
  bool _isFullscreen = false;
  bool _isLocked = false;
  bool _isMuted = false;
  Timer? _hideTimer;
  Timer? _seekTextTimer;
  String _seekText = '';

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      _controller.addListener(_listener);
      await _controller.initialize();
      if (!mounted) return;
      setState(() {
        _isInitialized = true;
        _duration = _controller.value.duration;
      });
      _controller.play();
      _startHideTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isError = true);
    }
  }

  void _listener() {
    if (!_controller.value.isInitialized) return;
    if (!mounted) return;
    setState(() {
      _duration = _controller.value.duration;
      _position = _controller.value.position;
    });
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller.value.isPlaying && !_isLocked) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _startHideTimer();
  }

  void _togglePlay() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
    _startHideTimer();
  }

  void _seekRelative(int seconds) {
    final newPos = _position + Duration(seconds: seconds);
    _controller.seekTo(newPos < Duration.zero ? Duration.zero : newPos > _duration ? _duration : newPos);
    setState(() => _seekText = '${seconds > 0 ? '+' : ''}$seconds s');
    _seekTextTimer?.cancel();
    _seekTextTimer = Timer(const Duration(milliseconds: 800), () => setState(() => _seekText = ''));
    _startHideTimer();
  }

  void _toggleFullscreen() async {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _controller.setVolume(_isMuted ? 0 : 1);
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _seekTextTimer?.cancel();
    _controller.removeListener(_listener);
    _controller.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgBlack,
      body: SafeArea(
        top: !_isFullscreen,
        bottom: false,
        child: _isError ? _buildError() : !_isInitialized ? _buildLoading() : _buildPlayer(),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: kViolet, strokeWidth: 2.5)),
        const SizedBox(height: 12),
        Text(widget.title, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        const Text('Chargement...', style: TextStyle(color: Colors.white38, fontSize: 10)),
      ]),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), shape: BoxShape.circle), child: const Icon(Icons.play_disabled_rounded, size: 32, color: Colors.white54)),
          const SizedBox(height: 14),
          const Text('Impossible de lire la vidéo', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Vérifie ta connexion ou réessaie plus tard', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 10.5)),
          const SizedBox(height: 18),
          ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: kViolet, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)), child: const Text('Retour', style: TextStyle(fontSize: 11, color: Colors.white))),
        ]),
      ),
    );
  }

  Widget _buildPlayer() {
    final progress = _duration.inMilliseconds == 0 ? 0.0 : _position.inMilliseconds / _duration.inMilliseconds;
    return GestureDetector(
      onTap: _toggleControls,
      onDoubleTapDown: (details) {
        final width = MediaQuery.of(context).size.width;
        if (details.globalPosition.dx < width / 2) {
          _seekRelative(-10);
        } else {
          _seekRelative(10);
        }
      },
      child: Stack(
        children: [
          Center(child: AspectRatio(aspectRatio: _controller.value.aspectRatio, child: VideoPlayer(_controller))),
          
          // Gradient haut et bas pour lisibilité
          if (_showControls) ...[
            Positioned.fill(child: IgnorePointer(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.6), Colors.transparent, Colors.transparent, Colors.black.withOpacity(0.75)]))))),
          ],

          // Seek text central
          if (_seekText.isNotEmpty)
            Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)), child: Text(_seekText, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)))),

          // TOP BAR
          if (_showControls)
            Positioned(
              top: 0, left: 0, right: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                child: Row(
                  children: [
                    InkWell(onTap: () => Navigator.pop(context), borderRadius: BorderRadius.circular(20), child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.black45, shape: BoxShape.circle), child: const Icon(Icons.arrow_back_rounded, size: 16, color: Colors.white))),
                    const SizedBox(width: 10),
                    Expanded(child: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600))),
                    InkWell(onTap: _toggleMute, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.black45, shape: BoxShape.circle), child: Icon(_isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded, size: 16, color: Colors.white))),
                    const SizedBox(width: 8),
                    InkWell(onTap: _toggleFullscreen, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.black45, shape: BoxShape.circle), child: Icon(_isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded, size: 16, color: Colors.white))),
                  ],
                ),
              ),
            ),

          // CENTER PLAY
          if (_showControls && !_isLocked)
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _circleBtn(Icons.replay_10_rounded, () => _seekRelative(-10)),
                  const SizedBox(width: 18),
                  GestureDetector(
                    onTap: _togglePlay,
                    child: Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(color: kViolet, shape: BoxShape.circle, boxShadow: [BoxShadow(color: kViolet.withOpacity(0.4), blurRadius: 18)]),
                      child: Icon(_controller.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 28, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 18),
                  _circleBtn(Icons.forward_10_rounded, () => _seekRelative(10)),
                ],
              ),
            ),

          // BOTTOM CONTROLS
          if (_showControls)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, 0, 12, _isFullscreen ? 10 : 18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        InkWell(onTap: () => setState(() => _isLocked = !_isLocked), child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Row(children: [Icon(_isLocked ? Icons.lock_rounded : Icons.lock_open_rounded, size: 10, color: Colors.white), const SizedBox(width: 4), Text(_isLocked ? 'Verrouillé' : 'Verrouiller', style: const TextStyle(color: Colors.white, fontSize: 9))]))),
                        const Spacer(),
                        Text('${_fmt(_position)} / ${_fmt(_duration)}', style: const TextStyle(color: Colors.white70, fontSize: 9.5)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                        activeTrackColor: kViolet,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: kViolet,
                      ),
                      child: Slider(
                        value: progress.clamp(0.0, 1.0),
                        onChanged: (v) {
                          final newPos = Duration(milliseconds: (v * _duration.inMilliseconds).round());
                          _controller.seekTo(newPos);
                        },
                        onChangeStart: (_) => _hideTimer?.cancel(),
                        onChangeEnd: (_) => _startHideTimer(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // LOCKED overlay
          if (_isLocked && _showControls)
            Positioned(
              bottom: 20, left: 0, right: 0,
              child: Center(child: InkWell(onTap: () => setState(() => _isLocked = false), child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.lock_rounded, size: 12, color: Colors.white), SizedBox(width: 6), Text('Appuie pour déverrouiller', style: TextStyle(color: Colors.white, fontSize: 10))])))),
            ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle, border: Border.all(color: Colors.white24)), child: Icon(icon, size: 18, color: Colors.white)),
    );
  }
}
