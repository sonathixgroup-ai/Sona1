import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/network_story.dart';

class StoryViewer extends StatefulWidget {
  final List<NetworkStory> stories;
  final int initialIndex;
  const StoryViewer({super.key, required this.stories, required this.initialIndex});
  @override State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> {
  late PageController _controller;
  late int _currentIndex;
  Timer? _timer;
  double _progress = 0;
  bool _paused = false;

  @override void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
    _startTimer();
  }

  @override void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _progress = 0;
    const duration = Duration(milliseconds: 5000);
    const tick = Duration(milliseconds: 50);
    _timer = Timer.periodic(tick, (t) {
      if (_paused ||!mounted) return;
      setState(() {
        _progress += tick.inMilliseconds / duration.inMilliseconds;
        if (_progress >= 1) {
          _progress = 0;
          if (_currentIndex < widget.stories.length - 1) {
            _controller.nextPage(duration: Duration(milliseconds: 250), curve: Curves.easeOut);
          } else {
            Navigator.pop(context);
          }
        }
      });
    });
  }

  Future<void> _deleteStory(String storyId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Supprimer la story?'),
        content: Text('Irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm!= true) return;
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('stories').delete().eq('id', storyId);
      // optionnel: supprime aussi le fichier storage si tu stockes le path
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Story supprimée'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final dx = details.globalPosition.dx;
          final w = MediaQuery.of(context).size.width;
          if (dx < w * 0.3) {
            if (_currentIndex > 0) _controller.previousPage(duration: Duration(milliseconds: 200), curve: Curves.easeOut);
          } else if (dx > w * 0.7) {
            if (_currentIndex < widget.stories.length - 1) {
              _controller.nextPage(duration: Duration(milliseconds: 200), curve: Curves.easeOut);
            } else {
              Navigator.pop(context);
            }
          }
        },
        onLongPressStart: (_) => setState(() => _paused = true),
        onLongPressEnd: (_) => setState(() => _paused = false),
        child: PageView.builder(
          controller: _controller,
          onPageChanged: (i) { setState(() { _currentIndex = i; _progress = 0; }); _startTimer(); },
          itemCount: widget.stories.length,
          itemBuilder: (context, index) {
            final s = widget.stories[index];
            final safeUrl = s.imageUrl?? '';
            final storyText = s.textContent?? s.text?? '';
            final isMyStory = s.userId == currentUserId;

            return Stack(
              children: [
                Positioned.fill(
                  child: safeUrl.isNotEmpty
                     ? Image.network(safeUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 50)))
                      : Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1B3B7A), Color(0xFF0B1B3D)]))),
                ),
                if (storyText.isNotEmpty)
                  Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Text(storyText, textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600, shadows: [Shadow(color: Colors.black87, blurRadius: 8)])))),

                // Progress bar
                Positioned(top: 0, left: 0, right: 0, child: SafeArea(child: Padding(padding: EdgeInsets.all(6), child: Row(children: List.generate(widget.stories.length, (i) {
                  return Expanded(child: Container(margin: EdgeInsets.symmetric(horizontal: 2), height: 3, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)), child: Align(alignment: Alignment.centerLeft, child: FractionallySizedBox(widthFactor: i == _currentIndex? _progress : (i < _currentIndex? 1.0 : 0.0), child: Container(color: Colors.white)))));
                }))))),

                // Header
                Positioned(top: 30, left: 16, right: 16, child: SafeArea(child: Row(children: [
                  CircleAvatar(radius: 18, backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white)),
                  SizedBox(width: 12),
                  Expanded(child: Text(s.userName, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, shadows: [Shadow(blurRadius: 4)])))),
                  if (isMyStory) Container(decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(20)), child: IconButton(icon: Icon(Icons.delete_outline, color: Colors.white), onPressed: () => _deleteStory(s.id))),
                  SizedBox(width: 8),
                  Container(decoration: BoxDecoration(color: Colors.black45, shape: BoxShape.circle), child: IconButton(icon: Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context))),
                ]))),
              ],
            );
          },
        ),
      ),
    );
  }
}
