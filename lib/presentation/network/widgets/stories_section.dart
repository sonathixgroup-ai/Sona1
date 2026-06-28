// lib/presentation/network/widgets/stories_section.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thix_id/presentation/network/state/network_provider.dart';
import 'package:thix_id/presentation/network/models/story_model.dart';

class StoriesSection extends StatelessWidget {
  const StoriesSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stories = context.select((NetworkProvider p) => p.state.stories);
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _CreateStoryTile();
          }
          final StoryModel s = stories[index - 1];
          return _StoryTile(story: s);
        },
      ),
    );
  }
}

class _CreateStoryTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
          child: IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
        ),
        const SizedBox(height: 8),
        const SizedBox(width: 72, child: Text('Créer une story', textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

class _StoryTile extends StatelessWidget {
  final StoryModel story;
  const _StoryTile({Key? key, required this.story}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(radius: 34, backgroundImage: NetworkImage(story.avatarUrl)),
        const SizedBox(height: 8),
        SizedBox(width: 72, child: Text(story.displayName, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
