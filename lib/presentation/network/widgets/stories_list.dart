import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/services/network_service.dart';
import 'package:thix_id/models/network_story.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

class StoriesList extends StatefulWidget {
  final Function(NetworkStory)? onStoryTap;
  final VoidCallback? onCreateStory;

  const StoriesList({
    super.key,
    this.onStoryTap,
    this.onCreateStory,
  });

  @override
  State<StoriesList> createState() => _StoriesListState();
}

class _StoriesListState extends State<StoriesList> {
  late NetworkService _networkService;
  List<NetworkStory> _stories = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _networkService = NetworkService(Supabase.instance.client);
    _loadStories();
  }

  Future<void> _loadStories() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stories = await _networkService.getActiveStories();
      setState(() {
        _stories = stories;
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ Erreur chargement stories: $e');
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _getTimeRemaining(DateTime expiresAt) {
    final now = DateTime.now();
    if (expiresAt.isBefore(now)) return 'expirée';
    final remaining = expiresAt.difference(now);
    if (remaining.inHours > 0) return '${remaining.inHours}h';
    if (remaining.inMinutes > 0) return '${remaining.inMinutes}min';
    return 'bientôt';
  }

  String _formatRelativeTime(DateTime createdAt) {
    return timeago.format(createdAt, locale: 'fr');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    if (_loading) {
      return const SizedBox(
        height: 72,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Erreur: $_error',
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: _loadStories,
              child: const Text('Réessayer', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    }

    if (_stories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Stories',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              TextButton(
                onPressed: _loadStories,
                child: const Text('Tout voir', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _stories.length + 1, // +1 pour "Ajouter une story"
            itemBuilder: (context, index) {
              // Premier élément = bouton "Ajouter une story" (si l'utilisateur est connecté)
              if (index == 0 && _stories.isNotEmpty) {
                return _buildAddStoryButton(context);
              }
              final storyIndex = index - 1;
              if (storyIndex < 0 || storyIndex >= _stories.length) {
                return const SizedBox.shrink();
              }
              final story = _stories[storyIndex];
              return _buildStoryItem(context, story);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddStoryButton(BuildContext context) {
    return GestureDetector(
      onTap: widget.onCreateStory ?? () {},
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    color: Colors.white,
                  ),
                  child: const Center(
                    child: Icon(Icons.add, size: 28, color: Colors.blue),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.live_tv, size: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Ma Story',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryItem(BuildContext context, NetworkStory story) {
    final isViewed = story.isViewed ?? false;
    final isCurrentUser = story.isCurrentUser ?? false;
    final hasAvatar = story.userAvatar != null && story.userAvatar!.isNotEmpty;
    final timeRemaining = _getTimeRemaining(story.expiresAt);
    final isExpired = story.expiresAt.isBefore(DateTime.now());

    return GestureDetector(
      onTap: () {
        if (isExpired) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cette story a expiré'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        widget.onStoryTap?.call(story);
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Stack(
              children: [
                // Avatar avec bordure
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isViewed
                        ? null
                        : const LinearGradient(
                            colors: [Colors.blue, Colors.purple],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    border: isViewed
                        ? Border.all(color: Colors.grey.shade300, width: 2)
                        : null,
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: hasAvatar
                        ? CachedNetworkImageProvider(story.userAvatar!)
                        : null,
                    child: !hasAvatar
                        ? Text(
                            story.userName.isNotEmpty
                                ? story.userName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          )
                        : null,
                  ),
                ),
                // Badge "Live" si actif
                if (!isViewed && !isCurrentUser && !isExpired)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // Indicateur "Vu"
                if (isViewed && !isCurrentUser)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: Colors.grey,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              story.userName,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (!isCurrentUser)
              Text(
                isExpired ? 'expirée' : timeRemaining,
                style: TextStyle(
                  fontSize: 8,
                  color: isExpired ? Colors.red : Colors.grey.shade500,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
