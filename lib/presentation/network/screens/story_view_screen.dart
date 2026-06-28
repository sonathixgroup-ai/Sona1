import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/story_model.dart';

class StoryViewScreen extends StatefulWidget {
  final List<Story> stories;
  final int initialIndex;

  const StoryViewScreen({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> {
  late PageController _pageController;
  late int _currentIndex;
  VideoPlayerController? _videoController;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _loadStory(_currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _loadStory(int index) {
    final story = widget.stories[index];
    // Marquer la story comme vue
    _markStoryViewed(story.id);

    // Charger le média si c'est une vidéo
    if (story.mediaUrl != null && story.mediaUrl!.endsWith('.mp4')) {
      _videoController?.dispose();
      _videoController = VideoPlayerController.networkUrl(Uri.parse(story.mediaUrl!))
        ..initialize().then((_) {
          setState(() {});
          _videoController!.play();
        });
    } else {
      _videoController?.dispose();
      _videoController = null;
    }

    // Démarrer le timer pour passer à la story suivante
    _startTimer();
  }

  void _markStoryViewed(String storyId) async {
    try {
      await Supabase.instance.client
          .from('stories')
          .update({'is_viewed': true})
          .eq('id', storyId);
    } catch (e) {
      // Ignorer les erreurs
    }
  }

  void _startTimer() {
    _progress = 0.0;
    const duration = Duration(seconds: 5);
    final startTime = DateTime.now();

    Future.doWhile(() async {
      final elapsed = DateTime.now().difference(startTime).inMilliseconds / 1000;
      final progress = (elapsed / duration.inSeconds).clamp(0.0, 1.0);
      setState(() => _progress = progress);
      if (progress >= 1.0) {
        _nextStory();
        return false;
      }
      await Future.delayed(const Duration(milliseconds: 50));
      return true;
    });
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      _currentIndex++;
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _loadStory(_currentIndex);
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _loadStory(_currentIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.localPosition.dx > width / 2) {
            _nextStory();
          } else {
            _previousStory();
          }
        },
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.stories.length,
              onPageChanged: (index) {
                _currentIndex = index;
                _loadStory(index);
              },
              itemBuilder: (context, index) {
                final story = widget.stories[index];
                return Container(
                  color: Colors.black,
                  child: story.mediaUrl != null
                      ? _videoController != null && _videoController!.value.isInitialized
                          ? VideoPlayer(_videoController!)
                          : Image.network(
                              story.mediaUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.error, color: Colors.white),
                              ),
                            )
                      : Center(
                          child: Text(
                            'Story de ${story.userName}',
                            style: const TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ),
                );
              },
            ),
            // Barre de progression
            Positioned(
              top: 40,
              left: 16,
              right: 16,
              child: Row(
                children: widget.stories.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final progress = idx < _currentIndex
                      ? 1.0
                      : idx == _currentIndex
                          ? _progress
                          : 0.0;
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      color: Colors.grey.shade700,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(color: Colors.white),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            // Informations utilisateur
            Positioned(
              top: 48,
              left: 16,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: widget.stories[_currentIndex].avatarUrl != null
                        ? NetworkImage(widget.stories[_currentIndex].avatarUrl!)
                        : null,
                    child: widget.stories[_currentIndex].avatarUrl == null
                        ? Text(widget.stories[_currentIndex].userName[0].toUpperCase())
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.stories[_currentIndex].userName,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            // Bouton fermer
            Positioned(
              top: 48,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
